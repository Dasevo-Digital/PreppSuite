/// Which translation models exist and where they are fetched from (#182).
///
/// The models are Mozilla's, the ones Firefox translates with, published
/// under the MPL 2.0 through Mozilla's Remote Settings -- a public, keyless
/// list of records with the files attached. Each record is one file of one
/// direction (model, shortlist, vocabulary) in one version; this picks,
/// per direction, the newest version a released Firefox on the same kind
/// of device would get, never one held back for Nightly.
///
/// Every model translates from or into English. German to Arabic is two
/// steps, German to English and English to Arabic, which is how Firefox
/// does it too.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/http_client.dart';
import '../../phrasebook/application/phrasebook.dart' show PhraseLanguage;

/// One direction a model translates in, such as German to English.
class TranslatorDirection {
  const TranslatorDirection(this.from, this.to);

  final PhraseLanguage from;
  final PhraseLanguage to;

  /// `deen`, as Mozilla names its files.
  String get code => '${from.name}${to.name}';

  @override
  bool operator ==(Object other) =>
      other is TranslatorDirection && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => code;
}

/// The directions a translation from [from] to [to] goes through: none
/// for the same language, one where either side is English, otherwise two
/// by way of English.
List<TranslatorDirection> directionsFor(
  PhraseLanguage from,
  PhraseLanguage to,
) {
  if (from == to) return const [];
  if (from == PhraseLanguage.en || to == PhraseLanguage.en) {
    return [TranslatorDirection(from, to)];
  }
  return [
    TranslatorDirection(from, PhraseLanguage.en),
    TranslatorDirection(PhraseLanguage.en, to),
  ];
}

/// The three files a direction needs.
enum TranslatorFileKind { model, lex, vocab }

class TranslatorFile {
  const TranslatorFile({
    required this.kind,
    required this.name,
    required this.size,
    required this.sha256,
    required this.url,
  });

  final TranslatorFileKind kind;

  /// The file's own name, which the engine reads the format from: a
  /// model has to end in `.bin`.
  final String name;
  final int size;
  final String sha256;
  final Uri url;
}

/// One direction in one version, with its files.
class TranslatorPack {
  const TranslatorPack({
    required this.direction,
    required this.version,
    required this.files,
  });

  final TranslatorDirection direction;
  final String version;
  final List<TranslatorFile> files;

  int get size => files.fold(0, (sum, file) => sum + file.size);
}

class TranslatorCatalogue {
  const TranslatorCatalogue(this.packs);

  final Map<TranslatorDirection, TranslatorPack> packs;

  static const recordsUrl =
      'https://firefox.settings.services.mozilla.com/v1/buckets/main/'
      'collections/translations-models/records';
  static const serverUrl = 'https://firefox.settings.services.mozilla.com/v1/';

  /// Where the attachments were served from when this was written; used
  /// only when the server does not say.
  static const fallbackAttachmentBase =
      'https://firefox-settings-attachments.cdn.mozilla.net/';

  /// Asks Mozilla for the current list.
  static Future<TranslatorCatalogue> fetch({
    http.Client? client,
    bool? android,
  }) async {
    final http.Client http0 = client ?? TimeoutClient();
    var base = fallbackAttachmentBase;
    try {
      final server = await http0.get(Uri.parse(serverUrl));
      if (server.statusCode == 200) {
        final told =
            ((jsonDecode(utf8.decode(server.bodyBytes)) as Map)['capabilities']
                    as Map?)?['attachments']
                as Map?;
        final url = told?['base_url'];
        if (url is String && url.startsWith('https://')) base = url;
      }
    } on Object {
      // The fallback is the address the files have had for years.
    }
    final response = await http0.get(Uri.parse(recordsUrl));
    if (response.statusCode != 200) {
      throw TranslatorCatalogueException(
        'the model list answered ${response.statusCode}',
      );
    }
    return parse(
      utf8.decode(response.bodyBytes),
      attachmentBase: base,
      android: android ?? Platform.isAndroid,
    );
  }

  /// Reads the records, keeping only the directions between the
  /// phrasebook's languages and English, each in its newest released
  /// version that has all three files. [android] picks the records meant
  /// for phones where Mozilla publishes one version for Android and
  /// another for the desktop.
  static TranslatorCatalogue parse(
    String body, {
    String attachmentBase = fallbackAttachmentBase,
    bool android = false,
  }) {
    final decoded = jsonDecode(body);
    final records = decoded is Map ? decoded['data'] : null;
    if (records is! List) {
      throw const TranslatorCatalogueException('not a model list');
    }
    final languages = PhraseLanguage.values.asNameMap();
    final base = Uri.parse(attachmentBase);

    // direction -> version -> files
    final found = <TranslatorDirection, Map<String, List<TranslatorFile>>>{};
    for (final record in records.whereType<Map>()) {
      if (!releasedFor(record['filter_expression'], android: android)) {
        continue;
      }
      final from = languages[record['fromLang']];
      final to = languages[record['toLang']];
      if (from == null || to == null) continue;
      if (from != PhraseLanguage.en && to != PhraseLanguage.en) continue;
      final kind = TranslatorFileKind.values.asNameMap()[record['fileType']];
      final version = record['version'];
      final name = record['name'];
      final attachment = record['attachment'];
      if (kind == null ||
          version is! String ||
          name is! String ||
          attachment is! Map) {
        continue;
      }
      final location = attachment['location'];
      final size = attachment['size'];
      final hash = attachment['hash'];
      // A name with a path in it is not a file name. The list is
      // Mozilla's, but what it says is still read as input.
      if (location is! String ||
          size is! int ||
          hash is! String ||
          name.contains('/') ||
          name.contains(r'\') ||
          name.startsWith('.')) {
        continue;
      }
      found
          .putIfAbsent(TranslatorDirection(from, to), () => {})
          .putIfAbsent(version, () => [])
          .add(
            TranslatorFile(
              kind: kind,
              name: name,
              size: size,
              sha256: hash.toLowerCase(),
              url: base.resolve(location),
            ),
          );
    }

    final packs = <TranslatorDirection, TranslatorPack>{};
    for (final MapEntry(key: direction, value: versions) in found.entries) {
      final complete = [
        for (final MapEntry(key: version, value: files) in versions.entries)
          if (TranslatorFileKind.values.every(
            (kind) => files.where((f) => f.kind == kind).length == 1,
          ))
            (version, files),
      ]..sort((a, b) => compareModelVersions(b.$1, a.$1));
      if (complete.isEmpty) continue;
      final (version, files) = complete.first;
      packs[direction] = TranslatorPack(
        direction: direction,
        version: version,
        files: [
          for (final kind in TranslatorFileKind.values)
            files.firstWhere((f) => f.kind == kind),
        ],
      );
    }
    return TranslatorCatalogue(packs);
  }
}

/// Whether a released Firefox would take a record with [filter], on
/// Android or on a desktop.
///
/// Most records have no filter. The rest say which channel or system they
/// are for, in Firefox's own expression language, and the list has used
/// five of them, all of one shape: `env.appinfo.OS` or `env.channel`
/// compared with `==` or `!=` to a quoted word, joined by `||` and `&&`.
/// That shape is read, as a release build sees it. Anything else is not
/// guessed at: the record is passed over, as a Firefox that did not
/// understand it would.
///
/// English to Russian is why this is read at all: it has no record
/// without a filter, only 2.0 for the desktop and 2.1 for Android.
bool releasedFor(Object? filter, {required bool android}) {
  if (filter == null) return true;
  if (filter is! String) return false;
  if (filter.trim().isEmpty) return true;
  final environment = {
    'env.appinfo.OS': android ? 'Android' : 'desktop',
    'env.channel': 'release',
  };
  final term = RegExp(
    r"^\s*(env\.appinfo\.OS|env\.channel)\s*(==|!=)\s*'([^']*)'\s*$",
  );
  var anyHolds = false;
  for (final alternative in filter.split('||')) {
    var allHold = true;
    for (final part in alternative.split('&&')) {
      final match = term.firstMatch(part);
      if (match == null) return false;
      final equal = environment[match.group(1)] == match.group(3);
      if (equal != (match.group(2) == '==')) allHold = false;
    }
    if (allHold) anyHolds = true;
  }
  return anyHolds;
}

/// Orders Mozilla's model versions: `2.1` after `2.0`, and `1.0a1`, an
/// early build of 1.0, before `1.0` itself.
int compareModelVersions(String a, String b) {
  (List<int>, int?) parts(String v) {
    final match = RegExp(r'^(\d+(?:\.\d+)*)(?:[ab](\d+))?').firstMatch(v);
    if (match == null) return (const [0], null);
    return (
      [for (final n in match.group(1)!.split('.')) int.parse(n)],
      match.group(2) == null ? null : int.parse(match.group(2)!),
    );
  }

  final (na, pa) = parts(a);
  final (nb, pb) = parts(b);
  for (var i = 0; i < na.length || i < nb.length; i++) {
    final x = i < na.length ? na[i] : 0;
    final y = i < nb.length ? nb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  // Same number: the release outranks any pre-release of it.
  if (pa == null && pb == null) return 0;
  if (pa == null) return 1;
  if (pb == null) return -1;
  return pa.compareTo(pb);
}

class TranslatorCatalogueException implements Exception {
  const TranslatorCatalogueException(this.message);

  final String message;

  @override
  String toString() => 'TranslatorCatalogueException: $message';
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../../../core/http_client.dart';

/// One archive offered by the Kiwix library.
class KiwixEntry {
  const KiwixEntry({
    required this.id,
    required this.name,
    required this.title,
    required this.summary,
    required this.language,
    required this.flavour,
    required this.size,
    required this.articleCount,
    required this.hasFullTextIndex,
    required this.downloadUrl,
    required this.illustrationPath,
  });

  final String id;

  /// The archive's stable name, e.g. `wikipedia_de_all`. The same name
  /// appears once per flavour, which is why it is not an identifier.
  final String name;

  final String title;
  final String summary;

  /// ISO 639-3, e.g. `deu`. Kiwix uses three-letter codes throughout.
  final String language;

  /// `maxi`, `mini`, `nopic` or empty — how much of the source is in it.
  final String flavour;

  /// Bytes, as the catalogue states them.
  final int size;

  final int articleCount;

  /// Whether the archive carries Xapian's own full-text index. The app
  /// cannot read it (see `docs/volltextsuche-xapian.md`) but it is a fair
  /// proxy for how complete an archive is.
  final bool hasFullTextIndex;

  final Uri downloadUrl;

  /// Path of the cover image on the library host, or null.
  final String? illustrationPath;

  /// The file name the download lands under.
  String get fileName => downloadUrl.pathSegments.last;
}

/// A language the library has archives in.
class KiwixLanguage {
  const KiwixLanguage({
    required this.code,
    required this.name,
    required this.archiveCount,
  });

  /// ISO 639-3.
  final String code;

  /// The language's name in itself — "Deutsch", "français" — which is
  /// what the catalogue gives and the right thing to show in a list
  /// somebody is scanning for their own language.
  final String name;

  final int archiveCount;
}

/// A page of catalogue results.
class KiwixPage {
  const KiwixPage({required this.entries, required this.total});

  final List<KiwixEntry> entries;

  /// How many entries match, of which this page is a slice.
  final int total;
}

/// Reads the public Kiwix library catalogue.
///
/// OPDS over plain HTTP, no key and no account — the same terms as every
/// other feed this app talks to. It is used only to find an archive; once
/// the file is on the device nothing here is ever consulted again.
class KiwixCatalogue {
  KiwixCatalogue({http.Client? httpClient, Uri? host})
    : _httpClient = httpClient ?? TimeoutClient(),
      host = host ?? Uri.parse('https://library.kiwix.org');

  final http.Client _httpClient;

  /// The library host, so a test can point somewhere else.
  final Uri host;

  /// Entries matching [language] (ISO 639-3) and a free-text [query].
  ///
  /// [start] and [count] page through what the server says it has;
  /// [KiwixPage.total] is the whole count, not this page's.
  Future<KiwixPage> entries({
    String? language,
    String? query,
    int start = 0,
    int count = 30,
  }) async {
    final url = host.replace(
      path: '/catalog/v2/entries',
      queryParameters: {
        if (language != null && language.isNotEmpty) 'lang': language,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'start': '$start',
        'count': '$count',
      },
    );

    final document = await _get(url);
    return KiwixPage(
      entries: [
        for (final entry in document.findAllElements('entry'))
          ?_parseEntry(entry),
      ],
      total:
          int.tryParse(_text(document.rootElement, 'totalResults') ?? '') ?? 0,
    );
  }

  /// Every language the library holds something in, most-stocked first.
  Future<List<KiwixLanguage>> languages() async {
    final document = await _get(host.replace(path: '/catalog/v2/languages'));

    final languages = [
      for (final entry in document.findAllElements('entry'))
        if (_text(entry, 'language') case final code?)
          KiwixLanguage(
            code: code,
            name: _text(entry, 'title') ?? code,
            archiveCount: int.tryParse(_text(entry, 'count') ?? '') ?? 0,
          ),
    ];

    languages.sort((a, b) => b.archiveCount.compareTo(a.archiveCount));
    return languages;
  }

  /// The cover image for [entry], or null if it has none.
  Uri? illustration(KiwixEntry entry) {
    final path = entry.illustrationPath;
    return path == null ? null : host.resolve(path);
  }

  Future<XmlDocument> _get(Uri url) async {
    final response = await _httpClient.get(url);
    if (response.statusCode != 200) {
      throw KiwixCatalogueException(
        'the library answered ${response.statusCode}',
      );
    }
    // bodyBytes rather than body, and this is not theoretical: `body`
    // decodes as Latin-1 whenever the header names no charset, and every
    // archive title in the catalogue is in its own language. The comment
    // saying this has been here longer than the code doing it — the call
    // below was `response.body`, and "français" came through as
    // "franÃ§ais". The live server does send `charset=utf-8`, which is
    // why it never showed; a mirror that does not would mangle the whole
    // library.
    return XmlDocument.parse(
      utf8.decode(response.bodyBytes, allowMalformed: true),
    );
  }

  KiwixEntry? _parseEntry(XmlElement entry) {
    final acquisition = entry
        .findElements('link')
        .where(
          (link) =>
              link.getAttribute('rel') ==
              'http://opds-spec.org/acquisition/open-access',
        )
        .firstOrNull;

    final href = acquisition?.getAttribute('href');
    final id = _text(entry, 'id');
    if (href == null || id == null) return null;

    // The catalogue links a Metalink description of the file, not the
    // file. The archive itself lies at the same address without that
    // suffix, and answers byte ranges there — which is what a resumable
    // download of thirty gigabytes needs.
    final download = Uri.tryParse(
      href.endsWith('.meta4') ? href.substring(0, href.length - 6) : href,
    );
    if (download == null) return null;

    final tags = _text(entry, 'tags') ?? '';

    return KiwixEntry(
      id: id,
      name: _text(entry, 'name') ?? '',
      title: _text(entry, 'title') ?? '',
      summary: _text(entry, 'summary') ?? '',
      language: _text(entry, 'language') ?? '',
      flavour: _text(entry, 'flavour') ?? '',
      size: int.tryParse(acquisition?.getAttribute('length') ?? '') ?? 0,
      articleCount: int.tryParse(_text(entry, 'articleCount') ?? '') ?? 0,
      hasFullTextIndex: tags.contains('_ftindex:yes'),
      downloadUrl: download,
      illustrationPath: entry
          .findElements('link')
          .where(
            (link) =>
                link.getAttribute('rel') ==
                'http://opds-spec.org/image/thumbnail',
          )
          .firstOrNull
          ?.getAttribute('href'),
    );
  }

  /// Direct children only: `<author>` carries a `<name>` of its own, and
  /// a search through the whole subtree finds the publisher instead of
  /// the archive.
  static String? _text(XmlElement parent, String name) {
    final element = parent
        .findElements(name)
        .followedBy(parent.findElements(name, namespaceUri: '*'))
        .firstOrNull;
    final text = element?.innerText.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class KiwixCatalogueException implements Exception {
  const KiwixCatalogueException(this.message);

  final String message;

  @override
  String toString() => 'KiwixCatalogueException: $message';
}

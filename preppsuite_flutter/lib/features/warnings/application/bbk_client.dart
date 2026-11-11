import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cap_text.dart';
import 'warning_http.dart';
import 'warning_translations.dart';
import '../../../core/http_client.dart';

/// A single raw entry from a BBK (warnung.bund.de) `mapData.json` feed —
/// intentionally untyped beyond this shape; `WarningIngest` maps it onto
/// the local `warnings` table. Fields confirmed against the live API on
/// 2026-08-14; see `docs/warning-feeds.md`.
///
/// Moved here from the server unchanged when the app took over fetching:
/// the feed is public and key-less, so there was never anything a server
/// added except a hop.
class BbkRawWarning {
  const BbkRawWarning({
    required this.id,
    required this.startDate,
    required this.severity,
    required this.eventTitleDe,
    required this.raw,
    this.description,
    this.instruction,
    this.areaDescription,
    this.senderContact,
    this.polygons = const [],
    this.translations,
    this.messageType,
  });

  final String id;
  final String startDate;
  final String severity;
  final String eventTitleDe;
  final Map<String, dynamic> raw;
  final String? description;
  final String? instruction;
  final String? areaDescription;
  final String? senderContact;
  final List<String> polygons;

  /// The official translations, by language (#357). Null where the detail
  /// was not read, empty where it was and carried none.
  final Map<String, WarningTranslation>? translations;

  /// CAP's `msgType`: `Alert`, `Update` or `Cancel`. Every feed carries it
  /// (`type` in `mapData.json`, `msgType` in a dashboard's payload and the
  /// detail).
  final String? messageType;

  BbkRawWarning withDetails({
    String? description,
    String? instruction,
    String? areaDescription,
    String? senderContact,
    List<String> polygons = const [],
    Map<String, WarningTranslation> translations = const {},
    String? messageType,
  }) => BbkRawWarning(
    id: id,
    startDate: startDate,
    severity: severity,
    eventTitleDe: eventTitleDe,
    raw: raw,
    description: description,
    instruction: instruction,
    areaDescription: areaDescription,
    senderContact: senderContact,
    polygons: polygons,
    translations: translations,
    messageType: messageType ?? this.messageType,
  );
}

/// The outcome of a nationwide poll across every BBK source.
///
/// [complete] is what makes expiring stale warnings safe: a source that
/// answered with a non-200 or unparseable body yields an empty list, which
/// is indistinguishable from "nothing is warned about right now" by looking
/// at [warnings] alone. Treating a failed fetch as an empty one would
/// silently retire every active warning on a single bad response, so
/// reaping only runs when every source actually answered.
class BbkFetchResult {
  const BbkFetchResult({required this.warnings, required this.complete});

  final List<BbkRawWarning> warnings;
  final bool complete;
}

/// Fetches Germany-wide warnings from the public, key-less BBK API.
///
/// All six published sources are polled: `mowas` (the federal Modular
/// Warning System), `dwd` (weather), `katwarn`, `biwapp`, `lhp` (flooding)
/// and `police`. All confirmed live to answer 200 with the same
/// `mapData.json` array shape, so one parser covers them.
class BbkClient {
  BbkClient({http.Client? httpClient})
    : _httpClient = httpClient ?? TimeoutClient();

  final http.Client _httpClient;

  static const _sources = [
    'mowas',
    'dwd',
    'katwarn',
    'biwapp',
    'lhp',
    'police',
  ];
  static const _baseUrl = 'https://warnung.bund.de/api31';

  /// All six sources, asked at once.
  ///
  /// One after another meant six round trips to the same host before the
  /// warning list could be drawn — measured against the live server at
  /// 115 ms where asking together took 28. The number is small on a desk
  /// connection and is not the point: on mobile data at 200 ms a round
  /// trip, six of them are a second and a quarter in front of the screen
  /// somebody opens first in an emergency.
  ///
  /// Order is kept, so warnings arrive in the same sequence as before and
  /// nothing downstream has to care that this changed.
  Future<BbkFetchResult> fetchAll() async {
    final fetched = await Future.wait(_sources.map(_fetchSource));

    final results = <BbkRawWarning>[];
    var complete = true;
    for (final source in fetched) {
      // One bad source must not discard the others' warnings, but it does
      // mean the picture is incomplete — see [BbkFetchResult.complete].
      if (source == null) {
        complete = false;
        continue;
      }
      results.addAll(source.warnings);
      if (!source.complete) complete = false;
    }

    return BbkFetchResult(warnings: results, complete: complete);
  }

  /// Fetches warnings for one district (Kreis), identified by its 5-digit
  /// Kreisschlüssel (e.g. "05334" for Städteregion Aachen). Confirmed live
  /// against `warnung.bund.de/api31/dashboard/{ars}.json` on 2026-08-14 —
  /// per the API's own docs, only Kreis-level precision is available (the
  /// last 7 of the 12 ARS digits are always zero); passing a full
  /// Gemeinde-level ARS wouldn't give finer results.
  ///
  /// Response shape differs from `mapData.json` (nested under
  /// `payload.data`, plus a top-level `sent` field) — parsed separately
  /// here rather than reusing `_parseEntry`.
  ///
  /// Anything but a list with status 200 throws [BbkDashboardUnavailable].
  /// It used to answer an empty list, which the poll could not tell from
  /// a district with nothing in force, and it then ended the warnings
  /// only this dashboard knows (#250). An entry that cannot be read is
  /// left out and makes the answer incomplete (#369).
  Future<BbkFetchResult> fetchDashboard(String kreisSchluessel) async {
    final ars = kreisSchluessel.padRight(12, '0');
    final response = await getWarningResponse(
      _httpClient,
      Uri.parse('$_baseUrl/dashboard/$ars.json'),
    );
    if (response.statusCode != 200) {
      throw BbkDashboardUnavailable(response.statusCode);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) throw BbkDashboardUnavailable(response.statusCode);

    return _parseAll(decoded, _parseDashboardEntry);
  }

  /// Every entry of [entries] that [parse] can read, and whether that was
  /// all of them.
  ///
  /// One at a time (#369). The casts used to run over the whole list at
  /// once, outside any error handling: a single entry without its
  /// `startDate` threw out of [fetchAll], the poll stopped there, and no
  /// warning of any source was stored, nor MeteoAlarm asked. Something
  /// that is not an entry at all was passed over without a word, and the
  /// list counted as complete.
  BbkFetchResult _parseAll(
    List<dynamic> entries,
    BbkRawWarning? Function(Map<String, dynamic> entry) parse,
  ) {
    final warnings = <BbkRawWarning>[];
    var complete = true;
    for (final entry in entries) {
      BbkRawWarning? warning;
      if (entry is Map<String, dynamic>) {
        try {
          warning = parse(entry);
        } on Object {
          warning = null;
        }
      }
      if (warning == null) {
        complete = false;
      } else {
        warnings.add(warning);
      }
    }
    return BbkFetchResult(warnings: warnings, complete: complete);
  }

  /// [value] where it is text with something in it.
  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  /// Loads the German CAP detail behind a compact map/dashboard entry.
  /// A failed detail request deliberately returns the compact warning: the
  /// alert itself remains useful, and the next poll asks again for any
  /// stored warning that still has no detail (see
  /// `WarningPollService._detailsForChanged`).
  ///
  /// A warning that has ended answers with a redirect to the archive; the
  /// client follows it, so a late detail still arrives.
  Future<BbkRawWarning> fetchDetails(BbkRawWarning warning) async {
    try {
      final response = await getWarningResponse(
        _httpClient,
        Uri.parse('$_baseUrl/warnings/${Uri.encodeComponent(warning.id)}.json'),
      );
      if (response.statusCode != 200) return warning;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return warning;
      final infos = decoded['info'];
      if (infos is! List) return warning;

      Map<dynamic, dynamic>? selected;
      final others = <String, WarningText>{};
      WarningText? read(Map<dynamic, dynamic> item) {
        final headline =
            capPlainText(item['headline']) ?? capPlainText(item['event']);
        if (headline == null) return null;
        return WarningText(
          event: capPlainText(item['event']) ?? headline,
          headline: headline,
          description: capPlainText(item['description']),
          instruction: capPlainText(item['instruction']),
        );
      }

      for (final item in infos) {
        if (item is! Map) continue;
        final language = normalizeCapLanguage('${item['language'] ?? ''}');
        selected ??= item;
        if (language == 'de') {
          selected = item;
          continue;
        }
        // Every other block is an official translation (#357). Kept as
        // plain text, the same way as the German.
        if (language.isEmpty) continue;
        if (read(item) case final text?) others[language] = text;
      }
      if (selected == null) return warning;

      // Only what a language says differently: MoWaS repeats the German
      // description in every block (see `warning_translations.dart`).
      final german = read(selected);
      final translatesHeadline = bbkTranslatesHeadline(warning.id);
      final translations = <String, WarningTranslation>{
        for (final MapEntry(key: language, value: text) in others.entries)
          if (german != null)
            language: ?compactWarningTranslation(
              german: german,
              translated: text,
              translatesHeadline: translatesHeadline,
            ),
      };

      final areas = selected['area'];
      final areaNames = <String>[];
      final polygons = <String>[];
      if (areas is List) {
        for (final area in areas.whereType<Map>()) {
          final name = area['areaDesc'];
          if (name is String && name.trim().isNotEmpty) {
            areaNames.add(name.trim());
          }
          final polygon = area['polygon'];
          if (polygon is List) {
            polygons.addAll(
              polygon.whereType<String>().where((p) => p.isNotEmpty),
            );
          }
        }
      }

      String? contact;
      final parameters = selected['parameter'];
      if (parameters is List) {
        for (final parameter in parameters.whereType<Map>()) {
          if (parameter['valueName'] == 'sender_signature') {
            contact = parameter['value'] as String?;
            break;
          }
        }
      }

      // Plain text, not the HTML the MoWaS payloads carry. See
      // [capPlainText].
      return warning.withDetails(
        description: capPlainText(selected['description']),
        instruction: capPlainText(selected['instruction']),
        areaDescription: capPlainText(areaNames.join('\n')),
        senderContact: capPlainText(contact ?? decoded['sender']),
        polygons: polygons,
        translations: translations,
        messageType: switch (decoded['msgType']) {
          final String type => type,
          _ => null,
        },
      );
    } on Object {
      return warning;
    }
  }

  /// Null where the entry has no id or no date: it cannot be stored.
  BbkRawWarning? _parseDashboardEntry(Map<String, dynamic> entry) {
    final id = _text(entry['id']);
    final sent = _text(entry['sent']);
    if (id == null || sent == null) return null;
    final i18nTitle = entry['i18nTitle'];
    final titleDe = i18nTitle is Map ? _text(i18nTitle['de']) : null;
    final payload = entry['payload'];
    final data = payload is Map ? payload['data'] : null;
    final severity = data is Map ? _text(data['severity']) : null;
    final headline = data is Map ? _text(data['headline']) : null;
    final messageType = data is Map ? _text(data['msgType']) : null;

    return BbkRawWarning(
      id: id,
      startDate: sent,
      severity: severity ?? 'Minor',
      eventTitleDe: titleDe ?? headline ?? id,
      raw: entry,
      messageType: messageType,
    );
  }

  /// Returns `null` when the source could not be read at all — distinct
  /// from an empty list, which means the source answered and has nothing
  /// active. See [BbkFetchResult.complete].
  Future<BbkFetchResult?> _fetchSource(String source) async {
    final http.Response response;
    try {
      response = await getWarningResponse(
        _httpClient,
        Uri.parse('$_baseUrl/$source/mapData.json'),
      );
    } catch (_) {
      return null;
    }
    if (response.statusCode != 200) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
    if (decoded is! List) return null;

    return _parseAll(decoded, _parseEntry);
  }

  /// Null where the entry has no id or no start: it cannot be stored.
  BbkRawWarning? _parseEntry(Map<String, dynamic> entry) {
    final id = _text(entry['id']);
    final startDate = _text(entry['startDate']);
    if (id == null || startDate == null) return null;
    final i18nTitle = entry['i18nTitle'];
    final titleDe = i18nTitle is Map ? _text(i18nTitle['de']) : null;

    return BbkRawWarning(
      id: id,
      startDate: startDate,
      severity: _text(entry['severity']) ?? 'Minor',
      eventTitleDe: titleDe ?? id,
      raw: entry,
      messageType: _text(entry['type']),
    );
  }
}

/// A district dashboard that did not answer with a list. Not "nothing in
/// force here": the poll keeps that district's warnings rather than
/// ending them (#250).
class BbkDashboardUnavailable implements Exception {
  const BbkDashboardUnavailable(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'BBK dashboard answered $statusCode';
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'warning_http.dart';
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

  BbkRawWarning withDetails({
    String? description,
    String? instruction,
    String? areaDescription,
    String? senderContact,
    List<String> polygons = const [],
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
      results.addAll(source);
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
  Future<List<BbkRawWarning>> fetchDashboard(String kreisSchluessel) async {
    final ars = kreisSchluessel.padRight(12, '0');
    final response = await getWarningResponse(
      _httpClient,
      Uri.parse('$_baseUrl/dashboard/$ars.json'),
    );
    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return [];

    return [
      for (final entry in decoded)
        if (entry is Map<String, dynamic>) _parseDashboardEntry(entry),
    ];
  }

  /// Loads the German CAP detail behind a compact map/dashboard entry.
  /// A failed detail request deliberately returns the compact warning: the
  /// alert itself remains useful and a later poll can fill its offline cache.
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
      for (final item in infos) {
        if (item is! Map) continue;
        final language = '${item['language'] ?? ''}'.toLowerCase();
        selected ??= item;
        if (language == 'de' || language == 'de-de') {
          selected = item;
          break;
        }
      }
      if (selected == null) return warning;

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

      String? text(Object? value) =>
          value is String && value.trim().isNotEmpty ? value.trim() : null;
      return warning.withDetails(
        description: text(selected['description']),
        instruction: text(selected['instruction']),
        areaDescription: areaNames.isEmpty ? null : areaNames.join('\n'),
        senderContact: text(contact ?? decoded['sender']),
        polygons: polygons,
      );
    } on Object {
      return warning;
    }
  }

  BbkRawWarning _parseDashboardEntry(Map<String, dynamic> entry) {
    final i18nTitle = entry['i18nTitle'];
    final titleDe = i18nTitle is Map ? i18nTitle['de'] as String? : null;
    final payload = entry['payload'];
    final data = payload is Map ? payload['data'] : null;
    final severity = data is Map ? data['severity'] as String? : null;
    final headline = data is Map ? data['headline'] as String? : null;

    return BbkRawWarning(
      id: entry['id'] as String,
      startDate: entry['sent'] as String,
      severity: severity ?? 'Minor',
      eventTitleDe: titleDe ?? headline ?? entry['id'] as String,
      raw: entry,
    );
  }

  /// Returns `null` when the source could not be read at all — distinct
  /// from an empty list, which means the source answered and has nothing
  /// active. See [BbkFetchResult.complete].
  Future<List<BbkRawWarning>?> _fetchSource(String source) async {
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

    return [
      for (final entry in decoded)
        if (entry is Map<String, dynamic>) _parseEntry(entry),
    ];
  }

  BbkRawWarning _parseEntry(Map<String, dynamic> entry) {
    final i18nTitle = entry['i18nTitle'];
    final titleDe = i18nTitle is Map ? i18nTitle['de'] as String? : null;

    return BbkRawWarning(
      id: entry['id'] as String,
      startDate: entry['startDate'] as String,
      severity: entry['severity'] as String? ?? 'Minor',
      eventTitleDe: titleDe ?? entry['id'] as String,
      raw: entry,
    );
  }
}

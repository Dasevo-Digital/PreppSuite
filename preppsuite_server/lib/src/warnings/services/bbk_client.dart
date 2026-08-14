import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single raw entry from a BBK (warnung.bund.de) `mapData.json` feed —
/// intentionally untyped beyond this shape; `WarningNormalizer` maps it to
/// the canonical [Warning] model. Fields confirmed against the live API on
/// 2026-08-14; see `docs/warning-feeds.md`.
class BbkRawWarning {
  const BbkRawWarning({
    required this.id,
    required this.startDate,
    required this.severity,
    required this.eventTitleDe,
    required this.raw,
  });

  final String id;
  final String startDate;
  final String severity;
  final String eventTitleDe;
  final Map<String, dynamic> raw;
}

/// Fetches Germany-wide warnings from the public, key-less BBK API.
///
/// Only `mowas` (the federal Modular Warning System — most civil-protection
/// warnings) and `dwd` (weather) are polled for v1; `katwarn`/`biwapp`/
/// `lhp`/`police` use the same `mapData.json` shape and can be added later
/// without any parsing changes.
class BbkClient {
  BbkClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _sources = ['mowas', 'dwd'];
  static const _baseUrl = 'https://warnung.bund.de/api31';

  Future<List<BbkRawWarning>> fetchAll() async {
    final results = <BbkRawWarning>[];
    for (final source in _sources) {
      results.addAll(await _fetchSource(source));
    }
    return results;
  }

  Future<List<BbkRawWarning>> _fetchSource(String source) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/$source/mapData.json'),
    );
    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return [];

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

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'geo_bounds.dart';
import '../../../core/http_client.dart';

/// A bunker from the WWBOTA ("World Wide Bunkers on the Air") reference
/// database — an amateur-radio activation-award catalogue (like POTA/SOTA),
/// **not** an official civil-protection shelter registry. Field names match
/// the real API response verbatim (confirmed live against
/// `api.wwbota.org/bunkers/` on 2026-08-14, e.g. `long` for longitude, not
/// `lon`).
class WwbotaBunker {
  const WwbotaBunker({
    required this.reference,
    required this.name,
    required this.type,
    required this.lat,
    required this.lon,
  });

  final String reference;
  final String name;
  final String type;
  final double lat;
  final double lon;
}

/// Fetches bunker locations from the public, key-less WWBOTA API. `DLBOTA`
/// is the German scheme; other `*BOTA` schemes exist for other countries
/// but aren't used here since the rest of this feature is DE-focused (same
/// scope as the BBK warning integration).
class WwbotaClient {
  WwbotaClient({http.Client? httpClient})
    : _ownsClient = httpClient == null,
      _httpClient = httpClient ?? TimeoutClient();

  final http.Client _httpClient;
  final bool _ownsClient;
  void close() {
    if (_ownsClient) _httpClient.close();
  }

  static const _baseUrl = 'https://api.wwbota.org';

  Future<List<WwbotaBunker>> fetchBunkers(
    GeoBoundingBox bounds, {
    String scheme = 'DLBOTA',
  }) async {
    final uri = Uri.parse('$_baseUrl/bunkers/').replace(
      queryParameters: {
        'scheme': scheme,
        'bbox': '${bounds.west},${bounds.south},${bounds.east},${bounds.north}',
      },
    );

    final response = await _httpClient
        .get(uri)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Shelter service returned ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return [];

    return [
      for (final entry in decoded)
        if (entry is Map<String, dynamic>) _parseEntry(entry),
    ].whereType<WwbotaBunker>().toList();
  }

  WwbotaBunker? _parseEntry(Map<String, dynamic> entry) {
    final reference = entry['reference'] as String?;
    final name = entry['name'] as String?;
    final lat = (entry['lat'] as num?)?.toDouble();
    final lon = (entry['long'] as num?)?.toDouble();
    if (reference == null || name == null || lat == null || lon == null) {
      return null;
    }

    return WwbotaBunker(
      reference: reference,
      name: name,
      type: entry['type'] as String? ?? '',
      lat: lat,
      lon: lon,
    );
  }
}

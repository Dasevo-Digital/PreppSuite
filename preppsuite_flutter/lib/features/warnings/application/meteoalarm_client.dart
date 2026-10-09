import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'warning_http.dart';
import '../../../core/http_client.dart';

/// A single `<entry>` from a MeteoAlarm legacy Atom+CAP feed. Fields
/// confirmed against the live feed on 2026-08-14; see
/// `docs/warning-feeds.md`.
class MeteoAlarmRawWarning {
  const MeteoAlarmRawWarning({
    required this.identifier,
    required this.title,
    required this.areaDesc,
    required this.event,
    required this.severity,
    required this.sent,
    required this.onset,
    required this.expires,
    required this.raw,
  });

  final String identifier;
  final String title;
  final String areaDesc;
  final String event;
  final String severity;
  final String sent;
  final String? onset;
  final String? expires;
  final Map<String, dynamic> raw;
}

/// Fetches a country's warnings from MeteoAlarm's public, key-less legacy
/// Atom feeds. MeteoAlarm covers the wider EUMETNET membership, not just EU
/// countries (e.g. includes Switzerland, Norway, UK).
class MeteoAlarmClient {
  MeteoAlarmClient({http.Client? httpClient})
    : _httpClient = httpClient ?? TimeoutClient();

  final http.Client _httpClient;

  static const _capNs = 'urn:oasis:names:tc:emergency:cap:1.2';

  /// [countrySlug] is the feed's URL slug, e.g. "germany", "austria",
  /// "united-kingdom" — see [meteoAlarmCountrySlugs] below for the
  /// ISO-code-to-slug mapping.
  Future<List<MeteoAlarmRawWarning>> fetchCountry(String countrySlug) async {
    final response = await getWarningResponse(
      _httpClient,
      Uri.parse(
        'https://feeds.meteoalarm.org/feeds/meteoalarm-legacy-atom-$countrySlug',
      ),
    );
    // Thrown, not an empty list. An empty list is "no warnings in force",
    // and that is what a 503 used to be filed as: the status then called
    // MeteoAlarm current while it was down (#92). The poll catches this
    // and marks the run incomplete; the stored warnings keep their own
    // expiry either way.
    if (response.statusCode != 200) {
      throw MeteoAlarmUnavailable(response.statusCode);
    }

    final document = XmlDocument.parse(response.body);
    return [
      for (final entry in document.findAllElements('entry')) _parseEntry(entry),
    ];
  }

  MeteoAlarmRawWarning _parseEntry(XmlElement entry) {
    String cap(String name) =>
        entry.getElement(name, namespaceUri: _capNs)?.innerText ?? '';
    String? capOrNull(String name) =>
        entry.getElement(name, namespaceUri: _capNs)?.innerText;

    return MeteoAlarmRawWarning(
      identifier: cap('identifier'),
      title: entry.getElement('title')?.innerText ?? cap('areaDesc'),
      areaDesc: cap('areaDesc'),
      event: cap('event'),
      severity: cap('severity').isEmpty ? 'Minor' : cap('severity'),
      sent: cap('sent'),
      onset: capOrNull('onset'),
      expires: capOrNull('expires'),
      raw: {
        'identifier': cap('identifier'),
        'title': entry.getElement('title')?.innerText,
        'areaDesc': cap('areaDesc'),
        'event': cap('event'),
        'severity': cap('severity'),
        'certainty': cap('certainty'),
        'urgency': cap('urgency'),
        'status': cap('status'),
        'messageType': cap('message_type'),
        'sent': cap('sent'),
        'onset': capOrNull('onset'),
        'expires': capOrNull('expires'),
      },
    );
  }
}

/// Maps a [WarningFeedCountry]-style ISO code to MeteoAlarm's URL slug.
/// Now lives next to `warning_feed_countries.dart` rather than in a
/// separate package, so the two lists can no longer drift apart unnoticed.
const meteoAlarmCountrySlugs = <String, String>{
  'DE': 'germany',
  'AT': 'austria',
  'CH': 'switzerland',
  'FR': 'france',
  'IT': 'italy',
  'ES': 'spain',
  'PT': 'portugal',
  'NL': 'netherlands',
  'BE': 'belgium',
  'LU': 'luxembourg',
  'PL': 'poland',
  'CZ': 'czechia',
  'DK': 'denmark',
  'SE': 'sweden',
  'NO': 'norway',
  'FI': 'finland',
  'IE': 'ireland',
  'GB': 'united-kingdom',
};

/// MeteoAlarm answered, but not with a feed.
class MeteoAlarmUnavailable implements Exception {
  const MeteoAlarmUnavailable(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'MeteoAlarm answered HTTP $statusCode';
}

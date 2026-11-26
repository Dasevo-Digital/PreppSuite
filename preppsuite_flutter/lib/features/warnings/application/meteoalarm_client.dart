import 'dart:convert';
import 'dart:isolate';

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
    this.areaCode,
    this.messageType,
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

  /// The area's own code in MeteoAlarm, its `EMMA_ID` geocode (`DE271`),
  /// where the entry carries one.
  final String? areaCode;

  /// CAP's `msgType`, which the feed calls `message_type`: `Alert`,
  /// `Update` or `Cancel`.
  final String? messageType;
}

/// What a MeteoAlarm entry is stored under, and what a full read of its
/// feed is checked against: its message and its area (#395).
///
/// The feed has one entry per message and area, and one message can name
/// many areas. On 2026-11-26 the German feed held 1,167 entries under 66
/// identifiers, one of them for 156 districts. Stored by the identifier
/// alone, every entry of a message wrote the same row, the last one won,
/// and a warning for 156 districts stood in the list as a warning for one
/// of them -- and was nobody else's.
String meteoAlarmExternalId(MeteoAlarmRawWarning warning) {
  final area =
      warning.areaCode ?? (warning.areaDesc.isEmpty ? null : warning.areaDesc);
  return area == null ? warning.identifier : '${warning.identifier}#$area';
}

/// The message a stored MeteoAlarm row is one area of, from its id.
String meteoAlarmMessageId(String externalId) {
  final area = externalId.indexOf('#');
  return area == -1 ? externalId : externalId.substring(0, area);
}

/// One look at a country's feed.
class MeteoAlarmFeed {
  const MeteoAlarmFeed({this.stamp, this.warnings});

  /// The feed's own `<updated>`, null where it has none.
  final String? stamp;

  /// What the feed holds, or null when it still carries the stamp the
  /// caller knew and was not read any further.
  final List<MeteoAlarmRawWarning>? warnings;
}

/// How far into a feed its stamp is looked for. It sits at 900 bytes in the
/// live feed; a feed that ever moves it past this is read in full.
const meteoAlarmHeadBytes = 8 * 1024;

final _stampPattern = RegExp(r'<updated>([^<]+)</updated>');

/// The feed's own `<updated>` in [head], the beginning of a feed.
///
/// Every entry has an `<updated>` as well, and the first of those says
/// nothing about the feed. Null while the head is too short to tell.
String? meteoAlarmFeedStamp(String head) {
  final match = _stampPattern.firstMatch(head);
  if (match == null) return null;
  final entry = head.indexOf('<entry');
  if (entry != -1 && entry < match.start) return null;
  return match.group(1);
}

class _FeedUnchanged implements Exception {
  const _FeedUnchanged();
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
  ///
  /// A feed that still carries [knownStamp] is left after its head (#299).
  /// The German one was 1.2 MB on an ordinary frosty day, and this server
  /// compresses nothing, sends neither ETag nor Last-Modified and ignores
  /// Range, so the only way not to fetch all of it is to stop reading.
  ///
  /// The stamp is when the feed was built, every half hour, and not when
  /// it last changed: on 2026-11-06 copies of one build were identical to
  /// the byte, and two builds in a row differed in the stamp alone. So the
  /// same stamp proves nothing changed, and a new one does not prove
  /// anything did. A poll every fifteen minutes reads every other time.
  Future<MeteoAlarmFeed> fetchCountry(
    String countrySlug, {
    String? knownStamp,
  }) async {
    var head = '';
    String? stamp;
    void watchHead(List<int> chunk) {
      if (stamp != null || head.length >= meteoAlarmHeadBytes) return;
      // Bytes as characters: the stamp is ASCII, and a letter a chunk cut
      // in two must not stop this from finding it.
      head += String.fromCharCodes(
        chunk.take(meteoAlarmHeadBytes - head.length),
      );
      stamp = meteoAlarmFeedStamp(head);
      if (stamp != null && stamp == knownStamp) throw const _FeedUnchanged();
    }

    final http.Response response;
    try {
      response = await getWarningResponse(
        _httpClient,
        Uri.parse(
          'https://feeds.meteoalarm.org/feeds/meteoalarm-legacy-atom-$countrySlug',
        ),
        onChunk: watchHead,
      );
    } on _FeedUnchanged {
      return MeteoAlarmFeed(stamp: stamp);
    }
    // Thrown, not an empty list. An empty list is "no warnings in force",
    // and that is what a 503 used to be filed as: the status then called
    // MeteoAlarm current while it was down (#92). The poll catches this
    // and marks the run incomplete; the stored warnings keep their own
    // expiry either way.
    if (response.statusCode != 200) {
      throw MeteoAlarmUnavailable(response.statusCode);
    }

    return MeteoAlarmFeed(
      stamp: stamp,
      // UTF-8, as the feed says it is, whatever the header says (#396).
      // `response.body` reads a response without a charset as Latin-1:
      // "Kreis Lörrach" came out as "Kreis LÃ¶rrach", which no district
      // in the warncell table is called, and the warning was left
      // unplaced -- a warning for everybody.
      warnings: await _parseElsewhere(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      ),
    );
  }

  // 43 ms for 808 entries on a Mac, several times that on a phone, and it
  // happened during start-up. In a function of its own, because a closure
  // sent to another isolate takes everything in its scope along, and the
  // scope of [fetchCountry] holds a pending request.
  static Future<List<MeteoAlarmRawWarning>> _parseElsewhere(String body) =>
      Isolate.run(() => _parse(body));

  static List<MeteoAlarmRawWarning> _parse(String body) {
    final document = XmlDocument.parse(body);
    return [
      for (final entry in document.findAllElements('entry')) _parseEntry(entry),
    ];
  }

  static MeteoAlarmRawWarning _parseEntry(XmlElement entry) {
    String cap(String name) =>
        entry.getElement(name, namespaceUri: _capNs)?.innerText ?? '';
    String? capOrNull(String name) =>
        entry.getElement(name, namespaceUri: _capNs)?.innerText;
    // `valueName` and `value` sit in the feed's default namespace, not in
    // CAP's.
    String? geocode(String name) {
      for (final code in entry.findElements('geocode', namespaceUri: _capNs)) {
        if (code.getElement('valueName', namespaceUri: '*')?.innerText.trim() !=
            name) {
          continue;
        }
        final value = code.getElement('value', namespaceUri: '*')?.innerText;
        if (value != null && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    return MeteoAlarmRawWarning(
      areaCode: geocode('EMMA_ID'),
      messageType: capOrNull('message_type')?.trim(),
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

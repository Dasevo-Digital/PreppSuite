import 'dart:convert';

import 'package:http/http.dart' as http;

/// What kind of thing is standing on the road.
enum RoadEventKind {
  /// The carriageway, or part of it, is shut.
  closure,

  /// The Autobahn GmbH's own warning — an obstacle, an accident.
  warning,
}

/// One closure or warning on one Autobahn.
class RoadEvent {
  const RoadEvent({
    required this.road,
    required this.kind,
    required this.title,
    required this.direction,
    required this.description,
    required this.startsAt,
    required this.future,
    required this.blocked,
    this.latitude,
    this.longitude,
  });

  /// "A2", "A39".
  final String road;

  final RoadEventKind kind;

  /// "A2 | Oberhausen - Gladbeck-Ellinghorst".
  final String title;

  /// Which way it applies — "Oberhausen -> Dortmund". One direction being
  /// shut while the other runs is the ordinary case, so this is not a
  /// detail.
  final String? direction;

  /// The service's own lines, in its own words.
  final List<String> description;

  final DateTime? startsAt;

  /// Set by the service for something that has not begun yet. Shown apart
  /// from what is standing on the road now: a closure starting on Friday
  /// is worth knowing and is not a reason to turn round today.
  final bool future;

  /// The service's own `isBlocked`. A warning is usually not blocking;
  /// a closure usually is, but not always — a lane can be shut while the
  /// road runs.
  final bool blocked;

  final double? latitude;
  final double? longitude;

  /// Standing on the road right now.
  bool get current => !future;
}

/// Reads closures and warnings from the Autobahn GmbH's open interface.
///
/// No key and no account. Roadworks are deliberately not fetched: the
/// same interface lists over a hundred per Autobahn, almost none of them
/// blocking anything, and a list nobody can read is worse than no list.
/// What this asks for is what would make somebody turn round.
class RoadClosureClient {
  RoadClosureClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const base = 'https://verkehr.autobahn.de/o/autobahn';

  /// Every Autobahn the service knows, in its own order.
  Future<List<String>> fetchRoads() async {
    final response = await _httpClient.get(Uri.parse('$base/'));
    if (response.statusCode != 200) {
      throw RoadClosureException(response.statusCode);
    }
    return parseRoads(utf8.decode(response.bodyBytes, allowMalformed: true));
  }

  /// Closures and warnings on one Autobahn, closures first.
  Future<List<RoadEvent>> fetchEvents(String road) async {
    final fetched = await Future.wait([
      _events(road, RoadEventKind.closure),
      _events(road, RoadEventKind.warning),
    ]);
    return [...fetched.first, ...fetched.last];
  }

  Future<List<RoadEvent>> _events(String road, RoadEventKind kind) async {
    final path = kind == RoadEventKind.closure ? 'closure' : 'warning';
    final response = await _httpClient.get(
      Uri.parse('$base/$road/services/$path'),
    );
    if (response.statusCode != 200) {
      throw RoadClosureException(response.statusCode);
    }
    return parseEvents(
      utf8.decode(response.bodyBytes, allowMalformed: true),
      road: road,
      kind: kind,
    );
  }

  static List<String> parseRoads(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return const [];
    final roads = decoded['roads'];
    if (roads is! List) return const [];
    return [
      for (final road in roads)
        if (road is String && road.isNotEmpty) road,
    ];
  }

  static List<RoadEvent> parseEvents(
    String body, {
    required String road,
    required RoadEventKind kind,
  }) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return const [];
    final items =
        decoded[kind == RoadEventKind.closure ? 'closure' : 'warning'];
    if (items is! List) return const [];

    final events = <RoadEvent>[];
    for (final item in items) {
      if (item is! Map<String, Object?>) continue;
      final title = item['title'];
      if (title is! String || title.isEmpty) continue;

      final point = '${item['point']}'.split(',');
      final subtitle = item['subtitle'];

      events.add(
        RoadEvent(
          road: road,
          kind: kind,
          title: title,
          direction: subtitle is String && subtitle.trim().isNotEmpty
              ? subtitle.trim()
              : null,
          description: [
            for (final line in (item['description'] as List? ?? const []))
              if (line is String && line.trim().isNotEmpty) line.trim(),
          ],
          startsAt: DateTime.tryParse('${item['startTimestamp']}'),
          // The service sends this one as a real boolean and `isBlocked`
          // as the string "true"/"false" — both are read for what they
          // are rather than trusted to be the same shape.
          future: item['future'] == true || item['future'] == 'true',
          blocked: item['isBlocked'] == true || item['isBlocked'] == 'true',
          latitude: point.length == 2 ? double.tryParse(point[0]) : null,
          longitude: point.length == 2 ? double.tryParse(point[1]) : null,
        ),
      );
    }
    return events;
  }
}

class RoadClosureException implements Exception {
  const RoadClosureException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'RoadClosureException: HTTP $statusCode';
}

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/road_closure_client.dart';

/// Cut from the real answers of the Autobahn GmbH's interface on
/// 2026-09-11.
const _roads = '{"roads":["A1","A2","A3","A7"]}';

/// One closure that has not begun and one that is standing on the road.
/// Note the shapes: `future` arrives as a real boolean, `isBlocked` as a
/// string.
const _closures = '''
{"closure":[
  {"identifier":"a","icon":"250","isBlocked":"false","future":true,
   "point":"51.5386,6.8438",
   "title":"A2 | Oberhausen - Gladbeck-Ellinghorst",
   "subtitle":" Oberhausen -> Dortmund",
   "startTimestamp":"2026-09-11T21:00:00+02:00",
   "description":["Zeitraum dieser Bauphase:","Beginn: 11.09.26 um 21:00 Uhr","",
     "A2: Oberhausen -> Dortmund"]},
  {"identifier":"b","isBlocked":"true","future":false,
   "point":"52.2733,10.5268",
   "title":"A2 | Braunschweig-Watenbüttel - Königslutter",
   "subtitle":" Hannover -> Berlin",
   "startTimestamp":"2026-09-10T06:00:00+02:00",
   "description":["Vollsperrung"]}]}
''';

const _warnings = '''
{"warning":[
  {"identifier":"c","isBlocked":"false","future":false,
   "point":"51.6,7.1",
   "title":"A2 | Stuckenbusch - Herten",
   "subtitle":" Dortmund -> Oberhausen",
   "startTimestamp":"2026-09-11T08:00:00+02:00",
   "description":["Gegenstände auf der Fahrbahn"]}]}
''';

void main() {
  test('the list of motorways comes through in the service order', () {
    expect(RoadClosureClient.parseRoads(_roads), ['A1', 'A2', 'A3', 'A7']);
  });

  test('a closure keeps its direction, its start and whether it blocks', () {
    final events = RoadClosureClient.parseEvents(
      _closures,
      road: 'A2',
      kind: RoadEventKind.closure,
    );

    expect(events.length, 2);
    final announced = events.first;
    expect(announced.title, 'A2 | Oberhausen - Gladbeck-Ellinghorst');
    // One direction shut while the other runs is the ordinary case, so
    // this is not a detail.
    expect(announced.direction, 'Oberhausen -> Dortmund');
    expect(announced.future, isTrue);
    expect(announced.current, isFalse);
    expect(announced.blocked, isFalse);
    expect(announced.startsAt, isNotNull);
    // Empty lines out of the service's own description are dropped.
    expect(announced.description, hasLength(3));

    final standing = events.last;
    expect(standing.current, isTrue);
    expect(standing.blocked, isTrue, reason: 'isBlocked arrives as a string');
    expect(standing.latitude, closeTo(52.2733, 0.0001));
    expect(standing.longitude, closeTo(10.5268, 0.0001));
  });

  test('a warning is read the same way and kept apart', () {
    final events = RoadClosureClient.parseEvents(
      _warnings,
      road: 'A2',
      kind: RoadEventKind.warning,
    );

    expect(events.single.kind, RoadEventKind.warning);
    expect(events.single.blocked, isFalse);
    expect(events.single.description.single, 'Gegenstände auf der Fahrbahn');
  });

  test('an empty road is not an error', () {
    expect(
      RoadClosureClient.parseEvents(
        '{"closure":[]}',
        road: 'A7',
        kind: RoadEventKind.closure,
      ),
      isEmpty,
    );
  });

  test('an entry without a title is skipped rather than shown blank', () {
    expect(
      RoadClosureClient.parseEvents(
        '{"closure":[{"identifier":"x"}]}',
        road: 'A7',
        kind: RoadEventKind.closure,
      ),
      isEmpty,
    );
  });
}

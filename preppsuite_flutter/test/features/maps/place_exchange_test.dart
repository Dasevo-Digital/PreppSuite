import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/personal_place.dart';
import 'package:preppsuite_flutter/features/maps/application/place_exchange.dart';

/// Own places, out of the app and back into it.
///
/// The one thing that has to be right is the order of the two numbers.
/// GPX names them; KML writes them as a comma-list with **longitude
/// first**. Swapping them puts a Berlin household in Somalia, and it looks
/// entirely plausible all the way through — which is why the round trip is
/// checked in both formats rather than trusted.
void main() {
  const places = [
    PersonalPlace(
      id: 'a',
      label: 'Treffpunkt Schule',
      latitude: 52.516275,
      longitude: 13.377704,
      note: 'Hinter der Turnhalle',
    ),
    PersonalPlace(
      id: 'b',
      label: 'Hauptabsperrhahn',
      latitude: 48.137154,
      longitude: 11.576124,
    ),
  ];

  var counter = 0;
  String nextId() => 'imported-${counter++}';
  setUp(() => counter = 0);

  group('GPX', () {
    test('a round trip keeps names, notes and both numbers', () {
      final back = placesFromXml(placesToGpx(places), newId: nextId);

      expect(back, hasLength(2));
      expect(back.first.label, 'Treffpunkt Schule');
      expect(back.first.note, 'Hinter der Turnhalle');
      expect(back.first.latitude, closeTo(52.516275, 1e-9));
      expect(back.first.longitude, closeTo(13.377704, 1e-9));
      // A place with no note comes back without one rather than with an
      // empty string.
      expect(back.last.note, isNull);
    });

    test('it is a GPX 1.1 document other programs will open', () {
      final gpx = placesToGpx(places);

      expect(gpx, contains('version="1.1"'));
      expect(gpx, contains('http://www.topografix.com/GPX/1/1'));
      expect(gpx, contains('<wpt lat="52.516275" lon="13.377704">'));
    });
  });

  group('KML', () {
    test('coordinates are written longitude first', () {
      // The trap. In KML the comma-list is lon,lat — the other way round
      // from everything else in this app.
      expect(placesToKml(places), contains('13.377704,52.516275,0'));
    });

    test('and read back the same way round', () {
      final back = placesFromXml(placesToKml(places), newId: nextId);

      expect(back, hasLength(2));
      expect(back.first.latitude, closeTo(52.516275, 1e-9));
      expect(back.first.longitude, closeTo(13.377704, 1e-9));
      expect(back.first.note, 'Hinter der Turnhalle');
    });

    test('a height on the end is ignored rather than confusing it', () {
      final back = placesFromXml('''
<kml xmlns="http://www.opengis.net/kml/2.2"><Document><Placemark>
  <name>Gipfel</name>
  <Point><coordinates> 11.576124,48.137154,519 </coordinates></Point>
</Placemark></Document></kml>''', newId: nextId);

      expect(back.single.latitude, closeTo(48.137154, 1e-9));
      expect(back.single.longitude, closeTo(11.576124, 1e-9));
    });
  });

  group('what comes in from outside', () {
    test('the format is sniffed, not taken from the file name', () {
      // A file through a chat app rarely still has an extension.
      expect(placesFromXml(placesToGpx(places), newId: nextId), hasLength(2));
      expect(placesFromXml(placesToKml(places), newId: nextId), hasLength(2));
    });

    test('something that is not XML costs nothing but the import', () {
      expect(placesFromXml('this is a photograph', newId: nextId), isEmpty);
      expect(placesFromXml('', newId: nextId), isEmpty);
    });

    test('one unusable point costs that point, not the file', () {
      final back = placesFromXml('''
<gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">
  <wpt lat="not a number" lon="13.4"><name>Kaputt</name></wpt>
  <wpt lat="91" lon="13.4"><name>Nordpol und weiter</name></wpt>
  <wpt lat="52.5" lon="13.4"><name>Gut</name></wpt>
</gpx>''', newId: nextId);

      expect(back.map((p) => p.label), ['Gut']);
    });

    test('a point with no name is labelled by where it is', () {
      final back = placesFromXml(
        '<gpx version="1.1"><wpt lat="52.5" lon="13.4"/></gpx>',
        newId: nextId,
      );

      expect(back.single.label, '52.50000, 13.40000');
    });

    test('ids are made here: one from another device means nothing', () {
      final back = placesFromXml(placesToGpx(places), newId: nextId);
      expect(back.map((p) => p.id), ['imported-0', 'imported-1']);
    });
  });

  group('importing the same file twice', () {
    test('does not double the list', () {
      // People do this, because they are not sure it worked the first
      // time.
      final once = mergePlaces(const [], places);
      final twice = mergePlaces(once, places);

      expect(once, hasLength(2));
      expect(twice, hasLength(2));
    });

    test('a point that came back through another program still matches', () {
      // Compared at five decimals, about a metre: a round trip elsewhere
      // comes back with a different last digit.
      final drifted = [
        PersonalPlace(
          id: 'x',
          label: 'Treffpunkt Schule',
          latitude: 52.5162751,
          longitude: 13.3777039,
        ),
      ];

      expect(mergePlaces(places, drifted), hasLength(2));
    });

    test('but a different place with the same name is kept', () {
      const other = PersonalPlace(
        id: 'y',
        label: 'Treffpunkt Schule',
        latitude: 48.1,
        longitude: 11.5,
      );

      expect(mergePlaces(places, const [other]), hasLength(3));
    });
  });
}

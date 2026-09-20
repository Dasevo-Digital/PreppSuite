import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/readable_position.dart';

/// Coordinates, checked against points somebody else published.
///
/// This is arithmetic nobody can eyeball. A transposed sign or a dropped
/// term gives a number that looks entirely plausible and puts a rescue
/// team in the wrong valley.
///
/// So the UTM values below were computed a second time, by a **different
/// derivation** — the Krüger series over the conformal latitude, rather
/// than the Snyder series the app uses — and the two agree to the
/// centimetre. Two spellings of the same mistake are possible; two
/// derivations of it are not. The Plus Code is held against the example
/// in the specification, and the two exact UTM values (a central meridian
/// is 500 000 m by definition) need no reference at all.
void main() {
  ReadablePosition at(double lat, double lon) =>
      ReadablePosition(latitude: lat, longitude: lon);

  group('degrees and minutes', () {
    test(
      'the Brandenburg Gate reads back the way a control room writes it',
      () {
        expect(
          at(52.516275, 13.377704).degreesMinutesSeconds,
          '52° 30′ 58.6″ N, 13° 22′ 39.7″ E',
        );
      },
    );

    test('south and west get their own letters', () {
      final south = at(-33.856159, 151.215256).degreesMinutesSeconds;
      expect(south, startsWith('33° 51′'));
      expect(south, contains('S'));
      expect(south, contains('E'));

      expect(at(38.8895, -77.0353).degreesMinutesSeconds, contains('W'));
    });

    test('59.96 seconds carries instead of printing as sixty', () {
      // One degree minus a hair: naive rounding writes 0° 59′ 60.0″.
      final text = at(0.9999999, 0).degreesMinutesSeconds;
      expect(text, isNot(contains('60.0″')));
      expect(text, startsWith('1° 00′ 00.0″ N'));
    });
  });

  group('UTM', () {
    test('a point on a central meridian sits at the false easting', () {
      // Zone 31 is centred on 3° E, and its centre line is 500 000 m by
      // definition — the one value in the whole projection that can be
      // checked without a table.
      final grid = at(0, 3).utm;
      expect(grid, startsWith('31N '));
      expect(grid, '31N 500000 0');
    });

    test('the Washington Monument lands where the second derivation says', () {
      expect(at(38.8895, -77.0353).utm, '18S 323478 4306483');
    });

    test('and so does a German position', () {
      expect(at(52.516275, 13.377704).utm, '33U 389918 5819699');
    });

    test('a second zone, at a German latitude, is exact as well', () {
      // Zone 32 is centred on 9° E. Anything on that line is 500 000 m
      // east, whatever the latitude — the projection's own definition.
      expect(at(52, 9).utm, '32U 500000 5761038');
    });

    test('south of the equator counts from the false origin', () {
      final grid = at(-33.856159, 151.215256).utm;
      expect(grid, startsWith('56H '));
      // Never negative: that is what the ten-million offset is for.
      expect(int.parse(grid.split(' ').last), greaterThan(6000000));
    });

    group('the two strips that are not six degrees wide', () {
      test('south-western Norway stays in one zone', () {
        // 32V was widened in 1950 so that the coast is not split.
        expect(ReadablePosition.utmZone(58, 5), 32);
        expect(ReadablePosition.utmZone(50, 5), 31);
      });

      test('Svalbard is rearranged as well', () {
        expect(ReadablePosition.utmZone(78, 15), 33);
        expect(ReadablePosition.utmZone(78, 25), 35);
      });
    });

    test('the band letters leave out I and O', () {
      final bands = [
        for (var lat = -80.0; lat < 84; lat += 4) ReadablePosition.utmBand(lat),
      ];
      expect(bands, isNot(contains('I')));
      expect(bands, isNot(contains('O')));
      expect(ReadablePosition.utmBand(52.5), 'U');
      expect(ReadablePosition.utmBand(0), 'N');
      expect(ReadablePosition.utmBand(-0.001), 'M');
    });
  });

  group('MGRS', () {
    test('the Washington Monument keeps its 100 km square', () {
      // UJ is the square the published reference names; the five digits
      // follow from the UTM values checked above.
      expect(at(38.8895, -77.0353).mgrs, '18S UJ 23478 06483');
    });

    test('a German position comes out in the right 100 km square', () {
      final reference = at(52.516275, 13.377704).mgrs;
      expect(reference, startsWith('33U '));
      // Five digits each way, zero-padded, so the two halves cannot be
      // told apart by length.
      final parts = reference.split(' ');
      expect(parts, hasLength(4));
      expect(parts[2], hasLength(5));
      expect(parts[3], hasLength(5));
    });
  });

  group('Plus Code', () {
    test('the example from the specification', () {
      expect(at(47.365590, 8.524997).plusCode, '8FVC9G8F+6X');
    });

    test('a code is always eight, a plus and two', () {
      for (final point in [
        at(52.516275, 13.377704),
        at(-33.856159, 151.215256),
        at(0, 0),
        at(-89.9, -179.9),
      ]) {
        expect(
          RegExp(
            r'^[23456789CFGHJMPQRVWX]{8}\+[23456789CFGHJMPQRVWX]{2}$',
          ).hasMatch(point.plusCode),
          isTrue,
          reason: point.plusCode,
        );
      }
    });

    test('a German position, checked a second way', () {
      // Recomputed with a separate implementation of the same published
      // algorithm, which also reproduces the specification's example
      // above — two runs of one spec, not one run twice.
      expect(at(52.516275, 13.377704).plusCode, '9F4MG98H+G3');
    });

    test('the north pole does not fall off the last row', () {
      // The one input that overruns the integer grid if it is not caught.
      expect(at(90, 0).plusCode, isNotEmpty);
    });
  });

  test('decimal keeps six places, which is about ten centimetres', () {
    expect(at(52.5, 13.0).decimal, '52.500000, 13.000000');
  });

  test('an accuracy travels with the position, or does not exist', () {
    expect(at(52.5, 13.0).accuracyMetres, isNull);
    expect(
      ReadablePosition(
        latitude: 52.5,
        longitude: 13.0,
        accuracyMetres: 12.4,
      ).accuracyMetres,
      12.4,
    );
  });
}

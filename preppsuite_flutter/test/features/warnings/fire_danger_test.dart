import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_level.dart';

/// Reading the DWD's forest fire danger index.
///
/// The five levels are the DWD's own wording — "sehr geringe Gefahr"
/// through "sehr hohe Gefahr" — and the index is meteorological
/// potential, not a warning and not a ban on entering a forest.
void main() {
  group('the station list', () {
    // Verbatim from the real file, which is fixed-width with semicolons
    // in it: every field is padded and therefore trimmed. And it is
    // Latin-1, which is what the client handles before this sees it.
    const list = '''
Stationsindex; Höhe in m;Breite   ;Länge    ;Name                    ;Bundesland
           44;        44;    52.93;     8.24;Großenkneten            ;Niedersachsen
          662;        81;    52.29;    10.45;Braunschweig            ;Niedersachsen
        20098;      1019;    48.57;     8.23;Seebach (Nationalpark)  ;Baden-Württemberg
''';

    test('reads the index, the place, the state and the position', () {
      final stations = FireDangerClient.parseStations(list);

      expect(stations, hasLength(3));
      final braunschweig = stations[1];
      expect(braunschweig.id, '662');
      expect(braunschweig.name, 'Braunschweig');
      expect(braunschweig.state, 'Niedersachsen');
      expect(braunschweig.heightAboveSea, 81);
      expect(braunschweig.latitude, closeTo(52.29, 0.001));
      expect(braunschweig.longitude, closeTo(10.45, 0.001));
    });

    test('the header row is not a station', () {
      // Recognised by its index not being a number, rather than by
      // counting lines: a file that gains a comment line would
      // otherwise turn one into a station called "Name".
      final stations = FireDangerClient.parseStations(list);
      expect(stations.map((s) => s.name), isNot(contains('Name')));
    });

    test('umlauts survive, which is the whole encoding question', () {
      final stations = FireDangerClient.parseStations(list);
      expect(stations.first.name, 'Großenkneten');
      expect(stations.last.state, 'Baden-Württemberg');
    });

    test('a truncated or empty list is empty, not an exception', () {
      expect(FireDangerClient.parseStations(''), isEmpty);
      expect(FireDangerClient.parseStations('662;81'), isEmpty);
    });
  });

  group('one station’s forecast', () {
    // The real header and two real rows for Braunschweig.
    const csv = '''
StationsID;Termin;wbi_0;wbi_1;wbi_2;wbi_3;wbi_4;wbi_5;wbi_6
662;20260910 04:14;2;3;2;1;1;1;2
662;20260911 04:14;2;2;1;1;1;1;1
''';

    test('the newest row comes first, whatever order the file is in', () {
      final rows = parseForecast(csv, station: 'Braunschweig');

      expect(rows, hasLength(2));
      expect(rows.first.issuedFor, DateTime(2026, 9, 11));
      expect(rows.last.issuedFor, DateTime(2026, 9, 10));
    });

    test('all seven days are read, today first', () {
      final forecast = parseForecast(csv, station: 'Braunschweig').first;

      expect(forecast.days.map((d) => d.step), [2, 2, 1, 1, 1, 1, 1]);
      expect(forecast.today, FireDangerLevel.low);
      expect(forecast.stationName, 'Braunschweig');
    });

    test('only the date is kept, not the model run time', () {
      // `20260911 04:14` — 04:14 is when the DWD computed it, not an
      // hour the danger applies to, and showing it beside a level
      // invites exactly that reading.
      final forecast = parseForecast(csv, station: 'Braunschweig').first;

      expect(forecast.issuedFor.hour, 0);
      expect(forecast.issuedFor.minute, 0);
    });

    test('a malformed row costs a day, not the file', () {
      final rows = parseForecast('''
StationsID;Termin;wbi_0
662;nonsense;2
662;20260911 04:14;3
''', station: 'Braunschweig');

      expect(rows, hasLength(1));
      expect(rows.single.today, FireDangerLevel.moderate);
    });

    test('a step outside one to five ends the run rather than shifting it', () {
      // A gap in the middle must not pull every later day one place
      // closer to today; that would report Friday's danger as
      // Thursday's.
      final forecast = parseForecast(
        'StationsID;Termin;a;b;c;d\n662;20260911 04:14;1;2;9;4\n',
        station: 'X',
      ).single;

      expect(forecast.days.map((d) => d.step), [1, 2]);
    });

    test('an empty file yields nothing', () {
      expect(parseForecast('', station: 'X'), isEmpty);
      expect(
        parseForecast('StationsID;Termin;wbi_0\n', station: 'X'),
        isEmpty,
      );
    });
  });

  group('what the days ahead say', () {
    FireDangerForecast forecast(List<int> steps) => FireDangerForecast(
      stationName: 'X',
      issuedFor: DateTime(2026, 9, 11),
      days: [for (final step in steps) FireDangerLevel.fromStep(step)!],
    );

    test('a rise ahead is named, with how far away it is', () {
      // The one thing a single number cannot say: level 2 today with
      // level 5 on Friday is a different week from level 2 throughout.
      final peak = forecast([2, 2, 3, 5, 4]).peakAhead;

      expect(peak!.level, FireDangerLevel.veryHigh);
      expect(peak.inDays, 3);
    });

    test('tomorrow is reported as one day', () {
      expect(forecast([1, 4, 1]).peakAhead!.inDays, 1);
    });

    test('a week that only falls has no peak to report', () {
      expect(forecast([4, 3, 2, 1]).peakAhead, isNull);
    });

    test('a flat week has none either', () {
      expect(forecast([2, 2, 2]).peakAhead, isNull);
    });

    test('and a forecast of only today has nothing ahead at all', () {
      expect(forecast([3]).peakAhead, isNull);
    });
  });

  group('staleness', () {
    FireDangerForecast issued(DateTime day) => FireDangerForecast(
      stationName: 'X',
      issuedFor: day,
      days: const [FireDangerLevel.low],
    );

    test('today’s and yesterday’s stand', () {
      // The DWD issues once a day in the small hours; before the run
      // arrives, yesterday's is the current one.
      expect(
        issued(DateTime(2026, 9, 11)).isStale(now: DateTime(2026, 9, 11, 8)),
        isFalse,
      );
      expect(
        issued(DateTime(2026, 9, 10)).isStale(now: DateTime(2026, 9, 11, 8)),
        isFalse,
      );
    });

    test('older than that is the end of the season or a lost connection', () {
      // Out of season — the DWD issues March to October — nothing new
      // arrives, and a level from last October must not stand all
      // winter as "today".
      expect(
        issued(DateTime(2025, 10, 30)).isStale(now: DateTime(2026, 1, 15)),
        isTrue,
      );
      expect(
        issued(DateTime(2026, 9, 8)).isStale(now: DateTime(2026, 9, 11)),
        isTrue,
      );
    });
  });

  group('the levels themselves', () {
    test('five steps, and the DWD’s numbering', () {
      expect(FireDangerLevel.values.map((l) => l.step), [1, 2, 3, 4, 5]);
      expect(FireDangerLevel.fromStep(1), FireDangerLevel.veryLow);
      expect(FireDangerLevel.fromStep(5), FireDangerLevel.veryHigh);
    });

    test('anything off the scale is not a level', () {
      expect(FireDangerLevel.fromStep(0), isNull);
      expect(FireDangerLevel.fromStep(6), isNull);
      expect(FireDangerLevel.fromStep(-1), isNull);
    });
  });
}

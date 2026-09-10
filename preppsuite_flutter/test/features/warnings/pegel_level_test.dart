import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_level.dart';

/// Reading a gauge without knowing the river.
///
/// The numbers below are the real published values for the Rhine at
/// Cologne, because that gauge is the reason this exists: it read 66 cm on
/// the day this was written, which is near-record *low* water, and any
/// scheme that reports a small number as calm and a large one as
/// dangerous gets that exactly backwards.
void main() {
  /// Cologne's published long-term levels, in centimetres.
  const koeln = {
    PegelReference.lowest: 69.0,
    PegelReference.meanLow: 114.0,
    PegelReference.mean: 297.0,
    PegelReference.meanFlood: 725.0,
    PegelReference.highest: 1069.0,
  };

  PegelReading reading(
    double centimetres, {
    Map<PegelReference, double> references = koeln,
    double? changeOverDay,
    DateTime? measuredAt,
  }) => PegelReading(
    stationName: 'KÖLN',
    water: 'RHEIN',
    centimetres: centimetres,
    measuredAt: measuredAt ?? DateTime(2026, 9, 10, 16, 30),
    references: references,
    changeOverDay: changeOverDay,
  );

  group('where a reading sits', () {
    test('66 cm at Cologne is a record low, not a calm river', () {
      expect(reading(66).band, PegelBand.recordLow);
    });

    test('just above the record is still low water', () {
      expect(reading(100).band, PegelBand.low);
    });

    test('the everyday range reads as ordinary', () {
      expect(reading(250).band, PegelBand.ordinary);
      expect(reading(297).band, PegelBand.ordinary, reason: 'the mean itself');
    });

    test('above the mean but short of a flood is elevated', () {
      expect(reading(500).band, PegelBand.elevated);
    });

    test('the mean of flood levels is where flood starts', () {
      expect(reading(725).band, PegelBand.flood);
      expect(reading(900).band, PegelBand.flood);
    });

    test('the highest ever recorded is its own band', () {
      // 1069 cm is 1993 at Cologne. Anything at or past it is outside
      // everything the gauge has seen, and saying "flood" for it would
      // be the same word as for a routine high water.
      expect(reading(1069).band, PegelBand.recordHigh);
      expect(reading(1200).band, PegelBand.recordHigh);
    });

    test('a gauge that publishes nothing says nothing', () {
      // About a quarter of them publish no reference values at all.
      // Inventing a threshold would be worse than an empty answer.
      expect(reading(400, references: const {}).band, PegelBand.unknown);
    });

    test('a gauge with only the flood mean can still say flood', () {
      const onlyFlood = {PegelReference.meanFlood: 725.0};

      expect(reading(800, references: onlyFlood).band, PegelBand.flood);
      expect(reading(200, references: onlyFlood).band, PegelBand.ordinary);
    });
  });

  group('the trend', () {
    test('a day of gain reads as rising', () {
      expect(reading(300, changeOverDay: 40).trend, PegelTrend.rising);
    });

    test('a day of loss reads as falling', () {
      expect(reading(300, changeOverDay: -40).trend, PegelTrend.falling);
    });

    test('a few centimetres either way is not a trend', () {
      // Wind and passing ships move a gauge by a centimetre or two, and a
      // household should not be told the river is rising because of a
      // barge.
      expect(reading(300, changeOverDay: 3).trend, PegelTrend.steady);
      expect(reading(300, changeOverDay: -4).trend, PegelTrend.steady);
    });

    test('no series means no claim', () {
      expect(reading(300).trend, PegelTrend.unknown);
    });
  });

  group('the change over a day', () {
    List<({DateTime at, double value})> series({
      required Duration span,
      required double from,
      required double to,
      Duration step = const Duration(minutes: 15),
    }) {
      final start = DateTime(2026, 9, 9, 16, 30);
      final steps = span.inMinutes ~/ step.inMinutes;
      return [
        for (var i = 0; i <= steps; i++)
          (at: start.add(step * i), value: from + (to - from) * i / steps),
      ];
    }

    test('a full two-day series gives the day', () {
      final samples = series(
        span: const Duration(days: 2),
        from: 100,
        to: 200,
      );

      // The newest is 200 and a day back is the midpoint, 150.
      expect(changeOverDay(samples), closeTo(50, 1));
    });

    test('a series too short to span a day says nothing', () {
      // Rather than reporting the change over the six hours it does have
      // as if it were a day.
      final samples = series(
        span: const Duration(hours: 6),
        from: 100,
        to: 180,
      );

      expect(changeOverDay(samples), isNull);
    });

    test('a single sample says nothing', () {
      expect(changeOverDay([(at: DateTime(2026, 9, 10), value: 66)]), isNull);
    });

    test('an empty series says nothing', () {
      expect(changeOverDay(const []), isNull);
    });

    test('samples out of order are handled', () {
      final samples = series(
        span: const Duration(days: 2),
        from: 100,
        to: 200,
      ).reversed.toList();

      expect(changeOverDay(samples), closeTo(50, 1));
    });

    test('a gap where the day-old sample should be says nothing', () {
      // Two clusters with nothing in between: the oldest sample is far
      // more than a day back, and treating it as "a day ago" would
      // manufacture a trend out of a data gap.
      final samples = [
        (at: DateTime(2026, 9, 1, 12), value: 100.0),
        (at: DateTime(2026, 9, 10, 16, 15), value: 190.0),
        (at: DateTime(2026, 9, 10, 16, 30), value: 200.0),
      ];

      expect(changeOverDay(samples), isNull);
    });
  });

  group('staleness', () {
    test('a reading from a quarter of an hour ago is current', () {
      final now = DateTime(2026, 9, 10, 16, 40);

      expect(reading(66).isStale(now: now), isFalse);
    });

    test('two hours behind is stale, because the gauge reports quarterly', () {
      // Inland gauges send every fifteen minutes. An hour of silence is
      // the app not reaching the service, not the river standing still,
      // and showing it as current would be the one lie that matters here.
      final now = DateTime(2026, 9, 10, 18, 30);

      expect(reading(66).isStale(now: now), isTrue);
    });
  });
}

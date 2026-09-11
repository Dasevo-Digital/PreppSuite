import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_level.dart';

/// Reading a gamma dose rate.
///
/// Every band here is the BfS's own, and that is the point of the tests:
/// a number with "radiation" beside it frightens people, so a threshold
/// this app invented would frighten them at the wrong moment. What BfS
/// publishes is 0.05–0.2 µSv/h as the natural range, rain lifting a
/// reading by up to a factor of three for hours as the harmless ordinary
/// case, and an event only in question beyond that or after a day.
void main() {
  RadiationReading reading({
    required double value,
    double? baseline,
    DateTime? at,
    bool validated = true,
  }) => RadiationReading(
    stationName: 'Hausach',
    microsievertsPerHour: value,
    measuredAt: at ?? DateTime.utc(2026, 9, 11, 6),
    baseline: baseline,
    validated: validated,
  );

  group('against the station’s own baseline', () {
    // Hausach really reads about 0.157 as its median over a week, and
    // the Black Forest ground is why. Judged against one national
    // number it would look permanently raised.
    test('its usual value is ordinary', () {
      expect(
        reading(value: 0.162, baseline: 0.157).band,
        RadiationBand.ordinary,
      );
    });

    test('a tenth above it is still ordinary', () {
      // The probes wander with ground moisture and temperature. A band
      // that flipped on every drizzle would train the reader to ignore
      // it.
      expect(
        reading(value: 0.172, baseline: 0.157).band,
        RadiationBand.ordinary,
      );
    });

    test('a rain spike reads as weather, not as an event', () {
      // 0.208 was the real weekly maximum at that station, 1.3 times
      // its baseline — a shower.
      expect(
        reading(value: 0.208, baseline: 0.157).band,
        RadiationBand.weather,
      );
    });

    test('up to three times the baseline is still weather', () {
      // The factor BfS attributes to washout, exactly.
      expect(
        reading(value: 0.157 * 3, baseline: 0.157).band,
        RadiationBand.weather,
      );
    });

    test('beyond three times it is past what weather explains', () {
      expect(
        reading(value: 0.157 * 3.01, baseline: 0.157).band,
        RadiationBand.unusual,
      );
    });

    test('and below its baseline is ordinary, not remarkable', () {
      // Lying snow shields the ground and the reading drops. That is
      // not a finding.
      expect(
        reading(value: 0.11, baseline: 0.157).band,
        RadiationBand.ordinary,
      );
    });
  });

  group('without a baseline', () {
    // A station read for the first time, or offline. The national range
    // is the only honest comparison and it is coarser.
    test('inside the natural range there is nothing to say', () {
      expect(reading(value: naturalFloor).band, RadiationBand.ordinary);
      expect(reading(value: naturalCeiling).band, RadiationBand.ordinary);
      expect(reading(value: 0.16).band, RadiationBand.ordinary);
    });

    test('above it, weather is still the first explanation', () {
      expect(reading(value: 0.4).band, RadiationBand.weather);
      expect(
        reading(value: naturalCeiling * weatherFactor).band,
        RadiationBand.weather,
      );
    });

    test('beyond that nothing is claimed either way', () {
      // Deliberately `unknown` and not `unusual`: without the station's
      // own history there is no factor to have exceeded, and calling it
      // unusual would be a claim the data does not support.
      expect(reading(value: 0.9).band, RadiationBand.unknown);
    });
  });

  group('the reference and the factor', () {
    test('the baseline is the reference where there is one', () {
      final read = reading(value: 0.314, baseline: 0.157);
      expect(read.reference, 0.157);
      expect(read.factor, closeTo(2, 0.001));
    });

    test('and the natural ceiling stands in where there is not', () {
      expect(reading(value: 0.2).reference, naturalCeiling);
    });
  });

  group('staleness', () {
    test('an hour behind is normal for an hourly network', () {
      expect(
        reading(
          value: 0.16,
          at: DateTime.utc(2026, 9, 11, 6),
        ).isStale(now: DateTime.utc(2026, 9, 11, 7)),
        isFalse,
      );
    });

    test('three hours behind is a missing connection', () {
      expect(
        reading(
          value: 0.16,
          at: DateTime.utc(2026, 9, 11, 6),
        ).isStale(now: DateTime.utc(2026, 9, 11, 9)),
        isTrue,
      );
    });
  });

  group('working out what a station usually reads', () {
    test('the median, because every shower in the series is a spike', () {
      // An average would fold the spikes into the thing they are meant
      // to be measured against. These twelve have one big one.
      final values = [
        0.15,
        0.15,
        0.16,
        0.15,
        0.16,
        0.15,
        0.60,
        0.16,
        0.15,
        0.16,
        0.15,
        0.16,
      ];
      final baseline = baselineFrom(values)!;

      expect(baseline, closeTo(0.155, 0.001));
      final mean = values.reduce((a, b) => a + b) / values.length;
      expect(mean, greaterThan(0.19));
    });

    test('twelve samples at least, or nothing', () {
      // A handful of hours could all be the same shower.
      expect(baselineFrom(List.filled(11, 0.16)), isNull);
      expect(baselineFrom(List.filled(12, 0.16)), 0.16);
    });

    test('zeroes and negatives are dropped, not averaged in', () {
      // A probe that reports nothing reports 0, and counting that as a
      // measurement would halve the baseline and make the next ordinary
      // reading look raised.
      final values = [...List.filled(12, 0.16), 0.0, 0.0, -1.0];
      expect(baselineFrom(values), 0.16);
    });

    test('an odd count takes the middle sample', () {
      expect(baselineFrom([for (var i = 1; i <= 13; i++) i * 0.01]), 0.07);
    });
  });
}

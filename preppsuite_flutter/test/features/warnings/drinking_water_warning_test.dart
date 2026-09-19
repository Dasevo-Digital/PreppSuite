import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/drinking_water_warning.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  final now = DateTime.utc(2026, 9, 19);

  Warning warning({String eventType = 'Warnung', String headline = ''}) =>
      Warning(
        source: 'bbk',
        externalId: 'w',
        countryCode: 'DE',
        severity: 'severe',
        eventType: eventType,
        headline: headline,
        effective: now,
        sent: now,
        updatedAt: now,
        notified: false,
      );

  test('the wording the live feed actually uses is recognised', () {
    // The one confirmed against the real BBK feed, quoted in
    // `warning_ingest.dart`.
    expect(
      isDrinkingWaterWarning(
        warning(headline: 'Vogelsbergkreis meldet: Warnung Trinkwasserunfall'),
      ),
      isTrue,
    );
    expect(
      isDrinkingWaterWarning(warning(eventType: 'Abkochgebot')),
      isTrue,
    );
    expect(
      isDrinkingWaterWarning(
        headlineOf('Ausfall der Wasserversorgung im Ortsteil Nord'),
      ),
      isTrue,
    );
  });

  test('an English feed is recognised too', () {
    expect(
      isDrinkingWaterWarning(warning(headline: 'Boil water notice issued')),
      isTrue,
    );
    expect(
      isDrinkingWaterWarning(warning(eventType: 'Drinking water quality')),
      isTrue,
    );
  });

  test('an unrelated warning is not', () {
    expect(isDrinkingWaterWarning(warning(headline: 'Orkanböen')), isFalse);
    expect(
      isDrinkingWaterWarning(
        warning(eventType: 'Hochwasser', headline: 'Pegel'),
      ),
      isFalse,
    );
  });

  test('it picks the water warnings out of a list, order kept', () {
    final all = [
      warning(headline: 'Orkanböen'),
      warning(headline: 'Abkochgebot Ortsteil Nord'),
      warning(headline: 'Trinkwasser verunreinigt'),
    ];

    expect(
      drinkingWaterWarnings(all).map((w) => w.headline),
      ['Abkochgebot Ortsteil Nord', 'Trinkwasser verunreinigt'],
    );
  });
}

Warning headlineOf(String headline) => Warning(
  source: 'bbk',
  externalId: 'w',
  countryCode: 'DE',
  severity: 'severe',
  eventType: 'Warnung',
  headline: headline,
  effective: DateTime.utc(2026, 9, 19),
  sent: DateTime.utc(2026, 9, 19),
  updatedAt: DateTime.utc(2026, 9, 19),
  notified: false,
);

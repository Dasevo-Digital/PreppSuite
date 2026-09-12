import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_bearing.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_l10n.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_en.dart';

void main() {
  test('a German screen writes the decimal with a comma', () {
    // `toStringAsFixed` always writes a point, so this read "1.1 km"
    // beside numbers that read "1,1" everywhere else on the same screen.
    final text = formatShelterDistance(
      AppLocalizationsDe(),
      1140,
      CompassPoint.northEast,
    );

    expect(text, contains('1,1 km'));
    expect(text, isNot(contains('1.1')));
  });

  test('and an English one with a point', () {
    final text = formatShelterDistance(
      AppLocalizationsEn(),
      1140,
      CompassPoint.northEast,
    );

    expect(text, contains('1.1 km'));
  });

  test('below a kilometre it stays in metres, to the nearest ten', () {
    // The coordinates are crowd-sourced; "287 m" claims a precision they
    // have not got.
    expect(
      formatShelterDistance(AppLocalizationsDe(), 287, CompassPoint.north),
      contains('290 m'),
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas_provider.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';

/// A postcode in the region field hid the warnings for the household's own
/// district and state (#349).
void main() {
  final l10n = AppLocalizationsDe();
  final areas = DwdAreas.parse(
    File('assets/dwd_warncells.csv').readAsStringSync(),
  );

  group('a stored key', () {
    test('that cannot be a district counts as none', () {
      const filter = WarningRegionFilter(
        countryCode: 'DE',
        ownRegionKey: '77756',
      );
      expect(filter.hasAnyRegion, isFalse, reason: 'everything is shown');
      expect(filter.ownKreisSchluessel, isNull);
    });

    test('a district key still is one, at five or twelve digits', () {
      for (final key in ['08317', '083170000000', '03101']) {
        final filter = WarningRegionFilter(
          countryCode: 'DE',
          ownRegionKey: key,
        );
        expect(filter.hasAnyRegion, isTrue, reason: key);
        expect(filter.ownKreisSchluessel, key.substring(0, 5));
      }
    });

    test('states run from 01 to 16', () {
      expect(isGermanRegionKey('01001'), isTrue);
      expect(isGermanRegionKey('16051'), isTrue);
      expect(isGermanRegionKey('00123'), isFalse);
      expect(isGermanRegionKey('17123'), isFalse);
      expect(isGermanRegionKey('abcde'), isFalse);
    });
  });

  group('the forms', () {
    test('refuse a postcode', () {
      expect(
        regionKeyProblem('77756', areas: areas, l10n: l10n),
        l10n.regionKeyUnknown,
      );
    });

    test('accept a district and an empty field', () {
      expect(regionKeyProblem('08317', areas: areas, l10n: l10n), isNull);
      expect(regionKeyProblem('', areas: areas, l10n: l10n), isNull);
    });

    test('refuse what has the wrong shape, before the table has loaded', () {
      expect(
        regionKeyProblem('1234', areas: null, l10n: l10n),
        l10n.settingsRegionKeyInvalid,
      );
      expect(regionKeyProblem('77756', areas: null, l10n: l10n), isNull);
    });
  });
}

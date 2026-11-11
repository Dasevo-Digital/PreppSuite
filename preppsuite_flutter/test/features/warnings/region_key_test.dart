import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas_provider.dart';
import 'package:preppsuite_flutter/features/warnings/application/german_district_keys.dart';
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

    test('a key counts only where a district has it', () {
      expect(isGermanRegionKey('01001'), isTrue);
      expect(isGermanRegionKey('16051'), isTrue);
      expect(isGermanRegionKey('00123'), isFalse);
      expect(isGermanRegionKey('17123'), isFalse);
      expect(isGermanRegionKey('abcde'), isFalse);
      // Postcodes that begin like a state: Leipzig like Bremen, Dresden
      // like Schleswig-Holstein, Berlin-Mitte like Berlin.
      for (final postcode in ['04109', '01067', '10115', '04103', '06108']) {
        expect(isGermanRegionKey(postcode), isFalse, reason: postcode);
      }
    });

    test('a postcode in Leipzig does not make Bremen the own state', () {
      const filter = WarningRegionFilter(
        countryCode: 'DE',
        ownRegionKey: '04109',
      );
      expect(filter.ownKreisSchluessel, isNull);
      expect(filter.hasAnyRegion, isFalse, reason: 'everything is shown');
    });

    test('a postcode beside a followed place still shows everything', () {
      const filter = WarningRegionFilter(
        countryCode: 'DE',
        ownRegionKey: '77756',
        extraRegions: [
          WarningRegion(kind: WarningRegionKind.kreis, value: '05334'),
        ],
      );
      expect(
        filter.hasAnyRegion,
        isFalse,
        reason: 'the followed place alone would hide where the household is',
      );
    });

    test('a followed postcode is no place', () {
      const postcode = WarningRegionFilter(
        countryCode: 'DE',
        extraRegions: [
          WarningRegion(kind: WarningRegionKind.kreis, value: '77756'),
        ],
      );
      expect(postcode.hasAnyRegion, isFalse);
      expect(postcode.followedKreisSchluessel, isEmpty);

      const district = WarningRegionFilter(
        countryCode: 'DE',
        extraRegions: [
          WarningRegion(kind: WarningRegionKind.kreis, value: '05334'),
          WarningRegion(kind: WarningRegionKind.bundesland, value: 'BY'),
        ],
      );
      expect(district.hasAnyRegion, isTrue);
      expect(district.followedKreisSchluessel, ['05334']);
    });

    test('the list in the code is the district table', () {
      final fromTable = {
        for (final line in File(
          'assets/dwd_warncells.csv',
        ).readAsLinesSync().where((line) => !line.startsWith('#')))
          if (line.split(';') case [_, final key, ...] when key.isNotEmpty) key,
      };
      expect(
        germanDistrictKeys,
        fromTable,
        reason: 'run tool/german_district_keys.py after the table changed',
      );
      for (final key in germanDistrictKeys) {
        expect(areas.describeDistrict(key), isNotNull, reason: key);
      }
    });
  });

  group('the forms', () {
    test('refuse a postcode, also one that begins like a state', () {
      for (final postcode in ['77756', '04109', '10115']) {
        expect(
          regionKeyProblem(postcode, l10n: l10n),
          l10n.regionKeyUnknown,
          reason: postcode,
        );
      }
    });

    test('accept a district and an empty field', () {
      expect(regionKeyProblem('08317', l10n: l10n), isNull);
      expect(regionKeyProblem('083170000000', l10n: l10n), isNull);
      expect(regionKeyProblem('', l10n: l10n), isNull);
    });

    test('refuse what has the wrong shape', () {
      expect(
        regionKeyProblem('1234', l10n: l10n),
        l10n.settingsRegionKeyInvalid,
      );
    });
  });
}

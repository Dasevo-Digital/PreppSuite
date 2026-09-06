import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:preppsuite_flutter/model/household_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const profile = HouseholdProfile(
    id: 'abc',
    name: 'Zuhause',
    countryCode: 'DE',
    regionKey: '053340000000',
    personCount: 3,
    extraRegions: [
      WarningRegion(kind: WarningRegionKind.bundesland, value: 'BY'),
    ],
  );

  group('serialisation', () {
    test('round-trips every field', () {
      final restored = HouseholdProfile.fromJson(profile.toJson());

      expect(restored!.id, 'abc');
      expect(restored.name, 'Zuhause');
      expect(restored.countryCode, 'DE');
      expect(restored.regionKey, '053340000000');
      expect(restored.personCount, 3);
      expect(restored.extraRegions, hasLength(1));
    });

    test('a profile without a region round-trips too', () {
      const bare = HouseholdProfile(id: 'x', name: 'A', countryCode: 'AT');

      final restored = HouseholdProfile.fromJson(bare.toJson());

      expect(restored!.regionKey, isNull);
      expect(restored.personCount, 1);
      expect(restored.extraRegions, isEmpty);
    });

    test('rubbish yields null rather than a half-built profile', () {
      // This is read from preferences and, later, from files other devices
      // wrote. A corrupt profile has to send the user through onboarding,
      // not crash the app on every launch.
      expect(HouseholdProfile.fromJson(const {}), isNull);
      expect(HouseholdProfile.fromJson(const {'id': ''}), isNull);
      expect(
        HouseholdProfile.fromJson(const {'id': 'a', 'name': 'b'}),
        isNull,
        reason: 'a profile without a country cannot poll anything',
      );
    });

    test('an unparseable extra region is dropped, not fatal', () {
      final restored = HouseholdProfile.fromJson({
        ...profile.toJson(),
        'extraRegions': ['bundesland:BY', 'nonsense', 42],
      });

      expect(restored!.extraRegions, hasLength(1));
    });
  });

  group('warningFilter', () {
    test('carries country, own region and extras', () {
      final filter = profile.warningFilter;

      expect(filter.countryCode, 'DE');
      expect(filter.ownKreisSchluessel, '05334');
      expect(filter.extraRegions, hasLength(1));
    });
  });

  group('copyWith', () {
    test('keeps the id — it is the identity of the data', () {
      // Two devices sharing a folder have to agree on it, so nothing in
      // the UI may change it.
      expect(profile.copyWith(name: 'Anders').id, 'abc');
    });

    test('clearing the region needs an explicit flag', () {
      // Otherwise `copyWith(regionKey: null)` would be indistinguishable
      // from "leave it alone" and the region could never be removed.
      expect(profile.copyWith(regionKey: null).regionKey, '053340000000');
      expect(profile.copyWith(clearRegionKey: true).regionKey, isNull);
    });
  });

  group('HouseholdProfileStore', () {
    test('nothing stored reads back as null', () async {
      expect(await const HouseholdProfileStore().load(), isNull);
    });

    test('a saved profile survives a reload', () async {
      const store = HouseholdProfileStore();
      await store.save(profile);

      expect((await store.load())!.id, 'abc');
    });

    test('a corrupt stored profile reads back as null', () async {
      SharedPreferences.setMockInitialValues({
        'householdProfile': 'not json',
      });

      expect(await const HouseholdProfileStore().load(), isNull);
    });
  });

  group('children and animals', () {
    test('survive the round trip through preferences', () {
      const profile = HouseholdProfile(
        id: 'h',
        name: 'Zuhause',
        countryCode: 'DE',
        personCount: 2,
        children: 3,
        dogs: 1,
        cats: 2,
      );

      final back = HouseholdProfile.fromJson(profile.toJson())!;
      expect(back.personCount, 2);
      expect(back.children, 3);
      expect(back.dogs, 1);
      expect(back.cats, 2);
    });

    // A profile written before these fields existed is the normal case on
    // an upgrade, not a corrupt one.
    test('are zero in a profile that predates them', () {
      final back = HouseholdProfile.fromJson({
        'id': 'h',
        'name': 'Zuhause',
        'countryCode': 'DE',
        'personCount': 2,
      })!;

      expect(back.personCount, 2);
      expect(back.children, 0);
      expect(back.dogs, 0);
      expect(back.cats, 0);
    });

    test('nonsense counts read as none', () {
      final back = HouseholdProfile.fromJson({
        'id': 'h',
        'name': 'Zuhause',
        'countryCode': 'DE',
        'children': -4,
        'dogs': 'zwei',
      })!;

      expect(back.children, 0);
      expect(back.dogs, 0);
    });
  });
}

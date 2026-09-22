import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which settings follow a household onto a second device.
///
/// The list is the whole design here, so the test is mostly about what is
/// *not* on it. Three kinds of setting would break the receiving device
/// rather than help it, and each of them has been on somebody's list of
/// "surely we just copy everything".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the allow-list', () {
    test('leaves out what identifies the device', () {
      // Two devices claiming one id is not a sync, it is a collision.
      expect(carriedSettings, isNot(contains('syncDeviceId')));
    });

    test('leaves out every local file path', () {
      for (final key in [
        'sharedFolderPath',
        'sharedFolderLabel',
        'offlineMapArchivePath',
        'offlineMapArchiveLabel',
        'knowledgeArchives',
        'knowledgeSelectedArchive',
        'knowledgeArchiveLocation',
        'knowledgePersonalDocuments',
      ]) {
        expect(carriedSettings, isNot(contains(key)), reason: key);
      }
    });

    test('leaves out the map key, which lives in the keychain', () {
      // Carrying it would move a secret out of the platform's credential
      // store and into a preferences file that is plain JSON on desktop.
      expect(carriedSettings, isNot(contains('mapTilerApiKey')));
      expect(carriedSettings, isNot(contains('map_tiler_api_key')));
    });

    test('leaves out the warning region, which mirrors the profile', () {
      // Those three keys are written from the profile on every save, so
      // carrying them would carry the shadow and lose the argument with
      // the thing itself a moment later.
      expect(carriedSettings, isNot(contains('warningCountryCode')));
      expect(carriedSettings, isNot(contains('warningRegionKey')));
    });

    test('carries what a household typed in by hand', () {
      // The energy plan is appliance-by-appliance work, and the most
      // painful thing to be asked for twice.
      expect(carriedSettings, contains('energyDraws'));
      expect(carriedSettings, contains('energyReserves'));
      expect(carriedSettings, contains('daylightLatitude'));
      expect(carriedSettings, contains('pegelStation'));
    });
  });

  group('reading and writing', () {
    test('a full round trip keeps every kind intact', () async {
      SharedPreferences.setMockInitialValues({
        'energyDraws': ['Kühlschrank;80', 'Router;12'],
        'daylightLatitude': 52.52,
        'expiryLeadDays': 14,
        'outageFreezerFull': true,
        'pegelStation': 'DRESDEN',
        // Not on the list: must not travel.
        'syncDeviceId': 'device-a',
      });
      final sent = await readCarriedSettings();

      expect(sent, isNot(contains('syncDeviceId')));

      SharedPreferences.setMockInitialValues({});
      expect(await applyCarriedSettings(sent), sent.length);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('energyDraws'), [
        'Kühlschrank;80',
        'Router;12',
      ]);
      expect(prefs.getDouble('daylightLatitude'), 52.52);
      expect(prefs.getInt('expiryLeadDays'), 14);
      expect(prefs.getBool('outageFreezerFull'), isTrue);
      expect(prefs.getString('pegelStation'), 'DRESDEN');
      expect(prefs.getString('syncDeviceId'), isNull);
    });

    test('a whole-numbered latitude still arrives as a decimal', () async {
      // JSON has one number type and preferences have two. Without the
      // kind table, 52.0 would cross as an int and land where getDouble
      // cannot read it — a bug that hides everywhere except on the
      // meridian.
      SharedPreferences.setMockInitialValues({});
      await applyCarriedSettings({'daylightLatitude': 52});

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('daylightLatitude'), 52.0);
    });

    test('an unknown key and a wrong type are dropped, not thrown', () async {
      SharedPreferences.setMockInitialValues({});
      final applied = await applyCarriedSettings({
        'somethingNewer': 'from a later version',
        'expiryLeadDays': 'fourteen',
        'pegelStation': 'DRESDEN',
      });

      // Only the one that made sense. A handover must not fail over a
      // setting the other side spells differently.
      expect(applied, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pegelStation'), 'DRESDEN');
    });

    test('a setting nobody ever touched is not sent at all', () async {
      // Sending it as a null would overwrite an opinion on the other side
      // with the absence of one here.
      SharedPreferences.setMockInitialValues({'pegelStation': 'DRESDEN'});
      expect(await readCarriedSettings(), {'pegelStation': 'DRESDEN'});
    });
  });

  group('the household as a whole', () {
    test('survives being written down and read back', () {
      const profile = HouseholdProfile(
        id: 'home',
        name: 'Zuhause',
        countryCode: 'DE',
        regionKey: '146270000000',
        personCount: 3,
        children: 1,
        dogs: 1,
      );
      final there = CarriedHousehold.fromJson(
        const CarriedHousehold(
          profile: profile,
          settings: {'pegelStation': 'DRESDEN'},
        ).toJson(),
      );

      expect(there.profile?.name, 'Zuhause');
      expect(there.profile?.personCount, 3);
      expect(there.profile?.children, 1);
      expect(there.settings, {'pegelStation': 'DRESDEN'});
    });

    test('a damaged profile costs the profile, not the settings', () {
      final there = CarriedHousehold.fromJson({
        'profile': {'name': 'no id here'},
        'settings': {'pegelStation': 'DRESDEN'},
      });

      expect(there.profile, isNull);
      expect(there.settings, {'pegelStation': 'DRESDEN'});
    });

    test('nothing at all reads as nothing at all', () {
      expect(CarriedHousehold.fromJson(null).isEmpty, isTrue);
      expect(CarriedHousehold.fromJson('nonsense').isEmpty, isTrue);
    });
  });

  group('what belongs to the household and used to stay behind', () {
    test('the places the household agreed on travel', () {
      // The meeting point, the way out, the well. They are coordinates,
      // not paths, so nothing about them points at the other machine.
      expect(carriedSettings['personalMapPlaces.v1']!.kind, CarriedKind.text);
    });

    test('and so does what the crisis overview was told by hand', () {
      // The answers the records cannot supply. Re-entering them on every
      // device is exactly the work a handover is supposed to save.
      expect(carriedSettings['preparednessHubV1']!.kind, CarriedKind.text);
    });

    test('both are stored as one string, which is what is claimed', () {
      // A kind that disagrees with the store is a setting that arrives
      // where `getString` cannot read it — see [CarriedKind].
      for (final key in ['personalMapPlaces.v1', 'preparednessHubV1']) {
        expect(carriedSettings[key]!.kind, CarriedKind.text, reason: key);
      }
    });
  });
}

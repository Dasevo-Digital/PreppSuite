import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/daylight/application/daylight_store.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/sharing/application/settings_sync_store.dart';
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
        'energyDraws': '[{"id":"d1","label":"Kühlschrank"}]',
        'watchedAutobahnen': ['A2', 'A7'],
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
      expect(
        prefs.getString('energyDraws'),
        '[{"id":"d1","label":"Kühlschrank"}]',
      );
      expect(prefs.getStringList('watchedAutobahnen'), ['A2', 'A7']);
      expect(prefs.getDouble('daylightLatitude'), 52.52);
      expect(prefs.getString('expiryLeadDays'), '14');
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

  group('what stays on the device', () {
    // The meeting point among them. The map screen says the places stay
    // on this device, and until 2.7.6 every sync carried them anyway.
    const places = '[{"id":"meeting-1","name":"Treffpunkt"}]';

    test('the places of the map are not handed over', () async {
      SharedPreferences.setMockInitialValues({
        'personalMapPlaces.v1': places,
        'pegelStation': 'DRESDEN',
      });

      expect(await readCarriedSettings(), {'pegelStation': 'DRESDEN'});
      expect(
        (await readCarriedHousehold()).settings,
        isNot(contains('personalMapPlaces.v1')),
      );
    });

    test('nor kept in step with the other devices', () async {
      SharedPreferences.setMockInitialValues({
        'personalMapPlaces.v1': places,
        'pegelStation': 'DRESDEN',
      });

      final synced = await readSyncedSettings();

      expect(synced.keys, ['pegelStation']);
    });

    test('an older device that still sends them is not listened to', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await applyCarriedSettings({'personalMapPlaces.v1': places}), 0);
      expect(
        await applySyncedSettings({
          'personalMapPlaces.v1': (
            value: places,
            at: DateTime.utc(2026, 10, 29),
          ),
        }),
        0,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('personalMapPlaces.v1'), isNull);
    });

    test('this device\'s own backup keeps them', () async {
      SharedPreferences.setMockInitialValues({'personalMapPlaces.v1': places});

      final backup = await readBackupHousehold();
      expect(backup.settings['personalMapPlaces.v1'], places);

      SharedPreferences.setMockInitialValues({});
      expect(await restoreBackupSettings(backup.settings), 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('personalMapPlaces.v1'), places);
    });
  });
  group('the crisis plan stays local on every road', () {
    const plan = '{"communication":{"text":"private-plan-fixture"}}';
    setUp(
      () => SharedPreferences.setMockInitialValues({'preparednessHubV1': plan}),
    );
    test(
      'setup, sync and old comparison baselines cannot transmit it',
      () async {
        expect(
          (await readCarriedHousehold()).settings,
          isNot(contains('preparednessHubV1')),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'carriedSettingStampsV1',
          jsonEncode({
            'preparednessHubV1': {'v': plan, 'at': '2026-01-01T00:00:00Z'},
          }),
        );
        expect(await readSyncedSettings(), isEmpty);
        expect(
          prefs.getString('carriedSettingStampsV1'),
          isNot(contains('private-plan-fixture')),
        );
      },
    );
    test('old senders cannot replace the local plan', () async {
      expect(
        await applyCarriedSettings({'preparednessHubV1': 'foreign-plan'}),
        0,
      );
      expect(
        await applySyncedSettings({
          'preparednessHubV1': (value: 'foreign-plan', at: DateTime.utc(2027)),
        }),
        0,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('preparednessHubV1'), plan);
    });
    test('its own backup still restores the plan', () async {
      final backup = await readBackupHousehold();
      expect(backup.settings['preparednessHubV1'], plan);
      SharedPreferences.setMockInitialValues({});
      expect(await restoreBackupSettings(backup.settings), 1);
      expect(
        (await SharedPreferences.getInstance()).getString('preparednessHubV1'),
        plan,
      );
    });
  });

  test('invalid numeric exchange cannot poison the next backup', () async {
    SharedPreferences.setMockInitialValues({});
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
      91,
      -91,
    ]) {
      expect(await applyCarriedSettings({'daylightLatitude': value}), 0);
    }
    for (final value in [181, -181, double.infinity]) {
      expect(await applyCarriedSettings({'daylightLongitude': value}), 0);
    }
    final incoming = jsonDecode(
      '{"daylightLatitude":1e999,"daylightLongitude":2}',
    ) as Map<String, dynamic>;
    expect(await applyCarriedSettings(incoming), 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daylightLatitude', double.infinity);
    expect(await const DaylightStore().load(), isNull);
    await expectLater(
      const DaylightStore().save(
        const DaylightPlace(latitude: 91, longitude: 2),
      ),
      throwsArgumentError,
    );
    final backup = await readBackupHousehold();
    expect(backup.settings, isNot(contains('daylightLatitude')));
    expect(() => jsonEncode(backup.toJson()), returnsNormally);
    expect(await applyCarriedSettings({'chargeReminderDays': -1}), 0);
    expect(await applyCarriedSettings({'chargeReminderDays': 1.5}), 0);
  });
  test(
    'lead times use the controller type and retain legacy single values',
    () async {
      SharedPreferences.setMockInitialValues({'expiryLeadDays': '90,14,1'});
      final sent = await readCarriedSettings();
      expect(sent['expiryLeadDays'], '90,14,1');
      SharedPreferences.setMockInitialValues({});
      expect(await applyCarriedSettings(sent), 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('expiryLeadDays'), '90,14,1');
      expect(await applyCarriedSettings({'expiryLeadDays': 14}), 1);
      expect(prefs.getString('expiryLeadDays'), '14');
      expect(await applyCarriedSettings({'expiryLeadDays': 0}), 1);
      expect(prefs.getString('expiryLeadDays'), '');
      for (final invalid in [-1, 1.5, 366, double.infinity]) {
        expect(await applyCarriedSettings({'chargeReminderDays': invalid}), 0);
      }
      expect(await applyCarriedSettings({'chargeReminderDays': 365}), 1);
    },
  );

  test('every carried number has a range of its own', () {
    // A new number among the carried settings must say what it may hold
    // instead of borrowing the charge interval's or the longitude's.
    final numbers = {
      for (final entry in carriedSettings.entries)
        if (entry.value.kind == CarriedKind.integer ||
            entry.value.kind == CarriedKind.decimal)
          entry.key,
    };
    expect(numbers, carriedNumberRanges);
    expect(validCarriedSettingValue('daylightLongitude', 120.5), isTrue);
    expect(validCarriedSettingValue('daylightLatitude', 90.5), isFalse);
  });
}

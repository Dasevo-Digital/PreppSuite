import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/private_preferences.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/sharing/application/settings_sync.dart';
import 'package:preppsuite_flutter/features/sharing/application/settings_sync_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryKeys implements LocalDatabaseKeyStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

/// The settings keeping step between two devices, end to end.
void main() {
  final monday = DateTime.utc(2026, 9, 21, 9);
  final tuesday = DateTime.utc(2026, 9, 22, 9);

  Future<SharedPreferences> device(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test(
    'private settings never leave a plaintext synchronization baseline',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final directory = await Directory.systemTemp.createTemp('sync-private-');
      final previous = LocalDatabaseEncryption.instance;
      addTearDown(() async {
        LocalDatabaseEncryption.instance = previous;
        PrivatePreferences.forgetDerivedKey();
        await directory.delete(recursive: true);
      });
      final source = LocalDatabaseEncryption(storage: _MemoryKeys());
      await source.initialize(directory: directory);
      LocalDatabaseEncryption.instance = source;
      PrivatePreferences.forgetDerivedKey();
      final prefs = await device({});
      const sentinel = 'private-contact-fixture';
      await const PrivatePreferences().setString(
        'checkInContacts.v1',
        sentinel,
      );
      final out = await readSyncedSettings(preferences: prefs, now: monday);
      expect(out['checkInContacts.v1']?.value, sentinel);
      expect(
        prefs.getString('carriedSettingStampsV1'),
        isNot(contains(sentinel)),
      );
      expect(
        readEnvelope(prefs.getString('carriedSettingStampsV1')!),
        isNotNull,
      );
      expect(
        (await const SettingsSyncStore().load(
          prefs,
        ))['checkInContacts.v1']?.value,
        sentinel,
      );
      // A baseline left by an older version is sealed without changing its
      // stamps, so upgrading cannot make an old edit look like a new one.
      await prefs.setString(
        'carriedSettingStampsV1',
        jsonEncode(encodeStampedSettings(out)),
      );
      final migrated = await const SettingsSyncStore().load(prefs);
      expect(migrated['checkInContacts.v1']?.at, settingsEpoch);
      expect(
        prefs.getString('carriedSettingStampsV1'),
        isNot(contains(sentinel)),
      );
    },
    skip: !LocalDatabaseEncryption.cipherAvailable,
  );

  group('what goes out', () {
    test('an untouched device starts everything at the floor', () async {
      // Two devices upgrading a minute apart must not let the later one
      // decide it is right about everything.
      final prefs = await device({'pegelStation': 'DRESDEN'});

      final out = await readSyncedSettings(preferences: prefs, now: monday);

      expect(out['pegelStation']!.at, settingsEpoch);
    });

    test('and the next change carries the moment it went out', () async {
      final prefs = await device({'pegelStation': 'DRESDEN'});
      await readSyncedSettings(preferences: prefs, now: monday);

      await prefs.setString('pegelStation', 'MAGDEBURG');
      final out = await readSyncedSettings(preferences: prefs, now: tuesday);

      expect(out['pegelStation']!.value, 'MAGDEBURG');
      expect(out['pegelStation']!.at, tuesday);
    });

    test('only what the household shares, not how this device looks', () {
      // Syncing the theme would mean the desktop going dark because
      // somebody turned the telephone dark on the train.
      expect(carriedSettings['themeModeOverride']!.when, CarriedWhen.setupOnly);
      expect(carriedSettings['localeOverride']!.when, CarriedWhen.setupOnly);
      expect(
        carriedSettings['notificationsEnabled']!.when,
        CarriedWhen.setupOnly,
      );
      expect(carriedSettings['pegelStation']!.when, CarriedWhen.always);
      expect(carriedSettings['energyDraws']!.when, CarriedWhen.always);
    });

    test('a setup-only setting is not in what goes out', () async {
      final prefs = await device({
        'pegelStation': 'DRESDEN',
        'themeModeOverride': 'dark',
      });

      final out = await readSyncedSettings(preferences: prefs, now: monday);

      expect(out.keys, contains('pegelStation'));
      expect(out.keys, isNot(contains('themeModeOverride')));
    });
  });

  group('what comes in', () {
    test('a newer change from the other device lands', () async {
      final prefs = await device({'pegelStation': 'DRESDEN'});
      await readSyncedSettings(preferences: prefs, now: monday);

      final applied = await applySyncedSettings(
        {'pegelStation': (value: 'MAGDEBURG', at: tuesday)},
        preferences: prefs,
      );

      expect(applied, 1);
      expect(prefs.getString('pegelStation'), 'MAGDEBURG');
    });

    test('an older one does not', () async {
      final prefs = await device({'pegelStation': 'DRESDEN'});
      await readSyncedSettings(preferences: prefs, now: tuesday);
      await prefs.setString('pegelStation', 'HAMBURG');
      await readSyncedSettings(preferences: prefs, now: tuesday);

      await applySyncedSettings(
        {'pegelStation': (value: 'MAGDEBURG', at: monday)},
        preferences: prefs,
      );

      expect(prefs.getString('pegelStation'), 'HAMBURG');
    });

    test('the same one twice changes nothing the second time', () async {
      final prefs = await device({'pegelStation': 'DRESDEN'});
      await readSyncedSettings(preferences: prefs, now: monday);
      final incoming = {'pegelStation': (value: 'MAGDEBURG', at: tuesday)};

      expect(
        await applySyncedSettings(incoming, preferences: prefs),
        1,
      );
      expect(
        await applySyncedSettings(incoming, preferences: prefs),
        0,
      );
    });

    test('a setup-only setting offered from outside is refused', () async {
      // Otherwise a household would find its desktop going dark because
      // the telephone did.
      final prefs = await device({'themeModeOverride': 'light'});

      final applied = await applySyncedSettings(
        {'themeModeOverride': (value: 'dark', at: tuesday)},
        preferences: prefs,
      );

      expect(applied, 0);
      expect(prefs.getString('themeModeOverride'), 'light');
    });

    test('and a key this version has never heard of is dropped', () async {
      final prefs = await device({});

      expect(
        await applySyncedSettings(
          {'somethingFromNextYear': (value: 'x', at: tuesday)},
          preferences: prefs,
        ),
        0,
      );
    });
  });

  test('two devices converge, whichever way round they speak', () async {
    // The whole point: a gauge changed on one is read by the other.
    final phone = await device({'pegelStation': 'DRESDEN'});
    final fromPhone = await readSyncedSettings(
      preferences: phone,
      now: monday,
    );

    final desktop = await device({'pegelStation': 'DRESDEN'});
    await readSyncedSettings(preferences: desktop, now: monday);

    // The phone changes it and publishes again.
    await phone.setString('pegelStation', 'MAGDEBURG');
    final afterChange = await readSyncedSettings(
      preferences: phone,
      now: tuesday,
    );
    expect(afterChange['pegelStation']!.at, tuesday);
    expect(fromPhone['pegelStation']!.at, settingsEpoch);

    await applySyncedSettings(afterChange, preferences: desktop);
    expect(desktop.getString('pegelStation'), 'MAGDEBURG');
  });

  group('every road applies them', () {
    /// Where a snapshot is merged in without its settings, and why.
    const excused = {
      // Restoring a backup is a copy of this device from its own past.
      // It has no business telling the other devices who changed the
      // river gauge last.
      'lib/features/settings/application/backup_service.dart',
    };

    test('a road that merges rows also merges settings', () {
      // Four roads carry a household: the folder, the handover in both
      // directions, and the QR chain. Adding a fifth and forgetting the
      // settings would be a household that syncs everything except the
      // one thing this was built for.
      final missing = <String>[];
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final source = file.readAsStringSync();
        if (!source.contains('applyHouseholdSnapshot(')) continue;
        if (source.contains('Future<int> applyHouseholdSnapshot')) continue;
        if (excused.contains(file.path)) continue;
        if (source.contains('applySyncedSettings(')) continue;
        missing.add(file.path);
      }

      expect(
        missing,
        isEmpty,
        reason:
            'These merge a household without its settings. Add '
            'applySyncedSettings, or name the file in `excused` with the '
            'reason it must not.',
      );
    });

    test('and nothing is excused that no longer merges one', () {
      for (final path in excused) {
        expect(File(path).existsSync(), isTrue, reason: path);
        expect(
          File(path).readAsStringSync(),
          contains('applyHouseholdSnapshot('),
          reason: path,
        );
      }
    });
  });
}

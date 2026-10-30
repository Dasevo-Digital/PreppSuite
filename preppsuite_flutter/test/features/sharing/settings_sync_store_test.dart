import 'dart:io';
import 'dart:async';
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

class _PausedSave extends SettingsSyncStore {
  final started = Completer<void>();
  final resume = Completer<void>();
  @override
  Future<void> save(
    Map<String, StampedSetting> settings, [
    SharedPreferences? preferences,
  ]) async {
    if (!started.isCompleted) {
      started.complete();
      await resume.future;
    }
    await super.save(settings, preferences);
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

  group('local edits and deletions survive reception', () {
    test('an unsent edit wins over an older remote change', () async {
      final prefs = await device({
        'watchedAutobahnen': <String>['old'],
      });
      await readSyncedSettings(preferences: prefs, now: monday);
      await prefs.setStringList('watchedAutobahnen', ['new-local']);
      await applySyncedSettings(
        {
          'watchedAutobahnen': (value: <String>['remote'], at: monday),
        },
        preferences: prefs,
        now: tuesday,
      );
      expect(prefs.getStringList('watchedAutobahnen'), ['new-local']);
      expect(
        (await const SettingsSyncStore().load(
          prefs,
        ))['watchedAutobahnen']!.value,
        ['new-local'],
      );
    });
    test('an unrelated remote key cannot roll back a local edit', () async {
      final prefs = await device({
        'watchedAutobahnen': <String>['old'],
      });
      await readSyncedSettings(preferences: prefs, now: monday);
      await prefs.setStringList('watchedAutobahnen', ['new-local']);
      expect(
        await applySyncedSettings(
          {'daylightLatitude': (value: 52.0, at: monday)},
          preferences: prefs,
          now: tuesday,
        ),
        1,
      );
      expect(prefs.getStringList('watchedAutobahnen'), ['new-local']);
      expect(prefs.getDouble('daylightLatitude'), 52);
    });
    test(
      'a published deletion beats an old snapshot and reaches a peer',
      () async {
        final prefs = await device({'pegelStation': 'old'});
        final original = await readSyncedSettings(
          preferences: prefs,
          now: monday,
        );
        await prefs.remove('pegelStation');
        final removed = await readSyncedSettings(
          preferences: prefs,
          now: tuesday,
        );
        expect(removed['pegelStation']!.value, isNull);
        await applySyncedSettings(original, preferences: prefs);
        expect(prefs.containsKey('pegelStation'), isFalse);
        final other = await device({'pegelStation': 'old'});
        await readSyncedSettings(preferences: other, now: monday);
        expect(await applySyncedSettings(removed, preferences: other), 1);
        expect(other.containsKey('pegelStation'), isFalse);
        expect(await applySyncedSettings(removed, preferences: other), 0);
      },
    );
    test(
      'an unsent deletion is stamped before merging an old snapshot',
      () async {
        final prefs = await device({'pegelStation': 'old'});
        final original = await readSyncedSettings(
          preferences: prefs,
          now: monday,
        );
        await prefs.remove('pegelStation');
        await applySyncedSettings(original, preferences: prefs, now: tuesday);
        expect(prefs.containsKey('pegelStation'), isFalse);
      },
    );
    test(
      'publish and receive share an order while persistence is delayed',
      () async {
        final prefs = await device({'pegelStation': 'old'});
        await readSyncedSettings(preferences: prefs, now: monday);
        await prefs.setString('pegelStation', 'new-local');
        final paused = _PausedSave();
        final publishing = readSyncedSettings(
          preferences: prefs,
          store: paused,
          now: tuesday,
        );
        await paused.started.future;
        var received = false;
        final receiving = applySyncedSettings(
          {'pegelStation': (value: 'remote-old', at: monday)},
          preferences: prefs,
          now: tuesday,
        ).then((_) => received = true);
        await Future<void>.delayed(Duration.zero);
        expect(received, isFalse);
        paused.resume.complete();
        await publishing;
        await receiving;
        expect(prefs.getString('pegelStation'), 'new-local');
      },
    );
    test(
      'a private compare-and-set preserves an edit during sealing',
      () async {
        final prefs = await device({'checkInContacts.v1': 'old'});
        final applying = const PrivatePreferences().compareAndSetString(
          'checkInContacts.v1',
          expectedStored: 'old',
          value: 'remote',
          preferences: prefs,
        );
        await prefs.setString('checkInContacts.v1', 'new-local');
        expect(await applying, isFalse);
        expect(prefs.getString('checkInContacts.v1'), 'new-local');
      },
    );
    test(
      'invalid remote values do not poison the comparison baseline',
      () async {
        final prefs = await device({'daylightLatitude': 52.0});
        await readSyncedSettings(preferences: prefs, now: monday);
        expect(
          await applySyncedSettings({
            'daylightLatitude': (value: double.infinity, at: tuesday),
          }, preferences: prefs),
          0,
        );
        expect(prefs.getDouble('daylightLatitude'), 52);
        expect(
          (await const SettingsSyncStore().load(
            prefs,
          ))['daylightLatitude']!.value,
          52,
        );
      },
    );
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

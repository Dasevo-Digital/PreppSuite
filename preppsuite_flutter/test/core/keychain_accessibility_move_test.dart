import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/keychain_accessibility_move.dart';
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/secure_storage.dart';

/// The iOS keychain entries move to "after first unlock" (#388).
///
/// The background warning poll mostly runs on a locked phone. With the
/// entries readable only while it is unlocked, it never got the database
/// key and never warned anybody. The move rewrites every entry, the key
/// among them, so it is tested here against a stop before every single
/// step, and against a second stop while the next start finishes it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late _Keychain keychain;

  // As 3.0.3 left them on an iPhone: the plugin's default accessibility.
  const before = {
    'preppsuite.localDatabaseEncryption.mode.v1': 'encrypted',
    'preppsuite.localDatabaseEncryption.key.v1':
        'q83vEjRWeJCrze8SNFZ4kKvN7xI0VniQq83vEjRWeJA=',
    'appLock.check.v1': 'c2VhbGVkIGNoZWNr',
  };

  setUp(() {
    keychain = _Keychain();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, keychain.handle);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void seed(Map<String, String> entries) {
    for (final MapEntry(:key, :value) in entries.entries) {
      keychain.entries[key] = (value: value, level: 'unlocked');
    }
  }

  void expectMoved(Map<String, String> entries) {
    expect(
      {
        for (final MapEntry(:key, :value) in keychain.entries.entries)
          if (key != keychainMoveDoneKey) key: value,
      },
      {
        for (final MapEntry(:key, :value) in entries.entries)
          key: (value: value, level: 'first_unlock'),
      },
    );
    expect(keychain.entries[keychainMoveDoneKey]?.level, 'first_unlock');
  }

  test('a locked phone gets the database key once the entries moved', () async {
    seed(before);
    keychain.locked = true;
    const store = SecureLocalDatabaseKeyStorage();
    expect(
      await store.read('preppsuite.localDatabaseEncryption.key.v1'),
      isNull,
      reason: 'before the move the key is only there while unlocked',
    );

    keychain.locked = false;
    expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.moved);
    expectMoved(before);

    keychain.locked = true;
    for (final MapEntry(:key, :value) in before.entries) {
      expect(await store.read(key), value);
    }
  });

  test('what the app writes on iOS stays readable on a locked phone', () async {
    await appSecureStorage.write(key: 'appLock.salt.v1', value: 'salt');
    expect(keychain.entries['appLock.salt.v1']?.level, 'first_unlock');

    keychain.locked = true;
    expect(await appSecureStorage.read(key: 'appLock.salt.v1'), 'salt');
  });

  test('an entry not yet moved still reads, while unlocked', () async {
    seed(before);
    for (final MapEntry(:key, :value) in before.entries) {
      expect(await appSecureStorage.read(key: key), value);
    }
  });

  test('macOS keeps the plugin default and has nothing to move', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.notNeeded);
    expect(keychain.calls, 0);

    await appSecureStorage.write(key: 'appLock.salt.v1', value: 'salt');
    expect(keychain.entries['appLock.salt.v1']?.level, 'unlocked');
    expect(keychain.options.last['usesDataProtectionKeychain'], 'true');
  });

  test('the move runs once', () async {
    seed(before);
    expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.moved);
    final calls = keychain.calls;

    expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.alreadyDone);
    expect(keychain.calls, calls + 1);
    expectMoved(before);
  });

  test('a locked phone leaves everything as it was', () async {
    seed(before);
    keychain.locked = true;
    expect(
      await moveKeychainToFirstUnlock(),
      KeychainMoveOutcome.deviceLocked,
    );
    expect(keychain.entries, {
      for (final MapEntry(:key, :value) in before.entries)
        key: (value: value, level: 'unlocked'),
    });
  });

  test('stopped before any step, and again while the next start goes on, '
      'nothing is lost and a later start finishes', () async {
    Future<void> expectReadable(String when) async {
      for (final MapEntry(:key, :value) in before.entries) {
        expect(
          await appSecureStorage.read(key: key),
          value,
          reason: '$key, $when',
        );
      }
    }

    seed(before);
    expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.moved);
    final steps = keychain.calls;
    expect(steps, greaterThan(before.length * 6));

    for (var first = 0; first < steps; first++) {
      for (var second = 0; second <= steps; second++) {
        keychain = _Keychain();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, keychain.handle);
        seed(before);

        keychain.stopBefore(first);
        expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.failed);
        keychain.restart();
        await expectReadable('stopped before step $first');

        keychain.stopBefore(second);
        final next = await moveKeychainToFirstUnlock();
        keychain.restart();
        await expectReadable('then before step $second');

        if (next != KeychainMoveOutcome.moved) {
          expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.moved);
        }
        expectMoved(before);
        await expectReadable('at the end');
      }
    }
  });

  test('a copy that does not read back leaves the entry untouched', () async {
    seed(before);
    keychain.misreads.add('${keychainMoveCopyPrefix}appLock.check.v1');

    expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.failed);
    expect(keychain.entries['appLock.check.v1'], (
      value: 'c2VhbGVkIGNoZWNr',
      level: 'unlocked',
    ));
    expect(
      keychain.entries.keys.where((k) => k.startsWith(keychainMoveCopyPrefix)),
      isEmpty,
    );

    keychain.misreads.clear();
    expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.moved);
    expectMoved(before);
  });

  test(
    'an entry that does not read back stays readable from its copy',
    () async {
      seed(before);
      const key = 'preppsuite.localDatabaseEncryption.key.v1';
      keychain.misreads.add(key);

      expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.failed);
      expect(keychain.entries[key], isNull);
      keychain.misreads.clear();
      expect(await appSecureStorage.read(key: key), before[key]);

      expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.moved);
      expectMoved(before);
    },
  );

  test('an entry the app wrote over its copy is the one kept', () async {
    keychain.entries['appLock.check.v1'] = (
      value: 'new check',
      level: 'first_unlock',
    );
    keychain.entries['${keychainMoveCopyPrefix}appLock.check.v1'] = (
      value: 'old check',
      level: 'first_unlock',
    );

    expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.moved);
    expectMoved({'appLock.check.v1': 'new check'});
  });

  test('a deleted entry does not come back from a copy', () async {
    const key = 'appLock.enabled.v1';
    keychain.entries['$keychainMoveCopyPrefix$key'] = (
      value: 'true',
      level: 'first_unlock',
    );
    expect(await appSecureStorage.read(key: key), 'true');

    await appSecureStorage.delete(key: key);
    expect(await appSecureStorage.read(key: key), isNull);
    expect(await moveKeychainToFirstUnlock(), KeychainMoveOutcome.moved);
    expectMoved({});
  });

  test('the plugin is the one the move was written against', () {
    // flutter_secure_storage_darwin 0.4 looks for an entry under every
    // accessibility when the one asked for finds nothing, and writes by
    // removing and adding. Both break what the move relies on: that a
    // lookup with the old accessibility finds only entries not yet moved.
    // Check the move against the new plugin before letting it in.
    final lock = File('../pubspec.lock').readAsStringSync();
    final version = RegExp(
      r'\n  flutter_secure_storage_darwin:\n(?:    [^\n]*\n|      [^\n]*\n)*?'
      r'    version: "([^"]+)"',
    ).firstMatch(lock)!.group(1)!;
    expect(version, startsWith('0.3.'));
  });
}

typedef _Entry = ({String value, String level});

/// The keychain as flutter_secure_storage_darwin 0.3.2 handles it.
///
/// What matters, from `FlutterSecureStorage.swift`:
/// - The accessibility, when the options name one, is part of every query,
///   and the keychain treats it as a filter. Without one, any matches.
/// - A write first asks whether the key exists, with that filter, and
///   updates the value only, keeping the accessibility. Otherwise it adds,
///   and the keychain refuses a second entry for an account it has, as
///   accounts are told apart without the accessibility: -25299.
/// - A delete ignores the accessibility.
/// - On a locked phone an entry readable only while unlocked answers
///   -25308 to everything.
class _Keychain {
  final entries = <String, _Entry>{};
  final options = <Map<String, String>>[];

  /// Keys whose value reads back wrong.
  final misreads = <String>{};

  bool locked = false;
  int calls = 0;
  int? _stopAt;
  bool _stopped = false;

  /// The app ends before call [step] of the next run gets through.
  void stopBefore(int step) {
    calls = 0;
    _stopAt = step;
  }

  void restart() {
    _stopAt = null;
    _stopped = false;
  }

  Future<Object?> handle(MethodCall call) async {
    if (_stopped || calls == _stopAt) {
      _stopped = true;
      throw PlatformException(code: 'stopped');
    }
    calls++;
    if (call.method == 'isProtectedDataAvailable') return !locked;

    final arguments = (call.arguments as Map).cast<String, Object?>();
    final options = (arguments['options'] as Map).cast<String, String>();
    this.options.add(options);
    expect(options['synchronizable'], 'false');
    expect(options['accountName'], 'flutter_secure_storage_service');
    final level = options['accessibility'];
    final key = arguments['key'] as String?;
    final entry = key == null ? null : entries[key];
    final matches = entry != null && (level == null || entry.level == level);

    void unlockedOnly(_Entry? entry) {
      if (locked && entry?.level == 'unlocked') {
        throw PlatformException(code: 'security', details: -25308);
      }
    }

    switch (call.method) {
      case 'read':
        if (!matches) return null;
        unlockedOnly(entry);
        return misreads.contains(key) ? '${entry.value}?' : entry.value;
      case 'containsKey':
        return matches;
      case 'write':
        unlockedOnly(entry);
        final value = arguments['value'] as String;
        if (matches) {
          entries[key!] = (value: value, level: entry.level);
        } else if (entry != null) {
          throw PlatformException(code: 'security', details: -25299);
        } else {
          final newLevel = level ?? 'unlocked';
          if (locked && newLevel == 'unlocked') {
            throw PlatformException(code: 'security', details: -25308);
          }
          entries[key!] = (value: value, level: newLevel);
        }
        return null;
      case 'delete':
        unlockedOnly(entry);
        entries.remove(key);
        return null;
      case 'readAll':
        final found = {
          for (final MapEntry(:key, :value) in entries.entries)
            if (level == null || value.level == level) key: value,
        };
        found.values.forEach(unlockedOnly);
        return {
          for (final MapEntry(:key, :value) in found.entries) key: value.value,
        };
    }
    throw MissingPluginException(call.method);
  }
}

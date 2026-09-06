import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_encryption.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_key_store.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'in_memory_sync_folder.dart';

/// Switching a folder over, and getting a second device into it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySyncFolder folder;
  late FolderEncryption encryption;

  // Long enough to be accepted; the real work factors make each of these
  // calls cost about a second, so the suite stays deliberately small.
  const passphrase = 'einhaushaltmitvorrat';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    folder = InMemorySyncFolder()
      ..householdFile = HouseholdFile(
        householdId: 'h1',
        name: 'Zuhause',
        countryCode: 'DE',
        createdAt: DateTime.utc(2026, 1, 1),
      ).encode();
    encryption = FolderEncryption(folder: folder);
  });

  test('a plain folder stays at version 1', () {
    // The asymmetry that keeps a household working while one member
    // updates: an older app must not be locked out of a folder that has
    // nothing new in it.
    expect(folder.householdFile, contains('"version": 1'));
  });

  test('turning it on marks the folder and keeps a key here', () async {
    final error = await encryption.enable(
      householdId: 'h1',
      passphrase: passphrase,
    );

    expect(error, isNull);
    expect(await encryption.isEncrypted(), isTrue);
    // Version 2 now, so an app that predates encryption refuses the
    // folder loudly instead of silently skipping every file in it.
    expect(folder.householdFile, contains('"version": 2'));
    expect(await const FolderKeyStore().read('h1'), isNotNull);
  });

  test('the passphrase itself never reaches the folder', () async {
    await encryption.enable(householdId: 'h1', passphrase: passphrase);

    expect(folder.householdFile!.contains(passphrase), isFalse);
  });

  test('a short passphrase is refused and changes nothing', () async {
    final error = await encryption.enable(
      householdId: 'h1',
      passphrase: 'kurz',
    );

    expect(error, FolderEncryptionError.tooShort);
    expect(await encryption.isEncrypted(), isFalse);
    expect(await const FolderKeyStore().read('h1'), isNull);
  });

  test('turning it on twice is refused', () async {
    // It would strand every device holding the current key, and there is
    // no way to tell them apart from a device that never had one.
    await encryption.enable(householdId: 'h1', passphrase: passphrase);

    expect(
      await encryption.enable(householdId: 'h1', passphrase: passphrase),
      FolderEncryptionError.alreadyEncrypted,
    );
  });

  test('an empty folder cannot be switched over', () async {
    folder.householdFile = null;

    expect(
      await encryption.enable(householdId: 'h1', passphrase: passphrase),
      FolderEncryptionError.noFolder,
    );
  });

  group('a second device', () {
    setUp(() async {
      await encryption.enable(householdId: 'h1', passphrase: passphrase);
      // A device that has the folder but not the key yet.
      SharedPreferences.setMockInitialValues({});
    });

    test('gets in with the right passphrase', () async {
      final error = await encryption.unlock(
        householdId: 'h1',
        passphrase: passphrase,
      );

      expect(error, isNull);
      expect(await const FolderKeyStore().read('h1'), isNotNull);
    });

    test('derives the same key the first device has', () async {
      // The whole premise of one shared passphrase: two devices must
      // arrive at identical bytes from the same words and the folder's
      // own salt, or neither can read the other's file.
      await encryption.unlock(householdId: 'h1', passphrase: passphrase);
      final second = await const FolderKeyStore().read('h1');

      final stored = HouseholdFile.decode(folder.householdFile!)!;
      final derived = await deriveFolderKey(passphrase, stored.vault!);

      expect(second!.bytes, derived.bytes);
    });

    test('is turned away by the wrong passphrase and keeps no key', () async {
      final error = await encryption.unlock(
        householdId: 'h1',
        passphrase: 'ganzetwasanderes',
      );

      expect(error, FolderEncryptionError.wrongPassphrase);
      expect(await const FolderKeyStore().read('h1'), isNull);
    });
  });
}

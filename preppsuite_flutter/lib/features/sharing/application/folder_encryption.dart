/// Turning encryption on for a shared folder, and unlocking one.
///
/// Both are rare, deliberate acts with consequences that cannot be taken
/// back, so neither happens as a side effect of a sync. See
/// `folder_crypto.dart` for what is actually protected and from whom.
library;

import 'folder_crypto.dart';
import 'folder_key_store.dart';
import 'household_file.dart';
import 'sync_folder.dart';

/// The shortest passphrase this app will accept.
///
/// Twelve, because the file it guards is one an attacker can copy and
/// grind against offline for as long as they like. Argon2id at 64 MB
/// makes that expensive per guess; a short passphrase makes the number of
/// guesses small enough that it does not matter.
const minimumPassphraseLength = 12;

enum FolderEncryptionError {
  /// No `household.json`, so there is no folder to speak of yet.
  noFolder,

  /// The passphrase does not open this folder.
  wrongPassphrase,

  /// Shorter than [minimumPassphraseLength].
  tooShort,

  /// The folder is already encrypted; turning it on again would strand
  /// every device that holds the current key.
  alreadyEncrypted,

  /// Reading or writing the folder failed.
  failed,
}

class FolderEncryption {
  const FolderEncryption({
    required SyncFolder folder,
    FolderKeyStore keyStore = const FolderKeyStore(),
  }) : _folder = folder,
       _keyStore = keyStore;

  final SyncFolder _folder;
  final FolderKeyStore _keyStore;

  /// Switches the folder over and remembers the key on this device.
  ///
  /// The order matters. The key is stored before `household.json` is
  /// written, so a crash in between leaves a device that can still open
  /// what it wrote — the other way round would produce a folder marked
  /// encrypted that nobody holds a key for.
  Future<FolderEncryptionError?> enable({
    required String householdId,
    required String passphrase,
  }) async {
    if (passphrase.length < minimumPassphraseLength) {
      return FolderEncryptionError.tooShort;
    }

    try {
      final raw = await _folder.readHouseholdFile();
      if (raw == null) return FolderEncryptionError.noFolder;

      final stored = HouseholdFile.decode(raw);
      if (stored == null || stored.householdId != householdId) {
        return FolderEncryptionError.failed;
      }
      if (await _keyStore.requiresEncryption(householdId) &&
          !stored.isEncrypted) {
        return FolderEncryptionError.failed;
      }
      if (stored.isEncrypted) return FolderEncryptionError.alreadyEncrypted;

      final parameters = VaultParameters(salt: newSalt());
      final key = await deriveFolderKey(passphrase, parameters);

      await _keyStore.write(householdId, key);
      await _folder.writeHouseholdFile(
        HouseholdFile(
          householdId: stored.householdId,
          name: stored.name,
          countryCode: stored.countryCode,
          createdAt: stored.createdAt,
          vault: parameters,
          check: await buildCheckValue(key),
        ).encode(),
      );
      return null;
    } on Object {
      return FolderEncryptionError.failed;
    }
  }

  /// Checks a passphrase against the folder and, if it opens it, keeps the
  /// derived key on this device.
  ///
  /// Checked against the folder's own token rather than against a device
  /// file, so "wrong passphrase" is never reported for a download that
  /// merely arrived half-written.
  Future<FolderEncryptionError?> unlock({
    required String householdId,
    required String passphrase,
  }) async {
    try {
      final raw = await _folder.readHouseholdFile();
      if (raw == null) return FolderEncryptionError.noFolder;

      final stored = HouseholdFile.decode(raw);
      if (stored == null ||
          stored.householdId != householdId ||
          !stored.isEncrypted) {
        return FolderEncryptionError.failed;
      }

      final key = await deriveFolderKey(passphrase, stored.vault!);
      if (!await checkFolderKey(key, stored.check!)) {
        return FolderEncryptionError.wrongPassphrase;
      }

      await _keyStore.write(householdId, key);
      return null;
    } on Object {
      return FolderEncryptionError.failed;
    }
  }

  /// Whether the folder is encrypted, or null if it cannot be read.
  Future<bool?> isEncrypted() async {
    try {
      final raw = await _folder.readHouseholdFile();
      if (raw == null) return null;
      return HouseholdFile.decode(raw)?.isEncrypted;
    } on Object {
      return null;
    }
  }
}

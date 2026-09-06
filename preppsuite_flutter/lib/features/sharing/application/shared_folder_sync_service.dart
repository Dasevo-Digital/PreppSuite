import '../../../local_db/database.dart';
import 'device_snapshot.dart';
import 'folder_crypto.dart';
import 'household_file.dart';
import 'sync_folder.dart';

/// Why a sync could not be completed. Null means it was.
enum SharedFolderSyncError {
  /// The folder is gone, or the app may no longer write to it — an
  /// external drive that was unplugged, or an Android path the picker
  /// handed over without the permission to use it.
  unwritable,

  /// The folder now names a different household than the one this device
  /// belongs to — someone replaced `household.json`, or restored the
  /// folder from another household's backup. Nothing is merged: the two
  /// sets of rows are unrelated and mixing them cannot be undone.
  differentHousehold,

  /// A newer version of PreppSuite owns this folder. Writing an older
  /// shape over it could drop fields this app does not know about, so it
  /// does nothing at all.
  unsupportedVersion,

  /// The folder is encrypted and this device holds no key for it, or one
  /// that no longer opens it. Nothing is read and nothing is written:
  /// publishing a plaintext file into an encrypted folder would undo the
  /// encryption for every row this device owns.
  locked,

  /// The folder could be reached but something failed while reading or
  /// writing. Worth retrying; the next run does.
  failed,
}

class SharedFolderSyncResult {
  const SharedFolderSyncResult({
    this.received = 0,
    this.devicesSeen = 0,
    this.published = false,
    this.error,
  });

  /// Rows that were actually applied — newer than what was stored here.
  final int received;

  /// How many devices have a snapshot in the folder, this one included.
  final int devicesSeen;

  /// Whether this device wrote its own snapshot during this run.
  final bool published;

  final SharedFolderSyncError? error;

  bool get succeeded => error == null;
}

/// Merges a household's data through a folder that several devices can
/// see.
///
/// The whole protocol is: read every other device's snapshot, keep the
/// newer of each row, then write our own. There is no locking, no
/// handshake and no ordering requirement — two devices syncing at the same
/// instant write different files, and whichever reads last simply sees
/// more. That is deliberate. Anything cleverer would need the devices to
/// be online at the same time, which is the one thing a folder cannot
/// promise.
///
/// Free of Riverpod and of `dart:io` so the merge can be tested against an
/// in-memory folder.
class SharedFolderSyncService {
  SharedFolderSyncService({
    required AppDatabase database,
    required SyncFolder folder,
    required this.deviceId,
    required this.identity,
    this.key,
    this.republish = false,
  }) : _db = database,
       _folder = folder;

  final AppDatabase _db;
  final SyncFolder _folder;

  /// This device's file name in the folder — the one file it writes.
  final String deviceId;

  /// Who this device thinks the folder belongs to. Checked against what
  /// is actually there on every run, and written back if it has gone
  /// missing.
  final HouseholdFile identity;

  /// The folder's key, if this device has unlocked it.
  ///
  /// Null for a plain folder, and null for an encrypted one this device
  /// has not been given the passphrase for — the second case is the
  /// [SharedFolderSyncError.locked] one.
  final FolderKey? key;

  /// Writes this device's file even when nothing changed.
  ///
  /// For the run straight after encryption is switched on: this device's
  /// existing file is still in the clear, and nothing about the rows in it
  /// is dirty, so the ordinary rule would leave the plaintext lying there
  /// beside the sealed ones.
  final bool republish;

  String get householdId => identity.householdId;

  /// What the folder itself says, which outranks [identity].
  ///
  /// A second device can turn encryption on while this one is running;
  /// the file in the folder is the truth about that, not the copy this
  /// device started with.
  HouseholdFile? _folderIdentity;

  /// Named so the "last synced" line in settings has something to read.
  static const syncStateEntity = 'sharedFolder';

  Future<SharedFolderSyncResult> sync() async {
    try {
      if (!await _folder.isWritable()) {
        return const SharedFolderSyncResult(
          error: SharedFolderSyncError.unwritable,
        );
      }

      final identityError = await _checkIdentity();
      if (identityError != null) {
        return SharedFolderSyncResult(error: identityError);
      }

      final deviceIds = await _folder.listDeviceIds();
      var received = 0;
      var foreignFiles = 0;
      var skippedFiles = 0;

      for (final id in deviceIds) {
        // Our own file can only contain what we already have.
        if (id == deviceId) continue;

        foreignFiles++;

        final raw = await _folder.readDeviceFile(id);
        final opened = raw == null ? null : await _open(raw);
        final snapshot = opened == null ? null : DeviceSnapshot.decode(opened);
        if (snapshot == null) {
          // Damaged, half-downloaded, written by a newer version, or
          // sealed under a key this device does not hold. All of them
          // mean the same thing here: leave it alone and try again.
          skippedFiles++;
          continue;
        }
        if (snapshot.householdId != householdId) continue;

        received += await _apply(snapshot);
      }

      final published = await _publishIfNeeded(
        learnedSomething: received > 0,
        ourFileExists: deviceIds.contains(deviceId),
      );

      await _db.setLastPulledAt(syncStateEntity, DateTime.now().toUtc());

      return SharedFolderSyncResult(
        received: received,
        devicesSeen: {...deviceIds, if (published) deviceId}.length,
        published: published,
        // Only when *every* other device's file was unreadable. One
        // skipped file among several is a download in progress; all of
        // them is a folder this version cannot read.
        error: foreignFiles > 0 && skippedFiles == foreignFiles
            ? SharedFolderSyncError.unsupportedVersion
            : null,
      );
    } catch (_) {
      // A folder mid-download, a file the sync engine is holding open, a
      // disk that filled up. None of it is worth losing the app over: the
      // local database is untouched and the next run tries again.
      return const SharedFolderSyncResult(
        error: SharedFolderSyncError.failed,
      );
    }
  }

  /// Confirms the folder still belongs to this household, restoring the
  /// identity file if it has been lost.
  ///
  /// Restoring matters more than it looks: without `household.json` the
  /// next device to pick this folder would treat it as empty and start a
  /// second household in it, and the two would sit side by side forever
  /// without ever merging.
  Future<SharedFolderSyncError?> _checkIdentity() async {
    final raw = await _folder.readHouseholdFile();
    if (raw == null) {
      await _folder.writeHouseholdFile(identity.encode());
      return null;
    }

    final stored = HouseholdFile.decode(raw);
    if (stored == null) return SharedFolderSyncError.unsupportedVersion;
    if (stored.householdId != householdId) {
      return SharedFolderSyncError.differentHousehold;
    }

    _folderIdentity = stored;
    if (stored.isEncrypted && key == null) {
      return SharedFolderSyncError.locked;
    }
    return null;
  }

  /// Whether this run has to seal what it writes.
  bool get _sealing => (_folderIdentity ?? identity).isEncrypted;

  /// Opens a file from the folder, whichever shape it is in.
  ///
  /// Both shapes are accepted on purpose: while a household is switching
  /// over, the device that turned encryption on has a sealed file in
  /// there and the others still have plain ones. Refusing the plain ones
  /// would drop those households' rows until every device had caught up.
  Future<String?> _open(String raw) async {
    if (!looksEncrypted(raw)) return raw;
    final folderKey = key;
    if (folderKey == null) return null;
    return decryptFromFolder(raw, folderKey);
  }

  Future<int> _apply(DeviceSnapshot snapshot) {
    return _db.mergeIncomingRows(
      inventory: [
        for (final json in snapshot.inventoryItems)
          ?_incoming(json, decodeInventoryItem(json)),
      ],
      templates: [
        for (final json in snapshot.checklistTemplates)
          ?_incoming(json, decodeChecklistTemplate(json)),
      ],
      items: [
        for (final json in snapshot.checklistItems)
          ?_incoming(json, decodeChecklistItem(json)),
      ],
      budget: [
        for (final json in snapshot.budgetEntries)
          ?_incoming(json, decodeBudgetEntry(json)),
      ],
    );
  }

  /// Lifts the two fields the merge compares out of the raw JSON, so the
  /// comparison never has to reach into a companion's `Value`s.
  IncomingRow<C>? _incoming<C>(Map<String, Object?> json, C? companion) {
    if (companion == null) return null;
    final clientId = json['clientId'];
    final updatedAt = asUtcDate(json['updatedAt']);
    if (clientId is! String || updatedAt == null) return null;
    return (clientId: clientId, updatedAt: updatedAt, companion: companion);
  }

  /// Writes this device's snapshot, unless there is demonstrably nothing
  /// to say.
  ///
  /// Rewriting an identical file would be harmless locally but not
  /// remotely: every write wakes the sync engine, which uploads the file
  /// and wakes every other device. Staying quiet when nothing changed is
  /// what keeps a household of four from generating constant traffic.
  ///
  /// Republishing rows we only just learned about is on purpose. It means
  /// every device carries the whole household, so losing one device — or
  /// simply never turning it on again — costs nothing.
  Future<bool> _publishIfNeeded({
    required bool learnedSomething,
    required bool ourFileExists,
  }) async {
    if (!republish &&
        !learnedSomething &&
        ourFileExists &&
        !await _hasUnpublishedRows()) {
      return false;
    }

    // Taken before the rows are read, so an edit made while the file is
    // being written stays dirty and goes out on the next run instead of
    // being marked published without ever having been in a snapshot.
    final readAt = DateTime.now().toUtc();

    final snapshot = DeviceSnapshot(
      deviceId: deviceId,
      householdId: householdId,
      writtenAt: readAt,
      inventoryItems: [
        for (final row in await _db.inventoryItemsForSync(householdId))
          encodeInventoryItem(row),
      ],
      checklistTemplates: [
        for (final row in await _db.checklistTemplatesForSync(householdId))
          encodeChecklistTemplate(row),
      ],
      checklistItems: [
        for (final row in await _db.checklistItemsForSync(householdId))
          encodeChecklistItem(row),
      ],
      budgetEntries: [
        for (final row in await _db.budgetEntriesForSync(householdId))
          encodeBudgetEntry(row),
      ],
    );

    final folderKey = key;
    // Belt and braces against publishing in the clear: the run is already
    // stopped with `locked` when the folder is sealed and no key is held,
    // and this refuses to write rather than fall back if that ever fails.
    if (_sealing && folderKey == null) return false;
    await _folder.writeDeviceFile(
      deviceId,
      _sealing
          ? await encryptForFolder(snapshot.encode(), folderKey!)
          : snapshot.encode(),
    );
    await _db.markHouseholdPublished(householdId, readAt);
    return true;
  }

  Future<bool> _hasUnpublishedRows() async {
    return (await _db.dirtyInventoryItems(householdId)).isNotEmpty ||
        (await _db.dirtyChecklistTemplates(householdId)).isNotEmpty ||
        (await _db.dirtyChecklistItems(householdId)).isNotEmpty ||
        (await _db.dirtyBudgetEntries(householdId)).isNotEmpty;
  }
}

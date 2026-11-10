import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cryptography/cryptography.dart' show Sha256;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../local_db/database.dart';
import 'device_snapshot.dart';
import 'snapshot_exchange.dart';
import 'settings_sync.dart';
import 'settings_sync_store.dart';
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

  /// Previously encrypted metadata is missing or has been downgraded.
  encryptionChanged,

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
    required this._folder,
    required this.deviceId,
    required this.identity,
    this.key,
    this.republish = false,
    this.requireEncryption = false,
    this.onEncryptedFolder,
  }) : _db = database;

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
  final bool requireEncryption;
  final Future<void> Function()? onEncryptedFolder;

  bool get _mustRemainEncrypted =>
      requireEncryption ||
      key != null ||
      identity.isEncrypted ||
      (_folderIdentity?.isEncrypted ?? false);

  String get householdId => identity.householdId;

  /// What the folder itself says, which outranks [identity].
  ///
  /// A second device can turn encryption on while this one is running;
  /// the file in the folder is the truth about that, not the copy this
  /// device started with.
  HouseholdFile? _folderIdentity;

  /// Named so the "last synced" line in settings has something to read.
  static const syncStateEntity = 'sharedFolder';

  /// Each other device's file as it was when its rows last went in here,
  /// beside how many rows the household had then -- per database, so a
  /// database opened afresh reads everything again.
  ///
  /// The folder is read every two minutes, and every file in it used to
  /// be decrypted, decoded and merged row by row each time, unchanged or
  /// not: in pure Dart and on the interface's isolate, some 80 ms a
  /// megabyte for the decryption alone (#254). A file exactly as it was,
  /// into a household that has lost no rows since, has nothing new to
  /// give. Kept in memory only, so every start of the app reads it all
  /// once.
  static final _applied =
      Expando<Map<String, ({int length, int hash, int rows})>>();

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

      // Our own file can only contain what we already have, once this
      // database has written it. Until then it may be all that is left: a
      // key lost and "start over", the folder as the household's only copy.
      // The id survives that, and the file used to be skipped here and
      // replaced at the end of the run by an empty one (#311).
      final ownFileKnown = await _db.lastPulledAt(_publishedEntity) != null;
      var ownFileUnread = false;

      for (final id in deviceIds) {
        final own = id == deviceId;
        if (own && ownFileKnown) continue;

        final raw = await _folder.readDeviceFile(id);
        // A plain file in a sealed folder is never read. Anybody who can
        // write to the folder — the cloud provider, a Syncthing peer —
        // could otherwise put rows and tombstones into every device
        // without knowing the passphrase, and this device would publish
        // them onwards under the seal. A device not switched over yet
        // loses nothing by it: its rows wait in its own database, and
        // its first run after unlocking replaces the plain file (see
        // [_publishIfNeeded]). Not counted as skipped, either: a folder
        // whose other devices have not caught up yet is not one this
        // version cannot read.
        if (raw != null && _sealing && !looksEncrypted(raw)) {
          ownFileUnread = ownFileUnread || own;
          continue;
        }

        if (!own) foreignFiles++;

        final applied = _applied[_db] ??= {};
        final memo = '$householdId/$id';
        final before = applied[memo];
        if (raw != null &&
            before != null &&
            before.length == raw.length &&
            before.hash == raw.hashCode &&
            before.rows == await _db.householdRowCount(householdId)) {
          continue;
        }

        final opened = raw == null ? null : await _open(raw);
        final snapshot = opened == null ? null : DeviceSnapshot.decode(opened);
        if (snapshot == null) {
          // Damaged, half-downloaded, written by a newer version, or
          // sealed under a key this device does not hold. All of them
          // mean the same thing here: leave it alone and try again.
          if (own) {
            ownFileUnread = true;
          } else {
            skippedFiles++;
          }
          continue;
        }
        if (snapshot.householdId != householdId) continue;

        received += await _apply(snapshot);
        applied[memo] = (
          length: raw!.length,
          hash: raw.hashCode,
          rows: await _db.householdRowCount(householdId),
        );
      }

      final beforePublishError = await _checkIdentity();
      if (beforePublishError != null) {
        return SharedFolderSyncResult(
          received: received,
          error: beforePublishError,
        );
      }
      final ourFile = deviceIds.contains(deviceId)
          ? await _folder.readDeviceFile(deviceId)
          : null;
      // A database with nothing in it has nothing to say, and a file of
      // ours it could not read may be a download still under way. Writing
      // would turn that into an empty file for good; waiting costs nothing,
      // because the first row here lifts this.
      final holdsBack =
          ownFileUnread && await _db.householdRowCount(householdId) == 0;
      final published =
          !holdsBack &&
          await _publishIfNeeded(
            ownFileWasKnown: ownFileKnown,
            learnedSomething: received > 0,
            ourFileExists: ourFile != null,
            ourFileIsPlain:
                _sealing && ourFile != null && !looksEncrypted(ourFile),
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
    } catch (error, stack) {
      // A folder mid-download, a file the sync engine is holding open, a
      // disk that filled up. None of it is worth losing the app over: the
      // local database is untouched and the next run tries again.
      //
      // Logged, though: a programming error lands here too, and from the
      // outside it is indistinguishable from a busy disk.
      developer.log(
        'shared folder sync failed',
        name: 'preppsuite.sharing',
        error: error,
        stackTrace: stack,
      );
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
      if (_mustRemainEncrypted) return SharedFolderSyncError.encryptionChanged;
      await _folder.writeHouseholdFile(identity.encode());
      return null;
    }

    final stored = HouseholdFile.decode(raw);
    if (stored == null) return SharedFolderSyncError.unsupportedVersion;
    if (stored.householdId != householdId) {
      return SharedFolderSyncError.differentHousehold;
    }

    if (!stored.isEncrypted && _mustRemainEncrypted) {
      return SharedFolderSyncError.encryptionChanged;
    }
    _folderIdentity = stored;
    if (stored.isEncrypted) {
      await onEncryptedFolder?.call();
      final folderKey = key;
      if (folderKey == null ||
          !await checkFolderKey(folderKey, stored.check!)) {
        return SharedFolderSyncError.locked;
      }
    }
    return null;
  }

  /// Set once this database has published to the folder as this device.
  String get _publishedEntity => 'sharedFolderVersion2:$householdId:$deviceId';

  /// Whether this run has to seal what it writes.
  bool get _sealing => (_folderIdentity ?? identity).isEncrypted;

  /// Opens a file from the folder.
  ///
  /// A plain file only reaches here in a plain folder; [sync] drops the
  /// plain ones from a sealed folder before they get this far.
  Future<String?> _open(String raw) async {
    if (!looksEncrypted(raw)) return raw;
    final folderKey = key;
    if (folderKey == null) return null;
    return decryptFromFolder(raw, folderKey);
  }

  /// Rows first, settings after. The rows are the payload; a setting
  /// that could not be stored must never cost them.
  Future<int> _apply(DeviceSnapshot snapshot) async {
    final rows = await applyHouseholdSnapshot(_db, snapshot);
    await applySyncedSettings(snapshot.settings);
    return rows;
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
  ///
  /// A plain file of our own in a sealed folder is always replaced. It is
  /// what a device leaves behind from before encryption was switched on,
  /// and since the others no longer read plain files, the rows in it
  /// reach nobody until it is.
  Future<bool> _publishIfNeeded({
    required bool ownFileWasKnown,
    required bool learnedSomething,
    required bool ourFileExists,
    required bool ourFileIsPlain,
  }) async {
    // Re-offer clean rows once after upgrading the conflict rule. The old
    // second-granularity acknowledgement could mark an unpublished edit
    // clean, so dirty alone cannot recover every existing installation.
    final needsRepair = await _db.lastPulledAt(_publishedEntity) == null;

    // The mark was there when this run began, which is why our own file
    // was not read, and it has gone since: the household was deleted under
    // a run already under way (#336). Writing now would put the empty
    // database over what may be the only copy. The next run reads the file
    // first, because the mark is gone.
    if (needsRepair && ownFileWasKnown) return false;

    // The settings, stamped, read before deciding: a station changed here
    // is something to say even when no row moved. Until #253 they were
    // read only once a row had already decided it, and a changed setting
    // on its own reached no other device -- not even on "sync now".
    final settings = await readSyncedSettings();
    final settingsPrint = await _settingsFingerprint(settings);
    final settingsKey =
        'sharedFolderSettingsPublished.v1.$householdId.$deviceId';
    final settingsChanged =
        await _publishedSettings(settingsKey, orElse: settingsPrint) !=
        settingsPrint;

    if (!republish &&
        !ourFileIsPlain &&
        !needsRepair &&
        !learnedSomething &&
        ourFileExists &&
        !settingsChanged &&
        !await _hasUnpublishedRows()) {
      return false;
    }

    // The snapshot stamps itself; that stamp is informational only, since
    // acknowledgement below uses each included row's own version rather
    // than any wall-clock instant.
    final snapshot = await readHouseholdSnapshot(
      _db,
      deviceId: deviceId,
      householdId: householdId,
      // What turns "the settings came over once at setup" into "the
      // settings stay in step": a station changed on the telephone is
      // published on the next round and reaches the desktop on its own.
      settings: settings,
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
    List<PublishedRow> versions(List<Map<String, Object?>> rows) => [
      for (final row in rows)
        (
          clientId: row['clientId'] as String,
          updatedAt: asUtcDate(row['updatedAt'])!,
        ),
    ];
    await _db.markHouseholdPublished(
      householdId,
      inventory: versions(snapshot.inventoryItems),
      templates: versions(snapshot.checklistTemplates),
      items: versions(snapshot.checklistItems),
      budget: versions(snapshot.budgetEntries),
      plans: versions(snapshot.householdPlans),
      members: versions(snapshot.householdMembers),
      owned: versions(snapshot.possessions),
      offers: versions(snapshot.neighbourOffers),
    );
    await _db.setLastPulledAt(_publishedEntity, DateTime.now().toUtc());
    await _rememberPublishedSettings(settingsKey, settingsPrint);
    return true;
  }

  /// A digest of [settings] as they travel, never the values: some of them
  /// are kept encrypted on this device, and this lands in plain
  /// preferences.
  static Future<String> _settingsFingerprint(
    Map<String, StampedSetting> settings,
  ) async {
    final encoded = encodeStampedSettings(settings);
    final canonical = jsonEncode({
      for (final key in encoded.keys.toList()..sort()) key: encoded[key],
    });
    final digest = await Sha256().hash(utf8.encode(canonical));
    return base64Encode(digest.bytes);
  }

  /// What went out last time; null where nothing is known, which reads as
  /// changed. A preferences store that cannot be reached reads as
  /// unchanged instead: the rows decide then, as they always did.
  static Future<String?> _publishedSettings(
    String key, {
    required String orElse,
  }) async {
    try {
      return (await SharedPreferences.getInstance()).getString(key);
    } on Object {
      return orElse;
    }
  }

  static Future<void> _rememberPublishedSettings(
    String key,
    String print,
  ) async {
    try {
      await (await SharedPreferences.getInstance()).setString(key, print);
    } on Object {
      // Published all the same; the next round publishes once more.
    }
  }

  Future<bool> _hasUnpublishedRows() async {
    return (await _db.dirtyInventoryItems(householdId)).isNotEmpty ||
        (await _db.dirtyChecklistTemplates(householdId)).isNotEmpty ||
        (await _db.dirtyChecklistItems(householdId)).isNotEmpty ||
        (await _db.dirtyBudgetEntries(householdId)).isNotEmpty ||
        (await _db.dirtyHouseholdPlans(householdId)).isNotEmpty ||
        (await _db.dirtyHouseholdMembers(householdId)).isNotEmpty ||
        (await _db.dirtyPossessions(householdId)).isNotEmpty ||
        (await _db.dirtyNeighbourOffers(householdId)).isNotEmpty;
  }
}

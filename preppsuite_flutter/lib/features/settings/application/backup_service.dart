import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../maps/application/pmtiles_archive.dart' show ByteRangeSource;

import '../../../local_db/database.dart';
import '../../preparedness/application/preparedness_hub_store.dart';
import '../../sharing/application/device_snapshot.dart';
import '../../sharing/application/folder_crypto.dart';
import '../../sharing/application/carried_settings.dart';
import '../../sharing/application/snapshot_exchange.dart';
import '../../warnings/application/warning_region_store.dart';
import '../../../model/household_profile.dart';
import '../../../model/household_profile_store.dart';
import 'backup_container.dart';
import 'backup_files.dart';

/// An encrypted copy of one household, as a single file.
///
/// Reading and merging go through `snapshot_exchange.dart` like every
/// other road a household travels. This file used to spell both out
/// again, and the cost showed the first time a table was added: a backup
/// that quietly held everything except the newest table would look
/// perfectly fine until somebody restored it.
///
/// The crisis plan is the one part that does not live in the database.
/// It is deliberately kept out of the shared folder — a radio frequency
/// or an evacuation route should not travel to every household device
/// just because the inventory does — but "not synced" must not mean
/// "lost with the phone", so the backup carries it in a section of its
/// own, under the same passphrase.
class BackupService {
  const BackupService(this.database, [this.hub = const PreparednessHubStore()]);

  final AppDatabase database;
  final PreparednessHubStore hub;

  Future<String> exportHousehold(String householdId, String passphrase) async {
    final (key, parameters) = await _newKey(passphrase);
    return jsonEncode(await _envelope(householdId, key, parameters));
  }

  /// Writes a format 3 backup into [out]: the household, and the [files]
  /// beside it (#114).
  ///
  /// [onFile] is told which file is being written, [onBytes] how much of
  /// it went in. Answers the labels of files that could not be opened;
  /// they are listed in the backup and carry no bytes, and a restore says
  /// so instead of failing.
  Future<List<String>> writeBackup({
    required RandomAccessFile out,
    required String householdId,
    required String passphrase,
    required List<BackupCandidate> files,
    BackupCancellation? cancellation,
    void Function(BackupFileEntry entry)? onFile,
    void Function(int bytes)? onBytes,
  }) async {
    final (key, parameters) = await _newKey(passphrase);
    final manifest = [
      for (var i = 0; i < files.length; i++) files[i].entry.withIndex(i),
    ];
    final envelope = await _envelope(householdId, key, parameters)
      ..['preppsuiteBackup'] = backupContainerVersion
      // Encrypted like every other section: which papers a household
      // keeps, and which archives, is nobody else's business.
      ..['files'] = await encryptForFolder(
        jsonEncode([for (final entry in manifest) entry.toJson()]),
        key,
      );

    final writer = BackupWriter(out, key);
    await writer.writeHeader(envelope);
    final unreadable = <String>[];
    for (var i = 0; i < files.length; i++) {
      cancellation?.check();
      final entry = manifest[i];
      onFile?.call(entry);
      final ByteRangeSource source;
      try {
        source = await files[i].open();
      } on Object {
        // A document on a disk that is not plugged in, an archive whose
        // permission did not survive. The household is worth saving
        // without it.
        unreadable.add(entry.label);
        continue;
      }
      try {
        await writer.writeEntry(
          i,
          source,
          encrypted: entry.kind.encrypted,
          cancellation: cancellation,
          onBytes: onBytes,
        );
      } finally {
        await source.close();
      }
    }
    await writer.finish();
    return unreadable;
  }

  Future<(FolderKey, VaultParameters)> _newKey(String passphrase) async {
    final random = Random.secure();
    final parameters = VaultParameters(
      salt: Uint8List.fromList(
        List.generate(saltLength, (_) => random.nextInt(256)),
      ),
    );
    return (await deriveFolderKey(passphrase, parameters), parameters);
  }

  Future<Map<String, Object?>> _envelope(
    String householdId,
    FolderKey key,
    VaultParameters parameters,
  ) async {
    final snapshot = (await readHouseholdSnapshot(
      database,
      deviceId: 'backup',
      householdId: householdId,
    )).encode();
    final plan = jsonEncode((await hub.load()).toJson());
    final carried = jsonEncode((await readCarriedHousehold()).toJson());
    return {
      'preppsuiteBackup': 2,
      'key': parameters.toJson(),
      'payload': await encryptForFolder(snapshot, key),
      // A separate section rather than a field inside the snapshot: an
      // older version reading this file ignores the key it does not know
      // and still restores the household, and a newer version reading an
      // older backup simply finds no plan.
      'device': await encryptForFolder(plan, key),
      // Format 2. The profile and the carried settings are not in the
      // database and were not in the backup either -- which meant a
      // restored household knew its whole stock and not how many people
      // it had to last, nor which district to watch. Now that those
      // values are encrypted on the device, a backup is also the only
      // way they survive a lost keychain.
      'household': await encryptForFolder(carried, key),
    };
  }

  /// Opens a backup file of any format and checks the passphrase, without
  /// changing anything.
  ///
  /// Null for every way it can fail to be this household's backup, as
  /// [verify] explains. [householdId] null accepts any household; only a
  /// device that has none may ask for that.
  Future<OpenedBackup?> open(
    BackupFile file,
    String passphrase, {
    String? householdId,
  }) async {
    final opened = await _open(file.envelope, householdId, passphrase);
    if (opened == null) return null;
    final (snapshot, key, envelope) = opened;
    return OpenedBackup(
      file: file,
      snapshot: snapshot,
      key: key,
      files: await _manifest(envelope['files'], key),
    );
  }

  /// The file list of a format 3 backup; empty for the older ones.
  ///
  /// A damaged list costs the files and not the household, the same rule
  /// as the plan and the settings.
  static Future<List<BackupFileEntry>> _manifest(
    Object? section,
    FolderKey key,
  ) async {
    if (section is! String) return const [];
    final clear = await decryptFromFolder(section, key);
    if (clear == null) return const [];
    try {
      final decoded = jsonDecode(clear);
      if (decoded is! List) return const [];
      return [for (final raw in decoded) ?BackupFileEntry.fromJson(raw)];
    } on FormatException {
      return const [];
    }
  }

  /// Opens a backup without changing anything, and says what is in it.
  ///
  /// Null for every way it can fail to be this household's backup: not a
  /// backup file, wrong passphrase, damaged payload, or somebody else's
  /// household. The caller cannot tell those apart, deliberately — a file
  /// picker plus a passphrase field is not a place to explain which half
  /// of the two was wrong.
  ///
  /// This is what "verified backup" means before the at-rest encryption
  /// upgrade: not that a file exists, but that this installation could
  /// read a household back out of it.
  Future<BackupCheck?> verify(
    String raw,
    String householdId,
    String passphrase,
  ) async {
    final file = BackupFile.fromString(raw);
    if (file == null) return null;
    final opened = await open(file, passphrase, householdId: householdId);
    return opened == null ? null : verifyOpened(opened);
  }

  /// What [verify] answers, for a backup that is already open.
  BackupCheck verifyOpened(OpenedBackup opened) =>
      BackupCheck(rows: opened.snapshot.rowCount, files: opened.files.length);

  /// Restores a backup onto a device that has no household yet, taking
  /// the household id from the file.
  ///
  /// The way back after a lost key. [restore] insists that the backup and
  /// this device speak of the same household, which is right when there
  /// is one to protect -- and a dead end after "set up again", because
  /// the household that was just created has a new id and would turn its
  /// own backup away.
  ///
  /// Only for a device with nothing to lose: it adopts an id, and every
  /// local row is partitioned by that id.
  Future<RestoredHousehold?> restoreAsNewHousehold(
    String raw,
    String passphrase,
  ) async {
    final file = BackupFile.fromString(raw);
    if (file == null) return null;
    final opened = await open(file, passphrase);
    return opened == null ? null : restoreOpenedAsNewHousehold(opened);
  }

  /// [restoreAsNewHousehold], for a backup that is already open.
  Future<RestoredHousehold> restoreOpenedAsNewHousehold(
    OpenedBackup opened,
  ) async {
    final snapshot = opened.snapshot;
    final key = opened.key;
    final envelope = opened.file.envelope;
    final householdId = snapshot.householdId;

    await _restorePlan(envelope['device'], key);
    // Handed back rather than written: the caller adopts it through the
    // profile provider, which is the one place that keeps the stores and
    // the screen in step.
    final profile = await _restoreCarried(
      envelope['household'],
      key,
      householdId,
    );
    final rows = await applyHouseholdSnapshot(database, snapshot);

    return RestoredHousehold(
      householdId: householdId,
      rows: rows,
      profile: profile,
    );
  }

  ///
  /// [saveProfile] is where the restored profile goes. The settings screen
  /// passes the profile provider's own `adopt`: writing the store
  /// directly, as this used to, left the provider holding the old profile
  /// — the next change on screen wrote it back over the restored one — and
  /// skipped the copy of the warning regions the background poll reads.
  /// Left out, the profile is written to both stores here.
  Future<int?> restore(
    String raw,
    String householdId,
    String passphrase, {
    Future<void> Function(HouseholdProfile profile)? saveProfile,
  }) async {
    final file = BackupFile.fromString(raw);
    if (file == null) return null;
    final opened = await open(file, passphrase, householdId: householdId);
    if (opened == null) return null;
    return restoreOpened(opened, saveProfile: saveProfile);
  }

  /// [restore], for a backup that is already open -- and was opened for
  /// this household, which [open] checked.
  Future<int> restoreOpened(
    OpenedBackup opened, {
    Future<void> Function(HouseholdProfile profile)? saveProfile,
  }) async {
    final snapshot = opened.snapshot;
    final key = opened.key;
    final envelope = opened.file.envelope;
    final householdId = snapshot.householdId;
    await _restorePlan(envelope['device'], key);
    final profile = await _restoreCarried(
      envelope['household'],
      key,
      householdId,
    );
    if (profile != null) await (saveProfile ?? _saveProfile)(profile);

    // The same merge as a shared folder, a QR chain and a handover: a
    // row is taken only when it is newer than what is held, so restoring
    // an old backup over a current household changes nothing rather than
    // winding it back.
    return applyHouseholdSnapshot(database, snapshot);
  }

  /// The one place that turns a file and a passphrase into a household.
  ///
  /// Shared by [verify] and [restore] so that "the app could read this
  /// backup" and "the app restored this backup" can never mean two
  /// different amounts of checking.
  /// [householdId] null accepts whatever household is in the file. Only
  /// [restoreAsNewHousehold] does that, and only on a device that has
  /// none.
  Future<(DeviceSnapshot, FolderKey, Map<String, Object?>)?> _open(
    Map<String, Object?> envelope,
    String? householdId,
    String passphrase,
  ) async {
    if (!const {1, 2, backupContainerVersion}.contains(
          envelope['preppsuiteBackup'],
        ) ||
        envelope['key'] is! Map<String, Object?> ||
        envelope['payload'] is! String) {
      return null;
    }
    final parameters = VaultParameters.fromJson(
      envelope['key']! as Map<String, Object?>,
    );
    if (parameters == null) return null;
    final key = await deriveFolderKey(passphrase, parameters);
    final clear = await decryptFromFolder(envelope['payload']! as String, key);
    if (clear == null) return null;
    final snapshot = DeviceSnapshot.decode(clear);
    if (snapshot == null) return null;
    if (householdId != null && snapshot.householdId != householdId) return null;
    return (snapshot, key, envelope);
  }

  /// The profile and the settings, from a format 2 backup.
  ///
  /// Written with the household id this device already has rather than
  /// the one in the file -- they agree, and where they ever did not, the
  /// id the rows have just been stamped with is the one that must win.
  /// The same rule the QR handover follows.
  ///
  /// Skipped without complaint for a format 1 backup, which has no such
  /// section, and for one whose section is damaged: it is the smaller
  /// half of the file and must not cost somebody the household.
  Future<HouseholdProfile?> _restoreCarried(
    Object? section,
    FolderKey key,
    String householdId,
  ) async {
    if (section is! String) return null;
    final clear = await decryptFromFolder(section, key);
    if (clear == null) return null;
    try {
      final carried = CarriedHousehold.fromJson(jsonDecode(clear));
      await applyCarriedSettings({
        for (final entry in carried.settings.entries)
          // The plan is restored by `_restorePlan`, which *merges* it.
          // Writing it again from here would hand back the older of the
          // two -- the exact thing that merge exists to prevent.
          if (entry.key != 'preparednessHubV1') entry.key: entry.value,
      });
      return carried.profile?.copyWith(id: householdId);
    } on Object {
      // Same reasoning as the plan below.
      return null;
    }
  }

  /// Both places a profile lives: the store, and the copy of its warning
  /// regions for the background poll, which has no provider to ask.
  static Future<void> _saveProfile(HouseholdProfile profile) async {
    await const HouseholdProfileStore().save(profile);
    await const WarningRegionStore().save(profile.warningFilter);
  }

  /// A backup written before this section existed, or one whose plan is
  /// damaged, must not cost somebody their household. The plan is the
  /// smaller half of the file, so it is restored where it can be and
  /// skipped where it cannot.
  Future<void> _restorePlan(Object? section, FolderKey key) async {
    if (section is! String) return;
    final clear = await decryptFromFolder(section, key);
    if (clear == null) return;
    try {
      await hub.mergeFrom(PreparednessHubData.fromJson(jsonDecode(clear)));
    } on Object {
      return;
    }
  }
}

/// What a backup was found to contain, for a check that changes nothing.
class BackupCheck {
  const BackupCheck({required this.rows, this.files = 0});

  /// Rows the file would restore. Shown to the person so that a backup of
  /// an empty household cannot pass as a safety net for a full one.
  final int rows;

  /// Files listed beside the rows. Zero for a backup before format 3.
  final int files;
}

/// A backup file, read as far as its envelope.
///
/// Formats 1 and 2 are a JSON document and are read whole; format 3 is a
/// container whose header is that same document, and whose files are
/// read later, one at a time, by [reader].
class BackupFile {
  const BackupFile._(this.envelope, this.reader);

  final Map<String, Object?> envelope;

  /// The container, for format 3. Null for the JSON formats.
  final BackupReader? reader;

  static BackupFile? fromString(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, Object?>
          ? BackupFile._(decoded, null)
          : null;
    } on FormatException {
      return null;
    }
  }

  /// Null when [source] holds neither a container nor a JSON backup.
  ///
  /// A JSON backup is read only up to [maxJsonBytes]: it is rows and
  /// settings, and a file larger than that is not one.
  static Future<BackupFile?> read(
    ByteRangeSource source, {
    int maxJsonBytes = 256 * 1024 * 1024,
  }) async {
    final reader = await BackupReader.open(source);
    if (reader != null) return BackupFile._(reader.envelope, reader);

    final bytes = BytesBuilder(copy: false);
    var offset = 0;
    while (offset <= maxJsonBytes) {
      final piece = await source.read(offset, backupChunkSize);
      if (piece.isEmpty) break;
      bytes.add(piece);
      offset += piece.length;
    }
    if (offset > maxJsonBytes) return null;
    try {
      return fromString(utf8.decode(bytes.takeBytes()));
    } on FormatException {
      return null;
    }
  }
}

/// A backup whose passphrase was right, ready to be restored.
class OpenedBackup {
  const OpenedBackup({
    required this.file,
    required this.snapshot,
    required this.key,
    required this.files,
  });

  final BackupFile file;
  final DeviceSnapshot snapshot;
  final FolderKey key;

  /// The files beside the rows. Empty before format 3.
  final List<BackupFileEntry> files;
}

/// What came out of a backup restored onto an empty device.
class RestoredHousehold {
  const RestoredHousehold({
    required this.householdId,
    required this.rows,
    this.profile,
  });

  final String householdId;
  final int rows;

  /// Null for a backup written before the profile travelled with it. The
  /// household is still there; it just has to be named again.
  final HouseholdProfile? profile;
}

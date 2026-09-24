import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../../local_db/database.dart';
import '../../preparedness/application/preparedness_hub_store.dart';
import '../../sharing/application/device_snapshot.dart';
import '../../sharing/application/folder_crypto.dart';
import '../../sharing/application/snapshot_exchange.dart';

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
    final snapshot = (await readHouseholdSnapshot(
      database,
      deviceId: 'backup',
      householdId: householdId,
    )).encode();
    final random = Random.secure();
    final parameters = VaultParameters(
      salt: Uint8List.fromList(
        List.generate(saltLength, (_) => random.nextInt(256)),
      ),
    );
    final key = await deriveFolderKey(passphrase, parameters);
    final plan = jsonEncode((await hub.load()).toJson());
    return jsonEncode({
      'preppsuiteBackup': 1,
      'key': parameters.toJson(),
      'payload': await encryptForFolder(snapshot, key),
      // A separate section rather than a field inside the snapshot: an
      // older version reading this file ignores the key it does not know
      // and still restores the household, and a newer version reading an
      // older backup simply finds no plan.
      'device': await encryptForFolder(plan, key),
    });
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
    final opened = await _open(raw, householdId, passphrase);
    if (opened == null) return null;
    return BackupCheck(rows: opened.$1.rowCount);
  }

  Future<int?> restore(
    String raw,
    String householdId,
    String passphrase,
  ) async {
    final opened = await _open(raw, householdId, passphrase);
    if (opened == null) return null;
    final (snapshot, key, device) = opened;
    await _restorePlan(device, key);

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
  Future<(DeviceSnapshot, FolderKey, Object?)?> _open(
    String raw,
    String householdId,
    String passphrase,
  ) async {
    final Object? envelope;
    try {
      envelope = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (envelope is! Map<String, Object?> ||
        envelope['preppsuiteBackup'] != 1 ||
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
    if (snapshot == null || snapshot.householdId != householdId) return null;
    return (snapshot, key, envelope['device']);
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
  const BackupCheck({required this.rows});

  /// Rows the file would restore. Shown to the person so that a backup of
  /// an empty household cannot pass as a safety net for a full one.
  final int rows;
}

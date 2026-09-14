import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../../local_db/database.dart';
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
class BackupService {
  const BackupService(this.database);

  final AppDatabase database;

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
    return jsonEncode({
      'preppsuiteBackup': 1,
      'key': parameters.toJson(),
      'payload': await encryptForFolder(snapshot, key),
    });
  }

  Future<int?> restore(
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

    // The same merge as a shared folder, a QR chain and a handover: a
    // row is taken only when it is newer than what is held, so restoring
    // an old backup over a current household changes nothing rather than
    // winding it back.
    return applyHouseholdSnapshot(database, snapshot);
  }
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../../../local_db/database.dart';
import '../../sharing/application/device_snapshot.dart';
import '../../sharing/application/folder_crypto.dart';

class BackupService {
  const BackupService(this.database);

  final AppDatabase database;

  Future<String> exportHousehold(String householdId, String passphrase) async {
    final snapshot = DeviceSnapshot(
      deviceId: 'backup',
      householdId: householdId,
      writtenAt: DateTime.now().toUtc(),
      inventoryItems: [
        for (final row in await database.inventoryItemsForSync(householdId))
          encodeInventoryItem(row),
      ],
      checklistTemplates: [
        for (final row in await database.checklistTemplatesForSync(householdId))
          encodeChecklistTemplate(row),
      ],
      checklistItems: [
        for (final row in await database.checklistItemsForSync(householdId))
          encodeChecklistItem(row),
      ],
      budgetEntries: [
        for (final row in await database.budgetEntriesForSync(householdId))
          encodeBudgetEntry(row),
      ],
      householdPlans: [
        for (final row in await database.householdPlansForSync(householdId))
          encodeHouseholdPlan(row),
      ],
      householdMembers: [
        for (final row in await database.householdMembersForSync(householdId))
          encodeHouseholdMember(row),
      ],
    ).encode();
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

    IncomingRow<C>? incoming<C>(Map<String, Object?> json, C? companion) {
      final id = json['clientId'];
      final updatedAt = asUtcDate(json['updatedAt']);
      if (companion == null || id is! String || updatedAt == null) return null;
      return (clientId: id, updatedAt: updatedAt, companion: companion);
    }

    return database.mergeIncomingRows(
      inventory: [
        for (final json in snapshot.inventoryItems)
          ?incoming(json, decodeInventoryItem(json)),
      ],
      templates: [
        for (final json in snapshot.checklistTemplates)
          ?incoming(json, decodeChecklistTemplate(json)),
      ],
      items: [
        for (final json in snapshot.checklistItems)
          ?incoming(json, decodeChecklistItem(json)),
      ],
      budget: [
        for (final json in snapshot.budgetEntries)
          ?incoming(json, decodeBudgetEntry(json)),
      ],
      plans: [
        for (final json in snapshot.householdPlans)
          ?incoming(json, decodeHouseholdPlan(json)),
      ],
      members: [
        for (final json in snapshot.householdMembers)
          ?incoming(json, decodeHouseholdMember(json)),
      ],
    );
  }
}

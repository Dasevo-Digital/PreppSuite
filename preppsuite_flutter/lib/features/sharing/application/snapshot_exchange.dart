import '../../../local_db/database.dart';
import 'device_snapshot.dart';

/// Reading a household out of the database and merging one back in.
///
/// Pulled out of `shared_folder_sync_service.dart` when a second and a
/// third way of moving a household appeared — the QR chain and the local
/// handover. All three carry the same [DeviceSnapshot]; only the road
/// between the two devices differs, and the merge rules must not.
///
/// That is the point of the file. A second copy of the merge would be a
/// second set of tie-break rules, and the one thing worse than a
/// household that fails to sync is two devices that quietly disagree
/// about what is in the cellar.

/// Everything this device knows about [householdId], ready to send.
Future<DeviceSnapshot> readHouseholdSnapshot(
  AppDatabase db, {
  required String deviceId,
  required String householdId,
}) async {
  return DeviceSnapshot(
    deviceId: deviceId,
    householdId: householdId,
    // Informational only. The merge compares each row's own version, not
    // this instant.
    writtenAt: DateTime.now().toUtc(),
    inventoryItems: [
      for (final row in await db.inventoryItemsForSync(householdId))
        encodeInventoryItem(row),
    ],
    checklistTemplates: [
      for (final row in await db.checklistTemplatesForSync(householdId))
        encodeChecklistTemplate(row),
    ],
    checklistItems: [
      for (final row in await db.checklistItemsForSync(householdId))
        encodeChecklistItem(row),
    ],
    budgetEntries: [
      for (final row in await db.budgetEntriesForSync(householdId))
        encodeBudgetEntry(row),
    ],
    householdPlans: [
      for (final row in await db.householdPlansForSync(householdId))
        encodeHouseholdPlan(row),
    ],
    householdMembers: [
      for (final row in await db.householdMembersForSync(householdId))
        encodeHouseholdMember(row),
    ],
  );
}

/// Merges [snapshot] in and answers how many rows it taught us.
///
/// The merge itself lives in the database and is version-based: a row is
/// taken only when it is newer than what is held. So applying the same
/// snapshot twice changes nothing the second time, and applying an old
/// one changes nothing at all — which is what makes it safe to hand a
/// household around by any road, in any order.
Future<int> applyHouseholdSnapshot(AppDatabase db, DeviceSnapshot snapshot) {
  return db.mergeIncomingRows(
    inventory: [
      for (final json in snapshot.inventoryItems)
        ?incomingRow(json, decodeInventoryItem(json)),
    ],
    templates: [
      for (final json in snapshot.checklistTemplates)
        ?incomingRow(json, decodeChecklistTemplate(json)),
    ],
    items: [
      for (final json in snapshot.checklistItems)
        ?incomingRow(json, decodeChecklistItem(json)),
    ],
    budget: [
      for (final json in snapshot.budgetEntries)
        ?incomingRow(json, decodeBudgetEntry(json)),
    ],
    plans: [
      for (final json in snapshot.householdPlans)
        ?incomingRow(json, decodeHouseholdPlan(json)),
    ],
    members: [
      for (final json in snapshot.householdMembers)
        ?incomingRow(json, decodeHouseholdMember(json)),
    ],
  );
}

/// Lifts the two fields the merge compares out of the raw JSON, so the
/// comparison never has to reach into a companion's `Value`s.
IncomingRow<C>? incomingRow<C>(Map<String, Object?> json, C? companion) {
  if (companion == null) return null;
  final clientId = json['clientId'];
  final updatedAt = asUtcDate(json['updatedAt']);
  if (clientId is! String || updatedAt == null) return null;
  return (clientId: clientId, updatedAt: updatedAt, companion: companion);
}

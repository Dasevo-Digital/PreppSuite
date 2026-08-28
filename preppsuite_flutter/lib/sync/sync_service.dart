import 'package:drift/drift.dart' show Value;
import 'package:preppsuite_client/preppsuite_client.dart' as proto;

import '../local_db/database.dart';
import '../main.dart';

/// The single boundary between local Drift storage (source of truth for the
/// UI) and the generated Serverpod client (remote sync calls). Nothing else
/// in `features/` should call `client.inventory` etc. directly.
///
/// Push-then-pull, per entity: push local edits first so a concurrent pull
/// on another device sees them as soon as possible, then pull remote changes
/// (including this device's own, now carrying the server-canonical
/// `updatedAt`) into local storage.
class SyncService {
  SyncService(this._db);

  final AppDatabase _db;

  static const _inventoryEntity = 'inventory';
  static const _checklistTemplateEntity = 'checklistTemplate';
  static const _checklistItemEntity = 'checklistItem';
  static const _budgetEntity = 'budget';
  static const _warningEntity = 'warning';

  // --- Push devices ------------------------------------------------------

  /// Tells the server this device wants warning pushes for [householdId].
  ///
  /// Not part of any entity's push/pull cycle: a device token is not
  /// household data, it belongs to exactly one device, and it must never
  /// end up in local storage that gets restored onto a different phone.
  /// It lives here only because this is the one place allowed to speak to
  /// the server.
  Future<void> registerPushDevice({
    required String householdId,
    required String token,
    required proto.PushPlatform platform,
  }) {
    return client.pushDevice.registerDevice(
      proto.UuidValue.fromString(householdId),
      token,
      platform,
    );
  }

  Future<void> unregisterPushDevice(String token) {
    return client.pushDevice.unregisterDevice(token);
  }

  // --- Inventory ---------------------------------------------------------

  Future<void> syncInventory(String householdId) async {
    final id = proto.UuidValue.fromString(householdId);
    await _pushInventory(id, householdId);
    await _pullInventory(id, householdId);
  }

  Future<void> _pushInventory(
    proto.UuidValue householdId,
    String householdIdString,
  ) async {
    final dirtyRows = await _db.dirtyInventoryItems(householdIdString);
    if (dirtyRows.isEmpty) return;

    final canonical = await client.inventory.pushInventoryChanges(
      householdId,
      dirtyRows.map(_inventoryToProto).toList(),
    );

    await _db.markInventoryItemsSynced([
      for (final row in canonical)
        (row.clientId.toString(), row.id!.toString(), row.updatedAt),
    ]);
  }

  Future<void> _pullInventory(
    proto.UuidValue householdId,
    String householdIdString,
  ) async {
    final since =
        await _db.lastPulledAt(_inventoryEntity) ?? DateTime.utc(2000);
    final changes = await client.inventory.pullInventoryChanges(
      householdId,
      since,
    );
    if (changes.isEmpty) return;

    var maxUpdatedAt = since;
    for (final item in changes) {
      await _db.upsertInventoryItem(_inventoryFromProto(item));
      if (item.updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = item.updatedAt;
      }
    }
    await _db.setLastPulledAt(_inventoryEntity, maxUpdatedAt);
  }

  proto.InventoryItem _inventoryToProto(InventoryItem row) {
    return proto.InventoryItem(
      id: row.serverId != null
          ? proto.UuidValue.fromString(row.serverId!)
          : null,
      householdId: proto.UuidValue.fromString(row.householdId),
      clientId: proto.UuidValue.fromString(row.clientId),
      name: row.name,
      category: proto.InventoryItemCategory.values.byName(row.category),
      barcode: row.barcode,
      offProductId: row.offProductId,
      quantity: row.quantity,
      unit: row.unit,
      storageLocation: row.storageLocation,
      expirationDate: row.expirationDate,
      minQuantity: row.minQuantity,
      notes: row.notes,
      // Drift/SQLite round-trips the correct instant but flags it as local
      // time; normalize to UTC before it crosses the wire so the server's
      // last-write-wins comparison and stored `updatedAt` are unambiguous.
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
    );
  }

  InventoryItemsCompanion _inventoryFromProto(proto.InventoryItem item) {
    return InventoryItemsCompanion.insert(
      clientId: item.clientId.toString(),
      serverId: Value(item.id?.toString()),
      householdId: item.householdId.toString(),
      name: item.name,
      category: item.category.name,
      barcode: Value(item.barcode),
      offProductId: Value(item.offProductId),
      quantity: item.quantity,
      unit: item.unit,
      storageLocation: item.storageLocation,
      expirationDate: Value(item.expirationDate),
      minQuantity: Value(item.minQuantity),
      notes: Value(item.notes),
      updatedAt: item.updatedAt,
      deletedAt: Value(item.deletedAt),
      dirty: const Value(false),
    );
  }

  // --- Checklists ----------------------------------------------------------
  //
  // Templates must be pushed and pulled *before* items: pushing an item
  // requires its template's server id (items reference templates by server
  // id, not client id), and pulling an item requires its template to
  // already exist locally so the item can be filed under the template's
  // local `clientId`.

  Future<void> syncChecklists(String householdId) async {
    final id = proto.UuidValue.fromString(householdId);
    await _pushChecklistTemplates(id, householdId);
    await _pullChecklistTemplates(id, householdId);
    await _pushChecklistItems(id, householdId);
    await _pullChecklistItems(id, householdId);
  }

  Future<void> _pushChecklistTemplates(
    proto.UuidValue householdId,
    String householdIdString,
  ) async {
    final dirtyRows = await _db.dirtyChecklistTemplates(householdIdString);
    if (dirtyRows.isEmpty) return;

    final canonical = await client.checklist.pushChecklistTemplateChanges(
      householdId,
      dirtyRows.map(_templateToProto).toList(),
    );

    await _db.markChecklistTemplatesSynced([
      for (final row in canonical)
        (row.clientId.toString(), row.id!.toString(), row.updatedAt),
    ]);
  }

  Future<void> _pullChecklistTemplates(
    proto.UuidValue householdId,
    String householdIdString,
  ) async {
    final since =
        await _db.lastPulledAt(_checklistTemplateEntity) ?? DateTime.utc(2000);
    final changes = await client.checklist.pullChecklistTemplateChanges(
      householdId,
      since,
    );
    if (changes.isEmpty) return;

    var maxUpdatedAt = since;
    for (final template in changes) {
      await _db.upsertChecklistTemplate(_templateFromProto(template));
      if (template.updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = template.updatedAt;
      }
    }
    await _db.setLastPulledAt(_checklistTemplateEntity, maxUpdatedAt);
  }

  Future<void> _pushChecklistItems(
    proto.UuidValue householdId,
    String householdIdString,
  ) async {
    final dirtyRows = await _db.dirtyChecklistItems(householdIdString);
    if (dirtyRows.isEmpty) return;

    final toPush = <proto.ChecklistItem>[];
    for (final row in dirtyRows) {
      final template = await _db.checklistTemplateByClientId(
        row.templateClientId,
      );
      // The template hasn't been synced yet (shouldn't normally happen
      // since templates are pushed first in the same sync pass, but a
      // template push can fail independently) — leave dirty, retry later.
      if (template?.serverId == null) continue;
      toPush.add(
        _itemToProto(row, proto.UuidValue.fromString(template!.serverId!)),
      );
    }
    if (toPush.isEmpty) return;

    final canonical = await client.checklist.pushChecklistItemChanges(
      householdId,
      toPush,
    );

    await _db.markChecklistItemsSynced([
      for (final row in canonical)
        (row.clientId.toString(), row.id!.toString(), row.updatedAt),
    ]);
  }

  Future<void> _pullChecklistItems(
    proto.UuidValue householdId,
    String householdIdString,
  ) async {
    final since =
        await _db.lastPulledAt(_checklistItemEntity) ?? DateTime.utc(2000);
    final changes = await client.checklist.pullChecklistItemChanges(
      householdId,
      since,
    );
    if (changes.isEmpty) return;

    var maxUpdatedAt = since;
    for (final item in changes) {
      final template = await _db.checklistTemplateByServerId(
        item.templateId.toString(),
      );
      // Its template should already be local (templates are pulled first in
      // the same pass); skip defensively if not — it'll resolve next sync.
      if (template == null) continue;

      await _db.upsertChecklistItem(_itemFromProto(item, template.clientId));
      if (item.updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = item.updatedAt;
      }
    }
    await _db.setLastPulledAt(_checklistItemEntity, maxUpdatedAt);
  }

  proto.ChecklistTemplate _templateToProto(ChecklistTemplate row) {
    return proto.ChecklistTemplate(
      id: row.serverId != null
          ? proto.UuidValue.fromString(row.serverId!)
          : null,
      householdId: row.householdId != null
          ? proto.UuidValue.fromString(row.householdId!)
          : null,
      clientId: proto.UuidValue.fromString(row.clientId),
      title: row.title,
      category: proto.ChecklistCategory.values.byName(row.category),
      isBuiltIn: row.isBuiltIn,
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
    );
  }

  ChecklistTemplatesCompanion _templateFromProto(proto.ChecklistTemplate t) {
    return ChecklistTemplatesCompanion.insert(
      clientId: t.clientId.toString(),
      serverId: Value(t.id?.toString()),
      householdId: Value(t.householdId?.toString()),
      title: t.title,
      category: t.category.name,
      isBuiltIn: Value(t.isBuiltIn),
      updatedAt: t.updatedAt,
      deletedAt: Value(t.deletedAt),
      dirty: const Value(false),
    );
  }

  proto.ChecklistItem _itemToProto(
    ChecklistItem row,
    proto.UuidValue templateId,
  ) {
    return proto.ChecklistItem(
      id: row.serverId != null
          ? proto.UuidValue.fromString(row.serverId!)
          : null,
      householdId: row.householdId != null
          ? proto.UuidValue.fromString(row.householdId!)
          : null,
      clientId: proto.UuidValue.fromString(row.clientId),
      templateId: templateId,
      title: row.title,
      targetQuantity: row.targetQuantity,
      isChecked: row.isChecked,
      linkedInventoryItemId: row.linkedInventoryItemId != null
          ? proto.UuidValue.fromString(row.linkedInventoryItemId!)
          : null,
      sortOrder: row.sortOrder,
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
    );
  }

  ChecklistItemsCompanion _itemFromProto(
    proto.ChecklistItem item,
    String templateClientId,
  ) {
    return ChecklistItemsCompanion.insert(
      clientId: item.clientId.toString(),
      serverId: Value(item.id?.toString()),
      householdId: Value(item.householdId?.toString()),
      templateClientId: templateClientId,
      title: item.title,
      targetQuantity: Value(item.targetQuantity),
      isChecked: Value(item.isChecked),
      linkedInventoryItemId: Value(item.linkedInventoryItemId?.toString()),
      sortOrder: Value(item.sortOrder),
      updatedAt: item.updatedAt,
      deletedAt: Value(item.deletedAt),
      dirty: const Value(false),
    );
  }

  // --- Budget --------------------------------------------------------------

  Future<void> syncBudget(String householdId) async {
    final id = proto.UuidValue.fromString(householdId);
    await _pushBudget(id, householdId);
    await _pullBudget(id, householdId);
  }

  Future<void> _pushBudget(
    proto.UuidValue householdId,
    String householdIdString,
  ) async {
    final dirtyRows = await _db.dirtyBudgetEntries(householdIdString);
    if (dirtyRows.isEmpty) return;

    final canonical = await client.budget.pushBudgetChanges(
      householdId,
      dirtyRows.map(_budgetToProto).toList(),
    );

    await _db.markBudgetEntriesSynced([
      for (final row in canonical)
        (row.clientId.toString(), row.id!.toString(), row.updatedAt),
    ]);
  }

  Future<void> _pullBudget(
    proto.UuidValue householdId,
    String householdIdString,
  ) async {
    final since = await _db.lastPulledAt(_budgetEntity) ?? DateTime.utc(2000);
    final changes = await client.budget.pullBudgetChanges(householdId, since);
    if (changes.isEmpty) return;

    var maxUpdatedAt = since;
    for (final entry in changes) {
      await _db.upsertBudgetEntry(_budgetFromProto(entry));
      if (entry.updatedAt.isAfter(maxUpdatedAt)) {
        maxUpdatedAt = entry.updatedAt;
      }
    }
    await _db.setLastPulledAt(_budgetEntity, maxUpdatedAt);
  }

  proto.BudgetEntry _budgetToProto(BudgetEntry row) {
    return proto.BudgetEntry(
      id: row.serverId != null
          ? proto.UuidValue.fromString(row.serverId!)
          : null,
      householdId: proto.UuidValue.fromString(row.householdId),
      clientId: proto.UuidValue.fromString(row.clientId),
      label: row.label,
      amountCents: row.amountCents,
      currency: row.currency,
      category: proto.InventoryItemCategory.values.byName(row.category),
      purchaseDate: row.purchaseDate,
      linkedInventoryItemId: row.linkedInventoryItemId != null
          ? proto.UuidValue.fromString(row.linkedInventoryItemId!)
          : null,
      updatedAt: row.updatedAt.toUtc(),
      deletedAt: row.deletedAt?.toUtc(),
    );
  }

  BudgetEntriesCompanion _budgetFromProto(proto.BudgetEntry entry) {
    return BudgetEntriesCompanion.insert(
      clientId: entry.clientId.toString(),
      serverId: Value(entry.id?.toString()),
      householdId: entry.householdId.toString(),
      label: entry.label,
      amountCents: entry.amountCents,
      currency: entry.currency,
      category: entry.category.name,
      purchaseDate: Value(entry.purchaseDate),
      linkedInventoryItemId: Value(entry.linkedInventoryItemId?.toString()),
      updatedAt: entry.updatedAt,
      deletedAt: Value(entry.deletedAt),
      dirty: const Value(false),
    );
  }

  // --- Warnings (pull-only, server-generated) -------------------------

  /// Returns the warnings that arrived/changed in this pull (empty if
  /// nothing new), so callers can react to genuinely new ones — see
  /// `WarningSyncController.syncNow`, which uses this to fire local
  /// notifications without needing to separately diff the local DB.
  Future<List<proto.Warning>> syncWarnings(String householdId) async {
    final id = proto.UuidValue.fromString(householdId);
    final since = await _db.lastPulledAt(_warningEntity) ?? DateTime.utc(2000);
    final changes = await client.warning.pullWarnings(id, since);

    if (changes.isNotEmpty) {
      var maxUpdatedAt = since;
      for (final warning in changes) {
        await _db.upsertWarning(_warningFromProto(warning));
        if (warning.updatedAt.isAfter(maxUpdatedAt)) {
          maxUpdatedAt = warning.updatedAt;
        }
      }
      await _db.setLastPulledAt(_warningEntity, maxUpdatedAt);
    }

    await _db.pruneExpiredWarnings();
    return changes;
  }

  WarningsCompanion _warningFromProto(proto.Warning warning) {
    return WarningsCompanion.insert(
      serverId: warning.id!.toString(),
      source: warning.source.name,
      externalId: warning.externalId,
      countryCode: warning.countryCode,
      regionKey: Value(warning.regionKey),
      severity: warning.severity.name,
      eventType: warning.eventType,
      headline: warning.headline,
      description: Value(warning.description),
      effective: warning.effective,
      expires: Value(warning.expires),
      sent: warning.sent,
      updatedAt: warning.updatedAt,
    );
  }
}

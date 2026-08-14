import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../households/household_service.dart';

/// Push/pull sync for [ChecklistTemplate] and [ChecklistItem], following the
/// exact pattern established by `InventoryService`. The only difference:
/// pulls also include built-in templates/items (`householdId == null`),
/// which are shared read-only across all households.
class ChecklistService {
  const ChecklistService({
    this.householdService = const HouseholdService(),
  });

  final HouseholdService householdService;

  Future<List<ChecklistTemplate>> pullTemplateChanges(
    Session session, {
    required UuidValue householdId,
    required DateTime since,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    return ChecklistTemplate.db.find(
      session,
      where: (t) =>
          (t.householdId.equals(householdId) | t.householdId.equals(null)) &
          (t.updatedAt > since),
      orderBy: (t) => t.updatedAt,
    );
  }

  Future<List<ChecklistTemplate>> pushTemplateChanges(
    Session session, {
    required UuidValue householdId,
    required List<ChecklistTemplate> changes,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    return session.db.transaction((transaction) async {
      final results = <ChecklistTemplate>[];
      for (final incoming in changes) {
        results.add(
          await _applyTemplateChange(
            session,
            householdId: householdId,
            incoming: incoming,
            transaction: transaction,
          ),
        );
      }
      return results;
    });
  }

  Future<List<ChecklistItem>> pullItemChanges(
    Session session, {
    required UuidValue householdId,
    required DateTime since,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    return ChecklistItem.db.find(
      session,
      where: (t) =>
          (t.householdId.equals(householdId) | t.householdId.equals(null)) &
          (t.updatedAt > since),
      orderBy: (t) => t.updatedAt,
    );
  }

  Future<List<ChecklistItem>> pushItemChanges(
    Session session, {
    required UuidValue householdId,
    required List<ChecklistItem> changes,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    return session.db.transaction((transaction) async {
      final results = <ChecklistItem>[];
      for (final incoming in changes) {
        results.add(
          await _applyItemChange(
            session,
            householdId: householdId,
            incoming: incoming,
            transaction: transaction,
          ),
        );
      }
      return results;
    });
  }

  Future<ChecklistTemplate> _applyTemplateChange(
    Session session, {
    required UuidValue householdId,
    required ChecklistTemplate incoming,
    required Transaction transaction,
  }) async {
    final existing = incoming.id != null
        ? await ChecklistTemplate.db.findById(
            session,
            incoming.id!,
            transaction: transaction,
          )
        : await ChecklistTemplate.db.findFirstRow(
            session,
            where: (t) =>
                t.householdId.equals(householdId) &
                t.clientId.equals(incoming.clientId),
            transaction: transaction,
          );

    // Built-in templates are server-owned; clients can only ever create or
    // edit their own household's templates through this endpoint.
    if (existing == null) {
      return ChecklistTemplate.db.insertRow(
        session,
        ChecklistTemplate(
          householdId: householdId,
          clientId: incoming.clientId,
          title: incoming.title,
          category: incoming.category,
          isBuiltIn: false,
          updatedAt: DateTime.now().toUtc(),
          deletedAt: incoming.deletedAt,
        ),
        transaction: transaction,
      );
    }

    if (existing.isBuiltIn || existing.householdId != householdId) {
      throw HouseholdException(reason: HouseholdExceptionReason.notAMember);
    }

    if (!incoming.updatedAt.isAfter(existing.updatedAt)) {
      return existing;
    }

    existing
      ..title = incoming.title
      ..category = incoming.category
      ..updatedAt = DateTime.now().toUtc()
      ..deletedAt = incoming.deletedAt;

    return ChecklistTemplate.db.updateRow(
      session,
      existing,
      transaction: transaction,
    );
  }

  Future<ChecklistItem> _applyItemChange(
    Session session, {
    required UuidValue householdId,
    required ChecklistItem incoming,
    required Transaction transaction,
  }) async {
    final existing = incoming.id != null
        ? await ChecklistItem.db.findById(
            session,
            incoming.id!,
            transaction: transaction,
          )
        : await ChecklistItem.db.findFirstRow(
            session,
            where: (t) =>
                t.householdId.equals(householdId) &
                t.clientId.equals(incoming.clientId),
            transaction: transaction,
          );

    if (existing == null) {
      final template = await ChecklistTemplate.db.findById(
        session,
        incoming.templateId,
        transaction: transaction,
      );
      if (template == null ||
          (template.householdId != null &&
              template.householdId != householdId)) {
        throw HouseholdException(reason: HouseholdExceptionReason.notAMember);
      }

      return ChecklistItem.db.insertRow(
        session,
        ChecklistItem(
          householdId: householdId,
          clientId: incoming.clientId,
          templateId: incoming.templateId,
          title: incoming.title,
          targetQuantity: incoming.targetQuantity,
          isChecked: incoming.isChecked,
          linkedInventoryItemId: incoming.linkedInventoryItemId,
          sortOrder: incoming.sortOrder,
          updatedAt: DateTime.now().toUtc(),
          deletedAt: incoming.deletedAt,
        ),
        transaction: transaction,
      );
    }

    if (existing.householdId != householdId) {
      throw HouseholdException(reason: HouseholdExceptionReason.notAMember);
    }

    if (!incoming.updatedAt.isAfter(existing.updatedAt)) {
      return existing;
    }

    existing
      ..title = incoming.title
      ..targetQuantity = incoming.targetQuantity
      ..isChecked = incoming.isChecked
      ..linkedInventoryItemId = incoming.linkedInventoryItemId
      ..sortOrder = incoming.sortOrder
      ..updatedAt = DateTime.now().toUtc()
      ..deletedAt = incoming.deletedAt;

    return ChecklistItem.db.updateRow(session, existing, transaction: transaction);
  }
}

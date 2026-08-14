import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'checklist_service.dart';

/// Delta sync for household checklists. Templates and items are synced as
/// two independent entities (same shape as `InventoryEndpoint`) rather than
/// nested, so each can be delta-pulled on its own regardless of whether its
/// counterpart also changed. Accessed through `client.checklist`.
class ChecklistEndpoint extends Endpoint {
  final _service = const ChecklistService();

  @override
  bool get requireLogin => true;

  Future<List<ChecklistTemplate>> pullChecklistTemplateChanges(
    Session session,
    UuidValue householdId,
    DateTime since,
  ) {
    return _service.pullTemplateChanges(
      session,
      householdId: householdId,
      since: since,
    );
  }

  Future<List<ChecklistTemplate>> pushChecklistTemplateChanges(
    Session session,
    UuidValue householdId,
    List<ChecklistTemplate> changes,
  ) {
    return _service.pushTemplateChanges(
      session,
      householdId: householdId,
      changes: changes,
    );
  }

  Future<List<ChecklistItem>> pullChecklistItemChanges(
    Session session,
    UuidValue householdId,
    DateTime since,
  ) {
    return _service.pullItemChanges(
      session,
      householdId: householdId,
      since: since,
    );
  }

  Future<List<ChecklistItem>> pushChecklistItemChanges(
    Session session,
    UuidValue householdId,
    List<ChecklistItem> changes,
  ) {
    return _service.pushItemChanges(
      session,
      householdId: householdId,
      changes: changes,
    );
  }
}

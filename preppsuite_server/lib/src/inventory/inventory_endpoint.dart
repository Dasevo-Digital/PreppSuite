import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'inventory_service.dart';

/// Delta sync for household inventory items. Accessed through
/// `client.inventory` on the client side.
class InventoryEndpoint extends Endpoint {
  final _service = const InventoryService();

  @override
  bool get requireLogin => true;

  /// Returns all inventory items (including tombstoned ones) for
  /// [householdId] changed after [since].
  Future<List<InventoryItem>> pullInventoryChanges(
    Session session,
    UuidValue householdId,
    DateTime since,
  ) {
    return _service.pullChanges(
      session,
      householdId: householdId,
      since: since,
    );
  }

  /// Upserts [changes] for [householdId] and returns the canonical
  /// server-side rows (with server-assigned ids and re-stamped
  /// `updatedAt`) so the client can reconcile its local copies.
  Future<List<InventoryItem>> pushInventoryChanges(
    Session session,
    UuidValue householdId,
    List<InventoryItem> changes,
  ) {
    return _service.pushChanges(
      session,
      householdId: householdId,
      changes: changes,
    );
  }
}

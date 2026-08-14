import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'budget_service.dart';

/// Delta sync for household budget entries. Accessed through
/// `client.budget`.
class BudgetEndpoint extends Endpoint {
  final _service = const BudgetService();

  @override
  bool get requireLogin => true;

  Future<List<BudgetEntry>> pullBudgetChanges(
    Session session,
    UuidValue householdId,
    DateTime since,
  ) {
    return _service.pullChanges(session, householdId: householdId, since: since);
  }

  Future<List<BudgetEntry>> pushBudgetChanges(
    Session session,
    UuidValue householdId,
    List<BudgetEntry> changes,
  ) {
    return _service.pushChanges(
      session,
      householdId: householdId,
      changes: changes,
    );
  }
}

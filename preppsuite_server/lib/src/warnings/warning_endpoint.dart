import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'warning_service.dart';

/// Read-only warning pull, scoped to the household's country. Accessed
/// through `client.warning`.
class WarningEndpoint extends Endpoint {
  final _service = const WarningService();

  @override
  bool get requireLogin => true;

  Future<List<Warning>> pullWarnings(
    Session session,
    UuidValue householdId,
    DateTime since,
  ) {
    return _service.pullChanges(session, householdId: householdId, since: since);
  }
}

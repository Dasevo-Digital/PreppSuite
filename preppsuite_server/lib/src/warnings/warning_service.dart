import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../households/household_service.dart';

/// Read-only warning pull, scoped to a household's country. Unlike the
/// syncable entities, [Warning] rows are entirely server-generated (by
/// `WarningPollFutureCall`) — there is no push.
class WarningService {
  const WarningService({
    this.householdService = const HouseholdService(),
  });

  final HouseholdService householdService;

  Future<List<Warning>> pullChanges(
    Session session, {
    required UuidValue householdId,
    required DateTime since,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    final household = await Household.db.findById(session, householdId);
    if (household == null) {
      throw HouseholdException(reason: HouseholdExceptionReason.notAMember);
    }

    return Warning.db.find(
      session,
      where: (t) =>
          t.countryCode.equals(household.countryCode) & (t.updatedAt > since),
      orderBy: (t) => t.updatedAt,
    );
  }
}

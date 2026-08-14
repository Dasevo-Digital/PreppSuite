import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'services/bbk_client.dart';
import 'services/meteoalarm_client.dart';
import 'services/warning_normalizer.dart';

/// Polls both warning feeds for every country currently in use by a
/// household, then reschedules itself. Serverpod has no periodic/cron
/// primitive, so a self-rescheduling `FutureCall` is the documented pattern
/// for this — see `docs/warning-feeds.md`.
///
/// This is a plain `invoke`-overriding `FutureCall`, not one of the
/// generated typed future calls (that variant expects strongly-typed
/// data/methods, which this doesn't need). Registered once in
/// `server.dart` and kicked off there at server start.
class WarningPollFutureCall extends FutureCall<SerializableModel> {
  WarningPollFutureCall({
    BbkClient? bbkClient,
    MeteoAlarmClient? meteoAlarmClient,
    WarningNormalizer? normalizer,
  }) : _bbkClient = bbkClient ?? BbkClient(),
       _meteoAlarmClient = meteoAlarmClient ?? MeteoAlarmClient(),
       _normalizer = normalizer ?? const WarningNormalizer();

  static const callName = 'warningPoll';
  static const pollInterval = Duration(minutes: 15);

  final BbkClient _bbkClient;
  final MeteoAlarmClient _meteoAlarmClient;
  final WarningNormalizer _normalizer;

  @override
  Future<void> invoke(Session session, SerializableModel? object) async {
    try {
      await _pollOnce(session);
    } catch (e, stackTrace) {
      // A failed poll must never break the reschedule chain — log and try
      // again next interval.
      session.log(
        'Warning poll failed: $e',
        level: LogLevel.warning,
        exception: e,
        stackTrace: stackTrace,
      );
    } finally {
      // Deliberately using the manual scheduling API instead of a generated
      // future call (see the class doc comment) — this is the officially
      // documented self-rescheduling pattern, the deprecation just steers
      // toward the newer typed-method style for future calls that need it.
      // ignore: deprecated_member_use
      await session.serverpod.futureCallWithDelay(callName, null, pollInterval);
    }
  }

  Future<void> _pollOnce(Session session) async {
    final countryCodes = await _distinctHouseholdCountryCodes(session);
    if (countryCodes.isEmpty) return;

    if (countryCodes.contains('DE')) {
      final bbkWarnings = await _bbkClient.fetchAll();
      await _normalizer.upsertBbk(session, bbkWarnings, countryCode: 'DE');
    }

    for (final countryCode in countryCodes) {
      final slug = meteoAlarmCountrySlugs[countryCode];
      if (slug == null) continue;

      final warnings = await _meteoAlarmClient.fetchCountry(slug);
      await _normalizer.upsertMeteoAlarm(
        session,
        warnings,
        countryCode: countryCode,
      );
    }
  }

  Future<Set<String>> _distinctHouseholdCountryCodes(Session session) async {
    final households = await Household.db.find(session);
    return households.map((h) => h.countryCode).toSet();
  }
}

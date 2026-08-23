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
    final households = await Household.db.find(session);
    final countryCodes = households.map((h) => h.countryCode).toSet();
    if (countryCodes.isEmpty) return;

    if (countryCodes.contains('DE')) {
      // Nationwide pass: cheap fallback for households without a region set,
      // and the only source of (coarser, state-level) precision for
      // `bundesland`-kind subscriptions, since there's no dedicated
      // state-wide BBK endpoint.
      final nationwide = await _bbkClient.fetchAll();
      await _normalizer.upsertBbk(
        session,
        nationwide.warnings,
        countryCode: 'DE',
      );

      final seenIds = {for (final w in nationwide.warnings) w.id};

      for (final kreisSchluessel in await _distinctKreisSchluessel(
        session,
        households,
      )) {
        final dashboardWarnings = await _bbkClient.fetchDashboard(
          kreisSchluessel,
        );
        await _normalizer.upsertBbk(
          session,
          dashboardWarnings,
          countryCode: 'DE',
          regionKeyOverride: kreisSchluessel,
        );
        // Folded into the same set so a warning that only the per-Kreis
        // endpoint knows about is not retired by the reap below.
        seenIds.addAll(dashboardWarnings.map((w) => w.id));
      }

      // Skipped whenever any source failed: an incomplete picture would
      // retire warnings that are still active (see [BbkFetchResult]).
      if (nationwide.complete) {
        final retired = await _normalizer.expireMissingBbk(
          session,
          seenExternalIds: seenIds,
          countryCode: 'DE',
        );
        if (retired > 0) {
          session.log('Warning poll: retired $retired stale BBK warning(s)');
        }
      } else {
        session.log(
          'Warning poll: at least one BBK source failed, skipping expiry '
          'of stale warnings this round',
          level: LogLevel.warning,
        );
      }
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

  /// Every distinct 5-digit Kreisschlüssel worth polling precisely: each
  /// household's own `regionKey` (first 5 digits) plus every household's
  /// `kind: kreis` [WarningRegionSubscription]s. Households sharing a
  /// district only cause one fetch, not one per household.
  Future<Set<String>> _distinctKreisSchluessel(
    Session session,
    List<Household> households,
  ) async {
    final result = <String>{};

    for (final household in households) {
      final regionKey = household.regionKey;
      if (regionKey != null && regionKey.length >= 5) {
        result.add(regionKey.substring(0, 5));
      }
    }

    final subscriptions = await WarningRegionSubscription.db.find(
      session,
      where: (t) => t.kind.equals(WarningRegionKind.kreis),
    );
    for (final subscription in subscriptions) {
      result.add(subscription.value);
    }

    return result;
  }
}

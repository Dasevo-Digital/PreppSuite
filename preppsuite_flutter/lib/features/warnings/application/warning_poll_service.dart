import '../../../model/categories.dart';

import '../../../local_db/database.dart';
import 'bbk_client.dart';
import 'dwd_areas.dart';
import 'meteoalarm_client.dart';
import 'warning_ingest.dart';
import 'warning_poll_status_store.dart';
import 'warning_severity_l10n.dart';

/// What one poll did, so the caller can log or display it without having
/// to re-query.
class WarningPollResult {
  const WarningPollResult({
    required this.fetched,
    required this.newsworthy,
    required this.retired,
    required this.complete,
  });

  /// Warnings the feeds returned, before deduplication.
  final int fetched;

  /// Warnings that are new or escalated — the ones a notification would be
  /// about.
  final List<NotifiableWarning> newsworthy;

  /// Warnings ended because they dropped out of a complete poll.
  final int retired;

  /// False when at least one source could not be read. Nothing was
  /// retired in that case.
  final bool complete;
}

/// Fetches both warning feeds and writes them to the local database.
///
/// This is what used to be `WarningPollFutureCall` on the server. Moving it
/// into the app removed a hop, not a capability: both feeds are public and
/// key-less, and the region filtering was already happening on the device
/// (`warning_relevance.dart`).
///
/// Deliberately free of Riverpod and of anything touching a widget tree —
/// the Android background worker runs this in a separate isolate where no
/// providers exist.
class WarningPollService {
  WarningPollService({
    required AppDatabase database,
    BbkClient? bbkClient,
    MeteoAlarmClient? meteoAlarmClient,
  }) : _db = database,
       _bbk = bbkClient ?? BbkClient(),
       _meteoAlarm = meteoAlarmClient ?? MeteoAlarmClient();

  final AppDatabase _db;
  final BbkClient _bbk;
  final MeteoAlarmClient _meteoAlarm;

  late final _ingest = WarningIngest(_db);

  /// Warnings below this are never announced. A steady trickle of "minor"
  /// notifications is how people learn to ignore the channel.
  static const notifySeverityFloor = WarningSeverity.moderate;

  /// Polls for [countryCode], optionally fetching [kreisSchluessel]
  /// precisely on top of the nationwide sweep.
  Future<WarningPollResult> poll({
    required String countryCode,
    String? kreisSchluessel,
  }) async {
    final newsworthy = <NotifiableWarning>[];
    var fetched = 0;
    var retired = 0;
    var complete = true;

    if (countryCode == 'DE') {
      final nationwide = await _bbk.fetchAll();
      final detailedNationwide = await _detailsForChanged(
        nationwide.warnings,
      );
      complete = nationwide.complete;
      fetched += nationwide.warnings.length;
      newsworthy.addAll(
        await _ingest.ingestBbk(detailedNationwide, countryCode: 'DE'),
      );

      final seen = {for (final w in nationwide.warnings) w.id};

      if (kreisSchluessel != null && kreisSchluessel.length >= 5) {
        final compactPrecise = await _bbk.fetchDashboard(
          kreisSchluessel.substring(0, 5),
        );
        final precise = await _detailsForChanged(compactPrecise);
        fetched += precise.length;
        newsworthy.addAll(
          await _ingest.ingestBbk(
            precise,
            countryCode: 'DE',
            regionKeyOverride: kreisSchluessel.substring(0, 5),
          ),
        );
        // Folded in so a warning only the per-Kreis endpoint knows about is
        // not retired by the sweep below.
        seen.addAll(precise.map((w) => w.id));
      }

      // Only when every source answered. An incomplete picture would end
      // warnings that are still running — see [BbkFetchResult.complete].
      if (complete) {
        retired += await _db.expireMissingWarnings(
          source: WarningSource.bbk.name,
          seenExternalIds: seen,
        );
      }
    }

    final slug = meteoAlarmCountrySlugs[countryCode];
    if (slug != null) {
      final warnings = await _meteoAlarm.fetchCountry(slug);
      fetched += warnings.length;
      // Only Germany can place these areas — the list behind it is the
      // DWD's. A table that will not load must not cost the warnings
      // themselves: without it they simply concern the whole country.
      DwdAreas? areas;
      if (countryCode == 'DE') {
        try {
          areas = await DwdAreas.load();
        } on Object {
          areas = null;
        }
      }
      newsworthy.addAll(
        await _ingest.ingestMeteoAlarm(
          warnings,
          countryCode: countryCode,
          areas: areas,
        ),
      );
    }

    // MeteoAlarm carries its own expiry, so those rows age out on their
    // own; this only keeps the table from growing without bound.
    await _db.pruneExpiredWarnings();
    await const WarningPollStatusStore().record(complete: complete);

    return WarningPollResult(
      fetched: fetched,
      newsworthy: newsworthy,
      retired: retired,
      complete: complete,
    );
  }

  /// BBK's map feed is deliberately small. Fetch full CAP payloads only for
  /// new or changed warnings; unchanged rows already carry their cached text.
  /// Four workers keep a weather event with many notices from serialising a
  /// refresh without opening an unbounded number of sockets.
  Future<List<BbkRawWarning>> _detailsForChanged(
    List<BbkRawWarning> warnings,
  ) async {
    // Loaded once, before the workers start. Asked inside the loop this was
    // one query per warning, and the ingest below then asked the same
    // question again for every one of them.
    final stored = await _db.warningsBySource(WarningSource.bbk.name);
    final result = List<BbkRawWarning>.from(warnings);
    var next = 0;
    Future<void> worker() async {
      while (next < warnings.length) {
        final at = next++;
        final warning = warnings[at];
        final existing = stored[warning.id];
        final sent = DateTime.tryParse(warning.startDate)?.toUtc();
        final changed =
            existing == null || (sent != null && sent.isAfter(existing.sent));
        if (changed) result[at] = await _bbk.fetchDetails(warning);
      }
    }

    await Future.wait(
      List.generate(warnings.length.clamp(0, 4), (_) => worker()),
    );
    return result;
  }

  /// The subset of [candidates] that should actually produce a
  /// notification: severe enough, not already expired, and not already
  /// announced.
  ///
  /// Reads the stored rows rather than trusting the caller's list, so a
  /// crash between polling and notifying cannot lose an announcement — the
  /// `notified` flag is the record, not the in-memory list.
  Future<List<Warning>> pendingNotifications({
    required bool Function(Warning) isRelevant,
  }) async {
    final now = DateTime.now().toUtc();
    final floor = warningSeverityRank(notifySeverityFloor);

    return [
      for (final warning in await _db.unnotifiedWarnings())
        if (warningSeverityRank(warningSeverityFromName(warning.severity)) >=
                floor &&
            !(warning.expires?.isBefore(now) ?? false) &&
            isRelevant(warning))
          warning,
    ];
  }

  Future<void> markNotified(List<Warning> warnings) {
    return _db.markWarningsNotified([
      for (final warning in warnings)
        (source: warning.source, externalId: warning.externalId),
    ]);
  }
}

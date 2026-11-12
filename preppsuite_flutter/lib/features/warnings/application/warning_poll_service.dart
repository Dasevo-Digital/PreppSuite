import '../../../core/error_log.dart';
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

  /// Warnings ended because they dropped out of the feed that listed them.
  ///
  /// The nationwide list retires only when it was read whole, and a
  /// district's warnings only when its dashboard answered (#369, #371). So
  /// a poll can retire nationwide warnings and still not be [complete],
  /// because a district did not answer.
  final int retired;

  /// False when at least one source could not be read. What that source
  /// listed is not retired.
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
    this.detailBudget = const Duration(seconds: 80),
  }) : _db = database,
       _bbk = bbkClient ?? BbkClient(),
       _meteoAlarm = meteoAlarmClient ?? MeteoAlarmClient();

  final Duration detailBudget;
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
    Iterable<String> extraKreisSchluessel = const [],
  }) async {
    final clock = Stopwatch()..start();
    final newsworthy = <NotifiableWarning>[];
    var fetched = 0;
    var retired = 0;
    var complete = true;
    // Per feed, for the status: whether each one asked answered in full.
    final sourcesOk = <String, bool>{};

    // Loaded once for the whole poll and shared by both feeds. Only
    // Germany has a table to place areas with; a table that will not load
    // must not cost the warnings themselves — without it they simply
    // concern the whole country.
    DwdAreas? areas;
    if (countryCode == 'DE') {
      try {
        areas = await DwdAreas.load();
      } on Object {
        areas = null;
      }
    }

    if (countryCode == 'DE') {
      // One BBK source that cannot be read must not cost MeteoAlarm, which
      // comes after (#369). The poll used to end here with the error, and
      // the weather warnings of that poll were never asked for.
      try {
        final nationwide = await _bbk.fetchAll();
        final detailedNationwide = await _detailsForChanged(
          nationwide.warnings,
          clock: clock,
        );
        complete = nationwide.complete;
        sourcesOk['bbk'] = nationwide.complete;
        // Whether absence from this poll may end a stored warning. Not the
        // same as [complete]: a district dashboard that did not answer
        // makes the poll incomplete, but its own warnings are kept by
        // [unanswered], and the nationwide ones may still end (#371).
        var mayRetire = nationwide.complete;
        fetched += nationwide.warnings.length;
        newsworthy.addAll(
          await _ingest.ingestBbk(
            detailedNationwide,
            countryCode: 'DE',
            areas: areas,
          ),
        );

        final seen = {for (final w in nationwide.warnings) w.id};
        // Districts whose dashboard did not answer this time, or not in
        // full. What only their dashboard knows is not in [seen], and is
        // not over (#250).
        final unanswered = <String>{};

        final districts = <String>{
          if (kreisSchluessel != null && kreisSchluessel.length >= 5)
            kreisSchluessel.substring(0, 5),
          for (final extra in extraKreisSchluessel)
            if (extra.length >= 5) extra.substring(0, 5),
        };
        for (final district in districts) {
          // Reserve time for the independent weather source. Optional
          // details must not keep a refresh occupied for an unbounded
          // number of calls.
          if (clock.elapsed >= detailBudget) {
            // A district-only warning may still be active. Without this
            // requested dashboard, absence from the national feed proves
            // nothing.
            complete = false;
            sourcesOk['bbk'] = false;
            mayRetire = false;
            break;
          }
          // A precise dashboard is an enhancement over the nationwide feed.
          // One offline "Meine Orte" entry must not cancel all current
          // alerts.
          try {
            final dashboard = await _bbk.fetchDashboard(district);
            final precise = await _detailsForChanged(
              dashboard.warnings,
              clock: clock,
            );
            fetched += precise.length;
            newsworthy.addAll(
              await _ingest.ingestBbk(
                precise,
                countryCode: 'DE',
                regionKeyOverride: district,
              ),
            );
            // Folded in so a warning only the per-Kreis endpoint knows
            // about is not retired by the sweep below.
            seen.addAll(precise.map((w) => w.id));
            if (!dashboard.complete) {
              unanswered.add(district);
              complete = false;
              sourcesOk['bbk'] = false;
            }
          } on Object {
            // The nationwide feed was complete. A failed optional district
            // lookup must not keep unrelated, retired nationwide warnings
            // -- nor end the ones it alone reported (#250). But the poll
            // did not get everything, and the status says so: it counted
            // as complete, and "updated" stood over a district whose
            // warnings had not been asked (#371).
            unanswered.add(district);
            complete = false;
            sourcesOk['bbk'] = false;
          }
        }

        // Only when every source answered. An incomplete picture would end
        // warnings that are still running — see [BbkFetchResult.complete].
        if (mayRetire) {
          retired += await _db.expireMissingWarnings(
            source: WarningSource.bbk.name,
            seenExternalIds: seen,
            keepRegionKeys: unanswered,
          );
        }
      } on Object catch (error, stack) {
        complete = false;
        sourcesOk['bbk'] = false;
        ErrorLog.instance.record(error, stack, context: 'BBK-Abruf');
      }
    }

    final slug = meteoAlarmCountrySlugs[countryCode];
    if (slug != null) {
      // Asked last, after BBK is already stored. A feed that times out or
      // arrives cut off used to throw out of the whole poll, which then
      // counted as failed and recorded no status although every German
      // warning had arrived (#46). It makes the picture incomplete, no
      // more.
      try {
        final feed = await _meteoAlarm.fetchCountry(
          slug,
          knownStamp: await _knownStamp(slug, countryCode),
        );
        final warnings = feed.warnings;
        if (warnings != null) {
          fetched += warnings.length;
          newsworthy.addAll(
            await _ingest.ingestMeteoAlarm(
              warnings,
              countryCode: countryCode,
              areas: areas,
            ),
          );
          // After storing, so a run that fails in between reads it again.
          await const WarningPollStatusStore().saveFeedStamp(slug, feed.stamp);
        }
        // A feed that said it has not changed has answered in full, and
        // nothing is missing: MeteoAlarm's rows end by their own expiry,
        // not by dropping out of the feed.
        sourcesOk['meteoalarm'] = true;
      } on Object {
        complete = false;
        sourcesOk['meteoalarm'] = false;
      }
    }

    // MeteoAlarm carries its own expiry, so those rows age out on their
    // own; this only keeps the table from growing without bound.
    await _db.pruneExpiredWarnings();
    await const WarningPollStatusStore().record(
      complete: complete,
      sourcesOk: sourcesOk,
    );

    return WarningPollResult(
      fetched: fetched,
      newsworthy: newsworthy,
      retired: retired,
      complete: complete,
    );
  }

  /// The stamp the feed may be compared with, or null to read it in full.
  ///
  /// Null with nothing stored for this country: after the data was deleted
  /// or a backup came back, the stamp still says these warnings are here.
  /// A country that really has none has a feed of a few kilobytes.
  Future<String?> _knownStamp(String slug, String countryCode) async {
    final stored = await _db.hasWarnings(
      source: WarningSource.meteoalarm.name,
      countryCode: countryCode,
    );
    return stored ? const WarningPollStatusStore().feedStamp(slug) : null;
  }

  /// How many stored warnings without a detail one pass asks again for:
  /// the nationwide feed and each district dashboard are a pass each.
  ///
  /// Every source has a detail behind every warning (all six checked live
  /// on 2026-10-17), so a row without one is a request that failed, and
  /// asking again repairs it. The cap is for the case that proves this
  /// wrong: a source that stops serving details must cost a few requests
  /// a poll, not three hundred every fifteen minutes.
  static const detailRetriesPerPoll = 12;

  /// How many stored warnings without their translations one pass reads
  /// again, after the missing details (#357); a pass as for
  /// [detailRetriesPerPoll].
  static const translationRetriesPerPoll = 12;

  /// BBK's map feed is deliberately small. Fetch full CAP payloads only for
  /// new or changed warnings, and for stored ones that never got theirs;
  /// the rest already carry their cached text. Four workers keep a weather
  /// event with many notices from serialising a refresh without opening an
  /// unbounded number of sockets.
  Future<List<BbkRawWarning>> _detailsForChanged(
    List<BbkRawWarning> warnings, {
    required Stopwatch clock,
  }) async {
    // Loaded once, before the workers start. Asked inside the loop this was
    // one query per warning, and the ingest below then asked the same
    // question again for every one of them.
    final stored = await _db.warningsBySource(WarningSource.bbk.name);
    final result = List<BbkRawWarning>.from(warnings);

    // In this order, because the time is limited: what is new or changed,
    // then a detail that never arrived, and only then the translations of
    // a warning stored before they were kept (#357). Those run for weeks
    // and would otherwise stay German until they end, but they shared one
    // count with the missing details, and a warning without its text
    // waited behind them.
    final changed = <int>[];
    final missingDetail = <int>[];
    final missingTranslations = <int>[];
    for (var at = 0; at < warnings.length; at++) {
      final warning = warnings[at];
      final existing = stored[warning.id];
      final sent = DateTime.tryParse(warning.startDate)?.toUtc();
      if (existing == null || (sent != null && sent.isAfter(existing.sent))) {
        changed.add(at);
      } else if (lacksBbkDetail(existing)) {
        missingDetail.add(at);
      } else if (existing.translationsJson == null) {
        missingTranslations.add(at);
      }
    }
    final planned = [
      ...changed,
      ...missingDetail.take(detailRetriesPerPoll),
      ...missingTranslations.take(translationRetriesPerPoll),
    ];

    var next = 0;
    Future<void> worker() async {
      while (next < planned.length && clock.elapsed < detailBudget) {
        final at = planned[next++];
        result[at] = await _bbk.fetchDetails(warnings[at]);
      }
    }

    await Future.wait(
      List.generate(planned.length.clamp(0, 4), (_) => worker()),
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
    return _db.markWarningsNotified(warnings);
  }
}

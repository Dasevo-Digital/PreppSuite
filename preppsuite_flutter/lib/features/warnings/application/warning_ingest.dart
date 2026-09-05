import 'package:drift/drift.dart';
import 'package:preppsuite_client/preppsuite_client.dart'
    show WarningSeverity, WarningSource;

import '../../../local_db/database.dart';
import 'bbk_client.dart';
import '../../household/application/german_states.dart';
import 'meteoalarm_client.dart';
import 'warning_severity_l10n.dart';

/// A warning worth telling the user about, with the reason it qualified.
typedef NotifiableWarning = ({String source, String externalId});

/// Maps both feeds' structurally different payloads onto the local
/// `warnings` table, deduplicating by `(source, externalId)`.
///
/// Ported from the server's `WarningNormalizer` when the app took over
/// fetching. The rule it exists to enforce is unchanged and is the reason
/// this is not just an insert: an existing row is only rewritten when the
/// source's `sent` timestamp actually moved, so re-polling an unchanged
/// warning is a no-op instead of churn that would look like news.
class WarningIngest {
  const WarningIngest(this._db);

  final AppDatabase _db;

  /// Upserts [warnings] and returns the ones worth notifying about.
  Future<List<NotifiableWarning>> ingestBbk(
    List<BbkRawWarning> warnings, {
    required String countryCode,

    /// Set when these came from a precise per-Kreis fetch, in which case
    /// the Kreisschlüssel is a better `regionKey` than the state code
    /// guessed from the warning id.
    String? regionKeyOverride,
  }) async {
    final notifiable = <NotifiableWarning>[];

    for (final warning in warnings) {
      final result = await _upsert(
        source: WarningSource.bbk,
        externalId: warning.id,
        countryCode: countryCode,
        regionKey: regionKeyOverride ?? bbkRegionFromId(warning.id),
        severity: _parseSeverity(warning.severity),
        eventType: warning.eventTitleDe,
        headline: warning.eventTitleDe,
        description: null,
        effective: _parseDateTime(warning.startDate) ?? DateTime.now().toUtc(),
        expires: null,
        sent: _parseDateTime(warning.startDate) ?? DateTime.now().toUtc(),
      );
      if (result != null) notifiable.add(result);
    }

    return notifiable;
  }

  Future<List<NotifiableWarning>> ingestMeteoAlarm(
    List<MeteoAlarmRawWarning> warnings, {
    required String countryCode,
  }) async {
    final notifiable = <NotifiableWarning>[];

    for (final warning in warnings) {
      if (warning.identifier.isEmpty) continue;

      final sent = _parseDateTime(warning.sent);
      if (sent == null) continue;

      final result = await _upsert(
        source: WarningSource.meteoalarm,
        externalId: warning.identifier,
        countryCode: countryCode,
        regionKey: warning.areaDesc.isEmpty ? null : warning.areaDesc,
        severity: _parseSeverity(warning.severity),
        eventType: warning.event,
        headline: warning.title,
        description: warning.areaDesc.isEmpty ? null : warning.areaDesc,
        effective: _parseDateTime(warning.onset) ?? sent,
        expires: _parseDateTime(warning.expires),
        sent: sent,
      );
      if (result != null) notifiable.add(result);
    }

    return notifiable;
  }

  /// Writes one warning and reports whether it is newsworthy.
  ///
  /// Newsworthy means new, or escalated to a higher severity. The sources
  /// reissue warnings constantly with corrected wording or a shifted end
  /// time; announcing every one of those is how a warning channel gets
  /// muted, which is the one thing it cannot survive.
  Future<NotifiableWarning?> _upsert({
    required WarningSource source,
    required String externalId,
    required String countryCode,
    required String? regionKey,
    required WarningSeverity severity,
    required String eventType,
    required String headline,
    required String? description,
    required DateTime effective,
    required DateTime? expires,
    required DateTime sent,
  }) async {
    final existing = await _db.findWarning(source.name, externalId);

    if (existing != null && !sent.isAfter(existing.sent)) return null;

    final escalated =
        existing != null &&
        warningSeverityRank(severity) >
            warningSeverityRank(warningSeverityFromName(existing.severity));

    final newsworthy = existing == null || escalated;
    final wasAnnounced = existing?.notified ?? false;

    await _db.upsertWarning(
      WarningsCompanion.insert(
        source: source.name,
        externalId: externalId,
        countryCode: countryCode,
        regionKey: Value(regionKey),
        severity: severity.name,
        eventType: eventType,
        headline: headline,
        description: Value(description),
        effective: effective,
        expires: Value(expires),
        sent: sent,
        updatedAt: DateTime.now().toUtc(),
        // Re-arms the announcement only when there is something new to
        // announce; an unchanged row keeps whatever it had.
        notified: Value(!newsworthy && wasAnnounced),
      ),
    );

    return newsworthy ? (source: source.name, externalId: externalId) : null;
  }

  WarningSeverity _parseSeverity(String value) {
    return WarningSeverity.values.asNameMap()[value.toLowerCase()] ??
        WarningSeverity.minor;
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }
}

/// BBK ids embed a state code, but not in one shape — the sources use two,
/// both confirmed against the live feeds:
///
/// - `mowas`/`dwd`: `mow.DE-HE-KS-SE106-...` → `HE` (Hesse)
/// - `lhp`/`police`: `lhp.LHP.NW.nw86768` → `NW` (North Rhine-Westphalia)
///
/// The second shape is only accepted when the two letters are actually a
/// known state code. Without that check any dot-separated pair of capitals
/// would be read as a region, and a wrong `regionKey` is worse than none:
/// none means "show it to everyone", while a wrong one hides the warning
/// from the households it concerns.
String? bbkRegionFromId(String id) {
  final withCountry = RegExp(r'DE-([A-Z]{2})-').firstMatch(id);
  if (withCountry != null) return withCountry.group(1);

  for (final match in RegExp(r'\.([A-Z]{2})\.').allMatches(id)) {
    final code = match.group(1)!;
    if (germanStateByBbkCode(code) != null) return code;
  }
  return null;
}

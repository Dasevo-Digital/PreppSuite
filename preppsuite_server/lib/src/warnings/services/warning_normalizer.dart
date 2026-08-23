import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'bbk_client.dart';
import 'german_states.dart';
import 'meteoalarm_client.dart';

/// Maps both sources' structurally different raw payloads onto the
/// canonical [Warning] model and upserts them, deduplicating by
/// `(source, externalId)`. An existing row is only touched if the source's
/// `sent` timestamp actually changed, so re-polling an unchanged warning is
/// a no-op (no needless `updatedAt` churn for clients pulling deltas).
class WarningNormalizer {
  const WarningNormalizer();

  Future<void> upsertBbk(
    Session session,
    List<BbkRawWarning> warnings, {
    required String countryCode,

    /// When set (precise per-Kreis polling via `BbkClient.fetchDashboard`),
    /// used as every warning's `regionKey` instead of the coarser
    /// state-code guess parsed from the warning id. Null for the nationwide
    /// `fetchAll()` poll, where the id-based guess is all we have.
    String? regionKeyOverride,
  }) async {
    for (final warning in warnings) {
      await _upsert(
        session,
        source: WarningSource.bbk,
        externalId: warning.id,
        countryCode: countryCode,
        regionKey: regionKeyOverride ?? _bbkRegionFromId(warning.id),
        severity: _parseSeverity(warning.severity),
        eventType: warning.eventTitleDe,
        headline: warning.eventTitleDe,
        description: null,
        effective: _parseDateTime(warning.startDate) ?? DateTime.now().toUtc(),
        expires: null,
        sent: _parseDateTime(warning.startDate) ?? DateTime.now().toUtc(),
        rawPayload: jsonEncode(warning.raw),
      );
    }
  }

  /// Ends BBK warnings that the source no longer lists.
  ///
  /// No BBK endpoint carries an expiry — neither `mapData.json` nor the
  /// per-Kreis dashboard (whose `valid` field is a boolean, not a date), so
  /// a warning stays "active" forever unless something retires it. What the
  /// feed does say is which warnings are current, so a warning that has
  /// dropped out of a *complete* poll is over, and gets `expires` stamped
  /// at the moment we noticed.
  ///
  /// Only ever called with the union of every source's ids from a poll
  /// where all of them answered — see [BbkFetchResult.complete]. Rows that
  /// already carry an `expires` are left alone, so the timestamp records
  /// when the warning ended rather than creeping forward on each poll.
  ///
  /// Returns how many warnings were retired.
  Future<int> expireMissingBbk(
    Session session, {
    required Set<String> seenExternalIds,
    required String countryCode,
  }) async {
    final active = await Warning.db.find(
      session,
      where: (t) =>
          t.source.equals(WarningSource.bbk) &
          t.countryCode.equals(countryCode) &
          t.expires.equals(null),
    );

    final now = DateTime.now().toUtc();
    var retired = 0;

    for (final warning in active) {
      if (seenExternalIds.contains(warning.externalId)) continue;

      warning
        ..expires = now
        ..updatedAt = now;
      await Warning.db.updateRow(session, warning);
      retired++;
    }

    return retired;
  }

  Future<void> upsertMeteoAlarm(
    Session session,
    List<MeteoAlarmRawWarning> warnings, {
    required String countryCode,
  }) async {
    for (final warning in warnings) {
      if (warning.identifier.isEmpty) continue;

      final sent = _parseDateTime(warning.sent);
      if (sent == null) continue;

      await _upsert(
        session,
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
        rawPayload: jsonEncode(warning.raw),
      );
    }
  }

  Future<void> _upsert(
    Session session, {
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
    required String rawPayload,
  }) async {
    final existing = await Warning.db.findFirstRow(
      session,
      where: (t) => t.source.equals(source) & t.externalId.equals(externalId),
    );

    if (existing != null && !sent.isAfter(existing.sent)) return;

    if (existing == null) {
      await Warning.db.insertRow(
        session,
        Warning(
          source: source,
          externalId: externalId,
          countryCode: countryCode,
          regionKey: regionKey,
          severity: severity,
          eventType: eventType,
          headline: headline,
          description: description,
          effective: effective,
          expires: expires,
          sent: sent,
          rawPayload: rawPayload,
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      return;
    }

    existing
      ..regionKey = regionKey
      ..severity = severity
      ..eventType = eventType
      ..headline = headline
      ..description = description
      ..effective = effective
      ..expires = expires
      ..sent = sent
      ..rawPayload = rawPayload
      ..updatedAt = DateTime.now().toUtc();
    await Warning.db.updateRow(session, existing);
  }

  WarningSeverity _parseSeverity(String value) {
    return WarningSeverity.values.asNameMap()[value.toLowerCase()] ??
        WarningSeverity.minor;
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  /// BBK ids embed a state code, but not in one shape — the sources use
  /// two, both confirmed against the live feeds:
  ///
  /// - `mowas`/`dwd`: `mow.DE-HE-KS-SE106-...` → `HE` (Hesse)
  /// - `lhp`/`police`: `lhp.LHP.NW.nw86768` → `NW` (North Rhine-Westphalia)
  ///
  /// The second shape is only accepted when the two letters are actually a
  /// known state code. Without that check any dot-separated pair of capitals
  /// would be read as a region, and a wrong `regionKey` is worse than none:
  /// none means "show it to everyone" (see `isWarningRelevant`), while a
  /// wrong one hides the warning from the households it concerns.
  String? _bbkRegionFromId(String id) {
    final withCountry = RegExp(r'DE-([A-Z]{2})-').firstMatch(id);
    if (withCountry != null) return withCountry.group(1);

    for (final match in RegExp(r'\.([A-Z]{2})\.').allMatches(id)) {
      final code = match.group(1)!;
      if (germanStateByBbkCode(code) != null) return code;
    }
    return null;
  }
}

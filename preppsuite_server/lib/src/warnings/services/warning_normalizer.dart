import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'bbk_client.dart';
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
  }) async {
    for (final warning in warnings) {
      await _upsert(
        session,
        source: WarningSource.bbk,
        externalId: warning.id,
        countryCode: countryCode,
        regionKey: _bbkRegionFromId(warning.id),
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

  /// BBK ids embed a state code, e.g. `mow.DE-HE-KS-...` → `HE` (Hesse).
  /// Best-effort/informational only.
  String? _bbkRegionFromId(String id) {
    final match = RegExp(r'DE-([A-Z]{2})-').firstMatch(id);
    return match?.group(1);
  }
}

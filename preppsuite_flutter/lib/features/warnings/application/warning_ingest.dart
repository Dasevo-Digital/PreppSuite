import 'dart:convert';

import 'package:drift/drift.dart';
import '../../../model/categories.dart';

import '../../../local_db/database.dart';
import 'bbk_client.dart';
import '../../household/application/german_states.dart';
import 'dwd_areas.dart';
import 'meteoalarm_client.dart';
import 'warning_severity_l10n.dart';

/// A warning worth telling the user about, with the reason it qualified.
typedef NotifiableWarning = ({String source, String externalId});

/// One row ready to write, and whether it is worth announcing.
typedef _Prepared = ({
  bool newsworthy,
  WarningsCompanion row,
  NotifiableWarning key,
});

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

    /// Last resort for the warnings whose id names no state — KATWARN's
    /// do not. See [_bbkRegionKey].
    DwdAreas? areas,
  }) async {
    // One query for the whole source, instead of one per warning inside the
    // loop below. See [AppDatabase.warningsBySource].
    final existing = await _db.warningsBySource(WarningSource.bbk.name);
    final notifiable = <NotifiableWarning>[];
    final rows = <WarningsCompanion>[];

    for (final warning in warnings) {
      final result = _prepare(
        existing: existing[warning.id],
        source: WarningSource.bbk,
        externalId: warning.id,
        countryCode: countryCode,
        regionKey: _bbkRegionKey(
          warning,
          override: regionKeyOverride,
          areas: areas,
        ),
        severity: _parseSeverity(warning.severity),
        eventType: warning.eventTitleDe,
        headline: warning.eventTitleDe,
        description: warning.description,
        instruction: warning.instruction,
        areaDescription: warning.areaDescription,
        senderContact: warning.senderContact,
        polygonsJson: warning.polygons.isEmpty
            ? null
            : jsonEncode(warning.polygons),
        effective: _parseDateTime(warning.startDate) ?? DateTime.now().toUtc(),
        expires: null,
        sent: _parseDateTime(warning.startDate) ?? DateTime.now().toUtc(),
      );
      if (result == null) continue;
      rows.add(result.row);
      if (result.newsworthy) notifiable.add(result.key);
    }

    // One transaction for the whole feed rather than one per warning.
    await _db.upsertWarnings(rows);
    return notifiable;
  }

  /// [areas] turns MeteoAlarm's area names into keys the region filter
  /// can match. Only Germany has one; elsewhere the names stay unplaced
  /// and the warnings count for the whole country, which is what they did
  /// before and is the safe reading.
  Future<List<NotifiableWarning>> ingestMeteoAlarm(
    List<MeteoAlarmRawWarning> warnings, {
    required String countryCode,
    DwdAreas? areas,
  }) async {
    final existing = await _db.warningsBySource(
      WarningSource.meteoalarm.name,
    );
    final notifiable = <NotifiableWarning>[];
    final rows = <WarningsCompanion>[];

    for (final warning in warnings) {
      if (warning.identifier.isEmpty) continue;

      final sent = _parseDateTime(warning.sent);
      if (sent == null) continue;

      final result = _prepare(
        existing: existing[warning.identifier],
        source: WarningSource.meteoalarm,
        externalId: warning.identifier,
        countryCode: countryCode,
        // Never the area description itself. It is words, and the
        // region filter compares keys — a key it cannot match does not
        // read as "somewhere else", it reads as nowhere, and the warning
        // is dropped. Measured against a live feed: 121 severe-weather
        // warnings, not one of which reached a household that had set a
        // region. Null instead means "concerns everyone", which is the
        // safe reading for a warning that cannot be placed.
        regionKey: warning.areaDesc.isEmpty
            ? null
            : areas?.regionKeyFor(warning.areaDesc),
        severity: _parseSeverity(warning.severity),
        eventType: warning.event,
        headline: warning.title,
        description: warning.areaDesc.isEmpty ? null : warning.areaDesc,
        instruction: null,
        areaDescription: warning.areaDesc.isEmpty ? null : warning.areaDesc,
        senderContact: null,
        polygonsJson: null,
        effective: _parseDateTime(warning.onset) ?? sent,
        expires: _parseDateTime(warning.expires),
        sent: sent,
      );
      if (result == null) continue;
      rows.add(result.row);
      if (result.newsworthy) notifiable.add(result.key);
    }

    // One transaction for the whole feed rather than one per warning.
    await _db.upsertWarnings(rows);
    return notifiable;
  }

  /// Prepares one warning's row and reports whether it is newsworthy.
  ///
  /// Newsworthy means new, or escalated to a higher severity. The sources
  /// reissue warnings constantly with corrected wording or a shifted end
  /// time; announcing every one of those is how a warning channel gets
  /// muted, which is the one thing it cannot survive.
  ///
  /// [existing] is passed in rather than looked up: the caller has already
  /// loaded every row of this source in one query, and this used to repeat
  /// that lookup per warning. Returns null when there is nothing to write.
  _Prepared? _prepare({
    required Warning? existing,
    required WarningSource source,
    required String externalId,
    required String countryCode,
    required String? regionKey,
    required WarningSeverity severity,
    required String eventType,
    required String headline,
    required String? description,
    required String? instruction,
    required String? areaDescription,
    required String? senderContact,
    required String? polygonsJson,
    required DateTime effective,
    required DateTime? expires,
    required DateTime sent,
  }) {
    if (existing != null && !sent.isAfter(existing.sent)) {
      // One exception to "unchanged is a no-op": a row that could not be
      // placed when it arrived and can be placed now. That happens when
      // this app learns a new way to read a region out of a warning --
      // and without it, the warnings already on screen keep the reading
      // that put them there, which for an unplaced warning is "concerns
      // everyone". Narrowing only, never a change to a key we already
      // have, and it is not newsworthy: nobody is notified twice because
      // the app got better at geography.
      //
      // The same holds for a Land narrowed to one of its districts (#11).
      // The nationwide feed knows most warnings only by the Land in their
      // id; the household's own district dashboard, polled after it, says
      // the same warning is for this district. Without this the district
      // never arrived, and a warning here could not be told from one at
      // the other end of the Land.
      if (!_narrows(existing.regionKey, regionKey)) return null;
    }

    final escalated =
        existing != null &&
        warningSeverityRank(severity) >
            warningSeverityRank(warningSeverityFromName(existing.severity));

    final newsworthy = existing == null || escalated;
    final wasAnnounced = existing?.notified ?? false;

    return (
      newsworthy: newsworthy,
      row: WarningsCompanion.insert(
        source: source.name,
        externalId: externalId,
        countryCode: countryCode,
        regionKey: Value(regionKey),
        severity: severity.name,
        eventType: eventType,
        headline: headline,
        description: Value(description),
        instruction: Value(instruction),
        areaDescription: Value(areaDescription),
        senderContact: Value(senderContact),
        polygonsJson: Value(polygonsJson),
        effective: effective,
        expires: Value(expires),
        sent: sent,
        updatedAt: DateTime.now().toUtc(),
        // Re-arms the announcement only when there is something new to
        // announce; an unchanged row keeps whatever it had.
        notified: Value(!newsworthy && wasAnnounced),
      ),
      key: (source: source.name, externalId: externalId),
    );
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

/// Where a BBK warning applies, best effort, in order of trust.
///
/// 1. A precise per-Kreis fetch, where the district is known outright.
/// 2. The state in the warning's own id, which is most sources.
/// 3. The one state its area description unanimously names.
/// 4. The one state the authority that issued it sits in.
///
/// Steps three and four exist because of KATWARN: its ids carry no state
/// at all (`kat.6aa2cd02995efd5eae120ffb_public_topics`), so an
/// earthquake near Worms came out unplaced — and unplaced means
/// "concerns everyone", which put it in front of a household in
/// Braunschweig. Both only ever yield a state, never a district: see
/// [DwdAreas.stateForAreaNames] for why narrowing further would be
/// dangerous.
///
/// The fourth step was added after a drinking-water alert for Lauterbach
/// in Hesse reached the same household in Lower Saxony. Its area
/// description is "Teile von Lauterbach", and that genuinely cannot be
/// placed: the warncell table holds a Lauterbach in Baden-Wurttemberg
/// and one in Thuringia, and the Hessian one is filed under
/// "Stadt Lauterbach (Hessen)", so the bare name matches neither
/// unanimously nor at all. What the warning does say is who sent it —
/// "Vogelsbergkreis meldet: ..." — and that name is in the table exactly
/// once.
///
/// Asking who warned rather than where is a weaker statement, which is
/// why it is tried last: an authority warns about its own area, but the
/// title is the only place that says so.
String? _bbkRegionKey(
  BbkRawWarning warning, {
  required String? override,
  required DwdAreas? areas,
}) {
  if (override != null) return override;

  final fromId = bbkRegionFromId(warning.id);
  if (fromId != null) return fromId;

  if (areas == null) return null;

  final description = warning.areaDescription;
  if (description != null) {
    final fromArea = areas.stateForAreaNames(description);
    if (fromArea != null) return fromArea;
  }

  final issuer = bbkIssuerFromTitle(warning.eventTitleDe);
  if (issuer == null) return null;
  return areas.stateForAreaNames(issuer);
}

/// The authority a KATWARN title names, or null.
///
/// KATWARN titles reaching the BBK feed are machine-built to one shape:
/// `<Absender> meldet: <Warnung>`. Confirmed on the live feed against
/// both an authority that is a district ("Vogelsbergkreis meldet: Warnung
/// Trinkwasserunfall") and one that is not ("Erdbebendienst Sudwest
/// meldet: Schwaches Erdbeben ... bei Worms"). The second is the reason
/// the name is looked up rather than trusted: a seismic service is not a
/// place, finds nothing in the warncell table, and correctly leaves the
/// warning where it was.
///
/// Titles from every other source do not carry the word at all, so they
/// fall out here rather than needing to be excluded by source.
String? bbkIssuerFromTitle(String title) {
  final match = RegExp(r'^(.{3,80}?)\s+meldet:').firstMatch(title);
  final issuer = match?.group(1)?.trim();
  return issuer == null || issuer.isEmpty ? null : issuer;
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

/// Whether [next] says more precisely where a warning applies than
/// [stored]: a key where there was none, or a district of the Land that
/// was stored.
bool _narrows(String? stored, String? next) {
  if (next == null) return false;
  if (stored == null) return true;
  final land = germanStateByBbkCode(stored);
  return land != null &&
      next.length >= 5 &&
      next.startsWith(land.arsPrefix) &&
      germanStateByBbkCode(next) == null;
}

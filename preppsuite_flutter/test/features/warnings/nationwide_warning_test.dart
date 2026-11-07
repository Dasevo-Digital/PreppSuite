import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_ingest.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_relevance.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// A warning's id names who sent it, not where it applies (#307).
///
/// The record of the warning day in 2025 is the case these are built on:
/// the federal office sends from Bonn, so its id reads as North
/// Rhine-Westphalia, and every household with a district elsewhere had a
/// nationwide alert as somebody else's business.
void main() {
  const warningDay = BbkRawWarning(
    id: 'mow.DE-NW-BN-SE030-20250911-30-001',
    startDate: '2025-09-11T11:00:01+02:00',
    severity: 'Extreme',
    eventTitleDe: 'Bundesweiter Warntag 2025 - Probewarnung - Deutschland',
    raw: {},
  );
  final withDetails = warningDay.withDetails(
    description: 'Probewarnung',
    areaDescription: 'Deutschland',
  );

  // Braunschweig, in Lower Saxony.
  const household = WarningRegionFilter(
    countryCode: 'DE',
    ownRegionKey: '03101',
  );

  late AppDatabase db;
  late WarningIngest ingest;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ingest = WarningIngest(db);
  });
  tearDown(() => db.close());

  Future<Warning> stored() async =>
      (await db.warningsBySource('bbk')).values.single;

  test('reaches a household in another Land', () async {
    await ingest.ingestBbk([withDetails], countryCode: 'DE');

    final warning = await stored();
    expect(warning.regionKey, isNull);
    expect(
      warningRelevance(warning: warning, filter: household),
      WarningRelevance.nationwide,
    );
    expect(isWarningRelevant(warning: warning, filter: household), isTrue);
    expect(
      bannerWarnings(
        warnings: [warning],
        filter: household,
        now: DateTime.utc(2025, 9, 11, 10),
      ),
      hasLength(1),
    );
  });

  test('stays everyone\'s when a district dashboard lists it', () async {
    await ingest.ingestBbk([withDetails], countryCode: 'DE');
    await ingest.ingestBbk(
      [warningDay],
      countryCode: 'DE',
      regionKeyOverride: '03101',
    );

    expect((await stored()).regionKey, isNull);
  });

  test('a detail that failed once still comes to the right place', () async {
    // No area yet: the id's Land, then the household's own district.
    await ingest.ingestBbk([warningDay], countryCode: 'DE');
    expect((await stored()).regionKey, 'NW');
    await ingest.ingestBbk(
      [warningDay],
      countryCode: 'DE',
      regionKeyOverride: '03101',
    );
    expect((await stored()).regionKey, '03101');

    // The next poll asks for the detail again and learns what it is.
    await ingest.ingestBbk([withDetails], countryCode: 'DE');
    expect((await stored()).regionKey, isNull);
  });

  group('one stored by an earlier version under the Land of its id', () {
    Future<void> storeAsBefore({required bool notified}) => db.upsertWarnings([
      WarningsCompanion.insert(
        source: 'bbk',
        externalId: warningDay.id,
        countryCode: 'DE',
        regionKey: const Value('NW'),
        severity: 'extreme',
        eventType: warningDay.eventTitleDe,
        headline: warningDay.eventTitleDe,
        areaDescription: const Value('Deutschland'),
        effective: DateTime.utc(2025, 9, 11, 9),
        sent: DateTime.utc(2025, 9, 11, 9, 0, 1),
        updatedAt: DateTime.utc(2025, 9, 11, 9),
        notified: Value(notified),
      ),
    ]);

    test('is widened, and still has its announcement to come', () async {
      await storeAsBefore(notified: false);

      await ingest.ingestBbk([warningDay], countryCode: 'DE');

      final warning = await stored();
      expect(warning.regionKey, isNull);
      expect(warning.notified, isFalse);
      expect(await db.unnotifiedWarnings(), hasLength(1));
    });

    test('is not announced a second time', () async {
      await storeAsBefore(notified: true);

      final notifiable = await ingest.ingestBbk([
        warningDay,
      ], countryCode: 'DE');

      final warning = await stored();
      expect(warning.regionKey, isNull);
      expect(warning.notified, isTrue);
      expect(notifiable, isEmpty);
    });
  });

  test('a warning across a border reaches the district it covers', () async {
    // Sent in Ulm, in Baden-Wurttemberg; listed on the dashboard of
    // Neu-Ulm, across the river in Bavaria.
    const acrossTheBorder = BbkRawWarning(
      id: 'mow.DE-BW-UL-W001-20261107-001',
      startDate: '2026-11-07T11:00:00+01:00',
      severity: 'Severe',
      eventTitleDe: 'Gefahrstoffaustritt',
      raw: {},
    );
    const neuUlm = WarningRegionFilter(
      countryCode: 'DE',
      ownRegionKey: '09775',
    );

    await ingest.ingestBbk([acrossTheBorder], countryCode: 'DE');
    expect(
      isWarningRelevant(warning: await stored(), filter: neuUlm),
      isFalse,
    );

    await ingest.ingestBbk(
      [acrossTheBorder],
      countryCode: 'DE',
      regionKeyOverride: '09775',
    );

    final warning = await stored();
    expect(
      warningRelevance(warning: warning, filter: neuUlm),
      WarningRelevance.ownDistrict,
    );
    // Not told before, because it was not relevant; the poll does it now.
    expect(warning.notified, isFalse);
  });

  group('bbkAreaIsWholeCountry', () {
    test('knows the names of the whole country', () {
      expect(bbkAreaIsWholeCountry('Deutschland'), isTrue);
      expect(bbkAreaIsWholeCountry(' Bundesrepublik Deutschland '), isTrue);
      expect(bbkAreaIsWholeCountry('Gesamtes Bundesgebiet'), isTrue);
      expect(bbkAreaIsWholeCountry('Kreis Paderborn\nDeutschland'), isTrue);
    });

    test('is not fooled by a place in Germany', () {
      expect(bbkAreaIsWholeCountry(null), isFalse);
      expect(bbkAreaIsWholeCountry(''), isFalse);
      expect(bbkAreaIsWholeCountry('Norddeutschland'), isFalse);
      expect(bbkAreaIsWholeCountry('Teile von Deutschland'), isFalse);
      expect(bbkAreaIsWholeCountry('Stadt Braunschweig'), isFalse);
    });
  });
}

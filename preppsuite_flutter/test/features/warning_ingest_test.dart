import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_ingest.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  late AppDatabase db;
  late WarningIngest ingest;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ingest = WarningIngest(db);
  });
  tearDown(() => db.close());

  BbkRawWarning raw({
    String id = 'mow.DE-HE-MKK-W220-20260811-001',
    String severity = 'Moderate',
    String startDate = '2026-08-11T08:30:54+02:00',
  }) {
    return BbkRawWarning(
      id: id,
      startDate: startDate,
      severity: severity,
      eventTitleDe: 'Testwarnung',
      raw: const {},
    );
  }

  test('a new warning is newsworthy', () async {
    final result = await ingest.ingestBbk([raw()], countryCode: 'DE');

    expect(result, hasLength(1));
  });

  test('the same warning reissued unchanged is not', () async {
    // The feeds republish constantly; announcing every repeat is how a
    // warning channel gets muted.
    await ingest.ingestBbk([raw()], countryCode: 'DE');
    final second = await ingest.ingestBbk([raw()], countryCode: 'DE');

    expect(second, isEmpty);
  });

  test('a rewritten warning at the same severity is not', () async {
    await ingest.ingestBbk([raw()], countryCode: 'DE');
    final second = await ingest.ingestBbk([
      raw(startDate: '2026-08-11T09:30:54+02:00'),
    ], countryCode: 'DE');

    expect(second, isEmpty);
  });

  test(
    'a warning escalating to a higher severity is newsworthy again',
    () async {
      // The one kind of update worth a second notification.
      await ingest.ingestBbk([raw(severity: 'Moderate')], countryCode: 'DE');
      final escalated = await ingest.ingestBbk([
        raw(severity: 'Extreme', startDate: '2026-08-11T09:30:54+02:00'),
      ], countryCode: 'DE');

      expect(escalated, hasLength(1));

      final stored = await db.findWarning('bbk', raw().id);
      expect(stored!.severity, 'extreme');
      expect(
        stored.notified,
        isFalse,
        reason: 'escalation must re-arm the announcement',
      );
    },
  );

  test('a warning dropping in severity is not announced again', () async {
    await ingest.ingestBbk([raw(severity: 'Extreme')], countryCode: 'DE');
    final calmer = await ingest.ingestBbk([
      raw(severity: 'Minor', startDate: '2026-08-11T09:30:54+02:00'),
    ], countryCode: 'DE');

    expect(calmer, isEmpty);
  });

  group('bbkRegionFromId', () {
    test('reads the state code from a mowas id', () {
      expect(bbkRegionFromId('mow.DE-HE-KS-SE106-20260811'), 'HE');
    });

    test('reads the state code from an lhp id', () {
      expect(bbkRegionFromId('lhp.LHP.NW.nw86768'), 'NW');
    });

    test('refuses a pair of capitals that is not a state', () {
      // A wrong region is worse than none: none shows the warning to
      // everyone, a wrong one hides it from the people it concerns.
      expect(bbkRegionFromId('foo.XY.bar'), isNull);
    });
  });
}

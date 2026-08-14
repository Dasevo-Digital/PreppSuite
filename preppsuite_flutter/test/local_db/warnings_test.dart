import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  WarningsCompanion draft({
    required String serverId,
    DateTime? expires,
    DateTime? sent,
  }) {
    final sentAt = sent ?? DateTime.utc(2026, 8);
    return WarningsCompanion.insert(
      serverId: serverId,
      source: 'bbk',
      externalId: 'ext-$serverId',
      countryCode: 'DE',
      severity: 'minor',
      eventType: 'Test',
      headline: 'Test warning $serverId',
      effective: sentAt,
      expires: Value(expires),
      sent: sentAt,
      updatedAt: sentAt,
    );
  }

  test('watchActiveWarnings excludes expired warnings', () async {
    await db.upsertWarning(
      draft(serverId: 'a', expires: DateTime.utc(2000)),
    );
    await db.upsertWarning(
      draft(serverId: 'b', expires: DateTime.utc(2100)),
    );
    await db.upsertWarning(draft(serverId: 'c'));

    final active = await db.watchActiveWarnings().first;

    expect(active.map((w) => w.serverId), containsAll(['b', 'c']));
    expect(active.map((w) => w.serverId), isNot(contains('a')));
  });

  test('watchAllWarnings includes expired warnings', () async {
    await db.upsertWarning(
      draft(serverId: 'a', expires: DateTime.utc(2000)),
    );

    final all = await db.watchAllWarnings().first;

    expect(all.map((w) => w.serverId), contains('a'));
  });

  test('upsertWarning with the same serverId overwrites instead of '
      'duplicating', () async {
    await db.upsertWarning(draft(serverId: 'a'));
    await db.upsertWarning(
      WarningsCompanion.insert(
        serverId: 'a',
        source: 'bbk',
        externalId: 'ext-a',
        countryCode: 'DE',
        severity: 'extreme',
        eventType: 'Updated',
        headline: 'Updated headline',
        effective: DateTime.utc(2026, 8),
        sent: DateTime.utc(2026, 8),
        updatedAt: DateTime.utc(2026, 8),
      ),
    );

    final all = await db.watchAllWarnings().first;

    expect(all, hasLength(1));
    expect(all.single.headline, 'Updated headline');
    expect(all.single.severity, 'extreme');
  });

  test('pruneExpiredWarnings removes only warnings past the retention '
      'window', () async {
    await db.upsertWarning(
      draft(serverId: 'long-expired', expires: DateTime.utc(2020)),
    );
    await db.upsertWarning(
      draft(
        serverId: 'recently-expired',
        expires: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    await db.upsertWarning(draft(serverId: 'active'));

    await db.pruneExpiredWarnings(retention: const Duration(days: 7));

    final remaining = await db.watchAllWarnings().first;
    expect(
      remaining.map((w) => w.serverId),
      containsAll(['recently-expired', 'active']),
    );
    expect(
      remaining.map((w) => w.serverId),
      isNot(contains('long-expired')),
    );
  });
}

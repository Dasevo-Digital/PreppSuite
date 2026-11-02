import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// What counts as in force follows the clock, not the moment the stream
/// was opened (#248).
void main() {
  final start = DateTime.utc(2026, 11, 2, 12);

  Warning warning(String id, {DateTime? expires}) => Warning(
    source: 'meteoalarm',
    externalId: id,
    countryCode: 'DE',
    severity: 'severe',
    eventType: 'Sturm',
    headline: 'Sturm $id',
    effective: start,
    expires: expires,
    sent: start,
    updatedAt: start,
    notified: false,
  );

  test('a warning leaves when it ends, with no change to the rows', () async {
    final now = DateTime.now().toUtc();
    Warning row(String id, {Duration? endsIn}) =>
        warning(id, expires: endsIn == null ? null : now.add(endsIn));
    final rows = StreamController<List<Warning>>();
    final seen = <List<String>>[];
    final subscription = warningsInForce(
      rows.stream,
    ).listen((list) => seen.add([for (final w in list) w.externalId]));

    rows.add([
      row('open'),
      row('soon', endsIn: const Duration(milliseconds: 300)),
      row('later', endsIn: const Duration(hours: 2)),
      row('over', endsIn: const Duration(minutes: -1)),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(seen.last, ['open', 'soon', 'later']);

    // Nothing new arrives from the database; the clock alone moves it.
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    expect(seen.last, ['open', 'later']);

    await subscription.cancel();
  });

  test('a BBK warning the poll ends leaves the open stream too', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    final seen = <int>[];
    final keepAlive = container.listen(
      activeWarningsProvider,
      (_, next) => next.whenData((list) => seen.add(list.length)),
      fireImmediately: true,
    );

    // drift keeps whole seconds: what the stream was opened with has to
    // lie a second before the end, as it does in a running app.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final at = DateTime.now().toUtc();
    await db.upsertWarnings([
      WarningsCompanion.insert(
        source: 'bbk',
        externalId: 'bombe',
        countryCode: 'DE',
        severity: 'severe',
        eventType: 'Kampfmittel',
        headline: 'Entschärfung',
        effective: at,
        sent: at,
        updatedAt: at,
      ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(seen.last, 1);

    await db.expireMissingWarnings(source: 'bbk', seenExternalIds: {});
    await Future<void>.delayed(const Duration(milliseconds: 500));

    expect(seen.last, 0, reason: 'until #248 the banner kept it until restart');

    keepAlive.close();
    container.dispose();
    await db.close();
  });
}

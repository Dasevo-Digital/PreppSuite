import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// What the background worker writes goes through a connection of its own,
/// and the open app's watchers know nothing of it (#332).
void main() {
  test('a warning from another connection reaches the watchers', () async {
    final directory = await Directory.systemTemp.createTemp('preppsuite-watch');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/preppsuite.sqlite');
    final open = AppDatabase.forTesting(NativeDatabase(file));
    final worker = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(open.close);
    addTearDown(worker.close);
    await open.customSelect('SELECT 1').get();

    final seen = <int>[];
    final subscription = open.watchActiveWarnings().listen(
      (rows) => seen.add(rows.length),
    );
    addTearDown(subscription.cancel);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await worker.upsertWarning(
      WarningsCompanion.insert(
        source: 'bbk',
        externalId: 'one',
        countryCode: 'DE',
        regionKey: const Value('05334'),
        severity: 'extreme',
        eventType: 'Evakuierung',
        headline: 'Evakuierung',
        effective: DateTime.utc(2026),
        sent: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(seen, everyElement(0), reason: 'what the problem is');

    open.refreshWarningWatchers();
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(seen.last, 1);
  });
}

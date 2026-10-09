import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/database_snapshots.dart';
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// A copy of the database a day, for the day it breaks (#140).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late File live;
  late AppDatabase db;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('snapshots');
    live = File('${dir.path}/preppsuite.sqlite');
    db = AppDatabase.forTesting(NativeDatabase(live));
    await db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'water',
        householdId: 'home',
        name: 'Trinkwasser',
        category: 'water',
        quantity: 12,
        unit: 'l',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026, 10, 9),
        dirty: const Value(false),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  final day = DateTime.utc(2026, 10, 9, 8);

  test('one a day, the last seven kept, nothing half written left', () async {
    final snapshots = DatabaseSnapshots(live);
    final first = await snapshots.takeIfDue(db.snapshotTo, now: day);
    expect(first, isNotNull);
    expect(snapshots.takenAt(first!), day);
    // Opened again the same morning: nothing new.
    expect(
      await snapshots.takeIfDue(
        db.snapshotTo,
        now: day.add(const Duration(hours: 3)),
      ),
      isNull,
    );
    for (var i = 1; i <= 9; i++) {
      await snapshots.takeIfDue(
        db.snapshotTo,
        now: day.add(Duration(days: i)),
      );
    }
    final kept = await snapshots.list();
    expect(kept, hasLength(7));
    expect(snapshots.takenAt(kept.first), day.add(const Duration(days: 9)));
    expect(
      snapshots.folder.listSync().where((e) => e.path.endsWith('.part')),
      isEmpty,
    );
  });

  test('a copy opens and holds the household', () async {
    final copy = (await DatabaseSnapshots(
      live,
    ).takeIfDue(db.snapshotTo, now: day))!;
    expect(LocalDatabaseEncryption.instance.opensCleanly(copy), isTrue);
    final reopened = AppDatabase.forTesting(NativeDatabase(copy));
    addTearDown(reopened.close);
    final items = await reopened.watchInventoryItems('home').first;
    expect(items.single.name, 'Trinkwasser');
  });

  test('a damaged file is not called clean', () async {
    final junk = File('${dir.path}/kaputt.sqlite')
      ..writeAsBytesSync(Uint8List.fromList(List.filled(4096, 7)));
    expect(LocalDatabaseEncryption.instance.opensCleanly(junk), isFalse);
  });

  test(
    'restoring keeps the damaged file beside it, never deletes it',
    () async {
      final snapshots = DatabaseSnapshots(live);
      final copy = (await snapshots.takeIfDue(db.snapshotTo, now: day))!;
      await db.close();
      // What a flat battery in the middle of a write can leave.
      live.writeAsBytesSync(Uint8List.fromList(List.filled(8192, 3)));
      File('${live.path}-wal').writeAsStringSync('half a transaction');

      await snapshots.restore(copy, now: day.add(const Duration(days: 1)));

      final names = dir.listSync().map((e) => e.path.split('/').last).toSet();
      expect(names, contains('preppsuite.sqlite.damaged-20261010T080000'));
      expect(names, contains('preppsuite.sqlite.damaged-20261010T080000-wal'));
      expect(names, isNot(contains('preppsuite.sqlite-wal')));
      db = AppDatabase.forTesting(NativeDatabase(live));
      expect(
        (await db.watchInventoryItems('home').first).single.name,
        'Trinkwasser',
      );
    },
  );

  test('once the database is encrypted, readable copies go at once', () async {
    final snapshots = DatabaseSnapshots(live);
    final plain = (await snapshots.takeIfDue(db.snapshotTo, now: day))!;
    await db.close();
    // The database as an encrypted one looks from outside: no header.
    live.writeAsBytesSync(Uint8List.fromList(List.filled(4096, 9)));

    // Within the day, which alone would not take a new one.
    final fresh = await snapshots.takeIfDue(
      (path) async => File(path).writeAsBytesSync(List.filled(4096, 9)),
      now: day.add(const Duration(hours: 1)),
    );
    expect(fresh, isNotNull);
    expect(plain.existsSync(), isFalse);
    expect(await snapshots.list(), [
      isA<File>().having((f) => f.path, 'path', fresh!.path),
    ]);
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
}

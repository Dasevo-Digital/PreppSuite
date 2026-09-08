import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  test(
    'a household backup restores its inventory into an empty database',
    () async {
      final source = AppDatabase.forTesting(NativeDatabase.memory());
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(source.close);
      addTearDown(target.close);

      await source.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: 'water',
          householdId: 'home',
          name: 'Trinkwasser',
          category: 'water',
          quantity: 12,
          unit: 'l',
          storageLocation: 'Keller',
          updatedAt: DateTime.utc(2026, 9, 8),
          dirty: const Value(true),
        ),
      );

      final raw = await BackupService(source).exportHousehold(
        'home',
        'secret-123',
      );
      expect(
        await BackupService(target).restore(raw, 'home', 'secret-123'),
        1,
      );

      final restored = (await target.watchInventoryItems('home').first).single;
      expect(restored.name, 'Trinkwasser');
      expect(restored.quantity, 12);
    },
  );

  test('a backup from another household is rejected', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final raw = await BackupService(db).exportHousehold('one', 'secret-123');
    expect(
      await BackupService(db).restore(raw, 'two', 'secret-123'),
      isNull,
    );
  });

  test('a backup cannot be opened with a wrong password', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final raw = await BackupService(db).exportHousehold('home', 'secret-123');
    expect(
      await BackupService(db).restore(raw, 'home', 'wrong-pass'),
      isNull,
    );
  });
}

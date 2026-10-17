import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/device_charge.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_filter.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  final now = DateTime(2026, 10, 17, 12);

  InventoryItem device(
    String name, {
    int? every = 30,
    DateTime? checked,
    String category = 'energy',
    DateTime? deletedAt,
  }) => InventoryItem(
    clientId: name,
    householdId: 'h',
    name: name,
    category: category,
    quantity: 1,
    unit: 'Stück',
    storageLocation: 'Flur',
    chargeEveryDays: every,
    chargeCheckedAt: checked,
    updatedAt: DateTime.utc(2026),
    deletedAt: deletedAt,
    dirty: false,
  );

  group('a device\'s check', () {
    test('none without an interval, and none once deleted', () {
      expect(deviceChargeCheck(device('Topf', every: null)), isNull);
      expect(
        deviceChargeCheck(device('Lampe', deletedAt: DateTime.utc(2026))),
        isNull,
      );
    });

    test('is due in calendar days from the last check', () {
      final check = deviceChargeCheck(
        device('Powerbank', checked: DateTime(2026, 10, 1, 20)),
      )!;
      expect(check.daysUntilDue(now: now), 14);
      expect(check.isDue(now: now), isFalse);
      expect(check.isDue(now: DateTime(2026, 10, 31, 8)), isTrue);
    });

    test('never confirmed is not overdue', () {
      final check = deviceChargeCheck(device('Radio'))!;
      expect(check.daysUntilDue(now: now), isNull);
      expect(check.isDue(now: now), isFalse);
    });
  });

  test('the most urgent device comes first', () {
    final charges = deviceCharges([
      device('Nie'),
      device('Bald', checked: DateTime(2026, 10, 10)),
      device('Überfällig', checked: DateTime(2026, 9, 1)),
      device('Ohne', every: null),
    ], now: now);
    expect(
      [for (final c in charges) c.item.name],
      [
        'Überfällig',
        'Bald',
        'Nie',
      ],
    );
  });

  group('reminders', () {
    test('on the morning of the day it is due', () {
      final reminders = planDeviceChargeReminders(
        items: [device('Powerbank', checked: DateTime(2026, 10, 1, 20))],
        now: now,
      );
      expect(reminders.single.itemName, 'Powerbank');
      expect(reminders.single.fireAt.year, 2026);
      expect(reminders.single.fireAt.month, 10);
      expect(reminders.single.fireAt.day, 31);
    });

    test('none for a device already overdue, or never confirmed', () {
      expect(
        planDeviceChargeReminders(
          items: [
            device('Überfällig', checked: DateTime(2026, 9, 1)),
            device('Nie'),
          ],
          now: now,
        ),
        isEmpty,
      );
    });
  });

  test('the list can show only the devices that are due', () {
    final filtered = filterInventory(
      [
        device('Überfällig', checked: DateTime(2026, 9, 1)),
        device('Bald', checked: DateTime(2026, 10, 10)),
      ],
      filter: const InventoryFilter(status: InventoryStatusFilter.chargeDue),
      now: now,
    );
    expect([for (final i in filtered) i.name], ['Überfällig']);
  });

  test('confirming a check moves it on and marks the row for sync', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final controller = InventoryController(db, 'h');
    final old = device('Powerbank', checked: DateTime.utc(2026, 9, 1));
    await db.upsertInventoryItem(old.toCompanion(false));

    final at = DateTime.utc(2026, 10, 17, 9);
    await controller.markCharged(old, at: at);

    final stored = (await db.watchInventoryItems('h').first).single;
    expect(stored.chargeCheckedAt?.toUtc(), at);
    expect(stored.chargeEveryDays, 30);
    expect(stored.dirty, isTrue);
    expect(stored.updatedAt.isAfter(old.updatedAt), isTrue);
  });
}

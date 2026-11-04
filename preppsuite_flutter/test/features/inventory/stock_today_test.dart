import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_satisfaction.dart';
import 'package:preppsuite_flutter/features/home/application/home_overview.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_csv_export.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_csv_import.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_filter.dart';
import 'package:preppsuite_flutter/features/inventory/application/medication_range.dart';
import 'package:preppsuite_flutter/features/inventory/application/rotation.dart';
import 'package:preppsuite_flutter/features/inventory/application/shopping_list.dart';
import 'package:preppsuite_flutter/features/inventory/application/stock_today.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

/// What is left today of a pack in daily use (#268): thirty tablets
/// counted twenty days ago at one a day are ten, wherever stock is
/// compared with a minimum.
void main() {
  final now = DateTime(2026, 11, 3, 9);

  InventoryItem item({
    double quantity = 30,
    double? minQuantity = 30,
    double? dailyDose = 1,
    int? refillLeadDays = 7,
    InventoryItemCategory category = InventoryItemCategory.medical,
    DateTime? countedOn,
  }) => InventoryItem(
    clientId: 'ramipril',
    householdId: 'household-1',
    name: 'Ramipril',
    category: category.name,
    quantity: quantity,
    unit: 'Tablette',
    storageLocation: 'Hausapotheke',
    minQuantity: minQuantity,
    dailyDose: dailyDose,
    refillLeadDays: refillLeadDays,
    stockCountedAt: (countedOn ?? DateTime(2026, 10, 14, 20)).toUtc(),
    updatedAt: DateTime.utc(2026, 10, 14),
    dirty: false,
  );

  group('stockToday', () {
    test('a pack in daily use less a dose for every day since', () {
      expect(stockToday(item(), now: now), 10);
      expect(isInDailyUse(item()), isTrue);
    });

    test('the same as the medication reach says', () {
      final pack = item();
      final range = medicationRanges([pack], now: now).single;
      expect(stockToday(pack, now: now), range.days * pack.dailyDose!);
    });

    test('the count itself on the day it was counted', () {
      expect(
        stockToday(item(countedOn: DateTime(2026, 11, 3, 7)), now: now),
        30,
      );
    });

    test('never below nought', () {
      expect(stockToday(item(quantity: 5), now: now), 0);
    });

    test('a reserve is what was counted, however long ago', () {
      expect(stockToday(item(refillLeadDays: null), now: now), 30);
    });

    test('only a medicine with a dose runs down by itself', () {
      expect(
        stockToday(item(category: InventoryItemCategory.petFood), now: now),
        30,
      );
      expect(stockToday(item(dailyDose: null), now: now), 30);
      expect(stockToday(item(dailyDose: 0), now: now), 30);
    });

    test('a part dose does not leave a float tail', () {
      expect(
        stockToday(
          item(dailyDose: 0.1, countedOn: DateTime(2026, 10, 27, 8)),
          now: now,
        ),
        29.3,
      );
    });

    test('counted in calendar days across the end of summer time', () {
      // 25 October 2026 is the end of summer time in Germany: the night
      // has 25 hours, and a count in hours would be a day short.
      expect(
        stockToday(item(countedOn: DateTime(2026, 10, 24, 23)), now: now),
        20,
      );
    });
  });

  group('everything that compares with the minimum', () {
    test('the shopping list asks for what is missing today', () {
      final list = buildShoppingList(items: [item()], days: 10, now: now);
      expect(list.entries.single.shortfall, 20);
    });

    test('a reserve at its minimum is not on the shopping list', () {
      final list = buildShoppingList(
        items: [item(refillLeadDays: null)],
        days: 10,
        now: now,
      );
      expect(list.entries, isEmpty);
    });

    test('the overview counts it as low', () {
      expect(summarizeInventory([item()], now: now).lowStock, 1);
      expect(
        summarizeInventory([item(refillLeadDays: null)], now: now).lowStock,
        0,
      );
    });

    test('the inventory filter finds it', () {
      final low = filterInventory(
        [item()],
        filter: const InventoryFilter(status: InventoryStatusFilter.lowStock),
        now: now,
      );
      expect(low, hasLength(1));
      expect(isBelowMinimum(item(), now: now), isTrue);
    });

    test('a checklist line stops being covered as the pack is used', () {
      final line = ChecklistItem(
        clientId: 'line',
        householdId: 'household-1',
        templateClientId: 'list',
        title: 'Medikamente für zwei Wochen',
        isChecked: false,
        linkedInventoryItemId: 'ramipril',
        targetQuantity: 14,
        sortOrder: 0,
        updatedAt: DateTime.utc(2026),
        dirty: false,
      );
      final byId = {'ramipril': item()};
      expect(isChecklistItemSatisfied(line, byId, now: now), isFalse);
      expect(
        isChecklistItemSatisfied(
          line,
          byId,
          now: DateTime(2026, 10, 20),
        ),
        isTrue,
      );
    });
  });

  group('everything else that shows it (#272)', () {
    ChecklistItem line({double target = 14}) => ChecklistItem(
      clientId: 'line',
      householdId: 'household-1',
      templateClientId: 'list',
      title: 'Medikamente für zwei Wochen',
      isChecked: false,
      linkedInventoryItemId: 'ramipril',
      targetQuantity: target,
      sortOrder: 0,
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );

    test("a list's progress counts the pack down as its line does", () {
      final byId = {'ramipril': item()};
      expect(
        checklistProgressByTemplate(
          items: [line()],
          inventoryById: byId,
          now: now,
        )['list'],
        (done: 0, total: 1),
      );
      expect(
        checklistProgressByTemplate(
          items: [line()],
          inventoryById: byId,
          now: DateTime(2026, 10, 20),
        )['list'],
        (done: 1, total: 1),
      );
    });

    test('the CSV holds what is left, since it has no day for the count', () {
      double exported(InventoryItem row) => parseInventoryCsv(
        buildInventoryCsv([row], now: now),
      ).rows.single.parsed!.quantity;
      expect(exported(item()), 10);
      expect(exported(item(refillLeadDays: null)), 30);
    });

    test('a pack taken down to nothing is not left to use first', () {
      final expiring = item(quantity: 15).copyWith(
        expirationDate: Value(DateTime(2026, 11, 20)),
      );
      expect(buildRotation([expiring], now: now), isEmpty);
      expect(
        buildRotation([expiring], now: DateTime(2026, 10, 20)),
        hasLength(1),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/medication_range.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

/// The arithmetic is one division, so what these guard is the other half:
/// which rows are allowed into it, and which are named as unanswered
/// rather than quietly dropped.
void main() {
  InventoryItem item({
    required String name,
    required double quantity,
    double? dailyDose,
    String unit = 'Tablette',
    InventoryItemCategory category = InventoryItemCategory.medical,
  }) => InventoryItem(
    clientId: name,
    householdId: 'household-1',
    name: name,
    category: category.name,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Hausapotheke',
    dailyDose: dailyDose,
    updatedAt: DateTime.utc(2026, 9, 14),
    dirty: false,
  );

  test('stock divided by the daily amount, and nothing else', () {
    final ranges = medicationRanges([
      item(name: 'Ramipril', quantity: 60, dailyDose: 2),
    ]);
    expect(ranges.single.days, 30);
    expect(ranges.single.wholeDays, 30);
  });

  test('a part-day is not rounded up', () {
    // Eleven at two a day is five and a half days. Saying six is how a
    // household runs out a day before it planned to.
    final ranges = medicationRanges([
      item(name: 'Ibuprofen', quantity: 11, dailyDose: 2),
    ]);
    expect(ranges.single.days, 5.5);
    expect(ranges.single.wholeDays, 5);
  });

  test('the soonest to run out comes first', () {
    final ranges = medicationRanges([
      item(name: 'Ramipril', quantity: 60, dailyDose: 2),
      item(name: 'Insulin', quantity: 3, dailyDose: 1, unit: 'Ampulle'),
      item(name: 'Metformin', quantity: 100, dailyDose: 2),
    ]);
    expect(ranges.map((r) => r.item.name), [
      'Insulin',
      'Ramipril',
      'Metformin',
    ]);
    expect(firstToRunOut(ranges)!.item.name, 'Insulin');
  });

  group('what is left out of the answer', () {
    test('anything that is not a medicine', () {
      // A dose on a tin of beans is a category that was changed after the
      // fact. It must not turn up in the medicine cabinet's reach.
      final ranges = medicationRanges([
        item(
          name: 'Bohnen',
          quantity: 10,
          dailyDose: 1,
          category: InventoryItemCategory.food,
        ),
      ]);
      expect(ranges, isEmpty);
    });

    test('a medicine with no daily amount', () {
      expect(medicationRanges([item(name: 'Salbe', quantity: 2)]), isEmpty);
    });

    test('a dose of zero, which would be a division by zero', () {
      final rows = [item(name: 'Salbe', quantity: 2, dailyDose: 0)];
      expect(medicationRanges(rows), isEmpty);
      expect(medicationsWithoutDose(rows).single.name, 'Salbe');
    });

    test('an empty row, which is a shopping list entry and not a reach', () {
      // Reported as zero days beside a real answer it would bury the real
      // one, and it is not the same statement.
      final rows = [item(name: 'Ramipril', quantity: 0, dailyDose: 2)];
      expect(medicationRanges(rows), isEmpty);
      expect(medicationsWithoutDose(rows), isEmpty);
    });
  });

  test('what cannot be answered is named, not dropped', () {
    final rows = [
      item(name: 'Ramipril', quantity: 60, dailyDose: 2),
      item(name: 'Wundsalbe', quantity: 1, unit: 'Tube'),
      item(name: 'Pflaster', quantity: 20, unit: 'Stück'),
    ];
    expect(medicationRanges(rows).map((r) => r.item.name), ['Ramipril']);
    expect(medicationsWithoutDose(rows).map((i) => i.name), [
      'Wundsalbe',
      'Pflaster',
    ]);
  });

  test('nothing at all is no answer rather than zero days', () {
    expect(firstToRunOut(medicationRanges([])), isNull);
  });

  group('the date it runs out', () {
    test('is counted in whole days from today', () {
      final range = medicationRanges([
        item(name: 'Ramipril', quantity: 60, dailyDose: 2),
      ]).single;
      expect(
        range.runsOutOn(DateTime(2026, 9, 14, 22, 30)),
        DateTime(2026, 10, 14),
      );
    });

    test('ignores the time of day it is asked at', () {
      final range = medicationRanges([
        item(name: 'Ramipril', quantity: 10, dailyDose: 1),
      ]).single;
      expect(
        range.runsOutOn(DateTime(2026, 9, 14, 0, 1)),
        range.runsOutOn(DateTime(2026, 9, 14, 23, 59)),
      );
    });
  });
}

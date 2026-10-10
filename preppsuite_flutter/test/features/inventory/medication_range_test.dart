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
    int? refillLeadDays,
    DateTime? stockCountedAt,
    DateTime? updatedAt,
  }) => InventoryItem(
    clientId: name,
    householdId: 'household-1',
    name: name,
    category: category.name,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Hausapotheke',
    dailyDose: dailyDose,
    refillLeadDays: refillLeadDays,
    stockCountedAt: stockCountedAt,
    updatedAt: updatedAt ?? DateTime.utc(2026, 9, 14),
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

    test('is not a day early across the end of summer time', () {
      // 30 days from 10 October cross the clock change on 25 October.
      // Midnight plus 30 blocks of 24 hours was 23:00 on 8 November.
      final range = medicationRanges([
        item(name: 'Ramipril', quantity: 30, dailyDose: 1),
      ]).single;
      expect(range.runsOutOn(DateTime(2026, 10, 10, 9)), DateTime(2026, 11, 9));
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

  group('a pack in daily use (#150)', () {
    // Counted on 1 October at noon: 60 tablets at two a day is 30 days.
    final counted = DateTime(2026, 10, 1, 12);
    final tenDaysOn = DateTime(2026, 10, 11, 8);

    test('is counted down from the day it was counted', () {
      final range = medicationRanges([
        item(
          name: 'Ramipril',
          quantity: 60,
          dailyDose: 2,
          refillLeadDays: 14,
          stockCountedAt: counted,
        ),
      ], now: tenDaysOn).single;

      expect(range.inDailyUse, isTrue);
      expect(range.wholeDays, 20);
      expect(range.days, 20);
      expect(range.runsOutOn(tenDaysOn), DateTime(2026, 10, 31));
      expect(range.refillOn, DateTime(2026, 10, 17));
    });

    test('ends on the same date whichever day it is asked on', () {
      // The point of counting from a date: opening the app every day
      // without booking anything must not push the end, and with it the
      // reminder, a day further out each time.
      List<DateTime> ends() => [
        for (final day in [1, 5, 20])
          medicationRanges(
            [
              item(
                name: 'Ramipril',
                quantity: 60,
                dailyDose: 2,
                refillLeadDays: 14,
                stockCountedAt: counted,
              ),
            ],
            now: DateTime(2026, 10, day, 9),
          ).single.runsOutOn(DateTime(2026, 10, day, 9)),
      ];

      expect(ends().toSet(), {DateTime(2026, 10, 31)});
    });

    test('a reserve beside it is still counted from today', () {
      final range = medicationRanges([
        item(
          name: 'Notvorrat Ramipril',
          quantity: 60,
          dailyDose: 2,
          stockCountedAt: counted,
        ),
      ], now: tenDaysOn).single;

      expect(range.inDailyUse, isFalse);
      expect(range.wholeDays, 30);
      expect(range.refillOn, isNull);
      expect(range.runsOutOn(tenDaysOn), DateTime(2026, 11, 10));
    });

    test('counts from its last change where no count was recorded', () {
      final range = medicationRanges([
        item(
          name: 'Ramipril',
          quantity: 30,
          dailyDose: 1,
          refillLeadDays: 7,
          updatedAt: DateTime.utc(2026, 10, 1, 10),
        ),
      ], now: tenDaysOn).single;

      expect(range.wholeDays, 20);
    });

    test('stays in at zero once the arithmetic says it is empty', () {
      // Either it has run out or its count is stale; both want a look,
      // and leaving it out would read as "nothing to worry about".
      final ranges = medicationRanges([
        item(
          name: 'Ramipril',
          quantity: 10,
          dailyDose: 1,
          refillLeadDays: 7,
          stockCountedAt: counted,
        ),
        item(name: 'Ibuprofen', quantity: 20, dailyDose: 1),
      ], now: tenDaysOn);

      expect(ranges.first.item.name, 'Ramipril');
      expect(ranges.first.wholeDays, 0);
      expect(firstToRunOut(ranges)!.item.name, 'Ramipril');
    });
  });
}

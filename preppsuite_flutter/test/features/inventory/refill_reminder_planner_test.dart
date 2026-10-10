import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/refill_reminder_planner.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// When the reminder for a new prescription comes, and when it does not.
void main() {
  final counted = DateTime(2026, 10, 1, 12);

  InventoryItem pills({
    String name = 'Ramipril',
    double quantity = 60,
    double? dailyDose = 2,
    int? refillLeadDays = 14,
    DateTime? deletedAt,
  }) => InventoryItem(
    clientId: name,
    householdId: 'household-1',
    name: name,
    category: 'medical',
    quantity: quantity,
    unit: 'Tabletten',
    storageLocation: 'Bad',
    dailyDose: dailyDose,
    refillLeadDays: refillLeadDays,
    stockCountedAt: counted,
    updatedAt: counted.toUtc(),
    deletedAt: deletedAt,
    dirty: false,
  );

  test('comes the chosen days before the end, in the morning', () {
    final reminder = planRefillReminders(
      items: [pills()],
      now: DateTime(2026, 10, 2, 8),
    ).single;

    expect(reminder.runsOutOn, DateTime(2026, 10, 31));
    expect(reminder.fireAt, DateTime(2026, 10, 17, 9));
    expect(reminder.itemName, 'Ramipril');
  });

  test('stays on its day however often it is planned', () {
    final days = {
      for (final day in [2, 6, 12, 16])
        planRefillReminders(
          items: [pills()],
          now: DateTime(2026, 10, day, 8),
        ).single.fireAt,
    };

    expect(days, {DateTime(2026, 10, 17, 9)});
  });

  test('is not planned again once its moment has passed', () {
    expect(
      planRefillReminders(items: [pills()], now: DateTime(2026, 10, 17, 10)),
      isEmpty,
    );
  });

  test('is only for a pack the household asked about', () {
    expect(
      planRefillReminders(
        items: [
          pills(refillLeadDays: null),
          pills(name: 'Ohne Dosis', dailyDose: null),
          pills(name: 'Gelöscht', deletedAt: DateTime.utc(2026, 10, 2)),
        ],
        now: DateTime(2026, 10, 2, 8),
      ),
      isEmpty,
    );
  });

  test('puts the soonest first', () {
    final reminders = planRefillReminders(
      items: [
        pills(name: 'Ramipril'),
        pills(name: 'Metformin', quantity: 40),
      ],
      now: DateTime(2026, 10, 2, 8),
    );

    expect(reminders.map((r) => r.itemName), ['Metformin', 'Ramipril']);
  });
}

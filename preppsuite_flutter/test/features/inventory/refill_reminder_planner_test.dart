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

  group('a pack that lasts no longer than the lead time (#401)', () {
    test('is reminded the morning after the count', () {
      // Ten days at two a day, fourteen days' lead: the refill day lies
      // before the count, and nothing used to be planned at all.
      final reminder = planRefillReminders(
        items: [pills(quantity: 20)],
        now: DateTime(2026, 10, 1, 12, 30),
      ).single;

      expect(reminder.fireAt, DateTime(2026, 10, 2, 9));
      expect(reminder.runsOutOn, DateTime(2026, 10, 11));
    });

    test('is reminded the morning after the count when it lasts exactly '
        'the lead time', () {
      final reminder = planRefillReminders(
        items: [pills(quantity: 28)],
        now: DateTime(2026, 10, 1, 12, 30),
      ).single;

      expect(reminder.fireAt, DateTime(2026, 10, 2, 9));
      expect(reminder.runsOutOn, DateTime(2026, 10, 15));
    });

    test('stays on that morning however often it is planned, and comes '
        'once', () {
      final moments = {
        for (final now in [
          DateTime(2026, 10, 1, 12, 30),
          DateTime(2026, 10, 1, 23, 59),
          DateTime(2026, 10, 2, 0, 1),
          DateTime(2026, 10, 2, 8, 59),
        ])
          for (final quantity in [20.0, 28.0])
            planRefillReminders(
              items: [pills(quantity: quantity)],
              now: now,
            ).single.fireAt,
      };
      expect(moments, {DateTime(2026, 10, 2, 9)});

      for (final now in [
        DateTime(2026, 10, 2, 9, 1),
        DateTime(2026, 10, 3, 8),
        DateTime(2026, 10, 20, 8),
      ]) {
        expect(
          planRefillReminders(items: [pills(quantity: 20)], now: now),
          isEmpty,
          reason: '$now',
        );
      }
    });

    test('is not reminded with nothing counted', () {
      expect(
        planRefillReminders(
          items: [pills(quantity: 0)],
          now: DateTime(2026, 10, 1, 12, 30),
        ),
        isEmpty,
      );
    });
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

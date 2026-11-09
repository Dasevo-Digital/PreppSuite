import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_planner.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/expiry_reminder_scheduler.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  InventoryItem item({
    required String clientId,
    String name = 'Test',
    DateTime? expirationDate,
    DateTime? deletedAt,
    String? expiryLeadDays,
    double quantity = 1,
    String category = 'food',
    double? dailyDose,
    int? refillLeadDays,
    DateTime? stockCountedAt,
  }) {
    return InventoryItem(
      clientId: clientId,
      householdId: 'h',
      name: name,
      category: category,
      quantity: quantity,
      dailyDose: dailyDose,
      refillLeadDays: refillLeadDays,
      stockCountedAt: stockCountedAt,
      unit: 'Stk',
      storageLocation: 'Keller',
      expirationDate: expirationDate,
      expiryLeadDays: expiryLeadDays,
      deletedAt: deletedAt,
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );
  }

  final now = DateTime(2026, 8, 23, 12);

  group('a medicine on the lock screen (#319)', () {
    final l10n = AppLocalizationsDe();

    ExpiryReminder planned(String category, int lead) => planExpiryReminders(
      items: [
        item(
          clientId: 'a',
          name: 'Insulin',
          category: category,
          expirationDate: DateTime(2026, 12, 1),
        ),
      ],
      now: now,
      leadDays: [lead],
    ).single;

    test('goes unnamed', () {
      expect(
        expiryReminderBody(l10n, planned('medical', 7)),
        'Ein Medikament läuft in 7 Tagen ab.',
      );
      expect(
        expiryReminderBody(l10n, planned('medical', 1)),
        'Ein Medikament läuft morgen ab.',
      );
    });

    test('a tin of soup keeps its name', () {
      expect(
        expiryReminderBody(l10n, planned('food', 7)),
        contains('Insulin'),
      );
    });

    test('and the prescription reminder names nothing', () {
      expect(l10n.refillReminderBody('1. Dez. 2026'), isNot(contains('{')));
      expect(l10n.refillReminderBody('1. Dez. 2026'), contains('Medikament'));
    });
  });

  group('planExpiryReminders', () {
    test('plans one reminder per lead time, at the configured hour', () {
      final reminders = planExpiryReminders(
        items: [
          item(clientId: 'a', expirationDate: DateTime(2026, 12, 1)),
        ],
        now: now,
        leadDays: const [30, 7],
      );

      expect(reminders, hasLength(2));
      expect(reminders[0].fireAt, DateTime(2026, 11, 1, expiryReminderHour));
      expect(reminders[0].leadDays, 30);
      expect(reminders[1].fireAt, DateTime(2026, 11, 24, expiryReminderHour));
      expect(reminders[1].leadDays, 7);
    });

    test('skips what will be gone before it would ring (#281)', () {
      final reminders = planExpiryReminders(
        items: [
          // Booked out after a blackout; the date stays on the row.
          item(
            clientId: 'milk',
            quantity: 0,
            expirationDate: DateTime(2026, 9, 10),
          ),
          // Twenty tablets at one a day, counted today: empty on
          // 12 September, so the 30-day reminder on 1 November rings for
          // nothing, and so does the 7-day one.
          item(
            clientId: 'tablets',
            category: 'medical',
            quantity: 20,
            dailyDose: 1,
            refillLeadDays: 7,
            stockCountedAt: now.toUtc(),
            expirationDate: DateTime(2026, 12, 1),
          ),
          // A hundred and twenty last until after both.
          item(
            clientId: 'more tablets',
            category: 'medical',
            quantity: 120,
            dailyDose: 1,
            refillLeadDays: 7,
            stockCountedAt: now.toUtc(),
            expirationDate: DateTime(2026, 12, 1),
          ),
        ],
        now: now,
        leadDays: const [30, 7],
      );

      expect(reminders.map((r) => r.itemClientId), [
        'more tablets',
        'more tablets',
      ]);
    });

    test('skips items without an expiration date', () {
      final reminders = planExpiryReminders(
        items: [item(clientId: 'a')],
        now: now,
      );

      expect(reminders, isEmpty);
    });

    test('skips tombstoned items', () {
      final reminders = planExpiryReminders(
        items: [
          item(
            clientId: 'a',
            expirationDate: DateTime(2026, 12, 1),
            deletedAt: DateTime.utc(2026, 8, 20),
          ),
        ],
        now: now,
      );

      expect(reminders, isEmpty);
    });

    test('drops lead times that already passed but keeps the nearer one', () {
      // Expires in 10 days: the 30-day reminder is in the past, the
      // 7-day one is still ahead.
      final reminders = planExpiryReminders(
        items: [
          item(clientId: 'a', expirationDate: DateTime(2026, 9, 2)),
        ],
        now: now,
        leadDays: const [30, 7],
      );

      expect(reminders, hasLength(1));
      expect(reminders.single.leadDays, 7);
      expect(reminders.single.fireAt, DateTime(2026, 8, 26, 9));
    });

    test('plans nothing for an item that already expired', () {
      final reminders = planExpiryReminders(
        items: [
          item(clientId: 'a', expirationDate: DateTime(2026, 8, 1)),
        ],
        now: now,
      );

      expect(reminders, isEmpty);
    });

    test('treats a reminder due earlier today as passed', () {
      // now is 12:00; the reminder hour is 09:00, so today's slot is gone.
      final reminders = planExpiryReminders(
        items: [
          item(clientId: 'a', expirationDate: DateTime(2026, 8, 30)),
        ],
        now: now,
        leadDays: const [7],
      );

      expect(reminders, isEmpty);
    });

    test('is sorted soonest first', () {
      final reminders = planExpiryReminders(
        items: [
          item(
            clientId: 'a',
            name: 'Spät',
            expirationDate: DateTime(2027, 1, 1),
          ),
          item(
            clientId: 'b',
            name: 'Früh',
            expirationDate: DateTime(2026, 10, 1),
          ),
        ],
        now: now,
        leadDays: const [7],
      );

      expect(reminders.map((r) => r.itemName), ['Früh', 'Spät']);
    });

    test('caps at the limit, keeping the soonest reminders', () {
      final reminders = planExpiryReminders(
        items: [
          for (var i = 0; i < 10; i++)
            item(
              clientId: 'item-$i',
              name: 'Item $i',
              // Later index expires later, so the earliest indexes win.
              expirationDate: DateTime(2026, 10, 1 + i),
            ),
        ],
        now: now,
        leadDays: const [7],
        limit: 3,
      );

      expect(reminders, hasLength(3));
      expect(reminders.map((r) => r.itemName), ['Item 0', 'Item 1', 'Item 2']);
    });

    test('gives each item/lead-time pair a distinct, stable id', () {
      List<ExpiryReminder> plan() => planExpiryReminders(
        items: [
          item(clientId: 'a', expirationDate: DateTime(2026, 12, 1)),
          item(clientId: 'b', expirationDate: DateTime(2026, 12, 1)),
        ],
        now: now,
        leadDays: const [30, 7],
      );

      final first = plan();
      final second = plan();

      expect(first.map((r) => r.id).toSet(), hasLength(4));
      expect(first.map((r) => r.id), second.map((r) => r.id));
      expect(first.every((r) => r.id >= 0), isTrue);
    });

    test('ignores negative lead times rather than scheduling after expiry', () {
      final reminders = planExpiryReminders(
        items: [
          item(clientId: 'a', expirationDate: DateTime(2026, 12, 1)),
        ],
        now: now,
        leadDays: const [-3, 7],
      );

      expect(reminders.map((r) => r.leadDays), [7]);
    });
  });

  group('an item with its own lead times', () {
    test('uses them instead of the household\'s', () {
      final reminders = planExpiryReminders(
        items: [
          item(
            clientId: 'a',
            expirationDate: DateTime(2026, 12, 1),
            expiryLeadDays: '14',
          ),
        ],
        now: now,
        leadDays: const [30, 7],
      );

      expect(reminders.map((r) => r.leadDays), [14]);
    });

    test('an empty list means never, which is not the same as null', () {
      // The distinction the column exists for: null follows the
      // household, an empty string is a deliberate silence. A single
      // integer column could not have said both.
      final reminders = planExpiryReminders(
        items: [
          item(
            clientId: 'quiet',
            expirationDate: DateTime(2026, 12, 1),
            expiryLeadDays: '',
          ),
          item(clientId: 'normal', expirationDate: DateTime(2026, 12, 1)),
        ],
        now: now,
        leadDays: const [30],
      );

      expect(reminders.map((r) => r.itemClientId), ['normal']);
    });

    test('still gets reminders when the household has switched its own '
        'off', () {
      // The case the scheduler used to short-circuit: no household lead
      // times at all, but one item that asked for its own.
      final reminders = planExpiryReminders(
        items: [
          item(
            clientId: 'a',
            expirationDate: DateTime(2026, 12, 1),
            expiryLeadDays: '7',
          ),
          item(clientId: 'b', expirationDate: DateTime(2026, 12, 1)),
        ],
        now: now,
        leadDays: const [],
      );

      expect(reminders.map((r) => r.itemClientId), ['a']);
    });
  });

  group('decoding what is stored', () {
    test('null is the household, empty is never', () {
      expect(decodeItemLeadDays(null), isNull);
      expect(decodeItemLeadDays(''), isEmpty);
    });

    test('sorts far to near, removes duplicates and survives rubbish', () {
      expect(decodeItemLeadDays('7, 30,7'), [30, 7]);
      expect(decodeItemLeadDays('30,,x,-3, 7 '), [30, 7]);
    });

    test('round-trips', () {
      expect(decodeItemLeadDays(encodeItemLeadDays([7, 30])), [30, 7]);
      expect(encodeItemLeadDays(const []), '');
    });
  });
}

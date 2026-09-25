import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_planner.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  InventoryItem item({
    required String clientId,
    String name = 'Test',
    DateTime? expirationDate,
    DateTime? deletedAt,
    String? expiryLeadDays,
  }) {
    return InventoryItem(
      clientId: clientId,
      householdId: 'h',
      name: name,
      category: 'food',
      quantity: 1,
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

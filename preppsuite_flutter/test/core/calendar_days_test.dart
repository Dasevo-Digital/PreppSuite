import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/calendar_days.dart';
import 'package:preppsuite_flutter/features/inventory/application/charge_reminder_provider.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_filter.dart';
import 'package:preppsuite_flutter/features/inventory/application/rotation.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_reminder.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_day.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Days counted across the clock changes (#233).
///
/// Summer time begins on 28 March 2027 and ends on 25 October 2026. These
/// only bite in a zone that has summer time, so `tool/pre_release_check.sh`
/// and the CI run this file once more under `TZ=Europe/Berlin`; in UTC they
/// pass either way.
void main() {
  InventoryItem item({
    String clientId = 'reis',
    DateTime? expires,
  }) => InventoryItem(
    clientId: clientId,
    householdId: 'h',
    name: 'Reis',
    category: 'food',
    quantity: 1,
    unit: 'kg',
    storageLocation: 'Keller',
    expirationDate: expires,
    updatedAt: DateTime.utc(2027),
    dirty: false,
  );

  group('calendarDaysBetween', () {
    test('counts the dates, not the hours, across the spring change', () {
      // 23 hours from midnight to midnight, which inDays called zero.
      expect(
        calendarDaysBetween(DateTime(2027, 3, 28), DateTime(2027, 3, 29)),
        1,
      );
      expect(
        calendarDaysBetween(DateTime(2027, 3, 20), DateTime(2027, 4, 10)),
        21,
      );
      expect(
        calendarDaysBetween(DateTime(2027, 3, 29), DateTime(2027, 3, 28)),
        -1,
      );
    });

    test('and across the autumn change', () {
      expect(
        calendarDaysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 26)),
        2,
      );
    });

    test('the time of day does not matter', () {
      expect(
        calendarDaysBetween(
          DateTime(2027, 3, 28, 23, 30),
          DateTime(2027, 3, 29, 0, 10),
        ),
        1,
      );
      expect(
        calendarDaysBetween(
          DateTime(2027, 3, 28, 1),
          DateTime(2027, 3, 28, 23),
        ),
        0,
      );
    });
  });

  group('what to use next', () {
    test('three weeks before an April date are three weeks', () {
      final rotation = buildRotation([
        item(expires: DateTime(2027, 4, 10)),
      ], now: DateTime(2027, 3, 20, 12));

      expect(rotation.single.daysLeft, 21);
    });

    test("the day after the change, yesterday's item is expired", () {
      // It stood under "bald" with "heute" -- a day after it ran out.
      final rotation = buildRotation([
        item(expires: DateTime(2027, 3, 28)),
      ], now: DateTime(2027, 3, 29, 12));

      expect(rotation.single.daysLeft, -1);
      expect(rotation.single.urgency, RotationUrgency.expired);
    });

    test('on the day of the change, tomorrow is not today', () {
      final rotation = buildRotation([
        item(expires: DateTime(2027, 3, 29)),
      ], now: DateTime(2027, 3, 28, 12));

      expect(rotation.single.daysLeft, 1);
    });
  });

  test('a backup a week old is a week old', () {
    final status = BackupStatus(
      lastBackup: DateTime(2027, 3, 25, 20).toUtc(),
      everyDays: 7,
    );
    final now = DateTime(2027, 4, 1, 12);

    expect(status.daysSince(now: now), 7);
    expect(status.isCurrent(now: now), isFalse);
  });

  group('the charge check', () {
    test('is due on its day and not the day before', () {
      final check = ChargeCheck(
        lastChecked: DateTime(2027, 1, 10, 12),
        everyDays: 90,
      );

      expect(check.daysUntilDue(now: DateTime(2027, 3, 1, 12)), 40);
      expect(check.isDue(now: DateTime(2027, 4, 9, 12)), isFalse);
      expect(check.isDue(now: DateTime(2027, 4, 10, 8)), isTrue);
    });

    test('a check due the day after the change is not due on it', () {
      final check = ChargeCheck(
        lastChecked: DateTime(2027, 3, 15, 12),
        everyDays: 14,
      );

      expect(check.isDue(now: DateTime(2027, 3, 28, 12)), isFalse);
    });
  });

  test('the warning day is counted in days from spring', () {
    // The second Thursday in September 2027 is the ninth.
    expect(daysUntilFederalWarningDay(from: DateTime(2027, 3, 1, 9)), 192);
  });

  test('"expiring" is the coming week, the change inside it or not', () {
    final now = DateTime(2027, 3, 21, 12);
    final items = [
      item(clientId: 'in-seven', expires: DateTime(2027, 3, 28)),
      item(clientId: 'in-eight', expires: DateTime(2027, 3, 29)),
    ];

    final expiring = filterInventory(
      items,
      filter: const InventoryFilter(status: InventoryStatusFilter.expiring),
      now: now,
    );

    expect([for (final row in expiring) row.clientId], ['in-seven']);
  });
}

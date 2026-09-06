import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/rotation.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The order in which things have to be dealt with.
void main() {
  // Local midday, so the date-only arithmetic is not decided by the hour.
  final now = DateTime(2026, 9, 6, 12);

  InventoryItem item({
    required String clientId,
    String name = 'Vorrat',
    double quantity = 1,
    DateTime? expirationDate,
  }) => InventoryItem(
    clientId: clientId,
    householdId: 'h',
    name: name,
    category: 'food',
    quantity: quantity,
    unit: 'Stück',
    storageLocation: 'Keller',
    expirationDate: expirationDate,
    updatedAt: now.toUtc(),
    dirty: false,
  );

  test('an item with no date cannot be rotated and is left out', () {
    // Salt does not expire. Listing it would bury the rows that do.
    final rotation = buildRotation([item(clientId: 'salz')], now: now);

    expect(rotation, isEmpty);
  });

  test('an item at zero has nothing left to use', () {
    final rotation = buildRotation(
      [
        item(
          clientId: 'leer',
          quantity: 0,
          expirationDate: DateTime(2026, 9, 1),
        ),
      ],
      now: now,
    );

    expect(rotation, isEmpty);
  });

  test('days are counted as calendar days, not hours elapsed', () {
    // Tomorrow morning is one day away, not zero. Someone reading "0"
    // would think it had to be used tonight.
    final rotation = buildRotation(
      [item(clientId: 'a', expirationDate: DateTime(2026, 9, 7, 8))],
      now: now,
    );

    expect(rotation.single.daysLeft, 1);
  });

  test('the day itself is zero', () {
    final rotation = buildRotation(
      [item(clientId: 'a', expirationDate: DateTime(2026, 9, 6, 23))],
      now: now,
    );

    expect(rotation.single.daysLeft, 0);
    expect(rotation.single.urgency, RotationUrgency.soon);
  });

  test('a date that has passed is negative and counts as expired', () {
    final rotation = buildRotation(
      [item(clientId: 'a', expirationDate: DateTime(2026, 9, 4))],
      now: now,
    );

    expect(rotation.single.daysLeft, -2);
    expect(rotation.single.urgency, RotationUrgency.expired);
  });

  test('a UTC date is read in local time, like every date on screen', () {
    final rotation = buildRotation(
      [item(clientId: 'a', expirationDate: DateTime.utc(2026, 9, 6, 12))],
      now: now,
    );

    expect(rotation.single.daysLeft, 0);
  });

  group('the order', () {
    test('is longest overdue first, then soonest to run out', () {
      final rotation = buildRotation(
        [
          item(clientId: 'spaeter', expirationDate: DateTime(2027, 1, 1)),
          item(clientId: 'bald', expirationDate: DateTime(2026, 9, 20)),
          item(clientId: 'knapp', expirationDate: DateTime(2026, 9, 5)),
          item(clientId: 'lange-hin', expirationDate: DateTime(2026, 1, 1)),
        ],
        now: now,
      );

      expect(
        rotation.map((e) => e.item.clientId),
        ['lange-hin', 'knapp', 'bald', 'spaeter'],
      );
    });

    test('the same date sorts by name, so the queue does not shuffle', () {
      final date = DateTime(2026, 9, 20);
      final rotation = buildRotation(
        [
          item(clientId: 'z', name: 'Zwieback', expirationDate: date),
          item(clientId: 'a', name: 'Apfelmus', expirationDate: date),
        ],
        now: now,
      );

      expect(rotation.map((e) => e.item.clientId), ['a', 'z']);
    });
  });

  test('beyond the window an item is dated but not pressing', () {
    final rotation = buildRotation(
      [item(clientId: 'a', expirationDate: DateTime(2027, 1, 1))],
      now: now,
    );

    expect(rotation.single.urgency, RotationUrgency.later);
  });

  test('the window edge belongs to the pressing side', () {
    // 30 days out is still "soon"; the count on the overview uses the same
    // window, and the two must not disagree about the same item.
    final rotation = buildRotation(
      [item(clientId: 'a', expirationDate: DateTime(2026, 10, 6))],
      now: now,
    );

    expect(rotation.single.daysLeft, 30);
    expect(rotation.single.urgency, RotationUrgency.soon);
  });
}

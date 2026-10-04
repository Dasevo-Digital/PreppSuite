import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/charge_reminder_provider.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_calendar_export.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The expiry dates as a calendar file (#102).
void main() {
  final now = DateTime(2026, 10, 4, 12);
  const off = ChargeCheck(lastChecked: null, everyDays: 0);

  InventoryItem item(
    String id, {
    String name = 'Bohnen',
    DateTime? expires,
    double quantity = 1,
    String? leadDays,
  }) => InventoryItem(
    clientId: id,
    householdId: 'h',
    name: name,
    category: 'food',
    quantity: quantity,
    unit: 'g',
    storageLocation: 'Keller',
    expirationDate: expires,
    expiryLeadDays: leadDays,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  String? build(List<InventoryItem> items, {ChargeCheck charge = off}) =>
      buildInventoryCalendar(
        items: items,
        householdLeadDays: const [7, 1],
        charge: charge,
        expiryTitle: (item) => 'MHD: ${item.name}',
        chargeTitle: 'Akkus prüfen',
        chargeDescription: 'Powerbanks aufladen',
        now: now,
      );

  /// The file with its folds undone, one logical line per entry.
  List<String> lines(String ics) =>
      ics.replaceAll('\r\n ', '').split('\r\n')..removeLast();

  test('an item with a future date is an all-day event', () {
    final ics = build([item('a', expires: DateTime(2026, 12, 24))])!;

    expect(
      lines(ics),
      containsAllInOrder([
        'BEGIN:VCALENDAR',
        'BEGIN:VEVENT',
        'UID:a-expiry@preppsuite',
        'DTSTART;VALUE=DATE:20261224',
        'DTEND;VALUE=DATE:20261225',
        'SUMMARY:MHD: Bohnen',
        'END:VEVENT',
        'END:VCALENDAR',
      ]),
    );
  });

  test('the household lead times become reminders at nine', () {
    final ics = build([item('a', expires: DateTime(2026, 12, 24))])!;

    // Seven days ahead at nine: six days and fifteen hours before midnight.
    expect(lines(ics), contains('TRIGGER:-P6DT15H'));
    expect(lines(ics), contains('TRIGGER:-P0DT15H'));
  });

  test("an item's own lead time wins, and 'never' means no alarm", () {
    final own = build([
      item('a', expires: DateTime(2026, 12, 24), leadDays: '30'),
    ])!;
    expect(lines(own), contains('TRIGGER:-P29DT15H'));
    expect(lines(own), isNot(contains('TRIGGER:-P6DT15H')));

    final never = build([
      item('a', expires: DateTime(2026, 12, 24), leadDays: ''),
    ])!;
    expect(never, isNot(contains('BEGIN:VALARM')));
  });

  test('past dates, used-up and undated items stay out', () {
    expect(
      build([
        item('past', expires: DateTime(2026, 9, 1)),
        item('empty', expires: DateTime(2026, 12, 24), quantity: 0),
        item('undated'),
      ]),
      isNull,
    );
  });

  test('the battery check repeats at its own interval', () {
    final ics = build(
      const [],
      charge: ChargeCheck(lastChecked: DateTime(2026, 10, 1), everyDays: 90),
    )!;

    expect(
      lines(ics),
      containsAllInOrder([
        'UID:charge-check@preppsuite',
        'DTSTART;VALUE=DATE:20261230',
        'RRULE:FREQ=DAILY;INTERVAL=90',
        'SUMMARY:Akkus prüfen',
      ]),
    );
  });

  test('commas and semicolons in a name are escaped', () {
    final ics = build([
      item('a', name: 'Reis, Nudeln; Mehl', expires: DateTime(2026, 12, 24)),
    ])!;

    expect(lines(ics), contains(r'SUMMARY:MHD: Reis\, Nudeln\; Mehl'));
  });

  test('long lines fold at 75 octets, never inside an umlaut', () {
    final name = 'Gemüsebrühe ' * 10;
    final ics = build([
      item('a', name: name, expires: DateTime(2026, 12, 24)),
    ])!;

    for (final physical in ics.split('\r\n')) {
      expect(utf8.encode(physical).length, lessThanOrEqualTo(75));
    }
    // Decodes cleanly and unfolds back to the whole name.
    expect(lines(ics), contains('SUMMARY:MHD: $name'));
  });

  test('every line ends in CRLF', () {
    final ics = build([item('a', expires: DateTime(2026, 12, 24))])!;

    expect(ics.endsWith('\r\n'), isTrue);
    expect(ics.replaceAll('\r\n', ''), isNot(contains('\n')));
  });
}

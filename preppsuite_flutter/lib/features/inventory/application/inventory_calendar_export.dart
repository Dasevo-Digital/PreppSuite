/// The stock's expiry dates and the battery check, as a calendar file.
///
/// The reminders the app schedules itself live on this one device and in
/// nobody else's day. A household calendar is where the other people in
/// the household already look, and an `.ics` file is the one thing every
/// calendar takes: Apple's, Google's, Outlook, Thunderbird (#102).
///
/// What goes out is what the file says and no more: an item's name and
/// its date. No quantities, no storage places, no notes -- a shared
/// calendar is read by more people than the inventory.
///
/// Every event carries a stable UID, so importing a newer file updates
/// the events from the older one instead of adding a second set.
library;

import 'dart:convert';

import '../../../local_db/database.dart';
import 'charge_reminder_provider.dart';
import 'expiry_reminder_planner.dart';

/// Builds the calendar, or null when there is nothing to put in it.
///
/// [householdLeadDays] are the household's reminder lead times; an item
/// with its own (`InventoryItem.expiryLeadDays`) uses those instead, and an
/// item set to "never" gets its event without an alarm. Dates before
/// today are left out: a calendar entry for a tin that expired last month
/// reminds nobody of anything.
String? buildInventoryCalendar({
  required List<InventoryItem> items,
  required List<int> householdLeadDays,
  required ChargeCheck charge,
  required String Function(InventoryItem item) expiryTitle,
  required String chargeTitle,
  required String chargeDescription,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final stamp = _utcStamp(clock);

  final events = <List<String>>[];
  for (final item in items) {
    final expires = item.expirationDate;
    if (item.deletedAt != null || item.quantity <= 0 || expires == null) {
      continue;
    }
    final day = DateTime(expires.year, expires.month, expires.day);
    if (day.isBefore(today)) continue;
    final leadDays =
        decodeItemLeadDays(item.expiryLeadDays) ?? householdLeadDays;
    events.add([
      'BEGIN:VEVENT',
      'UID:${item.clientId}-expiry@preppsuite',
      'DTSTAMP:$stamp',
      'DTSTART;VALUE=DATE:${_date(day)}',
      'DTEND;VALUE=DATE:${_date(day.add(const Duration(days: 1)))}',
      'SUMMARY:${_text(expiryTitle(item))}',
      'TRANSP:TRANSPARENT',
      for (final lead in leadDays) ..._alarm(lead),
      'END:VEVENT',
    ]);
  }

  final due = charge.dueAt;
  if (!charge.isOff && due != null) {
    events.add([
      'BEGIN:VEVENT',
      'UID:charge-check@preppsuite',
      'DTSTAMP:$stamp',
      'DTSTART;VALUE=DATE:${_date(due)}',
      'DTEND;VALUE=DATE:${_date(due.add(const Duration(days: 1)))}',
      'RRULE:FREQ=DAILY;INTERVAL=${charge.everyDays}',
      'SUMMARY:${_text(chargeTitle)}',
      'DESCRIPTION:${_text(chargeDescription)}',
      'TRANSP:TRANSPARENT',
      ..._alarm(0),
      'END:VEVENT',
    ]);
  }

  if (events.isEmpty) return null;
  final lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//PreppSuite//Vorrat//DE',
    'CALSCALE:GREGORIAN',
    for (final event in events) ...event,
    'END:VCALENDAR',
  ];
  // RFC 5545: CRLF line ends, and lines folded at 75 octets.
  return '${lines.map(_fold).join('\r\n')}\r\n';
}

/// How many items went into the calendar, for the message afterwards.
int calendarItemCount(List<InventoryItem> items, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  return items.where((item) {
    final expires = item.expirationDate;
    return item.deletedAt == null &&
        item.quantity > 0 &&
        expires != null &&
        !DateTime(expires.year, expires.month, expires.day).isBefore(today);
  }).length;
}

/// A reminder at nine in the morning, [days] before an all-day event.
///
/// An all-day event starts at midnight, so "-P3D" would ring at midnight
/// three days ahead. Nine o'clock is when the app's own reminders come
/// too.
List<String> _alarm(int days) => [
  'BEGIN:VALARM',
  'ACTION:DISPLAY',
  'DESCRIPTION:PreppSuite',
  days <= 0 ? 'TRIGGER:PT9H' : 'TRIGGER:-P${days - 1}DT15H',
  'END:VALARM',
];

String _date(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}'
    '${day.month.toString().padLeft(2, '0')}'
    '${day.day.toString().padLeft(2, '0')}';

String _utcStamp(DateTime time) {
  final utc = time.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${_date(utc)}T${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

/// RFC 5545 text: backslash, semicolon, comma and line breaks escaped.
String _text(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll(RegExp(r'\r\n|\r|\n'), r'\n');

/// Folds a line at 75 octets without cutting a character in half: an
/// umlaut is two octets, and a fold between them breaks the file.
String _fold(String line) {
  if (utf8.encode(line).length <= 75) return line;
  final parts = <String>[];
  final current = StringBuffer();
  var octets = 0;
  // The first line may hold 75 octets, every continuation 74 after the
  // leading space.
  var limit = 75;
  for (final rune in line.runes) {
    final char = String.fromCharCode(rune);
    final size = utf8.encode(char).length;
    if (octets + size > limit) {
      parts.add(current.toString());
      current.clear();
      octets = 0;
      limit = 74;
    }
    current.write(char);
    octets += size;
  }
  parts.add(current.toString());
  return parts.join('\r\n ');
}

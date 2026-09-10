import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_day.dart';

/// The second Thursday in September, worked out on the device.
///
/// Off-by-one-week is the failure mode here and it is invisible: a date
/// that looks plausible, a reminder that arrives on the wrong Thursday,
/// and nobody the wiser until the sirens do not sound. So the years below
/// are pinned against the calendar rather than against this code.
void main() {
  test('September starting on a Thursday still gives the second one', () {
    // 1 September 2033 is a Thursday, so the first Thursday is the 1st and
    // the second is the 8th. The case an offset of "add 7 to the first
    // weekday found" gets wrong.
    expect(DateTime(2033, 9).weekday, DateTime.thursday);
    expect(federalWarningDay(2033), DateTime(2033, 9, 8));
  });

  test('September starting on a Friday pushes it to the 14th', () {
    // 1 September 2028 is a Friday: first Thursday the 7th, second the
    // 14th — the latest the day can ever fall.
    expect(DateTime(2028, 9).weekday, DateTime.friday);
    expect(federalWarningDay(2028), DateTime(2028, 9, 14));
  });

  test('the known years match the announced dates', () {
    // Announced by the BBK for these years.
    expect(federalWarningDay(2026), DateTime(2026, 9, 10));
    expect(federalWarningDay(2025), DateTime(2025, 9, 11));
    expect(federalWarningDay(2024), DateTime(2024, 9, 12));
    expect(federalWarningDay(2023), DateTime(2023, 9, 14));
  });

  test('it always lands on a Thursday, and always in the 8th to 14th', () {
    for (var year = 2026; year <= 2050; year++) {
      final day = federalWarningDay(year);
      expect(day.weekday, DateTime.thursday, reason: '$year');
      expect(day.month, 9, reason: '$year');
      expect(day.day, inInclusiveRange(8, 14), reason: '$year');
    }
  });

  group('the next one', () {
    test('is today, all day, when today is the day', () {
      // Not tomorrow-onwards: checking whether the warning routes work is
      // still worth doing at four in the afternoon.
      final onTheDay = DateTime(2026, 9, 10, 16, 30);

      expect(nextFederalWarningDay(from: onTheDay), DateTime(2026, 9, 10));
      expect(daysUntilFederalWarningDay(from: onTheDay), 0);
      expect(isFederalWarningDay(onTheDay), isTrue);
    });

    test('rolls into next year the day after', () {
      final afterwards = DateTime(2026, 9, 11);

      expect(nextFederalWarningDay(from: afterwards), DateTime(2027, 9, 9));
      expect(daysUntilFederalWarningDay(from: afterwards), 363);
    });

    test('counts down from earlier in the year', () {
      expect(
        daysUntilFederalWarningDay(from: DateTime(2026, 9, 3)),
        7,
        reason: 'a week before',
      );
      expect(
        nextFederalWarningDay(from: DateTime(2026, 1, 1)),
        DateTime(2026, 9, 10),
      );
    });

    test('the time of day does not shift the count', () {
      // Compared at midnight, like the charge reminder: a reminder set at
      // eight in the morning is not "due at eight" a year later.
      expect(
        daysUntilFederalWarningDay(from: DateTime(2026, 9, 9, 23, 59)),
        1,
      );
      expect(daysUntilFederalWarningDay(from: DateTime(2026, 9, 9)), 1);
    });

    test('a day in December looks to the coming September', () {
      expect(
        nextFederalWarningDay(from: DateTime(2026, 12, 24)),
        DateTime(2027, 9, 9),
      );
    });
  });

  test('an ordinary day is not a warning day', () {
    expect(isFederalWarningDay(DateTime(2026, 9, 9)), isFalse);
    expect(isFederalWarningDay(DateTime(2026, 9, 17)), isFalse);
    expect(isFederalWarningDay(DateTime(2026, 3, 12)), isFalse);
  });
}

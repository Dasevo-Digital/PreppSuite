import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:preppsuite_flutter/features/energy/presentation/outage_screen.dart';

/// A full freezer holds 48 hours: "Bis 14:30" on a note on its door meant
/// the day after tomorrow, and nothing on the note said so.
void main() {
  setUpAll(() => initializeDateFormatting('de'));

  final now = DateTime(2026, 11, 12, 9);

  test('today is the time alone', () {
    expect(
      outageClockTime(DateTime(2026, 11, 12, 14, 30), 'de', now: now),
      '14:30',
    );
  });

  test('any other day says which', () {
    final later = outageClockTime(
      DateTime(2026, 11, 14, 14, 30),
      'de',
      now: now,
    );
    expect(later, contains('14:30'));
    expect(later, contains('14.11'));
    final earlier = outageClockTime(
      DateTime(2026, 11, 11, 22, 30),
      'de',
      now: now,
    );
    expect(earlier, contains('11.11'));
  });
}

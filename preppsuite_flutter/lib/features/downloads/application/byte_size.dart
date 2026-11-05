import 'package:intl/intl.dart';

/// A file size to put in front of someone.
///
/// Decimal units, because that is what a mirror means when it says a
/// download is 52 GB — matching the disk's own arithmetic matters more
/// here than the binary units a programmer would reach for.
///
/// Written in [locale], or in the app's language where none is named:
/// the app sets `Intl.defaultLocale` (#294). It wrote "1.4 GB" for a
/// German reader before, with the decimal point its own comment below
/// had already put a comma in place of.
String formatByteSize(int bytes, {String? locale}) {
  if (bytes < 1000) return '$bytes B';

  const units = ['kB', 'MB', 'GB', 'TB'];
  var value = bytes / 1000;
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }

  // One decimal below ten, none above: "1,4 GB" is worth knowing, "523,7
  // MB" is noise. Rounded first, so 9.96 does not come out as "10,0".
  final digits = value < 9.95 ? 1 : 0;
  final number = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: digits,
  ).format(value);
  return '$number ${units[unit]}';
}

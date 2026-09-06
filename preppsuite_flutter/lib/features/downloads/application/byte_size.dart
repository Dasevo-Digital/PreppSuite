/// A file size to put in front of someone.
///
/// Decimal units, because that is what a mirror means when it says a
/// download is 52 GB — matching the disk's own arithmetic matters more
/// here than the binary units a programmer would reach for.
String formatByteSize(int bytes) {
  if (bytes < 1000) return '$bytes B';

  const units = ['kB', 'MB', 'GB', 'TB'];
  var value = bytes / 1000;
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }

  // One decimal below ten, none above: "1,4 GB" is worth knowing, "523,7
  // MB" is noise.
  final digits = value < 10 ? 1 : 0;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

import 'package:csv/csv.dart';

import '../../../local_db/database.dart';

/// Column headers written by the export.
///
/// Every one of these is a header the importer recognizes (see the
/// `_...Headers` sets in `inventory_csv_import.dart`), which is the whole
/// point: an export nobody can read back in is not a way out of the app,
/// it is a screenshot. `inventory_csv_export_test` holds that round trip
/// in place.
const inventoryCsvHeaders = [
  'name',
  'category',
  'quantity',
  'unit',
  'storageLocation',
  'expirationDate',
  'minQuantity',
  'notes',
];

/// Semicolon, because a comma-separated file opens as a single column in a
/// German Excel — and someone exporting their supplies is usually about to
/// open them in a spreadsheet. The importer accepts either.
const inventoryCsvFieldDelimiter = ';';

/// Writes [items] as CSV.
///
/// Numbers use a decimal point rather than a comma: with a semicolon as
/// the field separator both would parse, but a point cannot be mistaken
/// for a separator by anything else that reads the file. Dates are written
/// as `YYYY-MM-DD`, the one format that sorts correctly as text and is
/// unambiguous between German and US readings.
String buildInventoryCsv(List<InventoryItem> items) {
  final rows = <List<String>>[
    inventoryCsvHeaders,
    for (final item in items)
      if (item.deletedAt == null)
        [
          item.name,
          item.category,
          _number(item.quantity),
          item.unit,
          item.storageLocation,
          _date(item.expirationDate),
          item.minQuantity == null ? '' : _number(item.minQuantity!),
          item.notes ?? '',
        ],
  ];

  // Excel preset: semicolon-separated with a byte-order mark, so a German
  // Excel opens the file in columns and shows umlauts correctly instead of
  // mojibake. The importer reads it back either way.
  return Csv.excel().encode(rows);
}

/// Drops the pointless `.0` on whole numbers — "6" rather than "6.0" is
/// what someone typed in and what they expect to see again.
String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

String _date(DateTime? value) {
  if (value == null) return '';
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

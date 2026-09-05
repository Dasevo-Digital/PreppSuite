import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import '../../../model/categories.dart';

/// A single successfully-parsed CSV row, ready to hand to
/// [InventoryController.addItemsBulk]. Also what an edited [InventoryCsvRow]
/// (valid or previously invalid) turns into once the user confirms it in
/// the edit dialog.
class ParsedInventoryRow {
  const ParsedInventoryRow({
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.storageLocation,
    this.expirationDate,
    this.minQuantity,
    this.notes,
  });

  final String name;
  final InventoryItemCategory category;
  final double quantity;
  final String unit;
  final String storageLocation;
  final DateTime? expirationDate;
  final double? minQuantity;
  final String? notes;
}

/// Why a given CSV row couldn't be parsed automatically. The presentation
/// layer turns this into a localized message; kept as an enum (plus
/// [detail] for the offending raw value) rather than a raw string so the
/// message can be translated.
enum InventoryCsvErrorType {
  nameMissing,
  unknownCategory,
  invalidQuantity,
  unitMissing,
  storageLocationMissing,
  invalidDate,
  invalidMinQuantity,
}

class InventoryCsvRowError {
  const InventoryCsvRowError({required this.type, this.detail});

  final InventoryCsvErrorType type;
  final String? detail;
}

/// One data row from the CSV, always carrying its raw cell text (for every
/// recognized column, `''` if that column wasn't present) regardless of
/// whether it parsed cleanly. This lets the UI offer a fix-it edit dialog
/// pre-filled with whatever *was* readable, rather than only being able to
/// show rows that already fully validated.
class InventoryCsvRow {
  const InventoryCsvRow({
    required this.rowNumber,
    required this.nameRaw,
    required this.categoryRaw,
    required this.quantityRaw,
    required this.unitRaw,
    required this.storageLocationRaw,
    required this.expirationDateRaw,
    required this.minQuantityRaw,
    required this.notesRaw,
    this.parsed,
    this.error,
  });

  /// 1-based, counting the header line as row 1 (matches what a user sees
  /// if they open the file in a spreadsheet app).
  final int rowNumber;

  final String nameRaw;
  final String categoryRaw;
  final String quantityRaw;
  final String unitRaw;
  final String storageLocationRaw;
  final String expirationDateRaw;
  final String minQuantityRaw;
  final String notesRaw;

  /// Non-null when this row parsed cleanly on its own.
  final ParsedInventoryRow? parsed;

  /// Non-null when this row needs a manual fix before it can be imported.
  final InventoryCsvRowError? error;

  bool get isValid => parsed != null;

  InventoryCsvRow withParsed(ParsedInventoryRow row) => InventoryCsvRow(
    rowNumber: rowNumber,
    nameRaw: row.name,
    categoryRaw: row.category.name,
    quantityRaw: quantityRaw,
    unitRaw: row.unit,
    storageLocationRaw: row.storageLocation,
    expirationDateRaw: expirationDateRaw,
    minQuantityRaw: minQuantityRaw,
    notesRaw: notesRaw,
    parsed: row,
  );
}

class InventoryCsvParseResult {
  const InventoryCsvParseResult({
    required this.rows,
    this.missingColumns = false,
  });

  final List<InventoryCsvRow> rows;

  /// True if the header row was missing one of the required columns; in
  /// that case [rows] is always empty since column positions couldn't be
  /// determined at all.
  final bool missingColumns;
}

const _nameHeaders = {'name', 'artikel', 'bezeichnung'};
const _categoryHeaders = {'category', 'kategorie'};
const _quantityHeaders = {'quantity', 'menge', 'anzahl'};
const _unitHeaders = {'unit', 'einheit'};
const _storageHeaders = {
  'storagelocation',
  'storage location',
  'lagerort',
  'ort',
};
const _expirationHeaders = {
  'expirationdate',
  'expiration date',
  'ablaufdatum',
  'verfallsdatum',
  'mhd',
};
const _minQuantityHeaders = {
  'minquantity',
  'min quantity',
  'mindestbestand',
  'mindestmenge',
};
const _notesHeaders = {'notes', 'notizen', 'bemerkung', 'bemerkungen'};

const Map<String, InventoryItemCategory> categoryAliases = {
  'water': InventoryItemCategory.water,
  'wasser': InventoryItemCategory.water,
  'food': InventoryItemCategory.food,
  'essen': InventoryItemCategory.food,
  'lebensmittel': InventoryItemCategory.food,
  'medical': InventoryItemCategory.medical,
  'medizin': InventoryItemCategory.medical,
  'erste hilfe': InventoryItemCategory.medical,
  'tools': InventoryItemCategory.tools,
  'werkzeug': InventoryItemCategory.tools,
  'documents': InventoryItemCategory.documents,
  'dokumente': InventoryItemCategory.documents,
  'energy': InventoryItemCategory.energy,
  'energie': InventoryItemCategory.energy,
  'hygiene': InventoryItemCategory.hygiene,
  'other': InventoryItemCategory.other,
  'sonstiges': InventoryItemCategory.other,
  'sonstige': InventoryItemCategory.other,
};

/// Decodes file bytes picked by `file_picker`. CSV exports from German
/// spreadsheet tools are often Windows-1252/Latin-1 rather than UTF-8 (e.g.
/// due to umlauts); fall back to Latin-1 if strict UTF-8 decoding fails.
String decodeCsvBytes(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes);
  }
}

double? parseCsvNumber(String raw) {
  if (raw.isEmpty) return null;
  return double.tryParse(raw.replaceAll(',', '.'));
}

DateTime? parseCsvDate(String raw) {
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
  final de = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{2,4})$');

  var match = iso.firstMatch(raw);
  if (match != null) {
    return DateTime(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  match = de.firstMatch(raw);
  if (match != null) {
    var year = int.parse(match[3]!);
    if (year < 100) year += 2000;
    return DateTime(year, int.parse(match[2]!), int.parse(match[1]!));
  }

  return null;
}

InventoryItemCategory? matchCategory(String raw) {
  final normalized = raw.trim().toLowerCase();
  final alias = categoryAliases[normalized];
  if (alias != null) return alias;
  for (final category in InventoryItemCategory.values) {
    if (category.name.toLowerCase() == normalized) return category;
  }
  return null;
}

/// Parses a CSV file's contents (as decoded text) into inventory rows.
///
/// Accepts either `,` or `;` as the field delimiter (auto-detected) and
/// both German and English column headers (see the `_...Headers` sets
/// above), case-insensitively. `name`, `category`, `quantity`, `unit`, and
/// `storageLocation` are required columns; `expirationDate`, `minQuantity`,
/// and `notes` are optional. Every data row is returned regardless of
/// whether it parsed — rows that didn't carry their raw cell text plus an
/// [InventoryCsvRowError] instead of a [ParsedInventoryRow], so the UI can
/// offer to fix them rather than silently dropping them.
InventoryCsvParseResult parseInventoryCsv(String content) {
  // `autoDetect` picks between `,` and `;` per line — German spreadsheet
  // exports commonly use `;` since `,` is the decimal separator there.
  final table = Csv(autoDetect: true).decode(content);

  if (table.isEmpty) {
    return const InventoryCsvParseResult(rows: []);
  }

  final header = table.first
      .map((cell) => cell.toString().trim().toLowerCase())
      .toList();
  final columnIndex = <String, int>{
    for (var i = 0; i < header.length; i++) header[i]: i,
  };

  int? indexFor(Set<String> aliases) {
    for (final alias in aliases) {
      final index = columnIndex[alias];
      if (index != null) return index;
    }
    return null;
  }

  final nameIdx = indexFor(_nameHeaders);
  final categoryIdx = indexFor(_categoryHeaders);
  final quantityIdx = indexFor(_quantityHeaders);
  final unitIdx = indexFor(_unitHeaders);
  final storageIdx = indexFor(_storageHeaders);
  final expirationIdx = indexFor(_expirationHeaders);
  final minQuantityIdx = indexFor(_minQuantityHeaders);
  final notesIdx = indexFor(_notesHeaders);

  if (nameIdx == null ||
      categoryIdx == null ||
      quantityIdx == null ||
      unitIdx == null ||
      storageIdx == null) {
    return const InventoryCsvParseResult(rows: [], missingColumns: true);
  }

  final rows = <InventoryCsvRow>[];

  for (var r = 1; r < table.length; r++) {
    final rowNumber = r + 1;
    final row = table[r];
    if (row.every((cell) => cell.toString().trim().isEmpty)) continue;

    String cell(int? index) =>
        index != null && index < row.length ? row[index].toString().trim() : '';

    final nameRaw = cell(nameIdx);
    final categoryRaw = cell(categoryIdx);
    final quantityRaw = cell(quantityIdx);
    final unitRaw = cell(unitIdx);
    final storageLocationRaw = cell(storageIdx);
    final expirationDateRaw = cell(expirationIdx);
    final minQuantityRaw = cell(minQuantityIdx);
    final notesRaw = cell(notesIdx);

    InventoryCsvRowError? error;
    ParsedInventoryRow? parsed;

    final category = matchCategory(categoryRaw);
    final quantity = parseCsvNumber(quantityRaw);
    final expirationDate = expirationDateRaw.isEmpty
        ? null
        : parseCsvDate(expirationDateRaw);
    final minQuantity = minQuantityRaw.isEmpty
        ? null
        : parseCsvNumber(minQuantityRaw);

    if (nameRaw.isEmpty) {
      error = const InventoryCsvRowError(
        type: InventoryCsvErrorType.nameMissing,
      );
    } else if (category == null) {
      error = InventoryCsvRowError(
        type: InventoryCsvErrorType.unknownCategory,
        detail: categoryRaw,
      );
    } else if (quantity == null) {
      error = InventoryCsvRowError(
        type: InventoryCsvErrorType.invalidQuantity,
        detail: quantityRaw,
      );
    } else if (unitRaw.isEmpty) {
      error = const InventoryCsvRowError(
        type: InventoryCsvErrorType.unitMissing,
      );
    } else if (storageLocationRaw.isEmpty) {
      error = const InventoryCsvRowError(
        type: InventoryCsvErrorType.storageLocationMissing,
      );
    } else if (expirationDateRaw.isNotEmpty && expirationDate == null) {
      error = InventoryCsvRowError(
        type: InventoryCsvErrorType.invalidDate,
        detail: expirationDateRaw,
      );
    } else if (minQuantityRaw.isNotEmpty && minQuantity == null) {
      error = InventoryCsvRowError(
        type: InventoryCsvErrorType.invalidMinQuantity,
        detail: minQuantityRaw,
      );
    } else {
      parsed = ParsedInventoryRow(
        name: nameRaw,
        category: category,
        quantity: quantity,
        unit: unitRaw,
        storageLocation: storageLocationRaw,
        expirationDate: expirationDate,
        minQuantity: minQuantity,
        notes: notesRaw.isEmpty ? null : notesRaw,
      );
    }

    rows.add(
      InventoryCsvRow(
        rowNumber: rowNumber,
        nameRaw: nameRaw,
        categoryRaw: categoryRaw,
        quantityRaw: quantityRaw,
        unitRaw: unitRaw,
        storageLocationRaw: storageLocationRaw,
        expirationDateRaw: expirationDateRaw,
        minQuantityRaw: minQuantityRaw,
        notesRaw: notesRaw,
        parsed: parsed,
        error: error,
      ),
    );
  }

  return InventoryCsvParseResult(rows: rows);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_csv_export.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_csv_import.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  InventoryItem item({
    String clientId = 'a',
    String name = 'Nudeln',
    String category = 'food',
    double quantity = 5,
    String unit = 'Stk',
    String storageLocation = 'Keller',
    DateTime? expirationDate,
    double? minQuantity,
    String? notes,
    DateTime? deletedAt,
  }) {
    return InventoryItem(
      clientId: clientId,
      householdId: 'h',
      name: name,
      category: category,
      quantity: quantity,
      unit: unit,
      storageLocation: storageLocation,
      expirationDate: expirationDate,
      minQuantity: minQuantity,
      notes: notes,
      deletedAt: deletedAt,
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );
  }

  group('buildInventoryCsv', () {
    test('writes a header line the importer accepts', () {
      // Checking that the names merely appear was too weak to catch a
      // header the importer does not know ("storage" instead of
      // "storageLocation"); asking the importer itself is the real test.
      final result = parseInventoryCsv(buildInventoryCsv([item()]));

      expect(
        result.missingColumns,
        isFalse,
        reason: 'every required column must be under a recognized name',
      );
    });

    test('leaves out tombstoned items', () {
      // They are deleted as far as the user is concerned; an export that
      // resurrects them on the next import would be a nasty surprise.
      final csv = buildInventoryCsv([
        item(clientId: 'a', name: 'Vorhanden'),
        item(clientId: 'b', name: 'Geloescht', deletedAt: DateTime.utc(2026)),
      ]);

      expect(csv, contains('Vorhanden'));
      expect(csv, isNot(contains('Geloescht')));
    });

    test('writes whole numbers without a decimal tail', () {
      final csv = buildInventoryCsv([item(quantity: 6)]);

      expect(csv, contains('6'));
      expect(csv, isNot(contains('6.0')));
    });

    test('writes dates in a sortable, unambiguous form', () {
      final csv = buildInventoryCsv([
        item(expirationDate: DateTime(2026, 3, 7)),
      ]);

      expect(csv, contains('2026-03-07'));
    });

    test('leaves optional fields empty rather than writing "null"', () {
      final csv = buildInventoryCsv([item()]);

      expect(csv, isNot(contains('null')));
    });

    test('an empty inventory still produces the header', () {
      final csv = buildInventoryCsv([]);

      expect(csv.trim().split('\r\n'), hasLength(1));
    });
  });

  group('round trip through the importer', () {
    /// The property that makes the export worth anything: what comes out
    /// can go back in. An export nobody can read back is a screenshot, not
    /// a way out of the app.
    test('every field survives export and re-import', () {
      final original = item(
        name: 'Vollkornnudeln',
        category: 'food',
        quantity: 2.5,
        unit: 'kg',
        storageLocation: 'Vorratskammer',
        expirationDate: DateTime(2027, 1, 15),
        minQuantity: 1.5,
        notes: 'Unterste Schublade',
      );

      final result = parseInventoryCsv(buildInventoryCsv([original]));

      expect(result.missingColumns, isFalse);
      expect(result.rows, hasLength(1));

      final parsed = result.rows.single.parsed;
      expect(parsed, isNotNull, reason: result.rows.single.error?.type.name);
      expect(parsed!.name, original.name);
      expect(parsed.category.name, original.category);
      expect(parsed.quantity, original.quantity);
      expect(parsed.unit, original.unit);
      expect(parsed.storageLocation, original.storageLocation);
      expect(parsed.expirationDate, original.expirationDate);
      expect(parsed.minQuantity, original.minQuantity);
      expect(parsed.notes, original.notes);
    });

    test('items without optional fields survive too', () {
      final result = parseInventoryCsv(
        buildInventoryCsv([item(name: 'Kerzen', category: 'other')]),
      );

      final parsed = result.rows.single.parsed;
      expect(parsed, isNotNull);
      expect(parsed!.name, 'Kerzen');
      expect(parsed.expirationDate, isNull);
      expect(parsed.minQuantity, isNull);
    });

    test('every category round-trips', () {
      // The importer maps category names through its own alias table; a
      // mismatch would silently turn every "medical" item into an error.
      const categories = [
        'water',
        'food',
        'medical',
        'tools',
        'documents',
        'energy',
        'hygiene',
        'other',
      ];
      final items = [
        for (final (i, c) in categories.indexed)
          item(clientId: 'c$i', name: 'Artikel $i', category: c),
      ];

      final result = parseInventoryCsv(buildInventoryCsv(items));

      expect(result.rows, hasLength(categories.length));
      expect(
        result.rows.map((r) => r.parsed?.category.name),
        categories,
      );
    });

    test('text with separators and quotes survives', () {
      // A note containing the field separator would split the row if it
      // were not quoted on the way out.
      final original = item(
        name: 'Reis; parboiled',
        notes: 'Regal "B", hinten',
        storageLocation: 'Keller, links',
      );

      final result = parseInventoryCsv(buildInventoryCsv([original]));

      final parsed = result.rows.single.parsed;
      expect(parsed, isNotNull);
      expect(parsed!.name, original.name);
      expect(parsed.notes, original.notes);
      expect(parsed.storageLocation, original.storageLocation);
    });

    test('umlauts survive', () {
      final result = parseInventoryCsv(
        buildInventoryCsv([
          item(name: 'Müsliriegel', storageLocation: 'Küchenschrank'),
        ]),
      );

      final parsed = result.rows.single.parsed;
      expect(parsed!.name, 'Müsliriegel');
      expect(parsed.storageLocation, 'Küchenschrank');
    });

    test('a whole inventory round-trips unchanged', () {
      final items = [
        item(
          clientId: 'a',
          name: 'Wasser',
          category: 'water',
          quantity: 24,
          unit: 'l',
        ),
        item(
          clientId: 'b',
          name: 'Verbandskasten',
          category: 'medical',
          quantity: 1,
          minQuantity: 1,
          expirationDate: DateTime(2028, 6, 30),
        ),
        item(
          clientId: 'c',
          name: 'Taschenlampe',
          category: 'tools',
          quantity: 3,
        ),
      ];

      final result = parseInventoryCsv(buildInventoryCsv(items));

      expect(result.rows.where((r) => r.parsed == null), isEmpty);
      expect(
        result.rows.map((r) => r.parsed!.name),
        items.map((i) => i.name),
      );
      expect(
        result.rows.map((r) => r.parsed!.quantity),
        items.map((i) => i.quantity),
      );
    });
  });
}

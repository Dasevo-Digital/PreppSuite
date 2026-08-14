import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_client/preppsuite_client.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_csv_import.dart';

void main() {
  group('parseInventoryCsv', () {
    test('parses a well-formed comma-delimited file with English headers', () {
      const csv =
          'name,category,quantity,unit,storageLocation,expirationDate,minQuantity,notes\n'
          'Wasser,water,12,Flasche,Keller,2027-05-01,6,still\n'
          'Nudeln,food,3,kg,Speisekammer,,,';

      final result = parseInventoryCsv(csv);

      expect(result.missingColumns, isFalse);
      expect(result.rows, hasLength(2));
      expect(result.rows.every((row) => row.isValid), isTrue);

      final water = result.rows[0].parsed!;
      expect(water.name, 'Wasser');
      expect(water.category, InventoryItemCategory.water);
      expect(water.quantity, 12);
      expect(water.unit, 'Flasche');
      expect(water.storageLocation, 'Keller');
      expect(water.expirationDate, DateTime(2027, 5, 1));
      expect(water.minQuantity, 6);
      expect(water.notes, 'still');

      final pasta = result.rows[1].parsed!;
      expect(pasta.expirationDate, isNull);
      expect(pasta.minQuantity, isNull);
      expect(pasta.notes, isNull);
    });

    test('parses semicolon-delimited German export with comma decimals', () {
      const csv =
          'Name;Kategorie;Menge;Einheit;Lagerort;Ablaufdatum;Mindestbestand\n'
          'Kerzen;Energie;10,5;Stück;Keller;01.12.2027;4,5';

      final result = parseInventoryCsv(csv);

      expect(result.missingColumns, isFalse);
      expect(result.rows, hasLength(1));
      final row = result.rows.single.parsed!;
      expect(row.category, InventoryItemCategory.energy);
      expect(row.quantity, 10.5);
      expect(row.expirationDate, DateTime(2027, 12, 1));
      expect(row.minQuantity, 4.5);
    });

    test('reports missing required columns without throwing', () {
      const csv = 'foo,bar\n1,2';

      final result = parseInventoryCsv(csv);

      expect(result.rows, isEmpty);
      expect(result.missingColumns, isTrue);
    });

    test(
      'keeps invalid rows with their raw text and reason, alongside valid ones',
      () {
        const csv =
            'name,category,quantity,unit,storageLocation\n'
            ',water,1,Stück,Keller\n' // missing name
            'Radio,unknown,1,Stück,Keller\n' // unknown category
            'Akku,tools,notanumber,Stück,Keller\n' // invalid quantity
            'Taschenlampe,tools,2,Stück,Keller'; // valid

        final result = parseInventoryCsv(csv);

        expect(result.rows, hasLength(4));
        expect(result.rows.where((row) => row.isValid), hasLength(1));
        expect(result.rows.last.parsed!.name, 'Taschenlampe');

        expect(result.rows[0].error!.type, InventoryCsvErrorType.nameMissing);
        expect(result.rows[0].rowNumber, 2);
        expect(result.rows[0].categoryRaw, 'water');

        expect(
          result.rows[1].error!.type,
          InventoryCsvErrorType.unknownCategory,
        );
        expect(result.rows[1].error!.detail, 'unknown');
        expect(result.rows[1].nameRaw, 'Radio');

        expect(
          result.rows[2].error!.type,
          InventoryCsvErrorType.invalidQuantity,
        );
        expect(result.rows[2].quantityRaw, 'notanumber');
      },
    );

    test('an invalid row can be promoted to valid via withParsed', () {
      const csv =
          'name,category,quantity,unit,storageLocation\n'
          'Radio,unknown,1,Stück,Keller';

      final result = parseInventoryCsv(csv);
      final invalidRow = result.rows.single;
      expect(invalidRow.isValid, isFalse);

      final fixed = invalidRow.withParsed(
        ParsedInventoryRow(
          name: 'Radio',
          category: InventoryItemCategory.tools,
          quantity: 1,
          unit: 'Stück',
          storageLocation: 'Keller',
        ),
      );

      expect(fixed.isValid, isTrue);
      expect(fixed.error, isNull);
      expect(fixed.rowNumber, invalidRow.rowNumber);
    });

    test('skips blank lines', () {
      const csv =
          'name,category,quantity,unit,storageLocation\n'
          'Wasser,water,1,Flasche,Keller\n'
          '\n'
          'Brot,food,1,Stück,Speisekammer';

      final result = parseInventoryCsv(csv);

      expect(result.rows, hasLength(2));
      expect(result.rows.every((row) => row.isValid), isTrue);
    });
  });
}

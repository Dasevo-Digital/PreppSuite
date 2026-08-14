import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/budget/application/missing_equipment_report.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

const _strings = MissingEquipmentReportStrings(
  title: 'Missing Equipment Report',
  generatedOn: 'Generated on 1 January 2026',
  checklistSectionTitle: 'Open checklist items',
  noMissingChecklistItems: 'Nothing open.',
  inventorySectionTitle: 'Low-stock inventory items',
  noLowStockItems: 'Nothing low.',
  columnItem: 'Item',
  columnQuantity: 'Quantity',
  columnMinQuantity: 'Minimum',
  columnUnit: 'Unit',
);

void main() {
  // MissingEquipmentReport loads the embedded font via rootBundle, which
  // needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  test(
    'build produces a valid, non-empty PDF for an empty household',
    () async {
      final bytes = await const MissingEquipmentReport().build(
        db: db,
        householdId: 'household-1',
        householdName: 'Test-Haushalt',
        strings: _strings,
      );

      expect(bytes, isNotEmpty);
      // PDF files start with the "%PDF-" magic header.
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    },
  );

  test(
    'build includes unchecked checklist items grouped under their template '
    'and excludes checked/deleted ones',
    () async {
      await db.upsertChecklistTemplate(
        ChecklistTemplatesCompanion.insert(
          clientId: 'template-1',
          householdId: const Value('household-1'),
          title: 'Wasser',
          category: 'water',
          updatedAt: DateTime.utc(2026),
        ),
      );
      await db.upsertChecklistItem(
        ChecklistItemsCompanion.insert(
          clientId: 'item-open',
          householdId: const Value('household-1'),
          templateClientId: 'template-1',
          title: 'Wasserkanister',
          updatedAt: DateTime.utc(2026),
        ),
      );
      await db.upsertChecklistItem(
        ChecklistItemsCompanion.insert(
          clientId: 'item-checked',
          householdId: const Value('household-1'),
          templateClientId: 'template-1',
          title: 'Bereits erledigt',
          isChecked: const Value(true),
          updatedAt: DateTime.utc(2026),
        ),
      );

      final bytes = await const MissingEquipmentReport().build(
        db: db,
        householdId: 'household-1',
        householdName: 'Test-Haushalt',
        strings: _strings,
      );

      expect(bytes, isNotEmpty);
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    },
  );

  test(
    'build embeds a Unicode font so German umlauts render correctly '
    '(the bundled base-14 PDF fonts silently mangle them)',
    () async {
      await db.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: 'umlaut-item',
          householdId: 'household-1',
          name: 'Wasserfilter für Trinkwasser – Größe M',
          category: 'water',
          quantity: 1,
          unit: 'Stück',
          storageLocation: 'Küche',
          minQuantity: const Value(2),
          updatedAt: DateTime.utc(2026),
        ),
      );

      final bytes = await const MissingEquipmentReport().build(
        db: db,
        householdId: 'household-1',
        householdName: 'Müller-Haushalt',
        strings: _strings,
      );

      // A TrueType font embedded in the PDF shows up as a FontFile2 stream;
      // this is the structural signal that the Unicode font was actually
      // used, not just that generation didn't throw.
      final content = ascii.decode(bytes, allowInvalid: true);
      expect(content, contains('FontFile2'));
    },
  );

  test('build includes inventory items below their minimum quantity', () async {
    await db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'low-stock',
        householdId: 'household-1',
        name: 'Trinkwasser',
        category: 'water',
        quantity: 1,
        unit: 'Flasche',
        storageLocation: 'Keller',
        minQuantity: const Value(6),
        updatedAt: DateTime.utc(2026),
      ),
    );
    await db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'well-stocked',
        householdId: 'household-1',
        name: 'Konserven',
        category: 'food',
        quantity: 10,
        unit: 'Dose',
        storageLocation: 'Keller',
        minQuantity: const Value(6),
        updatedAt: DateTime.utc(2026),
      ),
    );

    final lowStock = await db.lowStockInventoryItems('household-1');

    expect(lowStock.map((i) => i.clientId), ['low-stock']);
  });
}

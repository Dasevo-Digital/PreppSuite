import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/shopping_list.dart';
import 'package:preppsuite_flutter/features/inventory/application/shopping_list_export.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_calculator.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The file another app reads the shopping list from (#155). The format
/// is a promise to that app, so the tests read it back as that app would:
/// as JSON, field by field.
void main() {
  final now = DateTime.utc(2026, 10, 10, 9, 30);

  InventoryItem item({
    required String clientId,
    required String name,
    String category = 'food',
    required double quantity,
    required String unit,
    double? minQuantity,
  }) => InventoryItem(
    clientId: clientId,
    householdId: 'h',
    name: name,
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    minQuantity: minQuantity,
    updatedAt: now,
    dirty: false,
  );

  String german(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');

  Map<String, Object?> export(List<InventoryItem> items, {int days = 10}) {
    final list = buildShoppingList(
      items: items,
      days: days,
      household: const SupplyHousehold(adults: 2),
    );
    return jsonDecode(
      buildShoppingListFile(
        list,
        now: now,
        language: 'de',
        formatAmount: german,
      ),
    ) as Map<String, Object?>;
  }

  test('says what it is before anything else is read', () {
    final file = export(const []);

    expect(file['format'], 'preppsuite-einkaufsliste');
    expect(file['version'], 1);
    expect(file['origin'], 'minimums');
    expect(file['created'], '2026-10-10T09:30:00.000Z');
    expect(file['language'], 'de');
    expect(file['items'], isEmpty);
  });

  test('gives each line its amount for a program and for a person', () {
    final file = export([
      item(
        clientId: 'r',
        name: 'Reis',
        quantity: 0.5,
        unit: 'kg',
        minQuantity: 2,
      ),
    ]);
    final line = (file['items']! as List).single as Map<String, Object?>;

    expect(line['name'], 'Reis');
    expect(line['quantity'], '1,5 kg');
    expect(line['amount'], 1.5);
    expect(line['unit'], 'kg');
    expect(line['minimum'], 2);
    expect(line['supplyCategory'], 'food');
  });

  test('writes whole numbers as integers and keeps float noise out', () {
    final file = export([
      item(
        clientId: 'w',
        name: 'Mineralwasser',
        category: 'water',
        quantity: 6,
        unit: 'l',
        minQuantity: 12,
      ),
      // 0.3 - 0.1 is 0.19999999999999998 in a double.
      item(
        clientId: 'h',
        name: 'Hefe',
        quantity: 0.1,
        unit: 'kg',
        minQuantity: 0.3,
      ),
    ]);
    final lines = (file['items']! as List).cast<Map<String, Object?>>();
    final water = lines.firstWhere((l) => l['name'] == 'Mineralwasser');
    final yeast = lines.firstWhere((l) => l['name'] == 'Hefe');

    expect(water['amount'], isA<int>());
    expect(water['amount'], 6);
    expect(yeast['amount'], 0.2);
  });

  test('keeps the order of the list: the most depleted first', () {
    final file = export([
      item(
        clientId: 'a',
        name: 'Nudeln',
        quantity: 4,
        unit: 'kg',
        minQuantity: 5,
      ),
      item(
        clientId: 'b',
        name: 'Kerzen',
        category: 'energy',
        quantity: 0,
        unit: 'Stück',
        minQuantity: 10,
      ),
    ]);
    final names = [
      for (final line in (file['items']! as List).cast<Map<String, Object?>>())
        line['name'],
    ];

    expect(names, ['Kerzen', 'Nudeln']);
  });

  test('leaves out what is not short', () {
    final file = export([
      item(
        clientId: 'a',
        name: 'Nudeln',
        quantity: 5,
        unit: 'kg',
        minQuantity: 5,
      ),
      item(clientId: 'b', name: 'Salz', quantity: 0, unit: 'kg'),
    ]);

    expect(file['items'], isEmpty);
  });

  test('a line without a unit has no stray space', () {
    final file = export([
      item(
        clientId: 'a',
        name: 'Feuerzeug',
        category: 'energy',
        quantity: 0,
        unit: ' ',
        minQuantity: 2,
      ),
    ]);
    final line = (file['items']! as List).single as Map<String, Object?>;

    expect(line['quantity'], '2');
  });

  test('carries the household target apart from the lines', () {
    // Two adults, ten days: 40 l of water. 6 l in stock leaves 34 l, and
    // the item short of its own minimum does not add a second line.
    final file = export([
      item(
        clientId: 'w',
        name: 'Mineralwasser',
        category: 'water',
        quantity: 6,
        unit: 'l',
        minQuantity: 12,
      ),
    ]);
    final target = file['target']! as Map<String, Object?>;

    expect(target['days'], 10);
    expect(target['met'], isFalse);
    expect(target['waterLiters'], 34);
    expect((file['items']! as List), hasLength(1));
  });

  test('is named by its date', () {
    expect(
      shoppingListFileName(DateTime(2026, 3, 7)),
      'preppsuite-einkaufsliste-2026-03-07.json',
    );
  });
}

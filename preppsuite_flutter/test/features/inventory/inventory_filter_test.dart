import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_filter.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  final now = DateTime(2026, 9, 8, 15);
  InventoryItem item(
    String name, {
    int? days,
    double quantity = 5,
    String location = 'Keller',
    String category = 'food',
  }) => InventoryItem(
    clientId: name,
    householdId: 'h',
    name: name,
    category: category,
    quantity: quantity,
    minQuantity: 2,
    unit: 'Stk',
    storageLocation: location,
    barcode: '12345',
    notes: 'glutenfrei',
    expirationDate: days == null ? null : DateTime(2026, 9, 8 + days),
    updatedAt: now,
    dirty: false,
  );
  test(
    'search combines terms across fields and respects category and location',
    () {
      final items = [
        item('Nudeln'),
        item('Wasser', category: 'water'),
        item('Reis', location: 'Küche'),
      ];
      final found = filterInventory(
        items,
        query: ' KELLER  glutenfrei 123 ',
        filter: const InventoryFilter(category: 'food', location: 'Keller'),
      );
      expect(found.map((e) => e.name), ['Nudeln']);
      expect(items.length, 3);
    },
  );
  test(
    'date-only expiry distinguishes yesterday, today and the end of "soon"',
    () {
      // Thirty days, as on the overview that leads here (#271).
      final items = [
        item('old', days: -1),
        item('today', days: 0),
        item('soon', days: 30),
        item('later', days: 31),
        item('none'),
      ];
      expect(
        filterInventory(
          items,
          now: now,
          filter: const InventoryFilter(status: InventoryStatusFilter.expired),
        ).map((e) => e.name),
        ['old'],
      );
      expect(
        filterInventory(
          items,
          now: now,
          filter: const InventoryFilter(status: InventoryStatusFilter.expiring),
        ).map((e) => e.name),
        ['soon', 'today'],
      );
      expect(
        filterInventory(
          items,
          now: now,
          filter: const InventoryFilter(sort: InventorySort.expiry),
        ).map((e) => e.name),
        ['old', 'today', 'soon', 'later', 'none'],
      );
    },
  );
  test(
    'attention sorts urgent stock first and minimum equality is sufficient',
    () {
      final items = [
        item('normal', quantity: 2),
        item('soon', days: 1),
        item('low', quantity: 1),
        item('expired', days: -1),
      ];
      expect(
        filterInventory(
          items,
          now: now,
          filter: const InventoryFilter(sort: InventorySort.attention),
        ).map((e) => e.name),
        ['expired', 'low', 'soon', 'normal'],
      );
      expect(
        filterInventory(
          items,
          now: now,
          filter: const InventoryFilter(status: InventoryStatusFilter.lowStock),
        ).map((e) => e.name),
        ['low'],
      );
    },
  );

  group('an empty row (#281)', () {
    final items = [
      item('Milch', days: -2, quantity: 0),
      item('Joghurt', days: 3, quantity: 0),
      item('Ravioli', days: -1),
    ];
    List<String> found(InventoryStatusFilter status) => [
      for (final row in filterInventory(
        items,
        now: now,
        filter: InventoryFilter(status: status),
      ))
        row.name,
    ];

    test('is neither expired nor expiring, but still short', () {
      expect(found(InventoryStatusFilter.expired), ['Ravioli']);
      expect(found(InventoryStatusFilter.expiring), isEmpty);
      expect(found(InventoryStatusFilter.lowStock), ['Joghurt', 'Milch']);
    });

    test('and the badge counts what the filter finds', () {
      // Ravioli past its date; the two empty rows under their minimum.
      expect(countNeedingAttention(items, now: now), 3);
      expect(
        countNeedingAttention([
          item('Milch', days: -2, quantity: 5),
          item('Reis', quantity: 5),
        ], now: now),
        1,
      );
    });
  });

  test('sorts by name as a dictionary does (#283)', () {
    final items = [
      item('Zucker'),
      item('Öl'),
      item('apfelmus'),
      item('Äpfel'),
      item('Nudeln'),
    ];
    expect(filterInventory(items, now: now).map((e) => e.name), [
      'Äpfel',
      'apfelmus',
      'Nudeln',
      'Öl',
      'Zucker',
    ]);
  });
}

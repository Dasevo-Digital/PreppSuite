import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/home_overview.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

void main() {
  final now = DateTime.utc(2026, 9, 6);

  InventoryItem item({
    String clientId = 'a',
    String category = 'food',
    double quantity = 5,
    double? minQuantity,
    DateTime? expirationDate,
  }) => InventoryItem(
    clientId: clientId,
    householdId: 'household-1',
    name: 'Nudeln',
    category: category,
    quantity: quantity,
    unit: 'Packung',
    storageLocation: 'Keller',
    minQuantity: minQuantity,
    expirationDate: expirationDate,
    updatedAt: now,
    dirty: false,
  );

  group('summarizing the inventory', () {
    test('an empty inventory reads as empty, not as fine', () {
      final overview = summarizeInventory(const [], now: now);

      expect(overview.isEmpty, isTrue);
      expect(overview.total, 0);
      expect(overview.needsAttention, 0);
      expect(
        overview.countByCategory.keys,
        containsAll(InventoryItemCategory.values),
        reason: 'a zero next to a category is the useful part',
      );
    });

    test('expired and expiring soon are different questions', () {
      final overview = summarizeInventory([
        item(
          clientId: 'a',
          expirationDate: now.subtract(const Duration(days: 1)),
        ),
        item(clientId: 'b', expirationDate: now.add(const Duration(days: 10))),
        item(clientId: 'c', expirationDate: now.add(const Duration(days: 200))),
        item(clientId: 'd'),
      ], now: now);

      expect(overview.expired, 1);
      expect(overview.expiringSoon, 1);
      expect(overview.total, 4);
    });

    test('the day the window closes is still soon, not yet expired', () {
      final overview = summarizeInventory([
        item(expirationDate: now.add(soonWindow - const Duration(hours: 1))),
      ], now: now);

      expect(overview.expiringSoon, 1);
      expect(overview.expired, 0);
    });

    test('a day past the window is neither', () {
      final overview = summarizeInventory([
        item(expirationDate: now.add(soonWindow + const Duration(days: 1))),
      ], now: now);

      expect(overview.expiringSoon, 0);
      expect(overview.expired, 0);
    });

    test('an item both empty and expired is counted in both', () {
      // They are separate things to do — replace it, and buy more — so
      // collapsing them would hide one of the two.
      final overview = summarizeInventory([
        item(
          quantity: 0,
          minQuantity: 3,
          expirationDate: now.subtract(const Duration(days: 5)),
        ),
      ], now: now);

      expect(overview.expired, 1);
      expect(overview.lowStock, 1);
      expect(overview.needsAttention, 2);
    });

    test('exactly at the minimum is not low', () {
      expect(
        summarizeInventory([
          item(quantity: 3, minQuantity: 3),
        ], now: now).lowStock,
        0,
      );
      expect(
        summarizeInventory([
          item(quantity: 2.9, minQuantity: 3),
        ], now: now).lowStock,
        1,
      );
    });

    test('an item with no minimum is never low', () {
      expect(summarizeInventory([item(quantity: 0)], now: now).lowStock, 0);
    });

    test('categories are counted apart', () {
      final overview = summarizeInventory([
        item(clientId: 'a', category: 'water'),
        item(clientId: 'b', category: 'water'),
        item(clientId: 'c', category: 'food'),
      ], now: now);

      expect(overview.countByCategory[InventoryItemCategory.water], 2);
      expect(overview.countByCategory[InventoryItemCategory.food], 1);
      expect(overview.countByCategory[InventoryItemCategory.tools], 0);
    });
  });

  group('summarizing the checklists', () {
    ChecklistTemplate template(String clientId) => ChecklistTemplate(
      clientId: clientId,
      householdId: 'household-1',
      title: clientId,
      category: 'custom',
      kind: 'preparation',
      isBuiltIn: true,
      updatedAt: now,
      dirty: false,
    );

    ChecklistItem checklistItem(
      String clientId,
      String templateClientId, {
      bool checked = false,
    }) => ChecklistItem(
      clientId: clientId,
      householdId: 'household-1',
      templateClientId: templateClientId,
      title: clientId,
      isChecked: checked,
      sortOrder: 0,
      updatedAt: now,
      dirty: false,
    );

    test('counts ticks across every list', () {
      final overview = summarizeChecklists(
        templates: [template('t1'), template('t2')],
        items: [
          checklistItem('a', 't1', checked: true),
          checklistItem('b', 't1'),
          checklistItem('c', 't2', checked: true),
        ],
      );

      expect(overview.done, 2);
      expect(overview.total, 3);
      expect(overview.progress, closeTo(2 / 3, 0.001));
    });

    test('a list is complete only when it had something in it', () {
      final overview = summarizeChecklists(
        templates: [template('full'), template('empty')],
        items: [checklistItem('a', 'full', checked: true)],
      );

      expect(overview.listsComplete, 1);
      expect(overview.lists, 2);
    });

    test('nothing to do is zero progress, not a division by zero', () {
      final overview = summarizeChecklists(
        templates: const [],
        items: const [],
      );

      expect(overview.progress, 0);
      expect(overview.total, 0);
    });

    test('an item whose list is gone stops counting', () {
      // Deleting a list must not leave its items inflating the total
      // forever, which would make the bar unreachable.
      final overview = summarizeChecklists(
        templates: [template('t1')],
        items: [
          checklistItem('a', 't1', checked: true),
          checklistItem('orphan', 'deleted-list'),
        ],
      );

      expect(overview.total, 1);
      expect(overview.done, 1);
      expect(overview.progress, 1);
    });
  });
}

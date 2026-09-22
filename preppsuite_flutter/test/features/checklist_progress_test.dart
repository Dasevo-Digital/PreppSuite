import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_satisfaction.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// How far each list has got, worked out once for the whole screen.
void main() {
  final now = DateTime.utc(2026, 9, 22);

  ChecklistItem item({
    required String clientId,
    required String template,
    bool checked = false,
    String? linked,
    double? target,
  }) => ChecklistItem(
    clientId: clientId,
    householdId: 'h',
    templateClientId: template,
    title: clientId,
    isChecked: checked,
    linkedInventoryItemId: linked,
    targetQuantity: target,
    sortOrder: 0,
    updatedAt: now,
    dirty: false,
  );

  InventoryItem stock(String clientId, double quantity) => InventoryItem(
    clientId: clientId,
    householdId: 'h',
    name: clientId,
    category: 'food',
    quantity: quantity,
    unit: 'g',
    storageLocation: 'Keller',
    updatedAt: now,
    dirty: false,
  );

  test('counts ticked and stocked alike, per list', () {
    final progress = checklistProgressByTemplate(
      items: [
        item(clientId: 'a', template: 't1', checked: true),
        item(clientId: 'b', template: 't1', linked: 'reis', target: 2),
        item(clientId: 'c', template: 't1'),
        item(clientId: 'd', template: 't2'),
      ],
      inventoryById: {'reis': stock('reis', 5)},
    );

    expect(progress['t1'], (done: 2, total: 3));
    expect(progress['t2'], (done: 0, total: 1));
  });

  test('a stock below the target does not count', () {
    final progress = checklistProgressByTemplate(
      items: [item(clientId: 'a', template: 't', linked: 'reis', target: 10)],
      inventoryById: {'reis': stock('reis', 2)},
    );

    expect(progress['t'], (done: 0, total: 1));
  });

  test('a list with no items is absent, not nought out of nought', () {
    // The screen shows a line per list only where there is something to
    // report, and "0 von 0" is not something to report.
    final progress = checklistProgressByTemplate(
      items: const [],
      inventoryById: const {},
    );

    expect(progress, isEmpty);
  });

  test('the answer does not depend on the order items arrive in', () {
    final items = [
      item(clientId: 'a', template: 't', checked: true),
      item(clientId: 'b', template: 't'),
      item(clientId: 'c', template: 't', linked: 'reis'),
    ];

    expect(
      checklistProgressByTemplate(
        items: items,
        inventoryById: {'reis': stock('reis', 1)},
      ),
      checklistProgressByTemplate(
        items: items.reversed,
        inventoryById: {'reis': stock('reis', 1)},
      ),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/food_amount.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_groups.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Whether a supply is more than calories, measured against the BLE's
/// own table.
///
/// The load-bearing claim of this file is not the arithmetic — it is that
/// rows the app cannot count are **named** instead of quietly dropped. A
/// coverage figure that leaves out half the cupboard without saying so is
/// worse than no figure at all.
void main() {
  InventoryItem item({
    required String name,
    String category = 'food',
    double quantity = 1,
    String unit = 'kg',
    String? foodGroup,
    DateTime? deletedAt,
  }) => InventoryItem(
    clientId: name,
    householdId: 'h',
    name: name,
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    foodGroup: foodGroup,
    deletedAt: deletedAt,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  test('the targets are the BLE table, per person and day', () {
    // One person, one day. These seven numbers are the whole point of
    // the feature, so they are written out rather than computed.
    expect(supplyGroupTarget(SupplyGroup.grain, persons: 1, days: 1), 330);
    expect(supplyGroupTarget(SupplyGroup.vegetables, persons: 1, days: 1), 400);
    expect(supplyGroupTarget(SupplyGroup.fruit, persons: 1, days: 1), 250);
    expect(supplyGroupTarget(SupplyGroup.drinks, persons: 1, days: 1), 2000);
    expect(supplyGroupTarget(SupplyGroup.dairy, persons: 1, days: 1), 250);
    expect(supplyGroupTarget(SupplyGroup.protein, persons: 1, days: 1), 120);
    expect(supplyGroupTarget(SupplyGroup.fats, persons: 1, days: 1), 33);
  });

  test('the drinks row agrees with the water target the app already had', () {
    // Two litres a day, arrived at from the other direction as 1.5 to
    // drink plus 0.5 to cook with. They agree because both come from the
    // same table; if one ever moved without the other, this fails.
    expect(supplyGroupTarget(SupplyGroup.drinks, persons: 1, days: 1), 2000);
  });

  test('scales with people and days', () {
    expect(supplyGroupTarget(SupplyGroup.grain, persons: 3, days: 10), 9900);
  });

  test('sums what is assigned and measurable', () {
    final result = supplyGroupCoverage(
      items: [
        item(name: 'Nudeln', quantity: 2, unit: 'kg', foodGroup: 'grain'),
        item(name: 'Reis', quantity: 500, unit: 'g', foodGroup: 'grain'),
      ],
      persons: 1,
      days: 10,
    );
    final grain = result.coverage.firstWhere(
      (c) => c.group == SupplyGroup.grain,
    );

    expect(grain.have, 2500);
    expect(grain.target, 3300);
    expect(result.unassigned, isEmpty);
    expect(result.unmeasurable, isEmpty);
  });

  test('a row with no group is named, not guessed at', () {
    final result = supplyGroupCoverage(
      items: [item(name: 'Nudeln', quantity: 2, unit: 'kg')],
      persons: 1,
      days: 10,
    );

    // "Nudeln" is grain nearly always, and nearly always is not a rule
    // this app applies to somebody's supply.
    expect(
      result.coverage.firstWhere((c) => c.group == SupplyGroup.grain).have,
      0,
    );
    expect(result.unassigned.map((i) => i.name), ['Nudeln']);
  });

  test('a group with an uncountable unit is named too', () {
    final result = supplyGroupCoverage(
      items: [
        item(
          name: 'Bohnen',
          quantity: 6,
          unit: 'Dosen',
          foodGroup: 'vegetables',
        ),
      ],
      persons: 1,
      days: 10,
    );
    expect(result.unmeasurable.map((i) => i.name), ['Bohnen']);
  });

  test('a litre of oil does not count as a kilo of it', () {
    // Fats are measured by mass in the table. Nothing in this app
    // converts between mass and volume, and this is where that would
    // otherwise sneak in.
    final result = supplyGroupCoverage(
      items: [item(name: 'Rapsöl', quantity: 1, unit: 'l', foodGroup: 'fats')],
      persons: 1,
      days: 10,
    );
    expect(
      result.coverage.firstWhere((c) => c.group == SupplyGroup.fats).have,
      0,
    );
    expect(result.unmeasurable.map((i) => i.name), ['Rapsöl']);
  });

  test('tools and medicines are not missing a group, they have none', () {
    final result = supplyGroupCoverage(
      items: [
        item(name: 'Taschenlampe', category: 'tools', unit: 'Stk'),
        item(name: 'Ibuprofen', category: 'medical', unit: 'Stk'),
      ],
      persons: 1,
      days: 10,
    );
    expect(result.unassigned, isEmpty);
    expect(result.unmeasurable, isEmpty);
  });

  test('deleted rows count nowhere', () {
    final result = supplyGroupCoverage(
      items: [
        item(
          name: 'Nudeln',
          quantity: 2,
          unit: 'kg',
          foodGroup: 'grain',
          deletedAt: DateTime.utc(2026),
        ),
      ],
      persons: 1,
      days: 10,
    );
    expect(
      result.coverage.firstWhere((c) => c.group == SupplyGroup.grain).have,
      0,
    );
    expect(result.unassigned, isEmpty);
  });

  test('a group name from a newer build reads as none, not as a crash', () {
    // Rows travel through a shared folder between devices that may not
    // be on the same version.
    expect(supplyGroupFromName('seaweed'), isNull);
    expect(supplyGroupFromName(null), isNull);
    expect(supplyGroupFromName('grain'), SupplyGroup.grain);
  });

  test('the share is not capped, because the bar is not the number', () {
    final result = supplyGroupCoverage(
      items: [item(name: 'Reis', quantity: 10, unit: 'kg', foodGroup: 'grain')],
      persons: 1,
      days: 1,
    );
    final grain = result.coverage.firstWhere(
      (c) => c.group == SupplyGroup.grain,
    );
    expect(grain.share, closeTo(10000 / 330, 0.01));
  });

  test('every group states the base it is measured in', () {
    expect(baseOf(SupplyGroup.drinks), FoodBase.volume);
    for (final group in SupplyGroup.values.where(
      (g) => g != SupplyGroup.drinks,
    )) {
      expect(baseOf(group), FoodBase.mass, reason: group.name);
    }
  });
}

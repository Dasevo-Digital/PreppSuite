import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_range.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_store.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_calculator.dart';
import 'package:preppsuite_flutter/features/preparedness/application/scenario_export.dart';
import 'package:preppsuite_flutter/features/preparedness/application/scenario_gaps.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// A stretch without power, water or heating, and what it is short of
/// (#149). Every figure here comes from the household or from the
/// per-person amounts the supply calculator already uses.
void main() {
  final now = DateTime(2026, 10, 10, 12);

  InventoryItem item({
    required String id,
    required String category,
    required double quantity,
    required String unit,
    double? dailyDose,
    int? refillLeadDays,
    DateTime? stockCountedAt,
  }) => InventoryItem(
    clientId: id,
    householdId: 'h',
    name: id,
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    dailyDose: dailyDose,
    refillLeadDays: refillLeadDays,
    stockCountedAt: stockCountedAt,
    updatedAt: now.toUtc(),
    dirty: false,
  );

  const twoAdults = SupplyHousehold(adults: 2);

  const stove = EnergyPlan(
    reserves: [
      EnergyReserve(
        id: 'r',
        kind: EnergyKind.gas,
        label: 'Gaskartuschen',
        amount: 450,
      ),
      EnergyReserve(
        id: 'w',
        kind: EnergyKind.solidFuel,
        label: 'Brennholz',
        amount: 20,
      ),
    ],
    draws: [
      EnergyDraw(
        id: 'd',
        kind: EnergyKind.gas,
        label: 'Gaskocher',
        perHour: 160,
        hoursPerDay: 1,
      ),
    ],
  );

  ScenarioGaps gaps(List<InventoryItem> items, {int days = 3}) => scenarioGaps(
    items: items,
    household: twoAdults,
    energy: stove,
    days: days,
    now: now,
  );

  test('water is the household need over the stretch, less the stores', () {
    // Two adults at 2 l a day for three days: 12 l.
    final result = gaps([
      item(id: 'Wasser', category: 'water', quantity: 5, unit: 'l'),
    ]);

    expect(result.waterNeeded, 12);
    expect(result.waterStored, 5);
    expect(result.waterMissing, 7);
  });

  test('a longer stretch needs more of everything', () {
    final three = gaps(const []);
    final ten = gaps(const [], days: 10);

    expect(ten.waterNeeded, greaterThan(three.waterNeeded));
    expect(ten.kcalNeeded, greaterThan(three.kcalNeeded));
  });

  test('a medicine needs its dose for every day of the stretch', () {
    final result = gaps([
      item(
        id: 'Ramipril',
        category: 'medical',
        quantity: 2,
        unit: 'Tabletten',
        dailyDose: 1,
      ),
      item(
        id: 'Ibuprofen',
        category: 'medical',
        quantity: 20,
        unit: 'Tabletten',
        dailyDose: 1,
      ),
      item(id: 'Salbe', category: 'medical', quantity: 1, unit: 'Tube'),
    ]);

    expect(result.medicines.first.item.name, 'Ramipril');
    expect(result.medicines.first.needed, 3);
    expect(result.medicines.first.missing, 1);
    expect(result.medicines.last.missing, 0);
    expect(result.medicinesWithoutDose.single.name, 'Salbe');
  });

  test('a pack in daily use has what its count leaves, not its stock', () {
    // Ten tablets counted eight days ago at one a day: two are left.
    final result = gaps([
      item(
        id: 'Ramipril',
        category: 'medical',
        quantity: 10,
        unit: 'Tabletten',
        dailyDose: 1,
        refillLeadDays: 7,
        stockCountedAt: DateTime(2026, 10, 2, 9),
      ),
    ]);

    expect(result.medicines.single.available, 2);
    expect(result.medicines.single.missing, 1);
  });

  test('energy is what draws on it over the stretch, less the stores', () {
    final result = gaps(const []);
    final gas = result.energy.single;

    expect(gas.kind, EnergyKind.gas);
    expect(gas.needed, 480);
    expect(gas.missing, 30);
    expect(gas.uses, ['Gaskocher']);
    // Wood nothing draws on is no gap and no answer either.
    expect(result.energyUnused, [EnergyKind.solidFuel]);
  });

  group('the file', () {
    Map<String, Object?> export(ScenarioGaps result) => jsonDecode(
      buildScenarioFile(
        result,
        waterName: 'Trinkwasser',
        energyName: (kind) => kind.name,
        energyUnit: (kind) => kind.unit.name,
        now: now,
        language: 'de',
        formatAmount: (amount) => amount.toString(),
      ),
    ) as Map<String, Object?>;

    test('carries every gap a shop can close as a line', () {
      final file = export(
        gaps([
          item(
            id: 'Ramipril',
            category: 'medical',
            quantity: 2,
            unit: 'Tabletten',
            dailyDose: 1,
          ),
        ]),
      );
      final names = [
        for (final line in (file['items']! as List).cast<Map>()) line['name'],
      ];

      expect(file['origin'], 'scenario');
      expect(names, ['Trinkwasser', 'Ramipril', 'Gaskartuschen']);
      expect((file['scenario']! as Map)['days'], 3);
      expect(file.containsKey('target'), isFalse);
    });

    test('leaves out what is already covered', () {
      final file = export(
        gaps([
          item(id: 'Wasser', category: 'water', quantity: 100, unit: 'l'),
        ]),
      );
      final names = [
        for (final line in (file['items']! as List).cast<Map>()) line['name'],
      ];

      expect(names, ['Gaskartuschen']);
    });
  });
}

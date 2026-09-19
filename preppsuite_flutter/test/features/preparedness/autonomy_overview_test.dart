import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_range.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_store.dart';
import 'package:preppsuite_flutter/features/preparedness/application/autonomy_overview.dart';
import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_calculator.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  InventoryItem item({
    required String clientId,
    required String category,
    required double quantity,
    String unit = 'Stk',
    int? calories,
    double? dailyDose,
  }) => InventoryItem(
    clientId: clientId,
    householdId: 'home',
    name: clientId,
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    calories: calories,
    dailyDose: dailyDose,
    updatedAt: DateTime.utc(2026, 9, 19),
    dirty: false,
  );

  // Two adults: four litres and 4400 kcal a day.
  const twoAdults = SupplyHousehold(adults: 2);

  AutonomyReach reachFor(
    AutonomyResource resource, {
    List<InventoryItem> items = const [],
    EnergyPlan energy = const EnergyPlan(),
    AutonomySnapshot entered = const AutonomySnapshot(),
    SupplyHousehold household = twoAdults,
  }) => autonomyReaches(
    items: items,
    household: household,
    energy: energy,
    entered: entered,
  ).firstWhere((reach) => reach.resource == resource);

  group('what the app can divide, it no longer asks for', () {
    test('water comes out of the stock, not out of the dialog', () {
      final reach = reachFor(
        AutonomyResource.water,
        items: [
          item(clientId: 'w', category: 'water', quantity: 40, unit: 'l'),
        ],
        // A stale hand-entered figure must not win over the stock.
        entered: const AutonomySnapshot(waterDays: 99),
      );

      expect(reach.days, 10);
      expect(reach.basis, AutonomyBasis.stock);
    });

    test('food comes out of the calories', () {
      final reach = reachFor(
        AutonomyResource.food,
        items: [
          item(clientId: 'f', category: 'food', quantity: 1, calories: 22000),
        ],
      );

      expect(reach.days, 5);
      expect(reach.basis, AutonomyBasis.stock);
    });

    test('medicine is the one that runs out first, not the average', () {
      final reach = reachFor(
        AutonomyResource.medicine,
        items: [
          item(
            clientId: 'long',
            category: 'medical',
            quantity: 90,
            dailyDose: 1,
          ),
          item(
            clientId: 'short',
            category: 'medical',
            quantity: 11,
            dailyDose: 2,
          ),
        ],
      );

      // Eleven at two a day is five and a half, and five is what is left.
      expect(reach.days, 5);
    });

    test('energy comes out of the plan', () {
      final reach = reachFor(
        AutonomyResource.energy,
        energy: const EnergyPlan(
          reserves: [
            EnergyReserve(
              id: 'gas',
              kind: EnergyKind.gas,
              label: 'Kartuschen',
              amount: 900,
            ),
          ],
          draws: [
            EnergyDraw(
              id: 'stove',
              kind: EnergyKind.gas,
              label: 'Kocher',
              perHour: 150,
              hoursPerDay: 2,
            ),
          ],
        ),
      );

      expect(reach.days, 3);
      expect(reach.basis, AutonomyBasis.stock);
    });

    test('hygiene stays the household\'s own answer', () {
      final reach = reachFor(
        AutonomyResource.hygiene,
        entered: const AutonomySnapshot(hygieneDays: 14),
      );

      expect(reach.days, 14);
      expect(reach.basis, AutonomyBasis.entered);
      expect(reach.gap, AutonomyGap.onlyByHand);
    });
  });

  group('what it cannot divide, it says so about', () {
    test('water in crates is named, not quietly dropped', () {
      final reach = reachFor(
        AutonomyResource.water,
        items: [
          item(clientId: 'l', category: 'water', quantity: 40, unit: 'l'),
          item(clientId: 'k', category: 'water', quantity: 3, unit: 'Kiste'),
        ],
      );

      expect(reach.days, 10);
      // The crates are real water this number does not cover.
      expect(reach.unmeasured, 1);
    });

    test('water only in crates falls back to what was entered', () {
      final reach = reachFor(
        AutonomyResource.water,
        items: [
          item(clientId: 'k', category: 'water', quantity: 3, unit: 'Kiste'),
        ],
        entered: const AutonomySnapshot(waterDays: 8),
      );

      expect(reach.days, 8);
      expect(reach.basis, AutonomyBasis.entered);
      expect(reach.gap, AutonomyGap.notDivisible);
    });

    test('nothing recorded and nothing entered is open, not zero', () {
      final reach = reachFor(AutonomyResource.food);

      expect(reach.days, isNull);
      expect(reach.answered, isFalse);
      expect(reach.gap, AutonomyGap.nothingRecorded);
    });

    test('medicine without a dose is a gap, not a reach of zero', () {
      final reach = reachFor(
        AutonomyResource.medicine,
        items: [item(clientId: 'm', category: 'medical', quantity: 20)],
      );

      expect(reach.answered, isFalse);
      expect(reach.gap, AutonomyGap.notDivisible);
      expect(reach.unmeasured, 1);
    });

    test('a reserve nothing draws on is counted as uncovered', () {
      final reach = reachFor(
        AutonomyResource.energy,
        energy: const EnergyPlan(
          reserves: [
            EnergyReserve(
              id: 'gas',
              kind: EnergyKind.gas,
              label: 'Kartuschen',
              amount: 900,
            ),
          ],
        ),
        entered: const AutonomySnapshot(energyDays: 4),
      );

      expect(reach.days, 4);
      expect(reach.basis, AutonomyBasis.entered);
      expect(reach.unmeasured, 1);
    });
  });

  group('the household range', () {
    test('is the shortest answer, and an open question is not zero', () {
      final reaches = autonomyReaches(
        items: [
          item(clientId: 'w', category: 'water', quantity: 40, unit: 'l'),
          item(clientId: 'f', category: 'food', quantity: 1, calories: 8800),
        ],
        household: twoAdults,
        energy: const EnergyPlan(),
        entered: const AutonomySnapshot(),
      );

      // Water 10 days, food 2, and three questions with no answer at all.
      expect(limitingReach(reaches)?.resource, AutonomyResource.food);
      expect(limitingReach(reaches)?.days, 2);
      expect(
        openQuestions(reaches).map((reach) => reach.resource),
        [
          AutonomyResource.medicine,
          AutonomyResource.energy,
          AutonomyResource.hygiene,
        ],
      );
    });

    test('is absent while nothing at all can be answered', () {
      final reaches = autonomyReaches(
        items: const [],
        household: twoAdults,
        energy: const EnergyPlan(),
        entered: const AutonomySnapshot(),
      );

      expect(limitingReach(reaches), isNull);
      expect(openQuestions(reaches), hasLength(5));
    });
  });
}

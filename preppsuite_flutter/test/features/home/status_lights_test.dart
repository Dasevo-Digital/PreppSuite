import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/status_lights.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_calculator.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

/// The two lamps at the top of the overview, and what they refuse to say.
void main() {
  final now = DateTime.utc(2026, 9, 22);
  const oneAdult = SupplyHousehold(adults: 1);

  InventoryItem item({
    required String clientId,
    String category = 'food',
    double quantity = 100,
    String unit = 'g',
    double? calories,
  }) => InventoryItem(
    clientId: clientId,
    householdId: 'h',
    name: clientId,
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    calories: calories,
    updatedAt: now,
    dirty: false,
  );

  Warning warning(String severity) => Warning(
    source: 'bbk',
    externalId: severity,
    countryCode: 'DE',
    severity: severity,
    eventType: 'Test',
    headline: severity,
    effective: now,
    notified: false,
    sent: now,
    updatedAt: now,
  );

  group('the supply lamp', () {
    test('ten days of both is covered', () {
      // The BBK's own figures: 20 l and 22 000 kcal for one adult.
      final status = supplyStatus(
        items: [
          item(clientId: 'w', category: 'water', quantity: 20, unit: 'l'),
          item(clientId: 'f', quantity: 10000, unit: 'g', calories: 250),
        ],
        household: oneAdult,
      );

      expect(status.light, SupplyLight.covered);
      expect(status.daysCovered, greaterThanOrEqualTo(10));
    });

    test('short on one of the two is short', () {
      final status = supplyStatus(
        items: [
          item(clientId: 'w', category: 'water', quantity: 20, unit: 'l'),
          item(clientId: 'f', quantity: 500, unit: 'g', calories: 250),
        ],
        household: oneAdult,
      );

      expect(status.light, SupplyLight.short);
      expect(status.daysCovered, lessThan(10));
    });

    test('an empty database is grey, not red', () {
      // An empty database is not an empty cellar. Red here would accuse
      // a household of being unprepared when it has only not typed
      // anything in yet.
      expect(
        supplyStatus(items: const [], household: oneAdult).light,
        SupplyLight.unknown,
      );
    });

    test('and a cupboard of tools alone is grey too', () {
      expect(
        supplyStatus(
          items: [item(clientId: 't', category: 'tools', unit: 'Stk')],
          household: oneAdult,
        ).light,
        SupplyLight.unknown,
      );
    });

    test('a household that consumes nothing has no reach to report', () {
      expect(
        supplyStatus(
          items: [
            item(clientId: 'w', category: 'water', quantity: 20, unit: 'l'),
          ],
          household: const SupplyHousehold(adults: 0),
        ).light,
        SupplyLight.unknown,
      );
    });

    test('what the figure had to leave out is carried with it', () {
      // A lamp that covers less than the cupboard does has to be able to
      // admit it, or the number underneath is a quiet lie.
      final status = supplyStatus(
        items: [
          item(clientId: 'w', category: 'water', quantity: 20, unit: 'l'),
          item(clientId: 'f', quantity: 10000, unit: 'g', calories: 250),
          item(clientId: 'ravioli', quantity: 6, unit: 'Dose', calories: 90),
        ],
        household: oneAdult,
      );

      expect(status.uncounted, 1);
    });
  });

  group('the situation lamp', () {
    test('the worst one in force is the one shown', () {
      final status = situationStatus([
        warning('Minor'),
        warning('Severe'),
        warning('Moderate'),
      ]);

      expect(status.highest, WarningSeverity.severe);
      expect(status.count, 3);
      expect(status.quiet, isFalse);
    });

    test('nothing in force is quiet, and quiet is not an all-clear', () {
      // An authority publishes warnings, not all-clears. There is no
      // green on this lamp, and the absence of one must not be dressed
      // up as a statement about safety.
      final status = situationStatus(const []);

      expect(status.quiet, isTrue);
      expect(status.highest, isNull);
      expect(status.count, 0);
    });

    test('an unknown severity does not outrank a real one', () {
      // `WarningSeverity.fromName` falls back to minor, which must not
      // become a way for a malformed feed to shout.
      final status = situationStatus([
        warning('Severe'),
        warning('völlig unbekannt'),
      ]);

      expect(status.highest, WarningSeverity.severe);
    });
  });
}

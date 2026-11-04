import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/application/cold_store_contents.dart';
import 'package:preppsuite_flutter/features/energy/application/outage_food_safety.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

/// What is in the fridge and the freezer, read from where the stores
/// say things are kept (#276).
void main() {
  final now = DateTime(2026, 11, 4, 12);

  InventoryItem item(
    String name,
    String location, {
    double quantity = 1,
    InventoryItemCategory category = InventoryItemCategory.food,
    DateTime? deletedAt,
    double? dailyDose,
    int? refillLeadDays,
    DateTime? countedOn,
  }) => InventoryItem(
    clientId: name,
    householdId: 'h',
    name: name,
    category: category.name,
    quantity: quantity,
    unit: 'Stück',
    storageLocation: location,
    dailyDose: dailyDose,
    refillLeadDays: refillLeadDays,
    stockCountedAt: countedOn?.toUtc(),
    deletedAt: deletedAt,
    updatedAt: now.toUtc(),
    dirty: false,
  );

  group('which store a location names', () {
    test('the words a household writes, in three languages', () {
      for (final fridge in [
        'Kühlschrank',
        'kuehlschrank',
        'Kühlschrank Küche',
        'Kühlfach',
        'Fridge',
        'refrigerator',
        'Nevera',
        'Frigorífico',
        'frigorifico',
      ]) {
        expect(coldStoreOf(fridge), ColdStore.refrigerator, reason: fridge);
      }
      for (final freezer in [
        'Gefriertruhe',
        'Gefrierschrank',
        'Tiefkühlfach',
        'Tiefkuehltruhe',
        'Kühltruhe Keller',
        'Eisfach',
        'TK-Fach',
        'TK',
        'Freezer',
        'Congelador',
      ]) {
        expect(coldStoreOf(freezer), ColdStore.freezer, reason: freezer);
      }
    });

    test('the freezer inside a fridge is the freezer', () {
      expect(coldStoreOf('Gefrierfach im Kühlschrank'), ColdStore.freezer);
    });

    test('a place that only might be cold is not guessed at', () {
      for (final other in [
        'Küche',
        'Keller',
        'kühler Keller',
        'kühl und dunkel',
        'Werkzeugtruhe',
        'Spielzeugtruhe',
        'Stk-Regal',
        'Vorratskammer',
        '',
      ]) {
        expect(coldStoreOf(other), isNull, reason: other);
      }
    });
  });

  group('what is in them today', () {
    test('sorted into the two stores, by name', () {
      final contents = coldStoreContents([
        item('Milch', 'Kühlschrank'),
        item('Butter', 'Kühlschrank'),
        item('Erbsen', 'Gefriertruhe'),
        item('Nudeln', 'Keller'),
      ], now: now);
      expect(contents.refrigerator.map((i) => i.name), ['Butter', 'Milch']);
      expect(contents.freezer.map((i) => i.name), ['Erbsen']);
      expect(contents.of(ColdStore.freezer), contents.freezer);
      expect(contents.isEmpty, isFalse);
    });

    test('nothing that is gone, used up or deleted', () {
      final contents = coldStoreContents([
        item('Leer', 'Kühlschrank', quantity: 0),
        item('Gelöscht', 'Kühlschrank', deletedAt: DateTime.utc(2026)),
        // Ten at one a day, counted twenty days ago: nothing left today.
        item(
          'Insulin',
          'Kühlschrank',
          quantity: 10,
          category: InventoryItemCategory.medical,
          dailyDose: 1,
          refillLeadDays: 7,
          countedOn: DateTime(2026, 10, 15, 12),
        ),
      ], now: now);
      expect(contents.isEmpty, isTrue);
    });
  });

  test('food is put forward for throwing out, the rest is left to tick', () {
    expect(proposedForDiscard(item('Hack', 'Kühlschrank')), isTrue);
    expect(
      proposedForDiscard(
        item(
          'Nassfutter',
          'Kühlschrank',
          category: InventoryItemCategory.petFood,
        ),
      ),
      isTrue,
    );
    final insulin = item(
      'Insulin',
      'Kühlschrank',
      category: InventoryItemCategory.medical,
    );
    expect(proposedForDiscard(insulin), isFalse);
    expect(isColdMedicine(insulin), isTrue);
    expect(
      proposedForDiscard(
        item('Wasser', 'Kühlschrank', category: InventoryItemCategory.water),
      ),
      isFalse,
    );
  });
}

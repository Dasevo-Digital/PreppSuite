import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 25 adds the offers to and from the neighbours (#152): a new
/// table, nothing to convert, and its index.
void main() {
  NativeDatabase schemaTwentyFourDatabase() => NativeDatabase.memory(
    setup: (raw) => raw.execute('PRAGMA user_version = 24'),
  );

  Future<Set<String>> indexes(AppDatabase db) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    return {for (final row in rows) row.read<String>('name')};
  }

  test('an upgrade has the table and its index', () async {
    final db = AppDatabase.forTesting(schemaTwentyFourDatabase());
    addTearDown(db.close);

    expect(await db.watchNeighbourOffers('household-1').first, isEmpty);
    expect(await indexes(db), contains('neighbour_offers_household'));
  });

  test('a fresh install has the same index', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await indexes(db), contains('neighbour_offers_household'));
  });

  test('an offer written after the upgrade reads back', () async {
    final db = AppDatabase.forTesting(schemaTwentyFourDatabase());
    addTearDown(db.close);

    await db.upsertNeighbourOffer(
      NeighbourOffersCompanion.insert(
        clientId: 'o1',
        householdId: 'household-1',
        kind: 'water',
        body: '20 l Trinkwasser',
        offeredOn: DateTime.utc(2026, 10, 10),
        updatedAt: DateTime.utc(2026, 10, 10),
      ),
    );

    final offer = (await db.watchNeighbourOffers('household-1').first).single;
    expect(offer.body, '20 l Trinkwasser');
    expect(offer.received, isFalse);
  });
}

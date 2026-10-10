import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/card_species.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 24 lets a card be an animal's, with its chip number (#151).
///
/// Null after the upgrade, and null is a person: every card written so
/// far is one.
void main() {
  NativeDatabase schemaTwentyThreeDatabase() => NativeDatabase.memory(
    setup: (raw) {
      raw
        ..execute(
          'CREATE TABLE "household_members" ('
          '"client_id" TEXT NOT NULL, "household_id" TEXT NOT NULL, '
          '"name" TEXT NOT NULL, "birth_year" INTEGER NULL, '
          '"blood_type" TEXT NULL, "allergies" TEXT NULL, '
          '"medication" TEXT NULL, "conditions" TEXT NULL, '
          '"insurance" TEXT NULL, "doctor" TEXT NULL, '
          '"emergency_contact" TEXT NULL, "care_needs" TEXT NULL, '
          '"notes" TEXT NULL, '
          '"sort_order" INTEGER NOT NULL DEFAULT 0, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        )
        ..execute(
          'INSERT INTO household_members '
          '(client_id, household_id, name, allergies, updated_at, dirty) '
          "VALUES ('anna', 'household-1', 'Anna', 'Penicillin', "
          '1767225600, 0)',
        )
        ..execute('PRAGMA user_version = 23');
    },
  );

  test('upgrading keeps every card a person', () async {
    final db = AppDatabase.forTesting(schemaTwentyThreeDatabase());
    addTearDown(db.close);

    final card = (await db.watchHouseholdMembers('household-1').first).single;

    expect(card.name, 'Anna');
    expect(card.allergies, 'Penicillin');
    expect(card.species, isNull);
    expect(card.chipNumber, isNull);
    expect(card.isAnimal, isFalse);
  });

  test('an animal written after the upgrade reads back', () async {
    final db = AppDatabase.forTesting(schemaTwentyThreeDatabase());
    addTearDown(db.close);

    await db.upsertHouseholdMember(
      HouseholdMembersCompanion.insert(
        clientId: 'bello',
        householdId: 'household-1',
        name: 'Bello',
        species: const Value('dog'),
        chipNumber: const Value('276098100000001'),
        updatedAt: DateTime.utc(2026, 10, 10),
      ),
    );

    final cards = await db.watchHouseholdMembers('household-1').first;
    final bello = cards.firstWhere((card) => card.clientId == 'bello');
    expect(bello.cardSpecies, CardSpecies.dog);
    expect(bello.chipNumber, '276098100000001');
  });
}

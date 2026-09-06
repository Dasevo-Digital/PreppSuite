import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 11 adds `household_members` — the emergency cards.
void main() {
  /// An install sitting on schema 10: it has the plan table but no cards.
  NativeDatabase schemaTenDatabase() {
    return NativeDatabase.memory(
      setup: (raw) {
        raw.execute(
          'CREATE TABLE "household_plans" ('
          '"client_id" TEXT NOT NULL, "household_id" TEXT NOT NULL, '
          '"meeting_point_near" TEXT NULL, "meeting_point_far" TEXT NULL, '
          '"contact_name" TEXT NULL, "contact_phone" TEXT NULL, '
          '"kit_location" TEXT NULL, "shutoff_location" TEXT NULL, '
          '"notes" TEXT NULL, "updated_at" INTEGER NOT NULL, '
          '"deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );
        raw.execute(
          'INSERT INTO household_plans (client_id, household_id, '
          'meeting_point_near, updated_at, dirty) VALUES '
          "('household-1', 'household-1', 'Die Ecke', 1767225600, 0)",
        );

        raw.execute('PRAGMA user_version = 10');
      },
    );
  }

  test('upgrading from 10 adds the cards and keeps the plan', () async {
    final db = AppDatabase.forTesting(schemaTenDatabase());
    addTearDown(db.close);

    expect(await db.watchHouseholdMembers('household-1').first, isEmpty);
    expect(
      (await db.watchHouseholdPlan('household-1').first)?.meetingPointNear,
      'Die Ecke',
    );
  });

  test('a card keeps its empty fields empty rather than blank', () async {
    // Null and "" are different answers: one says nobody filled it in,
    // the other would print an empty line on the card as though it were
    // an answer.
    final db = AppDatabase.forTesting(schemaTenDatabase());
    addTearDown(db.close);

    await db.upsertHouseholdMember(
      HouseholdMembersCompanion.insert(
        clientId: 'm1',
        householdId: 'household-1',
        name: 'Lena',
        allergies: const Value('Penicillin'),
        updatedAt: DateTime.utc(2026),
        dirty: const Value(true),
      ),
    );

    final member = (await db.watchHouseholdMembers('household-1').first).single;
    expect(member.name, 'Lena');
    expect(member.allergies, 'Penicillin');
    expect(member.bloodType, isNull);
    expect(member.medication, isNull);
  });

  test('cards keep the order the household put them in', () async {
    // Alphabetical would put a child before a parent for no reason
    // anyone chose.
    final db = AppDatabase.forTesting(schemaTenDatabase());
    addTearDown(db.close);

    for (final (order, name) in [(0, 'Zeynep'), (1, 'Anton')]) {
      await db.upsertHouseholdMember(
        HouseholdMembersCompanion.insert(
          clientId: name,
          householdId: 'household-1',
          name: name,
          sortOrder: Value(order),
          updatedAt: DateTime.utc(2026),
          dirty: const Value(true),
        ),
      );
    }

    final members = await db.watchHouseholdMembers('household-1').first;
    expect(members.map((m) => m.name), ['Zeynep', 'Anton']);
  });

  test('a tombstoned card is gone from the list', () async {
    final db = AppDatabase.forTesting(schemaTenDatabase());
    addTearDown(db.close);

    await db.upsertHouseholdMember(
      HouseholdMembersCompanion.insert(
        clientId: 'm1',
        householdId: 'household-1',
        name: 'Lena',
        updatedAt: DateTime.utc(2026),
        deletedAt: Value(DateTime.utc(2026, 2)),
        dirty: const Value(true),
      ),
    );

    expect(await db.watchHouseholdMembers('household-1').first, isEmpty);
    // But still on the wire, or the removal never reaches the others.
    expect(await db.householdMembersForSync('household-1'), hasLength(1));
  });
}

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 13 adds `local_contact_point` to `household_plans`.
///
/// The statement is a plain `ALTER TABLE ADD COLUMN`; the risk is the
/// branch it sits in. `household_plans` is created in the schema-10 branch
/// from the table's *current* definition, so anything older than 10 comes
/// out of that branch already carrying this column — and adding it again
/// would take the whole migration down on those installs. Both halves are
/// covered here, because only one of them can be wrong at a time.
void main() {
  /// `household_plans` as schema 12 left it: today's table without the
  /// contact point, with a plan already written into it.
  NativeDatabase schemaTwelveDatabase() {
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
          'meeting_point_near, contact_name, updated_at, dirty) VALUES '
          "('household-1', 'household-1', 'Vor der Garage', "
          "'Tante Erna', 1767225600, 0)",
        );

        raw.execute('PRAGMA user_version = 12');
      },
    );
  }

  test('upgrading from 12 adds the column and keeps the plan', () async {
    final db = AppDatabase.forTesting(schemaTwelveDatabase());
    addTearDown(db.close);

    final plan = await db.watchHouseholdPlan('household-1').first;

    expect(plan, isNotNull);
    expect(plan!.meetingPointNear, 'Vor der Garage');
    expect(plan.contactName, 'Tante Erna');

    // Null, not empty. The printed plan shows the heading either way and
    // says "Nicht eingetragen" underneath, like every other section --
    // which on a plan is the point, because the gap is what needs
    // filling. Empty-means-null is what keeps that distinguishable from
    // somebody having typed a space.
    expect(plan.localContactPoint, isNull);
  });

  test('a plan written afterwards keeps the contact point', () async {
    final db = AppDatabase.forTesting(schemaTwelveDatabase());
    addTearDown(db.close);

    await db.upsertHouseholdPlan(
      HouseholdPlansCompanion.insert(
        clientId: 'household-1',
        householdId: 'household-1',
        localContactPoint: const Value('Grundschule Nordstadt, Turnhalle'),
        updatedAt: DateTime.utc(2026, 9, 10),
      ),
    );

    final plan = await db.watchHouseholdPlan('household-1').first;
    expect(plan!.localContactPoint, 'Grundschule Nordstadt, Turnhalle');
  });

  test('an install with no plans table at all survives', () async {
    // The half that would break on a duplicate column: schema 9 has no
    // `household_plans`, so the schema-10 branch creates it from the
    // current definition — contact point included — and the schema-13
    // branch has to leave it alone.
    final db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA user_version = 9'),
      ),
    );
    addTearDown(db.close);

    expect(await db.watchHouseholdPlan('household-1').first, isNull);

    await db.upsertHouseholdPlan(
      HouseholdPlansCompanion.insert(
        clientId: 'household-1',
        householdId: 'household-1',
        localContactPoint: const Value('Feuerwache 3'),
        updatedAt: DateTime.utc(2026, 9, 10),
      ),
    );

    expect(
      (await db.watchHouseholdPlan('household-1').first)!.localContactPoint,
      'Feuerwache 3',
    );
  });
}

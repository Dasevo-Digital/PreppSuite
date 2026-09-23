import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 18 gives an emergency card a distinct practical-support field.
///
/// It is deliberately separate from medical notes: a device that needs power,
/// a care arrangement or accessible transport is relevant in a crisis even
/// when no diagnosis belongs on the card.
void main() {
  NativeDatabase schemaSeventeenDatabase() => NativeDatabase.memory(
    setup: (raw) {
      raw
        ..execute(
          'CREATE TABLE "household_members" ('
          '"client_id" TEXT NOT NULL, "household_id" TEXT NOT NULL, '
          '"name" TEXT NOT NULL, "birth_year" INTEGER NULL, '
          '"blood_type" TEXT NULL, "allergies" TEXT NULL, '
          '"medication" TEXT NULL, "conditions" TEXT NULL, '
          '"insurance" TEXT NULL, "doctor" TEXT NULL, '
          '"emergency_contact" TEXT NULL, "notes" TEXT NULL, '
          '"sort_order" INTEGER NOT NULL DEFAULT 0, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        )
        ..execute(
          'INSERT INTO household_members '
          '(client_id, household_id, name, notes, updated_at, dirty) VALUES '
          "('member-1', 'household-1', 'Person Eins', 'Bestehende Notiz', "
          '1767225600, 0)',
        )
        ..execute('PRAGMA user_version = 17');
    },
  );

  test(
    'upgrading keeps existing cards and starts support needs empty',
    () async {
      final db = AppDatabase.forTesting(schemaSeventeenDatabase());
      addTearDown(db.close);

      final card = (await db.watchHouseholdMembers('household-1').first).single;

      expect(card.name, 'Person Eins');
      expect(card.notes, 'Bestehende Notiz');
      expect(card.careNeeds, isNull);
    },
  );
}

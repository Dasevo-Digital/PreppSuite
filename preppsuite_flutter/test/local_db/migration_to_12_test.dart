import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 12 adds the CAP detail cache to warnings.
void main() {
  test(
    'upgrading from 11 keeps the warning and adds offline details',
    () async {
      final db = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(
              'CREATE TABLE "warnings" ('
              '"source" TEXT NOT NULL, "external_id" TEXT NOT NULL, '
              '"country_code" TEXT NOT NULL, "region_key" TEXT NULL, '
              '"severity" TEXT NOT NULL, "event_type" TEXT NOT NULL, '
              '"headline" TEXT NOT NULL, "description" TEXT NULL, '
              '"effective" INTEGER NOT NULL, "expires" INTEGER NULL, '
              '"sent" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
              '"notified" INTEGER NOT NULL DEFAULT 0 CHECK ("notified" IN (0, 1)), '
              'PRIMARY KEY ("source", "external_id"))',
            );
            raw.execute(
              'INSERT INTO warnings (source, external_id, country_code, '
              'severity, event_type, headline, effective, sent, updated_at) '
              "VALUES ('bbk', 'warning-1', 'DE', 'severe', 'Sturm', "
              "'Sturmwarnung', 1767225600, 1767225600, 1767225600)",
            );
            raw.execute('PRAGMA user_version = 11');
          },
        ),
      );
      addTearDown(db.close);

      final warning = (await db.watchAllWarnings().first).single;
      expect(warning.headline, 'Sturmwarnung');
      expect(warning.instruction, isNull);
      expect(warning.areaDescription, isNull);
      expect(warning.senderContact, isNull);
      expect(warning.polygonsJson, isNull);
    },
  );
}

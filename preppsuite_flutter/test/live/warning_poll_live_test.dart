import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The whole poll against the real BBK and MeteoAlarm servers.
///
/// Skipped unless PREPPSUITE_TEST_NETWORK is set. Every client has its
/// own fixture tests; this is the one place that shows the chain from
/// the live feeds to rows in the database still holds — the question
/// behind "warnings no longer load" (#46).
void main() {
  // The binding is needed for the bundled area table, and it answers every
  // HTTP request with a 400 unless its override is lifted again.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real warning servers'
      : null;

  test(
    'a poll for Germany completes and stores what the feeds hold',
    () async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final result = await WarningPollService(database: db).poll(
        countryCode: 'DE',
        // Vogelsbergkreis, the district of #48.
        kreisSchluessel: '06535',
      );
      final stored = await db.warningsBySource('bbk');
      stdout.writeln(
        'fetched ${result.fetched}, complete ${result.complete}, '
        'stored BBK ${stored.length}',
      );

      expect(result.complete, isTrue);
      expect(result.fetched, greaterThan(0));
      expect(stored, isNotEmpty);
    },
    skip: reason,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

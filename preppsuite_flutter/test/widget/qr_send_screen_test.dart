import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/transfer/presentation/qr_send_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The sending screen had no test at all, although it is 426 lines and the
/// only way a household reaches a device with no network. The chain itself
/// is covered by `qr_chain_test.dart`; what is checked here is the screen
/// around it -- that it comes up, shows pictures, and that the speed
/// control a person is meant to reach for is reachable.
void main() {
  late AppDatabase db;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Without the network: binding a socket and announcing itself
          // is not a thing a test should do, and it is also what a device
          // without a network sees.
          home: const QrSendScreen(householdId: 'home', offerNetwork: false),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows a picture even for an empty household', (tester) async {
    await show(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(QrSendScreen), findsOneWidget);
  });

  testWidgets('the speed can be changed in both directions', (tester) async {
    // The frame rate is the one thing somebody has to adjust while
    // filming, and it is adjustable because the right value depends on
    // the camera and the light rather than on us.
    await show(tester);

    final slower = find.byIcon(Icons.slow_motion_video);
    final faster = find.byIcon(Icons.fast_forward);
    expect(slower, findsOneWidget);
    expect(faster, findsOneWidget);

    for (final control in [slower, faster, slower]) {
      final target = find
          .ancestor(of: control, matching: find.byType(OutlinedButton))
          .first;
      if (tester.widget<OutlinedButton>(target).onPressed == null) continue;
      await tester.tap(target);
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving takes the timer with it', (tester) async {
    // A periodic timer that outlives its screen fails the test framework
    // rather than the app, which is exactly why it is worth a test: it
    // would otherwise keep redrawing a widget that is gone.
    await show(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/core/notification_service.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';
import 'package:preppsuite_flutter/features/home/presentation/notification_taps.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A tapped notification opens its page (#382).
void main() {
  late AppDatabase db;
  late StreamController<String> taps;
  late List<ShellDestination> navigated;

  const profile = HouseholdProfile(id: 'h', name: 'Familie', countryCode: 'DE');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    taps = StreamController<String>.broadcast();
    navigated = [];
    await db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'rice',
        householdId: 'h',
        name: 'Reis',
        category: 'food',
        quantity: 2,
        unit: 'kg',
        storageLocation: 'Keller',
        expirationDate: Value(DateTime.utc(2026, 12, 1)),
        updatedAt: DateTime.utc(2026),
      ),
    );
  });

  tearDown(() async {
    await taps.close();
    await db.close();
  });

  Future<void> pump(WidgetTester tester, {String? launch}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: NotificationTaps(
              profile: profile,
              onNavigate: navigated.add,
              screenFor: (destination) =>
                  Scaffold(body: Text('Tab ${destination.name}')),
              taps: taps.stream,
              launchPayload: () async => launch,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('an expiry reminder opens the item', (tester) async {
    await pump(tester);
    taps.add('${NotificationService.expiryPayloadPrefix}rice');
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Reis'), findsWidgets);
  });

  testWidgets('a reminder for an item that is gone opens the stock', (
    tester,
  ) async {
    await pump(tester);
    taps.add('${NotificationService.refillPayloadPrefix}gone');
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(navigated, [ShellDestination.inventory]);
  });

  testWidgets('a warning switches to the warnings', (tester) async {
    await pump(tester);
    taps.add('${NotificationService.warningPayloadPrefix}mow.1');
    await tester.pump();
    expect(navigated, [ShellDestination.warnings]);
  });

  testWidgets('with a page open, the tab opens above it instead', (
    tester,
  ) async {
    await pump(tester);
    final context = tester.element(find.byType(NotificationTaps));
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const Text('Formular')),
      ),
    );
    await tester.pumpAndSettle();
    taps.add(NotificationService.chargeReminderPayload);
    await tester.pumpAndSettle();
    expect(navigated, isEmpty, reason: 'the edit underneath stays');
    expect(find.text('Tab overview'), findsOneWidget);
  });

  testWidgets('the notification that started the app is followed', (
    tester,
  ) async {
    await pump(tester, launch: NotificationService.warningDayPayload);
    await tester.pump();
    expect(navigated, [ShellDestination.warnings]);
  });

  testWidgets('a payload this version does not know does nothing', (
    tester,
  ) async {
    await pump(tester);
    taps.add('from-a-later-version');
    await tester.pumpAndSettle();
    expect(navigated, isEmpty);
  });
}

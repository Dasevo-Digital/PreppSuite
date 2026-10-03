import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/household/presentation/emergency_card_form_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "The emergency card cannot be saved" (#43).
///
/// The save button sits at the bottom of a long form and the only two
/// fields that can refuse a save — the name and the birth year — sit at
/// the top. On a phone the refusal was printed under a field that had
/// scrolled out of sight, so a tap on save did nothing anybody could see.
/// These tests stop before the database: a refused save never reaches it,
/// and see `emergency_card_people_test.dart` for why a widget test that
/// writes to it is not used here.
/// A phone, upright.
const screen = Size(390, 760);

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  late AppLocalizations l10n;

  Future<void> open(WidgetTester tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.binding.setSurfaceSize(screen);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          navigatorKey: navigator,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(),
        ),
      ),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const EmergencyCardFormScreen(householdId: 'h'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(
      tester.element(find.byType(EmergencyCardFormScreen)),
    )!;
  }

  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pumpAndSettle();
  }

  /// Inside the window, and not tucked under the app bar.
  bool onScreen(WidgetTester tester, Finder finder) {
    final box = tester.getRect(finder);
    return box.top >= kToolbarHeight && box.bottom <= screen.height;
  }

  testWidgets('a missing name is scrolled into view', (tester) async {
    await open(tester);
    await scrollToBottom(tester);

    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();

    final error = find.text(l10n.emergencyCardNameRequired);
    expect(error, findsOneWidget);
    expect(onScreen(tester, error), isTrue);
    expect(find.byType(EmergencyCardFormScreen), findsOneWidget);
  });

  testWidgets('a full date in the year field is scrolled into view', (
    tester,
  ) async {
    await open(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Lena');
    await tester.enterText(fields.at(1), '12.03.1985');
    // Then on down the form, as anybody filling it in would: the cursor
    // leaves the year field behind, so nothing keeps it on screen.
    await scrollToBottom(tester);
    await tester.enterText(
      find.byType(TextField).last,
      'Schlüssel bei Nachbarn',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();

    final error = find.text(l10n.emergencyCardBirthYearInvalid);
    expect(error, findsOneWidget);
    expect(onScreen(tester, error), isTrue);
  });
}

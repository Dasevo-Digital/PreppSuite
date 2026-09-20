import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/household/presentation/setup_choice_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

class _NoProfile extends HouseholdProfileController {
  @override
  Future<HouseholdProfile?> build() async => null;
}

/// The first question the app asks, and the one it never used to.
///
/// Setting up was a single form written when one household meant one
/// device. On the second device that form quietly makes a *second*
/// household: a new id, and because every table is partitioned by it, the
/// two can never merge. Everything here exists to stop somebody walking
/// into that.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [householdProfileProvider.overrideWith(_NoProfile.new)],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SetupChoiceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('joining is offered before creating is done', (tester) async {
    await show(tester);

    expect(find.text('Neuen Haushalt anlegen'), findsOneWidget);
    expect(find.text('Gemeinsamen Ordner wählen'), findsOneWidget);
    expect(find.text('Von einem anderen Gerät übernehmen'), findsOneWidget);
  });

  testWidgets('it says why two households cannot be merged later', (
    tester,
  ) async {
    await show(tester);

    // The whole point of the screen: somebody who starts a second
    // household here has no way back, and has to be told before, not
    // after.
    expect(
      find.textContaining('nie wieder vereinigen'),
      findsOneWidget,
    );
    expect(
      find.textContaining('noch keine eigenen Daten'),
      findsOneWidget,
    );
  });

  testWidgets('the new-household route still leads to the old form', (
    tester,
  ) async {
    await show(tester);

    await tester.tap(find.text('Neuen Haushalt anlegen'));
    await tester.pumpAndSettle();

    expect(find.text('Name des Haushalts'), findsOneWidget);
  });

  testWidgets('the scan route asks for this device first', (tester) async {
    await show(tester);

    await tester.tap(find.text('Von einem anderen Gerät übernehmen'));
    await tester.pumpAndSettle();

    // The form first and the camera afterwards: the other way round
    // leaves somebody filling in fields while the host's invitation
    // times out behind them.
    expect(find.text('Name des Haushalts'), findsOneWidget);
    expect(find.text('Weiter zum Abfilmen'), findsOneWidget);
  });

  testWidgets('is accessible', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('survives a doubled system font size', (tester) async {
    useLargeText(tester);
    await show(tester);

    expect(find.text('Haushalt einrichten'), findsOneWidget);
  });
}

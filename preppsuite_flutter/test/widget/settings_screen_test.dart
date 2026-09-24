import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/presentation/settings_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/core/locale_provider.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

void main() {
  const profile = HouseholdProfile(
    id: 'h',
    name: 'Haushalt',
    countryCode: 'DE',
  );

  Future<void> show(WidgetTester tester) => tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(profile: profile),
      ),
    ),
  );

  /// The same screen, but following whatever locale the app holds, which
  /// is what the running app does.
  Future<void> showFollowingLocale(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          locale: ref.watch(localeOverrideProvider),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(profile: profile),
        ),
      ),
    ),
  );

  testWidgets('groups settings into short, discoverable categories', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('Warnungen und Orte'), findsOneWidget);
    expect(find.text('Erinnerungen'), findsOneWidget);
    expect(find.text('Darstellung und Sprache'), findsOneWidget);
    expect(find.text('Daten und Sicherheit'), findsOneWidget);
    expect(find.text('Offline und Speicher'), findsOneWidget);
  });

  testWidgets('category list survives twice the system font size', (
    tester,
  ) async {
    useLargeText(tester);
    await show(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('a category page follows a language change on the spot', (
    tester,
  ) async {
    // The language picker lives on one of these pages. It used to be
    // built with the l10n of the moment the tile was tapped, so switching
    // to English left the page one was looking at in German -- which
    // reads exactly like the setting did not work.
    SharedPreferences.setMockInitialValues({'localeOverride': 'de'});
    await showFollowingLocale(tester);
    await tester.pumpAndSettle();

    // Taken hold of before navigating: the settings screen goes off-stage
    // behind the pushed category page, and `find` skips what is off-stage.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );

    await tester.tap(find.text('Darstellung und Sprache'));
    await tester.pumpAndSettle();
    expect(find.text('Sprache'), findsWidgets);
    await container
        .read(localeOverrideProvider.notifier)
        .setLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance and language'), findsOneWidget);
    expect(find.text('Darstellung und Sprache'), findsNothing);
  });
}

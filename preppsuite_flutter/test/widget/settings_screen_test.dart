import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/presentation/settings_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

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
}

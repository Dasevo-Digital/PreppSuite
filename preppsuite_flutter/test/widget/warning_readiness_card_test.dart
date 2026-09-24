import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/presentation/warning_readiness_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _card() => ProviderScope(
  child: MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: WarningReadinessCard(
          profile: const HouseholdProfile(
            id: 'h',
            name: 'Haushalt',
            countryCode: 'DE',
          ),
          l10n: AppLocalizations.of(context)!,
          onManagePlaces: () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('shows missing prerequisites without promising a refresh', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: WarningReadinessCard(
                profile: const HouseholdProfile(
                  id: 'h',
                  name: 'Haushalt',
                  countryCode: 'DE',
                ),
                l10n: AppLocalizations.of(context)!,
                onManagePlaces: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Warnbereitschaft'), findsOneWidget);
    expect(find.text('Noch kein Hauptort festgelegt'), findsOneWidget);
    expect(find.text('Noch keine vollständige Aktualisierung'), findsOneWidget);
  });

  testWidgets('names a background run that could not open the data', (
    tester,
  ) async {
    // The one trace such a run leaves. Without this row the device simply
    // stops warning and the screen still reads "not updated yet", which is
    // the same thing it says on the day the app was installed.
    SharedPreferences.setMockInitialValues({
      'warningPollLastBlocked': '2026-09-24T08:00:00.000Z',
    });

    await tester.pumpWidget(_card());
    await tester.pumpAndSettle();

    expect(find.text('Hintergrundabruf ausgesetzt'), findsOneWidget);
  });

  testWidgets('says nothing once a later refresh has succeeded', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'warningPollLastBlocked': '2026-09-24T08:00:00.000Z',
      'warningPollLastComplete': '2026-09-24T09:00:00.000Z',
    });

    await tester.pumpWidget(_card());
    await tester.pumpAndSettle();

    expect(find.text('Hintergrundabruf ausgesetzt'), findsNothing);
  });
}

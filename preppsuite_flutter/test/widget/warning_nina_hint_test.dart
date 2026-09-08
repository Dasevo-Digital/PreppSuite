import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

import 'accessibility.dart';

void main() {
  HouseholdProfile profile(String countryCode) => HouseholdProfile(
    id: 'household-1',
    name: 'Testhaushalt',
    countryCode: countryCode,
  );

  Future<void> pumpScreen(WidgetTester tester, String countryCode) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Served as a plain value rather than a drift stream: a real one
          // never settles inside a widget test.
          allWarningsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WarningListScreen(profile: profile(countryCode)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a German household is pointed at NINA', (tester) async {
    // The honest version of "we do not do push": the BBK's own app is
    // faster than this one can be, and saying so beats being quietly
    // slower.
    await pumpScreen(tester, 'DE');

    expect(find.textContaining('NINA'), findsOneWidget);
  });

  testWidgets('a household outside Germany is not', (tester) async {
    // NINA covers Germany only. Recommending a German federal app to an
    // Austrian household would be wrong, not merely useless.
    await pumpScreen(tester, 'AT');

    expect(find.textContaining('NINA'), findsNothing);
  });

  testWidgets('the NINA hint meets the accessibility guidelines', (
    tester,
  ) async {
    await pumpScreen(tester, 'DE');
    await expectAccessible(tester);
  });

  testWidgets('the NINA hint survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await pumpScreen(tester, 'DE');
  });
}

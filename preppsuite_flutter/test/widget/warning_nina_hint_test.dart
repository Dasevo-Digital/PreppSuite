import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_client/preppsuite_client.dart' as proto;
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

void main() {
  final householdId = proto.UuidValue.fromString(
    '00000000-0000-4000-8000-000000000001',
  );

  proto.Household household(String countryCode) => proto.Household(
    id: householdId,
    name: 'Testhaushalt',
    countryCode: countryCode,
    inviteCode: 'TESTTEST',
    createdAt: DateTime.utc(2026),
  );

  Future<void> pumpScreen(WidgetTester tester, String countryCode) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Served as a plain value rather than a drift stream: a real one
          // never settles inside a widget test.
          allWarningsProvider.overrideWith((ref) => Stream.value(const [])),
          householdWarningRegionsProvider(
            householdId,
          ).overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WarningListScreen(household: household(countryCode)),
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
}

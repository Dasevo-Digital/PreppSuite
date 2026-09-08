import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/warning_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

import 'accessibility.dart';

/// Whether the filter narrows the list is settled in
/// `test/features/warning_filter_test.dart`, without a widget tree. What
/// is left here is the part only the screen can get wrong: that the chips
/// are wired to the right condition, and that a list hidden by a filter
/// does not look like a list with nothing in it.
void main() {
  final now = DateTime.now();

  Warning warning({
    required String externalId,
    required String headline,
    String severity = 'moderate',
    String? regionKey,
    DateTime? expires,
  }) => Warning(
    source: 'bbk',
    externalId: externalId,
    countryCode: 'DE',
    regionKey: regionKey,
    severity: severity,
    eventType: 'Test',
    headline: headline,
    effective: now.subtract(const Duration(hours: 3)),
    expires: expires,
    sent: now.subtract(const Duration(hours: 3)),
    updatedAt: now,
    notified: false,
  );

  final storm = warning(
    externalId: 'storm',
    headline: 'Sturmböen Hannover',
    severity: 'severe',
    regionKey: '03241',
    expires: now.add(const Duration(hours: 6)),
  );
  final past = warning(
    externalId: 'past',
    headline: 'Glätte Bremen',
    regionKey: '04011',
    expires: now.subtract(const Duration(hours: 6)),
  );

  Future<void> pumpScreen(WidgetTester tester, List<Warning> warnings) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allWarningsProvider.overrideWith((ref) => Stream.value(warnings)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WarningListScreen(
            profile: const HouseholdProfile(
              id: 'household-1',
              name: 'Testhaushalt',
              countryCode: 'DE',
              regionKey: '03241',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('everything is shown until a chip is tapped', (tester) async {
    await pumpScreen(tester, [storm, past]);

    expect(find.text('Sturmböen Hannover'), findsOneWidget);
    expect(find.text('Glätte Bremen'), findsOneWidget);
    expect(find.textContaining('von 2 Warnungen'), findsNothing);
  });

  testWidgets('"Akut" hides what has already run out', (tester) async {
    await pumpScreen(tester, [storm, past]);

    await tester.tap(find.widgetWithText(FilterChip, 'Akut'));
    await tester.pumpAndSettle();

    expect(find.text('Sturmböen Hannover'), findsOneWidget);
    expect(find.text('Glätte Bremen'), findsNothing);
    expect(find.text('1 von 2 Warnungen'), findsOneWidget);
  });

  testWidgets('"Meine Regionen" hides another district', (tester) async {
    await pumpScreen(tester, [storm, past]);

    await tester.tap(find.widgetWithText(FilterChip, 'Meine Regionen'));
    await tester.pumpAndSettle();

    expect(find.text('Sturmböen Hannover'), findsOneWidget);
    expect(find.text('Glätte Bremen'), findsNothing);
  });

  testWidgets('searching a place name narrows to it', (tester) async {
    await pumpScreen(tester, [storm, past]);

    await tester.enterText(find.byType(TextField), 'bremen');
    await tester.pumpAndSettle();

    expect(find.text('Glätte Bremen'), findsOneWidget);
    expect(find.text('Sturmböen Hannover'), findsNothing);
  });

  testWidgets('a filter that hides everything says so, and offers a way back', (
    tester,
  ) async {
    // Otherwise it is indistinguishable from the feeds being quiet, and a
    // warning screen that looks empty when it is not is the worst bug
    // this screen can have.
    await pumpScreen(tester, [storm, past]);

    await tester.enterText(find.byType(TextField), 'erdbeben');
    await tester.pumpAndSettle();

    expect(find.textContaining('Keine der 2 Warnungen'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Filter zurücksetzen'));
    await tester.pumpAndSettle();

    expect(find.text('Sturmböen Hannover'), findsOneWidget);
    expect(find.text('Glätte Bremen'), findsOneWidget);
  });

  testWidgets('an empty feed still reads as an empty feed', (tester) async {
    await pumpScreen(tester, const []);

    expect(find.textContaining('Keine der'), findsNothing);
  });

  testWidgets('the warning list meets the accessibility guidelines', (
    tester,
  ) async {
    await pumpScreen(tester, [storm, past]);
    await expectAccessible(tester);
  });
}

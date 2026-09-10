import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/household/presentation/profile_setup_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Records what the screen asked for instead of writing it to preferences.
class _Recording extends HouseholdProfileController {
  HouseholdProfile? created;

  @override
  Future<HouseholdProfile?> build() async => null;

  @override
  Future<HouseholdProfile> create({
    required String name,
    required String countryCode,
    String? regionKey,
    int personCount = 1,
    int children = 0,
    int dogs = 0,
    int cats = 0,
  }) async {
    return created = HouseholdProfile(
      id: 'household-1',
      name: name,
      countryCode: countryCode,
      regionKey: regionKey,
      personCount: personCount,
      children: children,
      dogs: dogs,
      cats: cats,
    );
  }
}

/// What the first screen of the app asks for.
///
/// These four numbers are the entire input to the supply calculation, and
/// that calculation is the first thing the app shows. It used to ask for
/// "Personen im Haushalt" and store the answer as the adult count, so a
/// household with children was planned for wrong from the first launch —
/// either as too many adults or as too few people.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<_Recording> show(WidgetTester tester) async {
    final controller = _Recording();
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [householdProfileProvider.overrideWith(() => controller)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileSetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// The button behind a tooltip. `find.byTooltip` matches the tooltip
  /// widget itself, which is not the thing that carries `onPressed`.
  Finder button(String tooltip) => find.ancestor(
    of: find.byTooltip(tooltip),
    matching: find.byType(IconButton),
  );

  /// Taps the plus beside [label] [times] times.
  Future<void> add(
    WidgetTester tester,
    String label,
    int times,
  ) async {
    final plus = button('Einer mehr: $label');
    for (var i = 0; i < times; i++) {
      await tester.tap(plus);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('it asks for adults, children, dogs and cats', (tester) async {
    await show(tester);

    // Named the same as on the household screen, because it is the same
    // field. "Personen im Haushalt" invited the wrong number.
    expect(find.text('Erwachsene'), findsOneWidget);
    expect(find.text('Kinder'), findsOneWidget);
    expect(find.text('Hunde'), findsOneWidget);
    expect(find.text('Katzen'), findsOneWidget);
    expect(find.text('Personen im Haushalt'), findsNothing);
  });

  testWidgets('every count reaches the profile it creates', (tester) async {
    final controller = await show(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Familie Muster');
    await add(tester, 'Erwachsene', 1);
    await add(tester, 'Kinder', 2);
    await add(tester, 'Hunde', 1);
    await add(tester, 'Katzen', 3);

    final submit = find.widgetWithText(FilledButton, "Los geht's");
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    final created = controller.created;
    expect(created, isNotNull);
    expect(created!.name, 'Familie Muster');
    expect(created.personCount, 2, reason: 'starts at one, tapped once');
    expect(created.children, 2);
    expect(created.dogs, 1);
    expect(created.cats, 3);
  });

  testWidgets('a household cannot be set up with nobody in it', (
    tester,
  ) async {
    await show(tester);

    // Adults start at one and the minus is disabled there: a household
    // with no adults has nothing to plan for.
    expect(
      tester.widget<IconButton>(button('Einer weniger: Erwachsene')).onPressed,
      isNull,
    );
  });

  testWidgets('children and pets start at zero and can go back down', (
    tester,
  ) async {
    await show(tester);

    expect(
      tester.widget<IconButton>(button('Einer weniger: Kinder')).onPressed,
      isNull,
      reason: 'nothing to take away yet',
    );

    await add(tester, 'Kinder', 1);
    expect(
      tester.widget<IconButton>(button('Einer weniger: Kinder')).onPressed,
      isNotNull,
    );
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('the screen survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}

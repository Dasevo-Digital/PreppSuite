import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/prepper_recipes.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/prepper_recipes_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// Cooking out of the store cupboard.
///
/// This screen had no test at all, and the thing worth pinning is the one
/// it does differently from every other: the recipes themselves come in
/// two languages, chosen from the locale rather than from the l10n files.
/// A screen that reads the locale by hand is a screen that can stop
/// following it without anybody noticing.
///
/// The two lists are not translations of each other, so they may differ
/// in length. What is pinned is that each language gets *its whole list*
/// — the failure mode is a reader being served the other language's
/// dishes, or a list arriving short.
void main() {
  Future<void> show(WidgetTester tester, String locale) async {
    await tester.binding.setSurfaceSize(const Size(500, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PrepperRecipesScreen(householdId: 'h'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('German gets the German recipes', (tester) async {
    await show(tester, 'de');

    expect(find.text('Couscous mit Kichererbsen'), findsOneWidget);
    expect(find.text('Linsen-Tomaten-Topf'), findsOneWidget);
  });

  testWidgets('English gets its own recipes, never the German ones', (
    tester,
  ) async {
    // The failure this guards against is the one the drills screen had:
    // content that stays German whatever the locale says.
    await show(tester, 'en');

    expect(find.text('Beans on toast'), findsOneWidget);
    expect(find.text('Couscous mit Kichererbsen'), findsNothing);
    expect(find.textContaining('Kichererbsen'), findsNothing);
  });

  testWidgets('each language gets its whole list, not a shortened one', (
    tester,
  ) async {
    // Counted against the source lists rather than against each other:
    // the lists are allowed to differ in length, but a screen that drops
    // one dish is the failure nobody can see from the inside.
    await show(tester, 'de');
    expect(
      tester.widgetList(find.byType(ExpansionTile)),
      hasLength(prepperRecipesDe.length),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await show(tester, 'en');
    expect(
      tester.widgetList(find.byType(ExpansionTile)),
      hasLength(prepperRecipesEn.length),
    );
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester, 'de');
    await expectAccessible(tester);
  });

  testWidgets('the screen survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester, 'de');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
void main() {
  Future<void> show(WidgetTester tester, String locale) async {
    await tester.binding.setSurfaceSize(const Size(500, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PrepperRecipesScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('German gets the German recipes', (tester) async {
    await show(tester, 'de');

    expect(find.text('Couscous mit Kichererbsen'), findsOneWidget);
    expect(find.text('Linsen-Tomaten-Topf'), findsOneWidget);
  });

  testWidgets('English does not get German recipes', (tester) async {
    // The failure this guards against is the one the drills screen had:
    // content that stays German whatever the locale says.
    await show(tester, 'en');

    expect(find.text('Couscous mit Kichererbsen'), findsNothing);
    expect(find.textContaining('Kichererbsen'), findsNothing);
  });

  testWidgets('both languages offer the same number of recipes', (
    tester,
  ) async {
    // A half-translated list is worse than an untranslated one, and two
    // hand-maintained const lists are exactly how one goes short.
    await show(tester, 'de');
    final german = tester.widgetList(find.byType(ExpansionTile)).length;

    await tester.pumpWidget(const SizedBox.shrink());
    await show(tester, 'en');
    final english = tester.widgetList(find.byType(ExpansionTile)).length;

    expect(english, german);
    expect(german, greaterThan(0));
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

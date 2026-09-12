import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/article_viewer_choice.dart';
import 'package:preppsuite_flutter/features/settings/presentation/article_viewer_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: SingleChildScrollView(
              child: ArticleViewerCard(l10n: AppLocalizations.of(context)!),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('both options are offered with their reasons', (tester) async {
    await show(tester);

    expect(find.text('Eigenes Fenster'), findsOneWidget);
    expect(find.text('In der App'), findsOneWidget);
    // Each with what it buys and what it costs, because neither is
    // simply better.
    expect(find.textContaining('Skripte, Formelsatz'), findsOneWidget);
    expect(
      find.textContaining('Braucht gar nichts vom System'),
      findsOneWidget,
    );
  });

  testWidgets('the window is preselected', (tester) async {
    await show(tester);

    // The group's own value, not the tile's — a tile knows what it
    // stands for whether or not it is the chosen one.
    final group = tester.widget<RadioGroup<ArticleViewerChoice>>(
      find.byType(RadioGroup<ArticleViewerChoice>),
    );
    expect(group.groupValue, ArticleViewerChoice.systemWindow);
  });

  testWidgets('a stored choice is the one shown', (tester) async {
    await const ArticleViewerChoiceStore().save(ArticleViewerChoice.builtIn);
    await show(tester);

    final group = tester.widget<RadioGroup<ArticleViewerChoice>>(
      find.byType(RadioGroup<ArticleViewerChoice>),
    );
    expect(group.groupValue, ArticleViewerChoice.builtIn);
  });

  testWidgets('choosing the built-in reader is remembered', (tester) async {
    await show(tester);

    await tester.tap(find.text('In der App'));
    await tester.pumpAndSettle();

    expect(
      await const ArticleViewerChoiceStore().load(),
      ArticleViewerChoice.builtIn,
    );
  });

  testWidgets('and choosing the window back again', (tester) async {
    await const ArticleViewerChoiceStore().save(ArticleViewerChoice.builtIn);
    await show(tester);

    await tester.tap(find.text('Eigenes Fenster'));
    await tester.pumpAndSettle();

    expect(
      await const ArticleViewerChoiceStore().load(),
      ArticleViewerChoice.systemWindow,
    );
  });

  testWidgets('it says the fallback holds whatever is chosen', (tester) async {
    await show(tester);

    // Or the choice reads as "and otherwise nothing", which is the one
    // thing the built-in reader was built to stop.
    expect(find.textContaining('ohnehin selbst'), findsOneWidget);
  });

  testWidgets('is accessible', (tester) async {
    await show(tester);

    await expectAccessible(tester);
  });
}

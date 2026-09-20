import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/knowledge_check.dart';
import 'package:preppsuite_flutter/features/first_aid/application/knowledge_check_de.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/knowledge_check_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Being asked back, rather than reading the guide again.
///
/// What is pinned: that a wrong answer is answered with the guide's own
/// reason rather than a cross, that the guide itself is one tap away
/// while the question is still in mind, and that the round ends by
/// pointing at what to read.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester, {String locale = 'de'}) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const KnowledgeCheckScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The question now on screen, whichever the shuffle picked.
  KnowledgeQuestion current(WidgetTester tester) => knowledgeQuestionsDe
      .firstWhere((q) => find.text(q.question).evaluate().isNotEmpty);

  testWidgets('it asks one question at a time, and says how far along', (
    tester,
  ) async {
    await show(tester);

    expect(find.textContaining('Frage 1 von'), findsOneWidget);
    final question = current(tester);
    expect(find.text(question.answers.first), findsOneWidget);
  });

  testWidgets('a wrong answer is met with the reason, not a cross', (
    tester,
  ) async {
    await show(tester);
    final question = current(tester);
    final wrong = question.correct == 0 ? 1 : 0;

    await tester.tap(find.text(question.answers[wrong]));
    await tester.pumpAndSettle();

    expect(find.text('Nicht ganz.'), findsOneWidget);
    // The guide's own wording, while the question is still in mind.
    expect(find.text(question.because), findsOneWidget);
    expect(find.text('Anleitung lesen'), findsOneWidget);
  });

  testWidgets('a right answer says so and still gives the reason', (
    tester,
  ) async {
    await show(tester);
    final question = current(tester);

    await tester.tap(find.text(question.answers[question.correct]));
    await tester.pumpAndSettle();

    expect(find.text('Richtig.'), findsOneWidget);
    expect(find.text(question.because), findsOneWidget);
  });

  testWidgets('answering twice does not change the answer', (tester) async {
    // The first tap is the answer. A second one after seeing the reason
    // would let somebody mark themselves right.
    await show(tester);
    final question = current(tester);
    final wrong = question.correct == 0 ? 1 : 0;

    await tester.tap(find.text(question.answers[wrong]));
    await tester.pumpAndSettle();
    await tester.tap(find.text(question.answers[question.correct]));
    await tester.pumpAndSettle();

    expect(find.text('Nicht ganz.'), findsOneWidget);
  });

  testWidgets('a finished round says what to read again', (tester) async {
    await show(tester);

    for (var i = 0; i < knowledgeRoundLength; i++) {
      final question = current(tester);
      final wrong = question.correct == 0 ? 1 : 0;
      await tester.tap(find.text(question.answers[wrong]));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(i + 1 < knowledgeRoundLength ? 'Weiter' : 'Fertig'),
      );
      await tester.pumpAndSettle();
    }

    expect(
      find.textContaining('0 von $knowledgeRoundLength richtig'),
      findsOneWidget,
    );
    expect(find.text('Das würde ich noch einmal nachlesen'), findsOneWidget);
    expect(find.text('Noch eine Runde'), findsOneWidget);
  });

  testWidgets('English gets the English screen', (tester) async {
    await show(tester, locale: 'en');
    expect(find.text('Check your knowledge'), findsOneWidget);
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('it survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}

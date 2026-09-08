import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_providers.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/knowledge_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

const _wikibooks = StoredArchive(
  id: 'a',
  location: '/tmp/wikibooks.zim',
  label: 'Wikibooks',
);
const _klexikon = StoredArchive(
  id: 'b',
  location: '/tmp/klexikon.zim',
  label: 'Klexikon',
);

class _Library extends KnowledgeController {
  _Library(this.fixed);

  final KnowledgeState fixed;

  /// What the screen asked to switch to.
  final asked = <String>[];

  @override
  Future<KnowledgeState> build() async => fixed;

  @override
  Future<KnowledgeProblem?> select(String id) async {
    asked.add(id);
    return null;
  }
}

/// Switching between archives.
///
/// The archives cannot actually be opened here — that is real file I/O and
/// a listening port — so what is checked is the part the user touches: the
/// row is there, it marks the open one, and a tap asks for the other.
void main() {
  Future<_Library> show(WidgetTester tester, KnowledgeState state) async {
    final controller = _Library(state);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [knowledgeProvider.overrideWith(() => controller)],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KnowledgeScreen(),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  testWidgets('two archives are both offered, the open one marked', (
    tester,
  ) async {
    await show(
      tester,
      const KnowledgeState(
        library: [_wikibooks, _klexikon],
        selectedId: 'b',
      ),
    );

    expect(find.widgetWithText(ChoiceChip, 'Wikibooks'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Klexikon'), findsOneWidget);

    final open = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Klexikon'),
    );
    expect(open.selected, isTrue);
  });

  testWidgets('tapping the other one asks for it', (tester) async {
    final controller = await show(
      tester,
      const KnowledgeState(
        library: [_wikibooks, _klexikon],
        selectedId: 'b',
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Wikibooks'));
    await tester.pump();

    expect(controller.asked, ['a']);
  });

  testWidgets('a single archive gets no chooser', (tester) async {
    // A row with one choice in it is a line of clutter above every search.
    await show(
      tester,
      const KnowledgeState(library: [_wikibooks], selectedId: 'a'),
    );

    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('the archive switcher meets the accessibility guidelines', (
    tester,
  ) async {
    await show(
      tester,
      const KnowledgeState(library: [_wikibooks, _klexikon], selectedId: 'b'),
    );
    await expectAccessible(tester);
  });

  testWidgets('the archive switcher survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await show(
      tester,
      const KnowledgeState(library: [_wikibooks, _klexikon], selectedId: 'b'),
    );
  });
}

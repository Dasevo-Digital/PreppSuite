import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_providers.dart';
import 'package:preppsuite_flutter/features/knowledge/application/recommended_archives.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/knowledge_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _NoArchive extends KnowledgeController {
  @override
  Future<KnowledgeState> build() async => const KnowledgeState();
}

/// What somebody sees before they have downloaded anything.
///
/// The library holds thousands of files with names like
/// `wikiversity_de_all_maxi_2026-01`, and its search box helps nobody who
/// does not already know what to type. Schooling is the case this list
/// exists for: if public life stops for a season, the children still have
/// to learn something.
void main() {
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [knowledgeProvider.overrideWith(_NoArchive.new)],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KnowledgeScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('names an archive to start with, German schooling first', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('Womit anfangen'), findsOneWidget);

    // The German school material comes before the general encyclopedia.
    final wikibooks = tester.getTopLeft(find.text('Wikibooks')).dy;
    final klexikon = tester.getTopLeft(find.text('Klexikon')).dy;
    final wikipedia = tester.getTopLeft(find.text('Wikipedia')).dy;
    expect(wikibooks, lessThan(wikipedia));
    expect(klexikon, lessThan(wikipedia));

    expect(
      find.textContaining('Mathematikkurs bis zum Abitur'),
      findsOneWidget,
    );
  });

  testWidgets('says plainly that Khan Academy has no German archive', (
    tester,
  ) async {
    await show(tester);

    await tester.scrollUntilVisible(find.text('Khan Academy'), 200);

    expect(
      find.textContaining('ein deutsches Archiv gibt es nicht'),
      findsOneWidget,
    );
  });

  test('every suggestion carries a search and a language', () {
    for (final archive in RecommendedArchive.values) {
      expect(archive.query.trim(), isNotEmpty, reason: archive.name);
      expect(archive.language, hasLength(3), reason: archive.name);
    }
  });
}

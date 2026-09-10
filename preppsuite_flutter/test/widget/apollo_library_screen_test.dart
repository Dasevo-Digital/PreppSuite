import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_providers.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/apollo_library_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

class _NoArchive extends KnowledgeController {
  @override
  Future<KnowledgeState> build() async => const KnowledgeState();
}

void main() {
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [knowledgeProvider.overrideWith(_NoArchive.new)],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ApolloLibraryScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('organizes practical knowledge and education for offline use', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('APOLLO-Wissensbasis'), findsOneWidget);
    expect(find.text('Medizin & Erste Hilfe'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Überleben, Bushcraft & Selbstversorgung'),
      200,
    );
    expect(
      find.text('Überleben, Bushcraft & Selbstversorgung'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Lernen zu Hause'), 200);
    expect(find.text('Lernen zu Hause'), findsOneWidget);
  });

  testWidgets('meets accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });
}

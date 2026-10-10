import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_providers.dart';
import 'package:preppsuite_flutter/features/knowledge/application/library_costs.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/knowledge_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

class _Library extends KnowledgeController {
  _Library(this.fixed);

  final KnowledgeState fixed;

  @override
  Future<KnowledgeState> build() async => fixed;
}

/// What the whole library costs the device, under its tiles (#26).
void main() {
  Future<void> show(WidgetTester tester, List<StoredArchive> library) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          knowledgeProvider.overrideWith(
            () => _Library(KnowledgeState(library: library)),
          ),
          indexStorageBytesProvider.overrideWithValue(
            (id) async => id == 'a' ? 300 * 1024 * 1024 : 0,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KnowledgeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('adds up the archives, the indexes, and says one is open', (
    tester,
  ) async {
    await show(tester, const [
      StoredArchive(
        id: 'a',
        location: '/tmp/a.zim',
        label: 'Wikibooks',
        sizeBytes: 1024 * 1024 * 1024,
      ),
      StoredArchive(
        id: 'b',
        location: '/tmp/b.zim',
        label: 'Klexikon',
        sizeBytes: 512 * 1024 * 1024,
      ),
      StoredArchive(id: 'c', location: '/tmp/c.zim', label: 'PhET'),
    ]);

    expect(
      find.text('3 Archive, zusammen 1.5 GB auf dem Datenträger.'),
      findsOneWidget,
    );
    expect(find.textContaining('Bei einem ist die Größe'), findsOneWidget);
    expect(find.text('Eigene Suchindizes: 300 MB.'), findsOneWidget);
    expect(find.textContaining('höchstens 64 MB'), findsOneWidget);
  });
}

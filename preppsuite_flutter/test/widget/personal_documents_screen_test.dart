import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/personal_documents_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// The household's own documents.
///
/// The screen had no test, and it is the one holding the most sensitive
/// thing the app stores: a full-text index of whatever somebody scanned
/// in — insurance policies, medical letters, contracts. What it promises
/// about that index is therefore not decoration, and neither is the
/// question in front of throwing it away.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PersonalDocumentsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing added it says so rather than looking broken', (
    tester,
  ) async {
    await show(tester);

    expect(find.textContaining('Noch keine eigenen Dokumente'), findsOneWidget);
  });

  testWidgets('it states that the files themselves are not duplicated', (
    tester,
  ) async {
    // The fact somebody adding a medical letter needs from this screen:
    // nothing is copied anywhere they would afterwards have to remember
    // about. The other half — that the text index stays on the device —
    // is said in the dialog that offers the indexing, which is where the
    // choice is made.
    await show(tester);

    expect(find.textContaining('nicht dupliziert'), findsOneWidget);
    expect(find.textContaining('bleiben an ihrem Speicherort'), findsOneWidget);
  });

  testWidgets('clearing the index asks first, and says what survives', (
    tester,
  ) async {
    // Not undoable — the index has to be rebuilt from the files, which
    // may be on a drive that is no longer plugged in. So this one asks,
    // and the question says the originals are untouched, because the
    // sentence somebody fears is "your documents are gone".
    await show(tester);

    await tester.tap(find.byTooltip('Suchindex löschen'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.textContaining('Originaldateien bleiben erhalten'),
      findsOneWidget,
    );
  });

  testWidgets('and abandoning that question changes nothing', (tester) async {
    await show(tester);
    await tester.tap(find.byTooltip('Suchindex löschen'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('the screen survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });

  testWidgets('a file changed since indexing is named, with a way out', (
    tester,
  ) async {
    // #77: documents are read where they lie, so a newer edition saved
    // over one leaves its index answering from the old text. The real
    // file below no longer matches the fingerprint the index was built
    // with.
    late Directory dir;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('docs');
      final file = File('${dir.path}/Police.md');
      await file.writeAsString('Neue Fassung', flush: true);
      const store = PersonalDocumentStore();
      final id = (await store.add(
        location: file.path,
        label: 'Police.md',
      )).single.id;
      await store.updateIndex(
        id,
        status: 'ready',
        characters: 12,
        fingerprint: 'f1:5:1:alt',
      );
    });
    addTearDown(() => dir.delete(recursive: true));

    await show(tester);
    // The check reads the file for real, one await after another, and
    // each real read only completes outside the test's fake clock.
    final changed = find.textContaining('Datei geändert');
    for (var i = 0; i < 50 && changed.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }

    expect(find.textContaining('Datei geändert'), findsOneWidget);
    expect(find.textContaining('Ein Dokument hat sich'), findsOneWidget);
    expect(find.text('Index aktualisieren'), findsOneWidget);
  });
}

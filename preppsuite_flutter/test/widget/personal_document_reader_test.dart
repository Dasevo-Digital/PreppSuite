import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/personal_document_reader_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The built-in reader for EPUB and Markdown.
///
/// It used to extract the text on the interface's thread and lay all of it
/// out as one paragraph. Now the extraction runs in an isolate, so these
/// tests let real time pass for it.
void main() {
  late Directory workspace;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    workspace = Directory.systemTemp.createTempSync('preppsuite-reader');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  Future<void> open(WidgetTester tester, File file) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PersonalDocumentReaderScreen(
          document: PersonalDocument(
            id: 'doc',
            location: file.path,
            label: file.uri.pathSegments.last,
            addedAt: DateTime(2026, 10, 2),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
    }
  }

  testWidgets('shows the document paragraph by paragraph', (tester) async {
    final file = File('${workspace.path}/funk.md')
      ..writeAsStringSync('Erster Absatz.\n\nZweiter Absatz.');

    await open(tester, file);

    expect(find.text('Erster Absatz.'), findsOneWidget);
    expect(find.text('Zweiter Absatz.'), findsOneWidget);
  });

  testWidgets('says what to do with a document it cannot read', (
    tester,
  ) async {
    // An empty document is the one failure that needs no huge file to
    // produce; it takes the same road as a damaged one.
    final file = File('${workspace.path}/leer.md')..writeAsStringSync('');

    await open(tester, file);

    expect(
      find.text('Das Dokument konnte nicht geöffnet werden.'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Extern öffnen'),
      findsOneWidget,
    );
  });
}

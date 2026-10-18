import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';
import 'package:preppsuite_flutter/core/emergency_access.dart';
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides_de.dart';
import 'package:preppsuite_flutter/features/kids_comic/application/kids_comic.dart';
import 'package:preppsuite_flutter/features/kids_comic/application/kids_comic_de.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zstd_stream.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_engine.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_store.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';
import 'package:preppsuite_flutter/features/translator/application/translator_catalogue.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Does the app's native foundation hold on this platform (#142)?
///
/// The unit tests run on the machine that builds, against its libraries.
/// What ships is another thing: on Linux and Windows the packages were
/// built and never started, and a library missing from one of them --
/// SQLite with its cipher, PDFium, Zstandard, the translator -- would
/// have been found by the first person to open it. This runs on every
/// platform a release goes to, in the release itself, and touches each of
/// those for real, then draws the screens an emergency needs.
///
/// Never on this Mac: under the production identifier it would start
/// beside the household's real data. It runs on the iPhone simulator, the
/// Android emulator and the two build machines.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('start'));
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  testWidgets('SQLite with its cipher keeps and returns a household', (
    tester,
  ) async {
    expect(
      LocalDatabaseEncryption.cipherAvailable,
      isTrue,
      reason: 'the bundled SQLite has no cipher',
    );
    final file = File('${dir.path}/preppsuite.sqlite');
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'water',
        householdId: 'home',
        name: 'Trinkwasser',
        category: 'water',
        quantity: 12,
        unit: 'l',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026, 10, 9),
        dirty: const Value(false),
      ),
    );
    expect(
      (await db.watchInventoryItems('home').first).single.name,
      'Trinkwasser',
    );
    // The daily copy (#140) is SQLite's own and must work here too.
    await db.snapshotTo('${dir.path}/copy.sqlite');
    await db.close();
    expect(await File('${dir.path}/copy.sqlite').length(), greaterThan(0));
  });

  testWidgets('PDFium opens and draws a page', (tester) async {
    await tester.runAsync(() async {
      final document = pw.Document()
        ..addPage(pw.Page(build: (_) => pw.Text('Versicherungsschein')));
      final bytes = Uint8List.fromList(await document.save());
      await pdfrxFlutterInitialize();
      final pdf = await PdfDocument.openData(bytes);
      try {
        expect(pdf.pages, hasLength(1));
        final image = await pdf.pages.first.render(
          fullWidth: 200,
          fullHeight: 280,
        );
        expect(image, isNotNull, reason: 'PDFium drew nothing');
        image!.dispose();
      } finally {
        await pdf.dispose();
      }
    });
  });

  testWidgets('Zstandard unpacks what an archive carries', (tester) async {
    // A frame of "PreppSuite" compressed with zstd, made with the command
    // line tool: `printf PreppSuite | zstd -c | xxd -i`.
    final frame = Uint8List.fromList([
      0x28, 0xb5, 0x2f, 0xfd, 0x04, 0x58, 0x51, 0x00, 0x00, 0x50, 0x72, //
      0x65, 0x70, 0x70, 0x53, 0x75, 0x69, 0x74, 0x65, 0x97, 0x97, 0xaa, //
      0x45,
    ]);
    expect(
      String.fromCharCodes(zstdDecompress(frame, limit: 1024)),
      'PreppSuite',
    );
  });

  testWidgets('the translator library loads where the package carries it', (
    tester,
  ) async {
    // The release builds it for Linux, Windows and Android arm64 (#184,
    // #185); a working copy or the CI may not have, so Android only
    // insists when told to. iOS has none.
    const expectOnAndroid = bool.fromEnvironment(
      'PREPPSUITE_EXPECT_TRANSLATOR',
    );
    if (Platform.isLinux ||
        Platform.isWindows ||
        (Platform.isAndroid && expectOnAndroid)) {
      expect(translatorAvailable, isTrue, reason: 'preppsuite_translate');
    }
    if (!translatorAvailable) return;
    // A real call through the engine: a model that is not there is an
    // error from the library, not a crash of the app.
    const missing = InstalledTranslatorPack(
      direction: TranslatorDirection(PhraseLanguage.de, PhraseLanguage.en),
      version: 'test',
      size: 0,
      modelPath: '/nonexistent/model.bin',
      lexPath: '/nonexistent/lex.bin',
      vocabPath: '/nonexistent/vocab.spm',
    );
    // Caught inside: runAsync reports what escapes it as a test failure.
    final error = await tester.runAsync(() async {
      try {
        await translateText('Hallo', const [missing]);
        return null;
      } on TranslatorException catch (error) {
        return error;
      }
    });
    expect(error, isA<TranslatorException>());
  });

  testWidgets('the emergency help draws and leads to first aid', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: EmergencyAccessScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('112 anrufen'), findsOneWidget);
    await tester.tap(find.text('Erste Hilfe'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bewusstlose Person'), findsWidgets);
  });

  testWidgets('the comic’s pictures and the first aid charts decode', (
    tester,
  ) async {
    // They are WebP. An engine that cannot read it would show grey boxes
    // where the pictures belong, and no test on this Mac would notice.
    final images = [
      kidsComicAsset(kidsComicCover),
      for (final chapter in kidsComicDe.chapters)
        for (final panel in chapter.panels) panel.asset,
      for (final guide in firstAidGuidesDe) ?guide.chart,
    ];
    await tester.runAsync(() async {
      for (final image in images) {
        final data = await rootBundle.load(image);
        // The engine's own image decoder reads the format and its size.
        // An engine without WebP fails here, on every machine.
        final buffer = await ui.ImmutableBuffer.fromUint8List(
          data.buffer.asUint8List(),
        );
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        expect(descriptor.width, greaterThan(900), reason: image);
        // The whole picture as well, where there is a GPU to put it on.
        // The Windows build machine runs this over ssh with no desktop,
        // and there a decoded frame has nowhere to go: "No Impeller
        // context is available". That says nothing about the format.
        final codec = await descriptor.instantiateCodec();
        try {
          final frame = await codec.getNextFrame();
          expect(frame.image.width, descriptor.width, reason: image);
          frame.image.dispose();
        } on Exception catch (error) {
          if (!'$error'.contains('No Impeller context')) rethrow;
        } finally {
          codec.dispose();
          descriptor.dispose();
          buffer.dispose();
        }
      }
    });
  });
}

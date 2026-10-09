import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';
import 'package:preppsuite_flutter/core/emergency_access.dart';
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/features/knowledge/application/xapian_index.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zstd_stream.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Does the app's native foundation hold on this platform (#142)?
///
/// The unit tests run on the machine that builds, against its libraries.
/// What ships is another thing: on Linux and Windows the packages were
/// built and never started, and a library missing from one of them --
/// SQLite with its cipher, PDFium, Zstandard, the Xapian shim -- would
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

  testWidgets('the Xapian shim is where the package says it is', (
    tester,
  ) async {
    // Shipped with the desktop packages; iOS and Android search with the
    // app's own index, which is not a failure there.
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      expect(xapianAvailable, isTrue, reason: 'zim_xapian is missing');
    }
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
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_providers.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/knowledge_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/knowledge/zim_fixture.dart';

/// The start page of the encyclopedia.
///
/// What is on the device is the thing to see on arriving here. It used to
/// be a row of chips over a "browse" card — the chips naming archives one
/// line at a time, the card the only thing with any size to it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory workspace;

  /// Containers close once, whether the test closed them or the tear-down
  /// did. A test that has to shut down early — because an open archive
  /// leaves timers running that a widget test refuses to end on — says so
  /// here rather than racing the tear-down for it.
  final opened = <ProviderContainer>[];
  final closed = <ProviderContainer>{};
  void close(ProviderContainer container) {
    if (closed.add(container)) container.dispose();
  }

  setUp(() {
    opened.clear();
    closed.clear();
    SharedPreferences.setMockInitialValues({});
    workspace = Directory.systemTemp.createTempSync('preppsuite-start');
  });

  tearDown(() async {
    // Every archive shut before the files under it go. Windows refuses to
    // delete a file another handle still holds, and an archive is closed
    // asynchronously — so the folder is retried rather than deleted once
    // and hoped for. On macOS and Linux the first attempt succeeds.
    for (final container in opened) {
      close(container);
    }
    for (var attempt = 0; ; attempt++) {
      try {
        workspace.deleteSync(recursive: true);
        return;
      } on FileSystemException {
        if (attempt >= 40) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  });

  /// A genuine archive that says what it is. Uncompressed, so reading its
  /// metadata needs no native decompressor.
  String writeArchive(String title, String about, String fileName) => writeZim(
    workspace,
    ZimFixture(
      entries: [
        ZimFixtureEntry(
          namespace: 'C',
          url: 'Artikel',
          title: 'Artikel',
          content: utf8.encode('<h1>$title</h1>'),
        ),
        ZimFixtureEntry(
          namespace: 'M',
          url: 'Title',
          content: utf8.encode(title),
        ),
        ZimFixtureEntry(
          namespace: 'M',
          url: 'Description',
          content: utf8.encode(about),
        ),
      ],
    ),
    name: fileName,
  );

  Future<ProviderContainer> libraryOfTwo() async {
    // No full-text index here: switching archives opens the database of
    // the one being switched to, and its timers outlive a widget test.
    // What is under test is the library, not the index.
    final container = ProviderContainer(
      overrides: [knowledgeIndexDatabaseProvider.overrideWithValue(null)],
    );
    opened.add(container);
    await container.read(knowledgeProvider.future);

    final notifier = container.read(knowledgeProvider.notifier);
    for (final (title, about, file) in [
      ('Klexikon', 'Ein Lexikon fuer Kinder.', 'klexikon.zim'),
      ('Wikibooks', 'Lehrbuecher aller Art.', 'wikibooks.zim'),
    ]) {
      expect(
        await notifier.useArchive(
          location: writeArchive(title, about, file),
          label: file,
        ),
        isNull,
      );
    }
    return container;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KnowledgeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Pumps until [ready], letting the real event loop run in between.
  ///
  /// Opening an archive reads a file and starts a loopback server, and
  /// neither progresses against the fake clock a widget test runs on —
  /// while the waiting widgets only rebuild when that fake clock is
  /// pumped. So both have to be turned, in turns.
  Future<void> settle(WidgetTester tester, bool Function() ready) async {
    for (var i = 0; i < 50 && !ready(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(ready(), isTrue, reason: 'the screen never got there');
  }

  /// Builds the library and pumps the screen on it.
  ///
  /// The library is built inside [WidgetTester.runAsync]: opening an
  /// archive reads a real file and starts a real loopback server, and
  /// neither progresses against the fake clock a widget test runs on.
  Future<ProviderContainer> pumpLibrary(
    WidgetTester tester, {
    Future<ProviderContainer> Function()? build,
  }) async {
    late ProviderContainer container;
    await tester.runAsync(() async {
      container = await (build ?? libraryOfTwo)();
    });
    await pumpScreen(tester, container);
    return container;
  }

  testWidgets('the archives are tiles, with what each one says about itself', (
    tester,
  ) async {
    final container = await pumpLibrary(tester);

    expect(container.read(knowledgeProvider).requireValue.isReady, isTrue);

    Finder inGrid(Finder matching) =>
        find.descendant(of: find.byType(GridView), matching: matching);

    expect(find.byType(GridView), findsOneWidget);
    expect(inGrid(find.text('Klexikon')), findsOneWidget);
    expect(inGrid(find.text('Wikibooks')), findsOneWidget);
    expect(inGrid(find.text('Ein Lexikon fuer Kinder.')), findsOneWidget);
    // The one that is open is marked as such.
    expect(inGrid(find.byIcon(Icons.check_circle)), findsOneWidget);
    // And the browse card is still there, below them.
    expect(find.text('Archiv durchblättern'), findsOneWidget);
  });

  testWidgets('no archive can be deleted from the start page', (tester) async {
    // Removing belongs in "manage archives". A delete button one tap from
    // the archive somebody means to open is a trap.
    final container = await pumpLibrary(tester);
    expect(container.read(knowledgeProvider).requireValue.isReady, isTrue);

    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets('tapping a tile opens that archive', (tester) async {
    final container = await pumpLibrary(tester);

    // Wikibooks was added last, so Klexikon is the one to switch to.
    expect(container.read(knowledgeProvider).requireValue.title, 'Wikibooks');

    await tester.tap(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Klexikon'),
      ),
    );
    await settle(
      tester,
      () => container.read(knowledgeProvider).requireValue.title == 'Klexikon',
    );
    // An open archive holds a loopback server and a file handle, and the
    // timers behind them outlast the frame the assertion above passes on.
    // Closed here, in the real event loop, rather than left for the
    // tear-down that runs after the widget test checks for them.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      close(container);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });

  testWidgets('one archive alone still gets a tile', (tester) async {
    await pumpLibrary(
      tester,
      build: () async {
        final container = ProviderContainer();
        opened.add(container);
        await container.read(knowledgeProvider.future);
        await container
            .read(knowledgeProvider.notifier)
            .useArchive(
              location: writeArchive('Klexikon', 'Fuer Kinder.', 'k.zim'),
              label: 'k.zim',
            );
        return container;
      },
    );

    // The chip row hid itself below two archives, which left a library of
    // one showing nothing of itself at all.
    expect(find.byType(GridView), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Klexikon'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a search replaces the tiles with its results', (tester) async {
    await pumpLibrary(tester);

    await tester.enterText(find.byType(TextField), 'Artikel');
    // Past the 250 ms the field waits before it searches.
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byType(GridView),
      findsNothing,
      reason: 'the library gives way to what was asked for',
    );
    await settle(tester, () => find.text('Artikel').evaluate().isNotEmpty);
  });

  test('the library entry survives a restart of the app', () async {
    // The stored entry is what a downloaded archive becomes; if it does
    // not come back, the download was for nothing.
    final container = await libraryOfTwo();
    container.dispose();

    final again = ProviderContainer();
    opened.add(again);
    final state = await again.read(knowledgeProvider.future);
    expect(state.library.map((a) => a.title), ['Klexikon', 'Wikibooks']);
    expect(state.isReady, isTrue);
  });

  test('an archive keeps its own title and description in the library',
      () async {
    final container = await libraryOfTwo();
    final library = container.read(knowledgeProvider).requireValue.library;
    expect(library.map((a) => a.title), ['Klexikon', 'Wikibooks']);
    expect(library.first.description, 'Ein Lexikon fuer Kinder.');
    expect(library.first, isA<StoredArchive>());
  });
}

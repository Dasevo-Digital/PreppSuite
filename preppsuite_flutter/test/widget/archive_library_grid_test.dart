import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_providers.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/knowledge_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The smallest valid PNG there is, standing in for the 48x48
/// illustration every openZIM archive carries.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8'
    'DAwAAABQABAAAAAAAAAAA=',
  ),
);

/// An archive that has been opened since covers were stored: it knows
/// what it is called, what it is, and what it looks like.
final _ifixit = StoredArchive(
  id: 'a',
  location: 'bookmark://CED3F69F-6A45-4A8D-B5E0-3E8CBC9310A8',
  label: 'ifixit_de_all_2026-03.zim',
  title: 'iFixit in German',
  description: 'iFixit ist eine weltweite Gemeinschaft von Menschen.',
  cover: _png,
  sizeBytes: 3592670002,
  entryCount: 886124,
);

/// One from before, with nothing but its file name.
const _older = StoredArchive(
  id: 'b',
  location: '/tmp/wikibooks.zim',
  label: 'wikibooks_de_all_maxi_2026-01.zim',
);

/// A library that really loses an archive when one is removed, so the
/// sheet around it has something to react to.
class _MutableLibrary extends KnowledgeController {
  _MutableLibrary(this.initial);

  final KnowledgeState initial;

  @override
  Future<KnowledgeState> build() async => initial;

  @override
  Future<void> remove(String id) async {
    final current = state.requireValue;
    final library = [
      for (final archive in current.library)
        if (archive.id != id) archive,
    ];
    state = AsyncData(
      KnowledgeState(
        library: library,
        selectedId: library.any((a) => a.id == current.selectedId)
            ? current.selectedId
            : null,
      ),
    );
  }
}

class _Library extends KnowledgeController {
  _Library(this.fixed);

  final KnowledgeState fixed;
  final asked = <String>[];
  final removed = <String>[];

  @override
  Future<KnowledgeState> build() async => fixed;

  @override
  Future<KnowledgeProblem?> select(String id) async {
    asked.add(id);
    return null;
  }

  @override
  Future<void> remove(String id) async => removed.add(id);
}

/// The library as tiles.
///
/// It used to be a list of file names with `bookmark://BFDD0E14-...`
/// printed under each one — a macOS security handle, which means nothing
/// to anybody. What an archive actually carries is a title, a one-line
/// description and a cover, all written by whoever built it.
void main() {
  Future<_Library> openSheet(
    WidgetTester tester,
    KnowledgeState state,
  ) async {
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
    await tester.pumpAndSettle();

    // By icon, not by type: the menu is keyed on a private enum, so
    // `PopupMenuButton<_ArchiveAction>` cannot be named from here.
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive verwalten'));
    await tester.pumpAndSettle();
    return controller;
  }

  final both = KnowledgeState(
    library: [_ifixit, _older],
    selectedId: 'a',
  );

  testWidgets('a tile names the archive, not the file', (tester) async {
    await openSheet(tester, both);

    // Scoped to the grid: the switcher above the search now names the
    // archive too, for the same reason.
    Finder inGrid(Finder matching) =>
        find.descendant(of: find.byType(GridView), matching: matching);

    expect(inGrid(find.text('iFixit in German')), findsOneWidget);
    expect(
      inGrid(find.textContaining('iFixit ist eine weltweite Gemeinschaft')),
      findsOneWidget,
    );
    // And the handle is nowhere to be seen.
    expect(find.textContaining('bookmark://'), findsNothing);
  });

  testWidgets('an archive with no title of its own keeps its file name', (
    tester,
  ) async {
    // Entries added before covers were stored have none until the next
    // time they are opened, and a tile with nothing on it would be worse
    // than one with a file name.
    await openSheet(tester, both);

    // Scoped to the grid: the switcher behind the sheet names it too.
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('wikibooks_de_all_maxi_2026-01.zim'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the cover is drawn where there is one', (tester) async {
    await openSheet(tester, both);

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('and an icon where there is not', (tester) async {
    await openSheet(tester, both);

    expect(find.byIcon(Icons.menu_book_outlined), findsWidgets);
  });

  testWidgets('the open one is marked', (tester) async {
    await openSheet(tester, both);

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('tapping a tile asks for that archive', (tester) async {
    final controller = await openSheet(tester, both);

    await tester.tap(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('wikibooks_de_all_maxi_2026-01.zim'),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.asked, ['b']);
  });

  testWidgets('each tile can remove its own archive', (tester) async {
    final controller = await openSheet(tester, both);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();

    expect(controller.removed, hasLength(1));
  });

  testWidgets('the size and article count stay where they were', (
    tester,
  ) async {
    // The three numbers that say whether an archive is worth keeping on
    // a device.
    await openSheet(tester, both);

    // Binary units here, which is what `_formatBytes` on this screen
    // uses: 3,592,670,002 bytes is 3.3 GiB.
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.textContaining('886124 Einträge · ungefähr 3.3 GB'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('removing one archive leaves the sheet open', (tester) async {
    // It used to close on every delete, so clearing out three archives
    // meant reopening the sheet three times — and the count at the top
    // went on naming the number there had been before.
    final controller = _MutableLibrary(both);
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
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive verwalten'));
    await tester.pumpAndSettle();

    expect(find.text('2 Archive auf diesem Gerät'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();

    expect(
      find.text('Archive verwalten'),
      findsOneWidget,
      reason: 'the sheet stays put',
    );
    expect(
      find.text('1 Archive auf diesem Gerät'),
      findsOneWidget,
      reason: 'and says what is left, not what there was',
    );
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('emptying the library leaves the sheet open to add one', (
    tester,
  ) async {
    final controller = _MutableLibrary(both);
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
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive verwalten'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byIcon(Icons.delete_outline).last);
      await tester.pumpAndSettle();
    }

    expect(find.text('Kein Archiv mehr in der Bibliothek.'), findsOneWidget);
    // The way out is still under the finger rather than gone with it.
    expect(find.text('Weiteres Archiv hinzufügen'), findsOneWidget);
  });

  testWidgets('the library grid meets the accessibility guidelines', (
    tester,
  ) async {
    await openSheet(tester, both);
    await expectAccessible(tester);
  });

  testWidgets('the tiles survive twice the font size', (tester) async {
    useLargeText(tester);
    await openSheet(tester, both);
  });
}

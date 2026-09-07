import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_index_database.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_providers.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'zim_fixture.dart';

/// Several archives at once, and switching between them.
///
/// Before this the app held one: choosing a second one replaced the first,
/// which meant that keeping the school material and the encyclopedia meant
/// finding one of them again every time.
void main() {
  late Directory workspace;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    workspace = Directory.systemTemp.createTempSync('preppsuite-library');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  /// A tiny but genuine archive, named by its own `M/Title` entry so the
  /// test can tell which one is open.
  String writeArchive(String title, String fileName) {
    return writeZim(
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
        ],
      ),
      name: fileName,
    );
  }

  Future<KnowledgeState> load(ProviderContainer container) =>
      container.read(knowledgeProvider.future);

  test('a second archive is added rather than replacing the first', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await load(container);

    final notifier = container.read(knowledgeProvider.notifier);
    final wikibooks = writeArchive('Wikibooks', 'wikibooks.zim');
    final klexikon = writeArchive('Klexikon', 'klexikon.zim');

    expect(
      await notifier.useArchive(location: wikibooks, label: 'Wikibooks'),
      isNull,
    );
    expect(
      await notifier.useArchive(location: klexikon, label: 'Klexikon'),
      isNull,
    );

    final state = container.read(knowledgeProvider).requireValue;
    expect(state.library.map((a) => a.label), ['Wikibooks', 'Klexikon']);
    expect(state.label, 'Klexikon');
    expect(state.title, 'Klexikon');
    expect(state.isReady, isTrue);
  });

  test('switching opens the other one and keeps the library', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await load(container);

    final notifier = container.read(knowledgeProvider.notifier);
    await notifier.useArchive(
      location: writeArchive('Wikibooks', 'wikibooks.zim'),
      label: 'Wikibooks',
    );
    await notifier.useArchive(
      location: writeArchive('Klexikon', 'klexikon.zim'),
      label: 'Klexikon',
    );

    final wikibooksId = container
        .read(knowledgeProvider)
        .requireValue
        .library
        .first
        .id;

    expect(await notifier.select(wikibooksId), isNull);

    final state = container.read(knowledgeProvider).requireValue;
    expect(state.selectedId, wikibooksId);
    expect(state.title, 'Wikibooks');
    expect(state.library, hasLength(2), reason: 'switching is not removing');
  });

  test('adding the same file twice does not list it twice', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await load(container);

    final notifier = container.read(knowledgeProvider.notifier);
    final path = writeArchive('Wikibooks', 'wikibooks.zim');

    await notifier.useArchive(location: path, label: 'Wikibooks');
    await notifier.useArchive(location: path, label: 'Wikibooks');

    expect(
      container.read(knowledgeProvider).requireValue.library,
      hasLength(1),
    );
  });

  test('removing the open archive falls back to what is left', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await load(container);

    final notifier = container.read(knowledgeProvider.notifier);
    await notifier.useArchive(
      location: writeArchive('Wikibooks', 'wikibooks.zim'),
      label: 'Wikibooks',
    );
    await notifier.useArchive(
      location: writeArchive('Klexikon', 'klexikon.zim'),
      label: 'Klexikon',
    );

    final open = container.read(knowledgeProvider).requireValue.selectedId!;
    await notifier.remove(open);

    final state = container.read(knowledgeProvider).requireValue;
    expect(state.library.map((a) => a.label), ['Wikibooks']);
    expect(state.title, 'Wikibooks');
    expect(state.isReady, isTrue);
  });

  test(
    'a file that will not open leaves the library and the open one',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await load(container);

      final notifier = container.read(knowledgeProvider.notifier);
      await notifier.useArchive(
        location: writeArchive('Wikibooks', 'wikibooks.zim'),
        label: 'Wikibooks',
      );

      final nonsense = '${workspace.path}/nonsense.zim';
      File(nonsense).writeAsBytesSync(List.filled(200, 0));

      expect(
        await notifier.useArchive(location: nonsense, label: 'Unsinn'),
        KnowledgeProblem.unreadable,
      );

      final state = container.read(knowledgeProvider).requireValue;
      expect(state.library.map((a) => a.label), ['Wikibooks']);
      expect(state.title, 'Wikibooks', reason: 'the working one stayed open');
    },
  );

  test('the library survives a restart, with the same one open', () async {
    final first = ProviderContainer();
    await load(first);
    await first
        .read(knowledgeProvider.notifier)
        .useArchive(
          location: writeArchive('Wikibooks', 'wikibooks.zim'),
          label: 'Wikibooks',
        );
    await first
        .read(knowledgeProvider.notifier)
        .useArchive(
          location: writeArchive('Klexikon', 'klexikon.zim'),
          label: 'Klexikon',
        );
    first.dispose();

    final second = ProviderContainer();
    addTearDown(second.dispose);
    final state = await load(second);

    expect(state.library.map((a) => a.label), ['Wikibooks', 'Klexikon']);
    expect(state.title, 'Klexikon');
  });

  group('carrying over a single-archive setup', () {
    test('the stored archive becomes a library of one', () async {
      SharedPreferences.setMockInitialValues({
        'knowledgeArchiveLocation': '/somewhere/wikipedia_de_all_maxi.zim',
        'knowledgeArchiveLabel': 'Wikipedia',
      });

      final stored = await const ZimStore().library();

      expect(stored.archives, hasLength(1));
      expect(stored.archives.single.label, 'Wikipedia');
      expect(stored.selectedId, legacyArchiveId);

      // The old keys are gone, so removing every archive later does not
      // resurrect this one.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('knowledgeArchiveLocation'), isNull);
    });

    test('its index keeps the file name it already has on disk', () {
      // Rebuilding a full-text index over a whole encyclopedia is hours.
      expect(
        KnowledgeIndexDatabase.fileNameFor(legacyArchiveId),
        'preppsuite_knowledge',
      );
      expect(
        KnowledgeIndexDatabase.fileNameFor('a1b2c3'),
        'preppsuite_knowledge_a1b2c3',
      );
    });
  });
}

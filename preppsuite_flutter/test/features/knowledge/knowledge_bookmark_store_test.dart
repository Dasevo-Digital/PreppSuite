import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:preppsuite_flutter/features/knowledge/application/knowledge_bookmark_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('adds and removes an offline article bookmark', () async {
    const store = KnowledgeBookmarkStore();
    final bookmark = KnowledgeBookmark(
      archiveId: 'archive',
      entryUrl: 'water',
      title: 'Wasser',
      createdAt: DateTime(2026, 9, 17),
    );

    expect(await store.toggle(bookmark), isTrue);
    expect(await store.contains('archive', 'water'), isTrue);
    expect((await store.load()).single.title, 'Wasser');
    expect(await store.toggle(bookmark), isFalse);
    expect(await store.load(), isEmpty);
  });

  group('across devices', _acrossDevices);
}

/// Bookmarks travel with the household and into the backup, and the id
/// of an archive is drawn per device (#240).
void _acrossDevices() {
  const store = KnowledgeBookmarkStore();
  final setHere = KnowledgeBookmark(
    archiveId: '3f9a0c11d2e4b507',
    archiveName: 'wikipedia_de_all',
    entryUrl: 'Trinkwasser',
    title: 'Trinkwasser',
    createdAt: DateTime(2026, 10, 30),
  );

  test('a bookmark from another device opens in the same archive here', () {
    // The other device drew its own id for the same Wikipedia.
    expect(setHere.isIn('a01b2c3d4e5f6789', 'wikipedia_de_all'), isTrue);
    expect(setHere.isIn('a01b2c3d4e5f6789', 'wikipedia_en_all'), isFalse);
    // Until 2.7.9 only the id counted, and it never matched elsewhere.
    expect(setHere.isIn('a01b2c3d4e5f6789', null), isFalse);
  });

  test('the name decides even where two devices share an id', () {
    // Every device that moved up from a single archive calls it legacy.
    final legacy = KnowledgeBookmark(
      archiveId: 'legacy',
      archiveName: 'ifixit_de_all',
      entryUrl: 'A',
      title: 'A',
      createdAt: DateTime(2026, 10, 30),
    );

    expect(legacy.isIn('legacy', 'wikipedia_de_all'), isFalse);
    expect(legacy.isIn('legacy', null), isTrue);
  });

  test('marking the same article here does not mark it twice', () async {
    await store.toggle(setHere);

    expect(
      await store.contains(
        'a01b2c3d4e5f6789',
        'Trinkwasser',
        archiveName: 'wikipedia_de_all',
      ),
      isTrue,
    );
    // Tapping the filled bookmark here removes the one set there.
    final removed = await store.toggle(
      KnowledgeBookmark(
        archiveId: 'a01b2c3d4e5f6789',
        archiveName: 'wikipedia_de_all',
        entryUrl: 'Trinkwasser',
        title: 'Trinkwasser',
        createdAt: DateTime(2026, 10, 31),
      ),
    );
    expect(removed, isFalse);
    expect(await store.load(), isEmpty);
  });

  test(
    'an old bookmark is named when its own device opens the archive',
    () async {
      final old = KnowledgeBookmark(
        archiveId: '3f9a0c11d2e4b507',
        entryUrl: 'Notvorrat',
        title: 'Notvorrat',
        createdAt: DateTime(2026, 9, 17),
      );
      final other = KnowledgeBookmark(
        archiveId: 'ffffffffffffffff',
        entryUrl: 'Kurbelradio',
        title: 'Kurbelradio',
        createdAt: DateTime(2026, 9, 18),
      );
      await store.toggle(old);
      await store.toggle(other);

      await store.adoptArchiveName('3f9a0c11d2e4b507', 'wikipedia_de_all');

      final marks = {for (final mark in await store.load()) mark.title: mark};
      expect(marks['Notvorrat']!.archiveName, 'wikipedia_de_all');
      expect(marks['Kurbelradio']!.archiveName, isNull);
      expect(marks['Notvorrat']!.isIn('elsewhere', 'wikipedia_de_all'), isTrue);
    },
  );
}

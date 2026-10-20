import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_text.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The bookmark is asked of the native side, which needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keeps only a numeric local reading position', () async {
    const store = PersonalDocumentStore();
    final documents = await store.add(
      location: '/documents/handbook.md',
      label: 'Handbuch.md',
    );

    await store.updateReaderOffset(documents.single.id, 420);
    final restored = await store.load();

    expect(restored.single.readerOffset, 420);
    expect(restored.single.location, '/documents/handbook.md');
    expect(restored.single.label, 'Handbuch.md');
  });

  group('the fingerprint of what was indexed (#77)', () {
    test('is kept with the index and survives a reload', () async {
      const store = PersonalDocumentStore();
      final id = (await store.add(
        location: '/documents/plan.pdf',
        label: 'Plan.pdf',
      )).single.id;

      await store.updateIndex(id, status: 'ready', fingerprint: 'f1:abc');
      expect((await store.load()).single.sourceFingerprint, 'f1:abc');
    });

    test('an indexing run in progress keeps the previous one', () async {
      const store = PersonalDocumentStore();
      final id = (await store.add(
        location: '/documents/plan.pdf',
        label: 'Plan.pdf',
      )).single.id;
      await store.updateIndex(id, status: 'ready', fingerprint: 'f1:abc');

      await store.updateIndex(id, status: 'indexing');
      expect((await store.load()).single.sourceFingerprint, 'f1:abc');
    });

    test('clearing the index clears it too', () async {
      const store = PersonalDocumentStore();
      final id = (await store.add(
        location: '/documents/plan.pdf',
        label: 'Plan.pdf',
      )).single.id;
      await store.updateIndex(id, status: 'ready', fingerprint: 'f1:abc');

      await store.clearIndex();
      expect((await store.load()).single.sourceFingerprint, isNull);
    });
  });
  test('a document pointed somewhere new keeps all it was (#66)', () async {
    const store = PersonalDocumentStore();
    final id = (await store.add(
      location: 'bookmark://alt',
      label: 'Pilze.pdf',
    )).single.id;
    await store.updateIndex(
      id,
      status: 'ready',
      characters: 1200,
      fingerprint: 'f1:abc',
      recognized: true,
    );
    await store.updateReaderOffset(id, 42);

    await store.relocate(id, 'bookmark://neu');
    final moved = (await store.load()).single;

    expect(moved.id, id);
    expect(moved.location, 'bookmark://neu');
    expect(moved.label, 'Pilze.pdf');
    expect(moved.indexStatus, 'ready');
    expect(moved.indexedCharacters, 1200);
    expect(moved.sourceFingerprint, 'f1:abc');
    expect(moved.readerOffset, 42);
    // The note that the text was recognised, and may have gaps, stays.
    expect(moved.recognized, isTrue);
  });

  group('where a document can be read from (#66)', () {
    test('a bookmark that no longer opens on a Mac says so', () async {
      await expectLater(
        reachableDocumentLocation('bookmark://alt', bookmarks: true),
        throwsA(isA<PersonalDocumentUnreachable>()),
      );
    });

    test('elsewhere the handle goes to the native reader as it is', () async {
      expect(
        await reachableDocumentLocation('bookmark://alt', bookmarks: false),
        'bookmark://alt',
      );
    });

    test('a path is a path', () async {
      expect(
        await reachableDocumentLocation('/Scans/Pilze.pdf', bookmarks: true),
        '/Scans/Pilze.pdf',
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
}

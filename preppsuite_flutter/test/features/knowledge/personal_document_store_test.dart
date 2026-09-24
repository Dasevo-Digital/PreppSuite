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
}

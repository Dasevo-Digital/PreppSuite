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
}

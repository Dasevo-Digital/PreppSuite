import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/article_viewer_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'the window is the default, because it shows more of the article',
    () async {
      expect(
        await const ArticleViewerChoiceStore().load(),
        ArticleViewerChoice.systemWindow,
      );
    },
  );

  test('a choice is remembered', () async {
    const store = ArticleViewerChoiceStore();
    await store.save(ArticleViewerChoice.builtIn);

    expect(await store.load(), ArticleViewerChoice.builtIn);
  });

  test(
    'a value this version does not know falls back rather than throwing',
    () async {
      SharedPreferences.setMockInitialValues({
        'flutter.articleViewerChoice': 'holographic',
      });

      expect(
        await const ArticleViewerChoiceStore().load(),
        ArticleViewerChoice.systemWindow,
      );
    },
  );
}

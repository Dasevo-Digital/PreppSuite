import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/article_viewer.dart';

void main() {
  group('choosing how to show an article', () {
    test('the platforms with an embedded engine get a panel', () {
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ]) {
        expect(
          articleViewerFor(platform),
          ArticleViewer.panel,
          reason: '$platform',
        );
      }
    });

    test('the desktops without one get a window, not nothing', () {
      // `webview_flutter` has no Linux or Windows implementation. Before
      // this the article was where the feature stopped on both.
      expect(articleViewerFor(TargetPlatform.linux), ArticleViewer.window);
      expect(articleViewerFor(TargetPlatform.windows), ArticleViewer.window);
    });

    test('every platform is decided one way or the other', () {
      // The mapping is a switch over the whole enum rather than a default,
      // so a platform added to Flutter breaks the build here instead of
      // quietly reading as unsupported.
      for (final platform in TargetPlatform.values) {
        expect(() => articleViewerFor(platform), returnsNormally);
      }
    });
  });
}

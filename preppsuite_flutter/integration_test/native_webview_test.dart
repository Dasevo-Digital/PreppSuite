import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the native article engine renders local HTML and runs scripts', (
    tester,
  ) async {
    final loaded = Completer<void>();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!loaded.isCompleted) loaded.complete();
          },
        ),
      );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WebViewWidget(controller: controller)),
      ),
    );
    await controller.loadHtmlString('''
      <!doctype html><meta charset="utf-8">
      <p id="article">Offline-Wissen</p>
      <script>document.getElementById('article').textContent = 'Bereit';</script>
    ''');
    await loaded.future.timeout(const Duration(seconds: 30));
    final result = await controller.runJavaScriptReturningResult(
      "document.getElementById('article').textContent",
    );
    // Android can return a JSON-quoted string, iOS a plain string.
    expect(result.toString().replaceAll('"', ''), 'Bereit');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

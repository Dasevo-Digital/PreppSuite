import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// One article, rendered by the system's browser engine.
///
/// The page comes from the loopback server in front of the archive, so
/// every link, stylesheet and image inside it resolves against the same
/// origin and is answered from the same file. Following a link between
/// articles therefore needs no code here at all.
class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key, required this.title, required this.uri});

  final String title;
  final Uri uri;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      // The pages carry their own scripts. They are local files the user
      // downloaded, and the engine can reach nothing but the loopback
      // server that serves them.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(widget.uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}

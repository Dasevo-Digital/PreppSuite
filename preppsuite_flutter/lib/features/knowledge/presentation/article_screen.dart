import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/article_viewer.dart';

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
      // The pages carry their own scripts — real Wikipedia articles need
      // them for collapsible sections and maths. They are not trusted for
      // that: the reader opens whatever file the user selected, so an
      // archive could carry anything. What keeps it harmless is that it
      // cannot reach the network. The Content-Security-Policy the loopback
      // server sends does the actual work, and holds in the separate
      // window Linux and Windows use as well; the delegate below is the
      // second half, for the one thing a policy cannot express as
      // pleasantly — leaving the archive by following a link.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _decideNavigation),
      )
      ..loadRequest(widget.uri);
  }

  NavigationDecision _decideNavigation(NavigationRequest request) {
    if (isArchiveUrl(Uri.tryParse(request.url), widget.uri)) {
      return NavigationDecision.navigate;
    }
    // Silently refusing looks like a broken app. Say it, because the link
    // is not broken — it points somewhere this app deliberately does not
    // go, and the reader is offline anyway.
    _reportBlocked();
    return NavigationDecision.prevent;
  }

  void _reportBlocked() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.articleLinkLeavesArchive),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/article_viewer.dart';
import '../application/knowledge_bookmark_store.dart';

/// One article, rendered by the system's browser engine.
///
/// The page comes from the loopback server in front of the archive, so
/// every link, stylesheet and image inside it resolves against the same
/// origin and is answered from the same file. Following a link between
/// articles therefore needs no code here at all.
class ArticleScreen extends StatefulWidget {
  const ArticleScreen({
    super.key,
    required this.title,
    required this.uri,
    this.archiveId,
    this.entryUrl,
  });

  final String title;
  final Uri uri;

  /// Set only for a concrete archive entry; browser-internal links have no
  /// stable ZIM entry id to put in a reading list.
  final String? archiveId;
  final String? entryUrl;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final WebViewController _controller;

  /// The page currently on display, which is not always the one this
  /// screen was opened with.
  ///
  /// Links inside an archive navigate within the same web view, so the
  /// title bar used to keep naming the entry that was tapped three
  /// articles ago. In an iFixit archive that reads as a blank page
  /// labelled "iFixit in German" — which is exactly how a failed load
  /// looked too, with nothing to tell them apart.
  String? _pageTitle;

  bool _loading = true;
  bool _bookmarked = false;

  /// Why the page did not arrive, in the engine's own words.
  String? _failure;

  @override
  void initState() {
    super.initState();
    _restoreBookmark();
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
        NavigationDelegate(
          onNavigationRequest: _decideNavigation,
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _failure = null;
              });
            }
          },
          onPageFinished: (_) async {
            // The page's own <title>, which is better than the entry's:
            // the iFixit start page is entry "home/home" titled "iFixit
            // in German" and page-titled "iFixit: Das kostenlose
            // Reparaturhandbuch".
            final title = (await _controller.getTitle())?.trim();
            if (!mounted) return;
            setState(() {
              _loading = false;
              _pageTitle = title == null || title.isEmpty ? null : title;
            });
          },
          // Both of these used to go unreported, which is the whole
          // reason a page that failed showed as a blank white area with
          // a stale title and no way to tell what had happened.
          onWebResourceError: (error) {
            // Only the main document. A missing image inside a
            // thirty-gigabyte archive is not worth a full-screen error,
            // and real archives have plenty of them.
            if (error.isForMainFrame == false) return;
            if (mounted) {
              setState(() {
                _loading = false;
                _failure = error.description;
              });
            }
          },
          onHttpError: (error) {
            final status = error.response?.statusCode;
            if (mounted) {
              setState(() {
                _loading = false;
                _failure = status == null ? '' : '$status';
              });
            }
          },
          onUrlChange: (_) {
            // Cleared on the way out, so the bar never names the page
            // before last while the next one is still arriving.
            if (mounted) setState(() => _pageTitle = null);
          },
        ),
      )
      ..loadRequest(widget.uri);
  }

  Future<void> _restoreBookmark() async {
    final archiveId = widget.archiveId;
    final entryUrl = widget.entryUrl;
    if (archiveId == null || entryUrl == null) return;
    final saved = await const KnowledgeBookmarkStore().contains(
      archiveId,
      entryUrl,
    );
    if (mounted) setState(() => _bookmarked = saved);
  }

  Future<void> _toggleBookmark() async {
    final archiveId = widget.archiveId;
    final entryUrl = widget.entryUrl;
    if (archiveId == null || entryUrl == null) return;
    final saved = await const KnowledgeBookmarkStore().toggle(
      KnowledgeBookmark(
        archiveId: archiveId,
        entryUrl: entryUrl,
        title: widget.title,
        createdAt: DateTime.now(),
      ),
    );
    if (mounted) setState(() => _bookmarked = saved);
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle ?? widget.title),
        actions: [
          if (widget.archiveId != null && widget.entryUrl != null)
            IconButton(
              tooltip: _bookmarked
                  ? 'Lesezeichen entfernen'
                  : 'Lesezeichen setzen',
              icon: Icon(_bookmarked ? Icons.bookmark : Icons.bookmark_border),
              onPressed: _toggleBookmark,
            ),
        ],
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: _failure == null
          ? WebViewWidget(controller: _controller)
          : _Failure(
              detail: _failure!,
              l10n: l10n,
              onRetry: () {
                setState(() {
                  _failure = null;
                  _loading = true;
                });
                _controller.reload();
              },
            ),
    );
  }
}

/// A page that did not arrive, and what is known about why.
///
/// A blank web view is indistinguishable from an article with no content
/// in it, so this replaces the view entirely rather than sitting over it.
class _Failure extends StatelessWidget {
  const _Failure({
    required this.detail,
    required this.l10n,
    required this.onRetry,
  });

  /// The engine's description, or an HTTP status. Kept and shown: this is
  /// the app's own loopback server answering, so a status here means a
  /// named entry the archive would not give up, which is worth reporting
  /// rather than smoothing over.
  final String detail;

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = int.tryParse(detail);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.articleLoadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                status == null ? detail : l10n.articleHttpStatus('$status'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.articleReload),
            ),
          ],
        ),
      ),
    );
  }
}

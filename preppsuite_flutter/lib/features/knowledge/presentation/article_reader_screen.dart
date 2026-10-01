import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/article_document.dart';
import '../application/article_viewer.dart';

/// Reads an article without a browser engine.
///
/// The fallback for the two platforms whose engine is not part of the
/// system: Linux needs WebKitGTK and Windows the WebView2 runtime, and on
/// a machine without either — with no network to fetch one — the
/// encyclopedia used to be a search that found articles nobody could
/// read. That is exactly the situation this app is for, so it now draws
/// the article itself.
///
/// Deliberately less than a browser, and it says so at the top: no
/// scripts, no typeset formulas, no floated infoboxes. Text, headings,
/// lists, tables, links and pictures — which for a reference work is
/// nearly all of it. What it gains over a web view is that the app's own
/// text size and colours finally apply to the article as well.
/// The schemes a link out of an archive may be handed on with.
const externalLinkSchemes = {'http', 'https', 'mailto'};

class ArticleReaderScreen extends StatefulWidget {
  const ArticleReaderScreen({
    super.key,
    required this.title,
    required this.uri,
    this.client,
  });

  final String title;
  final Uri uri;

  /// Overridden in tests. The pages come from the loopback server in
  /// front of the open archive.
  final http.Client? client;

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  late final http.Client _client = widget.client ?? http.Client();
  final _scroll = ScrollController();

  ArticleDocument? _document;
  String? _failure;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    if (widget.client == null) _client.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await _client.get(widget.uri);
      if (response.statusCode != 200) {
        throw http.ClientException('${response.statusCode}', widget.uri);
      }
      // `bodyBytes` decoded as UTF-8 and never `response.body`: without a
      // charset in the header the latter decodes as Latin-1, and a ZIM
      // article is UTF-8 throughout. That is the trap that turned
      // "français" into "franÃ§ais" in the catalogue.
      final document = parseArticle(
        utf8.decode(response.bodyBytes, allowMalformed: true),
        baseUrl: widget.uri,
      );
      if (!mounted) return;
      setState(() {
        _document = document;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = '$error';
        _loading = false;
      });
    }
  }

  /// Follows a link inside the archive, and refuses one that leaves it.
  ///
  /// The same rule the web view enforces: an archive is a file the user
  /// picked and may contain anything, so a link out of it is offered to
  /// the system browser rather than followed here.
  Future<void> _follow(String href) async {
    final target = Uri.tryParse(href);
    final l10n = AppLocalizations.of(context)!;
    if (target == null) return;

    if (!isArchiveUrl(target, widget.uri)) {
      // Only what a browser or a mail program is for. The address comes
      // out of an archive somebody else made, and the system would hand
      // `file:`, `smb:` or another app's own scheme to whatever claims
      // it — a local file opened, an app started with chosen arguments.
      final opened =
          externalLinkSchemes.contains(target.scheme.toLowerCase()) &&
          await launchUrl(target, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.articleReaderExternal)),
        );
      }
      return;
    }

    // A fragment on this very page is a jump, not a new article. There is
    // nothing to scroll to without measuring every block, so it is left
    // alone rather than opening the same page again on top of itself.
    if (target.removeFragment() == widget.uri.removeFragment()) return;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ArticleReaderScreen(
          title: _titleFrom(target),
          uri: target,
          client: widget.client,
        ),
      ),
    );
  }

  /// The last part of the address, which is what a ZIM entry is named
  /// after — a decent title until the page has been read.
  static String _titleFrom(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty);
    if (segments.isEmpty) return '';
    return Uri.decodeComponent(segments.last).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final document = _document;

    return Scaffold(
      appBar: AppBar(
        title: Text(document?.title ?? widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.articleReaderSimple,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failure != null
          ? _Message(text: l10n.articleReaderFailed, detail: _failure)
          : document == null || document.isEmpty
          ? _Message(text: l10n.articleReaderEmpty)
          : _article(l10n, document),
    );
  }

  Widget _article(AppLocalizations l10n, ArticleDocument document) {
    return Scrollbar(
      controller: _scroll,
      // Selection across the whole article rather than per block: a
      // figure worth copying is rarely inside one paragraph, and
      // `SelectableText` would also swallow the taps that follow links.
      child: SelectionArea(
        child: ListView.builder(
          controller: _scroll,
          // Built as it scrolls: "Deutschland" is a thousand blocks, and
          // building all of them to show twenty is the same mistake the
          // shopping list made.
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          itemCount: document.blocks.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.articleReaderWhy,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return ArticleBlockView(
              block: document.blocks[index - 1],
              onFollow: _follow,
              imageMissing: l10n.articleReaderImageMissing,
            );
          },
        ),
      ),
    );
  }
}

/// One block, drawn.
///
/// Public so the drawing can be tested a block at a time rather than
/// through a whole screen and a server.
class ArticleBlockView extends StatelessWidget {
  const ArticleBlockView({
    super.key,
    required this.block,
    required this.onFollow,
    required this.imageMissing,
  });

  final ArticleBlock block;
  final Future<void> Function(String href) onFollow;
  final String imageMissing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (block) {
      ArticleHeading(:final level, :final text) => Padding(
        padding: EdgeInsets.only(top: level <= 2 ? 24 : 16, bottom: 6),
        child: _text(
          context,
          text,
          switch (level) {
            1 => theme.textTheme.headlineSmall,
            2 => theme.textTheme.titleLarge,
            3 => theme.textTheme.titleMedium,
            _ => theme.textTheme.titleSmall,
          },
        ),
      ),

      ArticleParagraph(:final text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _text(context, text, theme.textTheme.bodyMedium),
      ),

      ArticleListEntry(:final text, :final depth, :final marker) => Padding(
        padding: EdgeInsets.only(left: 12.0 * depth, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(marker, style: theme.textTheme.bodyMedium),
            ),
            Expanded(child: _text(context, text, theme.textTheme.bodyMedium)),
          ],
        ),
      ),

      ArticleQuote(:final text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 3,
              ),
            ),
          ),
          child: _text(context, text, theme.textTheme.bodyMedium),
        ),
      ),

      ArticleCode(:final text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.all(8),
          // Code lines are as wide as they were written; wrapping them
          // changes what they say.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),

      ArticleImage(:final source, :final caption, :final alt) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: alt,
              image: true,
              child: Image.network(
                source,
                fit: BoxFit.contain,
                // A no-picture archive still carries the markup, so a
                // picture that is not there is ordinary rather than an
                // error — and it must not take the article with it.
                errorBuilder: (context, _, _) => Text(
                  alt ?? imageMissing,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 4),
              Text(caption, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),

      ArticleTable(:final rows, :final headerRows) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
            children: [
              for (var row = 0; row < rows.length; row++)
                TableRow(
                  decoration: row < headerRows
                      ? BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                        )
                      : null,
                  children: [
                    for (final cell in _padded(rows, row))
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: _text(
                          context,
                          cell,
                          row < headerRows
                              ? theme.textTheme.labelLarge
                              : theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),

      ArticleRule() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1),
      ),
    };
  }

  /// Every row padded to the widest, because `Table` refuses rows of
  /// differing length and a real article has plenty of them — a cell
  /// spanning two columns leaves its row one short.
  static List<ArticleText> _padded(List<List<ArticleText>> rows, int index) {
    final width = rows.fold<int>(
      0,
      (most, row) => row.length > most ? row.length : most,
    );
    final row = rows[index];
    return [
      ...row,
      for (var i = row.length; i < width; i++) ArticleText.empty,
    ];
  }

  /// A recognizer for one link, kept in [into] so it can be let go of.
  TapGestureRecognizer _tap(List<TapGestureRecognizer> into, String href) {
    final recognizer = TapGestureRecognizer()..onTap = () => onFollow(href);
    into.add(recognizer);
    return recognizer;
  }

  Widget _text(BuildContext context, ArticleText text, TextStyle? base) {
    final theme = Theme.of(context);
    final recognizers = <TapGestureRecognizer>[];

    final spans = <InlineSpan>[
      for (final span in text.spans)
        TextSpan(
          text: span.text,
          style: (base ?? const TextStyle()).copyWith(
            fontWeight: span.bold ? FontWeight.bold : null,
            fontStyle: span.italic ? FontStyle.italic : null,
            fontFamily: span.code ? 'monospace' : null,
            fontSize: span.superscript || span.subscript
                ? (base?.fontSize ?? 14) * 0.75
                : null,
            color: span.link != null ? theme.colorScheme.primary : null,
            decoration: span.link != null ? TextDecoration.underline : null,
          ),
          recognizer: span.link == null ? null : _tap(recognizers, span.link!),
        ),
    ];

    return _SelfDisposingText(spans: spans, recognizers: recognizers);
  }
}

/// A rich text that lets go of its tap recognizers.
///
/// `TapGestureRecognizer` holds native resources and leaks if it is never
/// disposed. One per link and a thousand blocks per article is exactly
/// the scale at which that stops being theoretical.
class _SelfDisposingText extends StatefulWidget {
  const _SelfDisposingText({required this.spans, required this.recognizers});

  final List<InlineSpan> spans;
  final List<TapGestureRecognizer> recognizers;

  @override
  State<_SelfDisposingText> createState() => _SelfDisposingTextState();
}

class _SelfDisposingTextState extends State<_SelfDisposingText> {
  @override
  void dispose() {
    for (final recognizer in widget.recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(children: widget.spans));
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: Theme.of(context).textTheme.titleMedium),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(detail!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}

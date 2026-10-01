import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

/// An article reduced to what can be drawn without a browser engine.
///
/// The app opens articles in the system's own web view wherever there is
/// one. On Linux that is WebKitGTK and on Windows the WebView2 runtime,
/// and neither ships with the app — on a machine that has not got them,
/// and no network to fetch them with, the encyclopedia used to be a
/// search that found articles nobody could read. That is precisely the
/// situation this app exists for.
///
/// So the article is parsed into blocks and spans here, and drawn with
/// ordinary Flutter widgets. It is less than a browser and says so:
/// no scripts, no layout, no formulas typeset. It is the text, the
/// headings, the lists, the links and the pictures — which for a
/// reference work is nearly all of it.
///
/// Parsing is the Dart team's `html` package rather than something
/// hand-rolled: real-world markup is full of unclosed tags and a
/// forgiving parser is a large thing to get right. The drawing is ours,
/// because that is the part that has to match this app.
class ArticleDocument {
  const ArticleDocument({required this.title, required this.blocks});

  /// The article's own `<title>`, where it has one.
  final String? title;

  final List<ArticleBlock> blocks;

  bool get isEmpty => blocks.isEmpty;
}

/// One thing standing on its own line.
sealed class ArticleBlock {
  const ArticleBlock();
}

class ArticleHeading extends ArticleBlock {
  const ArticleHeading({required this.level, required this.text});

  /// 1 to 6, as in the markup.
  final int level;
  final ArticleText text;
}

class ArticleParagraph extends ArticleBlock {
  const ArticleParagraph(this.text);

  final ArticleText text;
}

class ArticleListEntry extends ArticleBlock {
  const ArticleListEntry({
    required this.text,
    required this.depth,
    required this.marker,
  });

  final ArticleText text;

  /// How deeply nested, from zero. Lists inside lists are ordinary in a
  /// reference work and flattening them loses the argument.
  final int depth;

  /// The bullet or the number, worked out while parsing so that the
  /// drawing has nothing to count.
  final String marker;
}

class ArticleQuote extends ArticleBlock {
  const ArticleQuote(this.text);

  final ArticleText text;
}

/// Preformatted text, kept exactly as it stands.
class ArticleCode extends ArticleBlock {
  const ArticleCode(this.text);

  final String text;
}

class ArticleImage extends ArticleBlock {
  const ArticleImage({required this.source, this.caption, this.alt});

  /// Resolved against the article's own address, so the loopback server
  /// in front of the archive can answer it.
  final String source;

  final String? caption;
  final String? alt;
}

/// A table, as rows of cells.
///
/// Wikipedia's infoboxes are tables, and so is every list of figures
/// worth having. Drawn plainly rather than laid out — a browser would
/// float the infobox to the right, and this will not.
class ArticleTable extends ArticleBlock {
  const ArticleTable({required this.rows, required this.headerRows});

  final List<List<ArticleText>> rows;

  /// How many rows at the top are headings.
  final int headerRows;
}

class ArticleRule extends ArticleBlock {
  const ArticleRule();
}

/// A run of text with its formatting.
class ArticleText {
  const ArticleText(this.spans);

  static const empty = ArticleText([]);

  final List<ArticleSpan> spans;

  bool get isEmpty => spans.every((span) => span.text.trim().isEmpty);

  /// The words alone, for a test or a search.
  String get plain => spans.map((span) => span.text).join();
}

class ArticleSpan {
  const ArticleSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.superscript = false,
    this.subscript = false,
    this.link,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;
  final bool superscript;
  final bool subscript;

  /// Where a tap goes, resolved against the article's own address. Null
  /// where this run is not a link.
  final String? link;

  ArticleSpan withText(String replacement) => ArticleSpan(
    replacement,
    bold: bold,
    italic: italic,
    code: code,
    superscript: superscript,
    subscript: subscript,
    link: link,
  );
}

/// Elements whose content is not the article.
///
/// Scripts and styles are obvious. The rest is MediaWiki's own furniture:
/// the edit pencils beside every heading, the navigation boxes at the
/// foot, and the "jump to" links a screen reader is meant to use. None of
/// it means anything without the site around it.
const _skippedTags = {'script', 'style', 'link', 'meta', 'noscript'};
const _skippedClasses = {
  'mw-editsection',
  'navbox',
  'noprint',
  'mw-jump-link',
  'mw-empty-elt',
};

/// Turns [source] into a document.
///
/// [baseUrl] is the article's own address; every link and image is
/// resolved against it, which is what makes a relative `../I/picture.png`
/// answerable by the loopback server in front of the archive.
ArticleDocument parseArticle(String source, {Uri? baseUrl}) {
  final document = html.parse(source);
  final body = document.body;
  if (body == null) {
    return const ArticleDocument(title: null, blocks: []);
  }

  final builder = _Builder(baseUrl);
  builder.visitChildren(body);
  builder.flush();

  final title = document.head?.querySelector('title')?.text.trim();

  return ArticleDocument(
    title: title == null || title.isEmpty ? null : title,
    blocks: List.unmodifiable(builder.blocks),
  );
}

/// Walks the tree once, collecting blocks and gathering inline runs as it
/// goes.
class _Builder {
  _Builder(this.baseUrl);

  final Uri? baseUrl;
  final blocks = <ArticleBlock>[];

  /// Inline text seen since the last block was closed.
  final _pending = <ArticleSpan>[];

  /// The list nesting, one entry per open list: whether it is numbered
  /// and how many items it has had.
  final _lists = <({bool ordered, int count})>[];

  /// Set while inside a list item that has not been closed yet, so that
  /// whatever closes it produces an entry rather than a paragraph.
  ///
  /// Needed because a list item may contain a nested list, and the text
  /// before that nested list has to come out as the outer item. Without
  /// this it came out as an ordinary paragraph and lost its bullet — the
  /// outline of an article is most of what makes it readable.
  ({int depth, String marker})? _openEntry;

  void visitChildren(dom.Node node) {
    for (final child in node.nodes) {
      visit(child);
    }
  }

  void visit(dom.Node node, {_Style style = const _Style()}) {
    if (node is dom.Text) {
      _addText(node.data, style);
      return;
    }
    if (node is! dom.Element) return;

    final tag = node.localName?.toLowerCase() ?? '';
    if (_skippedTags.contains(tag) || _isFurniture(node)) return;

    switch (tag) {
      case 'br':
        _addText('\n', style);

      case 'hr':
        flush();
        blocks.add(const ArticleRule());

      case 'p' ||
          'div' ||
          'section' ||
          'article' ||
          'main' ||
          'header' ||
          'footer' ||
          'aside' ||
          'dd' ||
          'dt' ||
          'dl' ||
          'address':
        flush();
        for (final child in node.nodes) {
          visit(child, style: style);
        }
        flush();

      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        flush();
        final level = int.parse(tag.substring(1));
        for (final child in node.nodes) {
          visit(child, style: style);
        }
        final text = _take();
        if (!text.isEmpty) {
          blocks.add(ArticleHeading(level: level, text: text));
        }

      case 'ul' || 'ol':
        flush();
        _lists.add((ordered: tag == 'ol', count: 0));
        for (final child in node.nodes) {
          visit(child, style: style);
        }
        _lists.removeLast();

      case 'li':
        flush();
        final outer = _openEntry;
        final depth = _lists.length - 1;
        _openEntry = (
          depth: depth < 0 ? 0 : depth,
          marker: _nextMarker(),
        );
        for (final child in node.nodes) {
          visit(child, style: style);
        }
        flush();
        _openEntry = outer;

      case 'blockquote':
        flush();
        for (final child in node.nodes) {
          visit(child, style: style);
        }
        final text = _take();
        if (!text.isEmpty) blocks.add(ArticleQuote(text));

      case 'pre':
        flush();
        final text = node.text;
        if (text.trim().isNotEmpty) blocks.add(ArticleCode(text));

      case 'img':
        _addImage(node);

      case 'figure':
        flush();
        _addFigure(node, style);

      case 'table':
        flush();
        _addTable(node, style);

      case 'a':
        final href = node.attributes['href'];
        for (final child in node.nodes) {
          visit(
            child,
            style: style.copyWith(link: _resolve(href) ?? style.link),
          );
        }

      case 'b' || 'strong':
        _descend(node, style.copyWith(bold: true));

      case 'i' || 'em' || 'cite' || 'var' || 'dfn':
        _descend(node, style.copyWith(italic: true));

      case 'code' || 'kbd' || 'samp' || 'tt':
        _descend(node, style.copyWith(code: true));

      case 'sup':
        _descend(node, style.copyWith(superscript: true));

      case 'sub':
        _descend(node, style.copyWith(subscript: true));

      default:
        _descend(node, style);
    }
  }

  void _descend(dom.Element node, _Style style) {
    for (final child in node.nodes) {
      visit(child, style: style);
    }
  }

  /// Whether this element is MediaWiki's furniture rather than the
  /// article.
  bool _isFurniture(dom.Element node) {
    final classes = node.className.split(RegExp(r'\s+'));
    return classes.any(_skippedClasses.contains);
  }

  void _addText(String text, _Style style) {
    // Collapsed the way a browser collapses it: the markup is indented
    // for people reading the source, and every one of those newlines
    // would otherwise become a space in the middle of a sentence.
    final collapsed = text
        .replaceAll(RegExp(r'[ \t\r\f]*\n[ \t\r\f]*'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ');
    if (collapsed.isEmpty) return;
    _pending.add(style.span(collapsed));
  }

  void _addImage(dom.Element node) {
    final source = _resolveImage(node.attributes['src']);
    if (source == null) return;
    flush();
    blocks.add(
      ArticleImage(source: source, alt: _trimmed(node.attributes['alt'])),
    );
  }

  void _addFigure(dom.Element node, _Style style) {
    final image = node.querySelector('img');
    final source = _resolveImage(image?.attributes['src']);
    final caption = _trimmed(node.querySelector('figcaption')?.text);

    if (source == null) {
      // A figure without a picture is still worth its caption — in a
      // no-picture archive that is all there is, and dropping it would
      // lose the one sentence explaining what is missing.
      if (caption != null) blocks.add(ArticleParagraph(_plain(caption, style)));
      return;
    }
    blocks.add(
      ArticleImage(
        source: source,
        caption: caption,
        alt: _trimmed(image?.attributes['alt']),
      ),
    );
  }

  void _addTable(dom.Element node, _Style style) {
    final rows = <List<ArticleText>>[];
    var headerRows = 0;
    var stillHeading = true;

    for (final row in node.querySelectorAll('tr')) {
      final cells = <ArticleText>[];
      var allHeadings = true;

      for (final cell in row.children) {
        final tag = cell.localName?.toLowerCase();
        if (tag != 'td' && tag != 'th') continue;
        if (tag != 'th') allHeadings = false;

        final nested = _Builder(baseUrl);
        for (final child in cell.nodes) {
          nested.visit(child, style: style);
        }
        cells.add(nested._take());
      }

      if (cells.isEmpty) continue;
      if (stillHeading && allHeadings) {
        headerRows++;
      } else {
        stillHeading = false;
      }
      rows.add(cells);
    }

    if (rows.isEmpty) return;
    blocks.add(ArticleTable(rows: rows, headerRows: headerRows));
  }

  String _nextMarker() {
    if (_lists.isEmpty) return '•';
    final open = _lists.removeLast();
    final next = open.count + 1;
    _lists.add((ordered: open.ordered, count: next));
    return open.ordered ? '$next.' : '•';
  }

  /// Closes whatever inline text is pending.
  ///
  /// As a list entry while one is open, and as a paragraph otherwise.
  /// The entry is closed with it: text that follows a nested list inside
  /// the same item is a paragraph, which is both rare and right.
  void flush() {
    final text = _take();
    if (text.isEmpty) return;

    final open = _openEntry;
    if (open == null) {
      blocks.add(ArticleParagraph(text));
      return;
    }
    blocks.add(
      ArticleListEntry(text: text, depth: open.depth, marker: open.marker),
    );
    _openEntry = null;
  }

  ArticleText _take() {
    final spans = _tidy(_pending);
    _pending.clear();
    return ArticleText(List.unmodifiable(spans));
  }

  ArticleText _plain(String text, _Style style) =>
      ArticleText([style.span(text)]);

  /// A picture's address, or null for one that is not in the archive.
  ///
  /// A link is only followed when somebody taps it, and the reader asks
  /// first before leaving; a picture is fetched the moment the page is
  /// drawn. An `<img src="https://…">` in an archive therefore told
  /// whoever served it the reader's address and when the article was
  /// opened — and `//upload.wikimedia.org`, which resolves against the
  /// loopback server's `http:`, did so in the clear. The web view's
  /// content policy stops that; this reader has none, so it is stopped
  /// here, and a figure keeps its caption as it would without a picture.
  String? _resolveImage(String? src) {
    final resolved = _resolve(src);
    if (resolved == null) return null;
    final target = Uri.tryParse(resolved);
    if (target == null) return null;
    final base = baseUrl;
    if (base == null) {
      return target.hasScheme || resolved.startsWith('//') ? null : resolved;
    }
    final inArchive =
        target.scheme == base.scheme &&
        target.host == base.host &&
        target.port == base.port;
    return inArchive ? resolved : null;
  }

  String? _resolve(String? href) {
    final trimmed = _trimmed(href);
    if (trimmed == null) return null;
    final base = baseUrl;
    if (base == null) return trimmed;
    try {
      return base.resolve(trimmed).toString();
    } on FormatException {
      return trimmed;
    }
  }
}

/// Trims the runs and drops the empty ones.
///
/// Done once at the end rather than while collecting, because the spaces
/// between two runs are only meaningless at the edges of a block —
/// "the <b>very</b> best" needs both of them.
List<ArticleSpan> _tidy(List<ArticleSpan> spans) {
  final out = [...spans];

  while (out.isNotEmpty) {
    final first = out.first.text.trimLeft();
    if (first.isEmpty) {
      out.removeAt(0);
      continue;
    }
    out[0] = out.first.withText(first);
    break;
  }
  while (out.isNotEmpty) {
    final last = out.last.text.trimRight();
    if (last.isEmpty) {
      out.removeLast();
      continue;
    }
    out[out.length - 1] = out.last.withText(last);
    break;
  }
  return out;
}

String? _trimmed(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// The formatting in force while walking down the tree.
class _Style {
  const _Style({
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.superscript = false,
    this.subscript = false,
    this.link,
  });

  final bool bold;
  final bool italic;
  final bool code;
  final bool superscript;
  final bool subscript;
  final String? link;

  _Style copyWith({
    bool? bold,
    bool? italic,
    bool? code,
    bool? superscript,
    bool? subscript,
    String? link,
  }) => _Style(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    code: code ?? this.code,
    superscript: superscript ?? this.superscript,
    subscript: subscript ?? this.subscript,
    link: link ?? this.link,
  );

  ArticleSpan span(String text) => ArticleSpan(
    text,
    bold: bold,
    italic: italic,
    code: code,
    superscript: superscript,
    subscript: subscript,
    link: link,
  );
}

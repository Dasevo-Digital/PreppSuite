/// Reduces an article's HTML to the words worth indexing.
///
/// Not a parser and not trying to be one. The index only needs terms, so
/// tags, attributes and anything inside a script or a style block are
/// dropped wholesale — what a real parser would buy here is nothing the
/// search would notice.
String htmlToIndexableText(String html) {
  final out = StringBuffer();

  var at = 0;
  var pendingSpace = false;

  while (at < html.length) {
    final tagStart = html.indexOf('<', at);
    if (tagStart < 0) {
      _appendText(out, html.substring(at), pendingSpace: pendingSpace);
      break;
    }

    if (tagStart > at) {
      _appendText(
        out,
        html.substring(at, tagStart),
        pendingSpace: pendingSpace,
      );
      pendingSpace = false;
    }

    final skipTo = _skipTag(html, tagStart);
    if (skipTo == null) break;

    // A tag boundary is a word boundary: "<b>Trink</b>wasser" must not
    // become one term, and "<p>a</p><p>b</p>" must not become "ab".
    pendingSpace = true;
    at = skipTo;
  }

  return out.toString().trim();
}

/// The offset just past the tag beginning at [start], skipping the whole
/// element for script and style.
///
/// Compares in place, letter by letter. It used to lower-case the whole
/// document to look at one tag -- once per tag, so an article with 1,500
/// tags was copied 1,500 times. Indexing a Wikipedia article took most
/// of a second, 98 % of it here, and the whole encyclopedia would have
/// taken weeks (#198).
int? _skipTag(String html, int start) {
  for (final element in const ['<script', '<style']) {
    if (_hasAt(html, element, start)) {
      final closing = _indexOfTag(html, '</${element.substring(1)}', start);
      if (closing < 0) return null;
      final end = html.indexOf('>', closing);
      return end < 0 ? null : end + 1;
    }
  }

  final end = html.indexOf('>', start);
  return end < 0 ? null : end + 1;
}

/// Whether [html] holds [tag], written in lower-case ASCII, at [at] in
/// any case.
bool _hasAt(String html, String tag, int at) {
  if (at + tag.length > html.length) return false;
  for (var i = 0; i < tag.length; i++) {
    var unit = html.codeUnitAt(at + i);
    if (unit >= 0x41 && unit <= 0x5A) unit |= 0x20;
    if (unit != tag.codeUnitAt(i)) return false;
  }
  return true;
}

/// The first offset from [from] on where [tag] starts, in any case, or -1.
int _indexOfTag(String html, String tag, int from) {
  for (
    var at = html.indexOf('<', from);
    at >= 0;
    at = html.indexOf('<', at + 1)
  ) {
    if (_hasAt(html, tag, at)) return at;
  }
  return -1;
}

final _whitespace = RegExp(r'\s+');
final _decimalReference = RegExp(r'&#(\d+);');
final _hexReference = RegExp(r'&#[xX]([0-9a-fA-F]+);');

void _appendText(StringBuffer out, String raw, {required bool pendingSpace}) {
  final text = _decodeEntities(raw).replaceAll(_whitespace, ' ');
  if (text.trim().isEmpty) return;

  if (out.isNotEmpty && (pendingSpace || text.startsWith(' '))) {
    out.write(' ');
  }
  out.write(text.trim());
}

/// The handful of entities that actually occur in article text.
///
/// Numeric references are decoded because German articles are full of
/// them; the rest of the named ones would only ever add noise terms.
String _decodeEntities(String text) {
  if (!text.contains('&')) return text;

  return text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAllMapped(_decimalReference, (match) {
        final code = int.tryParse(match[1]!);
        return code == null ? match[0]! : String.fromCharCode(code);
      })
      .replaceAllMapped(_hexReference, (match) {
        final code = int.tryParse(match[1]!, radix: 16);
        return code == null ? match[0]! : String.fromCharCode(code);
      });
}

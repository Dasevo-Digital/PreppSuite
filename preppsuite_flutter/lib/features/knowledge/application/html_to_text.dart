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
int? _skipTag(String html, int start) {
  final lower = html.toLowerCase();

  for (final element in ['script', 'style']) {
    if (lower.startsWith('<$element', start)) {
      final closing = lower.indexOf('</$element', start);
      if (closing < 0) return null;
      final end = html.indexOf('>', closing);
      return end < 0 ? null : end + 1;
    }
  }

  final end = html.indexOf('>', start);
  return end < 0 ? null : end + 1;
}

void _appendText(StringBuffer out, String raw, {required bool pendingSpace}) {
  final text = _decodeEntities(raw).replaceAll(RegExp(r'\s+'), ' ');
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
      .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
        final code = int.tryParse(match[1]!);
        return code == null ? match[0]! : String.fromCharCode(code);
      })
      .replaceAllMapped(RegExp(r'&#[xX]([0-9a-fA-F]+);'), (match) {
        final code = int.tryParse(match[1]!, radix: 16);
        return code == null ? match[0]! : String.fromCharCode(code);
      });
}

/// CAP text from warnung.bund.de as the screen has to show it.
///
/// The MoWaS payloads carry their line breaks as HTML and their quotation
/// marks as entities: the all-clear for a bomb disposal in Braunschweig
/// read `…gesendet durch Feuerwehr Braunschweig.<br/><br/>Die Weltkriegsbombe…`
/// with `&quot;` around the warning's name, and the app draws text, not
/// HTML, so that is what stood on the screen. Checked against the live
/// feed on 2026-10-17: every MoWaS detail had it, DWD and LHP had none.
///
/// Only the tags that turn up in that text are taken out, by name. A
/// blanket `<…>` would also eat a water level written as "< 3 m" by a
/// source that does not encode it -- and a warning that silently loses
/// words is worse than one with a stray tag.
library;

final _lineBreak = RegExp(r'<br\s*/?>', caseSensitive: false);
final _paragraphEnd = RegExp(r'</(?:p|div)\s*>', caseSensitive: false);
final _listItem = RegExp(r'<li\b[^>]*>', caseSensitive: false);
final _otherTags = RegExp(
  r'</?(?:p|div|span|b|i|u|em|strong|font|ul|ol|li|a)\b[^>]*>',
  caseSensitive: false,
);
final _entity = RegExp(r'&(#\d+|#[xX][0-9a-fA-F]+|[a-zA-Z]+);');

const _named = {
  'quot': '"',
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'apos': "'",
  'nbsp': ' ',
  'auml': 'ä',
  'ouml': 'ö',
  'uuml': 'ü',
  'Auml': 'Ä',
  'Ouml': 'Ö',
  'Uuml': 'Ü',
  'szlig': 'ß',
  'euro': '€',
  'deg': '°',
  'ndash': '–',
  'mdash': '—',
  'hellip': '…',
  'bdquo': '„',
  'ldquo': '“',
  'rdquo': '”',
  'laquo': '«',
  'raquo': '»',
};

/// [value] as plain text, or null when nothing readable is left.
///
/// Entities are decoded in one pass, so `&amp;lt;` stays the four
/// characters `&lt;` that the source meant, and one it does not know is
/// left as written rather than dropped.
String? capPlainText(Object? value) {
  if (value is! String) return null;
  final stripped = value
      .replaceAll('\r\n', '\n')
      .replaceAll(_lineBreak, '\n')
      .replaceAll(_listItem, '\n• ')
      .replaceAll(_paragraphEnd, '\n')
      .replaceAll(_otherTags, '');
  final decoded = stripped.replaceAllMapped(_entity, (match) {
    final name = match.group(1)!;
    if (name.startsWith('#')) {
      final hex = name.length > 1 && (name[1] == 'x' || name[1] == 'X');
      final code = int.tryParse(
        hex ? name.substring(2) : name.substring(1),
        radix: hex ? 16 : 10,
      );
      if (code == null || code <= 0 || code > 0x10FFFF) return match[0]!;
      return String.fromCharCode(code);
    }
    return _named[name] ?? match[0]!;
  });
  final lines = [
    for (final line in decoded.split('\n'))
      line.replaceAll(RegExp(r'[ \t ]+'), ' ').trim(),
  ];
  // At most one blank line in a row: `<br/><br/>` is a paragraph, and
  // three of them are still one.
  final text = lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return text.isEmpty ? null : text;
}

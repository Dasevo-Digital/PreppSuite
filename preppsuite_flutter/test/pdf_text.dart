import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:typed_data';

/// Everything printed on a PDF, as one searchable string.
///
/// Reports are read back out of the finished document rather than
/// trusted: what an export puts on a sheet of paper cannot be taken back,
/// and some of these sheets name blood group, allergies and medication. A
/// field that leaks onto the page when nobody asked for it is not a
/// cosmetic bug.
///
/// The content streams are Flate-compressed in the real output, so they
/// are inflated here rather than the compression being switched off for
/// the test — the point is to read what actually leaves the app.
///
/// PDF splits a line into several literals for kerning, so 'Familie
/// Muster' arrives as two. They are joined back with spaces, which is
/// close enough to ask whether a value reached the paper.
String textIn(Uint8List pdf) {
  final raw = latin1.decode(pdf, allowInvalid: true);
  final parts = <String>[];

  for (final match in RegExp(r'stream\r?\n').allMatches(raw)) {
    final end = raw.indexOf('endstream', match.end);
    if (end < 0) continue;
    final List<int> inflated;
    try {
      inflated = ZLibCodec().decode(pdf.sublist(match.end, end));
    } on Object {
      continue;
    }
    final text = latin1.decode(inflated, allowInvalid: true);
    for (final literal in RegExp(r'\(([^()]*)\)').allMatches(text)) {
      parts.add(literal.group(1)!);
    }
  }
  return parts.join(' ');
}

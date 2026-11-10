/// Pieces the printed sheets share, built so that nothing on them can be
/// too long for a page (#351).
///
/// `pw.Bullet` cannot be split. A medication list pasted in from a plan or
/// a page of notes was taller than a sheet, and the whole document failed
/// with "Widget won't fit into the page": no crisis plan and no emergency
/// folder at all, for having written too much into one of them.
library;

import 'dart:math' as math;

import 'package:pdf/widgets.dart' as pw;

/// One bulleted line that runs on to the next page where it has to.
pw.Widget pdfLine(String text, {pw.TextStyle? style}) => pw.Padding(
  padding: const pw.EdgeInsets.only(left: 12, bottom: 5),
  child: pw.Text('•  $text', style: style, overflow: pw.TextOverflow.span),
);

/// About how many lines [text] takes on an A4 page at the sheets' size.
int pdfEstimatedLines(String text) => text
    .split('\n')
    .fold(0, (lines, line) => lines + math.max(1, (line.length / 90).ceil()));

/// What a card may take and still be kept on one page.
const pdfCardLinesTogether = 30;

/// A person's card: the name and what is filled in.
///
/// On one page where it fits, so that what is printed about a person stays
/// under their name: a card split across pages left medication at the top
/// of the next one with no name above it (#351). A card longer than that
/// runs on, and every line carries the name, so a page that begins halfway
/// through it still says whose it is.
List<pw.Widget> pdfCard(
  String name,
  List<({String label, String value})> rows,
) {
  final heading = pw.Text(
    name,
    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
  );
  final lines = rows.fold(
    1,
    (sum, row) => sum + pdfEstimatedLines('${row.label}: ${row.value}'),
  );
  if (lines <= pdfCardLinesTogether) {
    return [
      pw.Inseparable(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            heading,
            for (final row in rows) pdfLine('${row.label}: ${row.value}'),
          ],
        ),
      ),
      pw.SizedBox(height: 10),
    ];
  }
  return [
    heading,
    for (final row in rows) pdfLine('${row.label} ($name): ${row.value}'),
    pw.SizedBox(height: 10),
  ];
}

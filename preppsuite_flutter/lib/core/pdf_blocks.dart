/// Pieces the printed sheets share, built so that nothing on them can be
/// too long for a page (#351).
///
/// `pw.Bullet` cannot be split. A medication list pasted in from a plan or
/// a page of notes was taller than a sheet, and the whole document failed
/// with "Widget won't fit into the page": no crisis plan and no emergency
/// folder at all, for having written too much into one of them.
library;

import 'dart:math' as math;

import 'package:pdf/pdf.dart' show PdfException;
import 'package:pdf/widgets.dart' as pw;

/// One bulleted line that runs on to the next page where it has to.
pw.Widget pdfLine(String text, {pw.TextStyle? style}) => pw.Padding(
  padding: const pw.EdgeInsets.only(left: 12, bottom: 5),
  child: pw.Text('•  $text', style: style, overflow: pw.TextOverflow.span),
);

/// About how many characters a bulleted line holds on an A4 page at the
/// sheets' size. Measured with the bundled Noto: 70 to 75. Fewer are
/// assumed, because a guess too high is a card that does not fit; 90 was
/// one, and a card of 24 medium lines was taken for 27 of 30 and measured
/// 812 of 728 points (#351).
const pdfCharactersPerLine = 60;

/// About how many lines [text] takes on an A4 page at the sheets' size.
int pdfEstimatedLines(String text) => text
    .split('\n')
    .fold(
      0,
      (lines, line) =>
          lines + math.max(1, (line.length / pdfCharactersPerLine).ceil()),
    );

/// What a card may take and still be kept on one page.
const pdfCardLinesTogether = 30;

/// A person's card: the name and what is filled in.
///
/// On one page where it fits, so that what is printed about a person stays
/// under their name: a card split across pages left medication at the top
/// of the next one with no name above it (#351). A card longer than that
/// runs on, and every line carries the name, so a page that begins halfway
/// through it still says whose it is. [together] false lets every card run
/// on; see [pdfKeepingCardsTogether].
List<pw.Widget> pdfCard(
  String name,
  List<({String label, String value})> rows, {
  bool together = true,
}) {
  final heading = pw.Text(
    name,
    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
  );
  final lines = rows.fold(
    1,
    (sum, row) => sum + pdfEstimatedLines('${row.label}: ${row.value}'),
  );
  if (together && lines <= pdfCardLinesTogether) {
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

/// [render] with every card that seems short enough kept on one page, and
/// where one was not after all, once more with every card allowed to run
/// on. The lines are guessed from characters, and a font or a script that
/// sets wider than the guess must not cost the whole document (#351).
Future<T> pdfKeepingCardsTogether<T>(
  Future<T> Function(bool cardsTogether) render,
) async {
  try {
    return await render(true);
  } on PdfException {
    return render(false);
  }
}

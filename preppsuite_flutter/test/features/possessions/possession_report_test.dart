import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:preppsuite_flutter/core/pdf_blocks.dart';
import 'package:preppsuite_flutter/features/possessions/application/possession_report.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import '../../pdf_text.dart';

/// The possessions list on paper, with entries nobody kept short (#403).
void main() {
  // The bundled font comes through rootBundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  const strings = PossessionReportStrings(
    title: 'Hausrat',
    generatedOn: 'Erstellt am 26.11.2026',
    empty: 'Nichts erfasst.',
    noRoom: 'Ohne Raum',
    columnName: 'Name',
    columnSerial: 'Seriennummer',
    columnAcquired: 'Gekauft',
    columnPrice: 'Preis',
    columnNotes: 'Notizen',
    total: 'Summe: 1.200,00 EUR',
    withoutPrice: 'Zwei ohne Preis',
    keepElsewhere: 'Woanders aufbewahren.',
  );

  Possession thing(String id, String name, {String? notes, String? room}) =>
      Possession(
        clientId: id,
        householdId: 'h',
        name: name,
        room: room ?? 'Wohnzimmer',
        notes: notes,
        updatedAt: DateTime.utc(2026),
        dirty: false,
      );

  Future<Uint8List> build(List<Possession> rows, {pw.Font? font}) =>
      const PossessionReport()
          .build(
            rows: rows,
            householdName: 'Familie Muster',
            strings: strings,
            money: (cents, currency) => '$cents ${currency ?? ''}',
            date: (day) => '${day.day}.${day.month}.${day.year}',
            font: font,
          )
          // A row taller than a page laid the same page out for ever in a
          // release build; in a test the assert throws first, and this
          // keeps a regression from hanging the suite either way.
          .timeout(const Duration(seconds: 30));

  // 10,000 characters: five times what already made a row taller than a
  // page.
  final longNote = List.filled(1250, 'Kratzer ').join();

  test('a note of 10,000 characters is printed, in full', () async {
    final pdf = await build([
      thing('a', 'Fernseher', notes: 'Wandhalterung'),
      thing('b', 'Sofa', notes: longNote),
      thing('c', 'Stehlampe', notes: 'danach'),
    ], font: pw.Font.helvetica());

    // Kerning splits some words into pieces on the page; these two
    // arrive whole.
    final text = textIn(pdf);
    expect(text, contains('danach'));
    expect(text, contains('Summe'));
    // Cut short in the table, and all of it beneath.
    expect(
      'Kratzer'.allMatches(text).length,
      greaterThanOrEqualTo(1250),
    );
  });

  test('with the bundled font as well', () async {
    final pdf = await build([
      thing('b', 'Sofa', notes: longNote),
      thing('c', 'Kommode', notes: List.filled(400, 'Zeile').join('\n')),
      thing('d', List.filled(300, 'Name').join(' '), room: longNote),
    ]);

    expect(ascii.decode(pdf.take(5).toList()), '%PDF-');
  });

  group('a table cell (pdfCell)', () {
    test('keeps a short text as it is, on one line', () {
      expect(pdfCell('Kratzer\nlinks  unten'), 'Kratzer links unten');
    });

    test('cuts a long one with an ellipsis', () {
      final cell = pdfCell(longNote);
      expect(cell.length, lessThanOrEqualTo(pdfCellCharacters));
      expect(cell, endsWith('…'));
      expect(longNote, startsWith(cell.substring(0, cell.length - 1)));
    });

    test('does not cut a character in two', () {
      final emoji = List.filled(150, '📺').join();
      final cell = pdfCell(emoji);
      expect(cell.length, lessThanOrEqualTo(pdfCellCharacters));
      expect(
        () => utf8.encode(cell.substring(0, cell.length - 1)),
        returnsNormally,
      );
      expect(cell.runes.where((r) => r >= 0xD800 && r <= 0xDFFF), isEmpty);
    });
  });
}

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../local_db/database.dart';
import 'possession_controller.dart';

/// Localized strings for the report, gathered by the caller so this stays
/// free of a `BuildContext`.
class PossessionReportStrings {
  const PossessionReportStrings({
    required this.title,
    required this.generatedOn,
    required this.empty,
    required this.noRoom,
    required this.columnName,
    required this.columnSerial,
    required this.columnAcquired,
    required this.columnPrice,
    required this.columnNotes,
    required this.total,
    required this.withoutPrice,
    required this.keepElsewhere,
  });

  final String title;
  final String generatedOn;
  final String empty;

  /// Heading for entries nobody assigned a room to.
  final String noRoom;

  final String columnName;
  final String columnSerial;
  final String columnAcquired;
  final String columnPrice;
  final String columnNotes;

  /// "Summe: 4.320,00 EUR", already formatted by the caller.
  final String total;

  /// How many entries carry no price and are therefore not in the total.
  final String withoutPrice;

  /// The sentence that makes the document worth printing at all.
  final String keepElsewhere;
}

/// The household's possessions on paper, grouped by room.
///
/// The point of the export, and the reason this feature has one at all:
/// a list of what burned that is stored only in the flat that burned is
/// not a list. Printed, mailed to oneself or dropped on a stick at
/// somebody else's house, it survives the event it was written for.
///
/// Photos are deliberately not in it. They are the most persuasive part
/// of a claim and also the part that would turn a two-page list into a
/// forty-megabyte file somebody then does not send.
class PossessionReport {
  const PossessionReport();

  Future<Uint8List> build({
    required List<Possession> rows,
    required String householdName,
    required PossessionReportStrings strings,

    /// A formatter for money, handed in because the locale lives with the
    /// caller. Given cents and the row's currency.
    required String Function(int cents, String? currency) money,

    /// Likewise for dates.
    required String Function(DateTime) date,

    /// Overridden in tests — see `emergency_plan_report.dart` for why a
    /// bundled subset font makes the finished page unreadable.
    pw.Font? font,
  }) async {
    font ??= pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );

    final grouped = byRoom(rows);

    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              strings.title,
              style: const pw.TextStyle(fontSize: 24),
            ),
          ),
          pw.Text(householdName, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            strings.generatedOn,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),

          if (rows.isEmpty)
            pw.Text(strings.empty)
          else ...[
            for (final entry in grouped.entries) ...[
              pw.Header(level: 1, text: entry.key ?? strings.noRoom),
              pw.TableHelper.fromTextArray(
                headers: [
                  strings.columnName,
                  strings.columnSerial,
                  strings.columnAcquired,
                  strings.columnPrice,
                  strings.columnNotes,
                ],
                data: [
                  for (final row in entry.value)
                    [
                      row.name,
                      row.serialNumber ?? '',
                      row.acquiredOn == null ? '' : date(row.acquiredOn!),
                      row.purchasePriceCents == null
                          ? ''
                          : money(row.purchasePriceCents!, row.currency),
                      row.notes ?? '',
                    ],
                ],
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerStyle: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 12),
            ],
            pw.Divider(),
            pw.Text(strings.total),
            pw.Text(
              strings.withoutPrice,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],

          pw.SizedBox(height: 16),
          pw.Text(
            strings.keepElsewhere,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    return document.save();
  }
}

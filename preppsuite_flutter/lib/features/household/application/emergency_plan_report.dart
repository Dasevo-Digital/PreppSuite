import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../local_db/database.dart';

class EmergencyPlanReportStrings {
  const EmergencyPlanReportStrings({
    required this.title,
    required this.generatedOn,
    required this.meetingPoints,
    required this.contact,
    required this.equipment,
    required this.notes,
    required this.empty,
  });

  final String title;
  final String generatedOn;
  final String meetingPoints;
  final String contact;
  final String equipment;
  final String notes;
  final String empty;
}

/// A compact paper copy of the household's agreement.
class EmergencyPlanReport {
  const EmergencyPlanReport();

  Future<Uint8List> build({
    required HouseholdPlan plan,
    required String householdName,
    required EmergencyPlanReportStrings strings,
  }) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: font),
    );
    final sections = <({String title, List<String> rows})>[
      (
        title: strings.meetingPoints,
        rows: [
          if (plan.meetingPointNear != null) plan.meetingPointNear!,
          if (plan.meetingPointFar != null) plan.meetingPointFar!,
        ],
      ),
      (
        title: strings.contact,
        rows: [
          if (plan.contactName != null) plan.contactName!,
          if (plan.contactPhone != null) plan.contactPhone!,
        ],
      ),
      (
        title: strings.equipment,
        rows: [
          if (plan.kitLocation != null) plan.kitLocation!,
          if (plan.shutoffLocation != null) plan.shutoffLocation!,
        ],
      ),
      (title: strings.notes, rows: [if (plan.notes != null) plan.notes!]),
    ];
    document.addPage(
      pw.MultiPage(
        build: (_) => [
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
          for (final section in sections) ...[
            pw.Header(level: 1, text: section.title),
            if (section.rows.isEmpty)
              pw.Text(strings.empty)
            else
              for (final row in section.rows) pw.Bullet(text: row),
          ],
        ],
      ),
    );
    return document.save();
  }
}

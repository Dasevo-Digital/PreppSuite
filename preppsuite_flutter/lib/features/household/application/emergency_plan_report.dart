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
    required this.contactPoint,
    required this.equipment,
    required this.notes,
    required this.empty,
    required this.cards,
    required this.cardsWarning,
    required this.fields,
  });

  final String title;
  final String generatedOn;
  final String meetingPoints;
  final String contact;

  /// Heading for the municipality's contact point.
  final String contactPoint;

  final String equipment;
  final String notes;
  final String empty;

  /// Heading of the emergency-card section, and the line printed with it.
  final String cards;
  final String cardsWarning;

  /// Labels for the card rows, in the order they should be printed.
  final EmergencyCardFieldStrings fields;
}

/// The labels of one emergency card.
class EmergencyCardFieldStrings {
  const EmergencyCardFieldStrings({
    required this.birthYear,
    required this.bloodType,
    required this.allergies,
    required this.medication,
    required this.conditions,
    required this.insurance,
    required this.doctor,
    required this.contact,
    required this.notes,
  });

  final String birthYear;
  final String bloodType;
  final String allergies;
  final String medication;
  final String conditions;
  final String insurance;
  final String doctor;
  final String contact;
  final String notes;
}

/// A compact paper copy of the household's agreement.
class EmergencyPlanReport {
  const EmergencyPlanReport();

  /// [members] adds a page of emergency cards.
  ///
  /// Empty by default, and asked for each time rather than remembered. A
  /// printed card is the one copy of this data that works when the phone
  /// is dead or gone, which is exactly why somebody wants it — and it is
  /// also a loose sheet of paper naming a person's blood group, allergies
  /// and medication, which no lock protects. Whether that trade is worth
  /// making is not a decision an app should make once and keep.
  Future<Uint8List> build({
    required HouseholdPlan plan,
    required String householdName,
    required EmergencyPlanReportStrings strings,
    List<HouseholdMember> members = const [],

    /// Overridden in tests. The bundled Noto subsets itself and writes the
    /// text as glyph indices, which makes the finished page unreadable
    /// without the font — fine for printing and useless for checking what
    /// reached the paper. A built-in font writes the strings literally.
    pw.Font? font,
  }) async {
    // A static cut, deliberately: the theme below uses the same face for
    // base and bold, so no weight is ever interpolated, and the variable
    // NotoSans carried 1.25 MB of glyph variation data for that on every
    // platform. `tool/font_instance.py` produces the asset and
    // `font_asset_test.dart` guards it -- a fresh download from Google
    // Fonts is variable and would put the megabyte back.
    font ??= pw.Font.ttf(
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
      // Its own section rather than a third line under the contact: on
      // paper the heading is what somebody reads first, and "where to go
      // when nothing works" is not the same errand as "who to ring".
      (
        title: strings.contactPoint,
        rows: [if (plan.localContactPoint != null) plan.localContactPoint!],
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
          if (members.isNotEmpty) ...[
            pw.Header(level: 1, text: strings.cards),
            // On the sheet itself, not only in the dialog that offered it.
            // The dialog is gone the moment it is answered; the paper is
            // what somebody finds in a drawer two years from now.
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600),
              ),
              child: pw.Text(
                strings.cardsWarning,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.SizedBox(height: 8),
            for (final member in members) ...[
              pw.Text(
                member.name,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              for (final row in _cardRows(member, strings.fields))
                pw.Bullet(text: '${row.label}: ${row.value}'),
              pw.SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
    return document.save();
  }

  /// The filled-in fields of one card, in reading order.
  ///
  /// Empty fields are left out rather than printed as blanks: a card with
  /// "Allergien: —" on it invites the reader to believe somebody checked,
  /// and on a sheet handed to a paramedic that is worse than silence.
  static List<({String label, String value})> _cardRows(
    HouseholdMember member,
    EmergencyCardFieldStrings fields,
  ) {
    final rows = <({String label, String value})>[];
    void add(String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      rows.add((label: label, value: value.trim()));
    }

    if (member.birthYear != null) {
      add(fields.birthYear, '${member.birthYear}');
    }
    add(fields.bloodType, member.bloodType);
    add(fields.allergies, member.allergies);
    add(fields.medication, member.medication);
    add(fields.conditions, member.conditions);
    add(fields.insurance, member.insurance);
    add(fields.doctor, member.doctor);
    add(fields.contact, member.emergencyContact);
    add(fields.notes, member.notes);
    return rows;
  }
}

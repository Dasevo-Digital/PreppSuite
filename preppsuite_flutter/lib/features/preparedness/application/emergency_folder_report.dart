/// The whole folder, as one document.
///
/// This app is built on the assumption that the device may be gone — that
/// is why the database is local, why the maps download and why the
/// knowledge archive is offline. Paper is the last fallback under all of
/// it, and until now it came in five separate exports on five separate
/// screens: the household plan, the possessions list, the checklists, the
/// missing-equipment report and the crisis briefing. Each one partial,
/// and the household had to know all five existed.
///
/// Meanwhile the crisis hub asked, in `EmergencyFolderStatus`, whether
/// copies of the important papers were ready — a question the app posed
/// and then gave no help answering.
///
/// This is that help. It deliberately leaves out the two exports that are
/// not folder material: the possessions list is for an insurer and
/// belongs in a different drawer, and the shopping-style equipment report
/// is a to-do list, not a record.
///
/// Sections with nothing in them are printed as empty rather than left
/// out. A folder that shows its own gaps is one somebody can finish.
library;

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../local_db/database.dart';
import '../../household/application/emergency_plan_report.dart';
import 'preparedness_hub_store.dart';

/// Everything printed on the folder, already translated.
class EmergencyFolderReportStrings {
  const EmergencyFolderReportStrings({
    required this.title,
    required this.generatedOn,
    required this.intro,
    required this.empty,
    required this.meetingPoints,
    required this.contact,
    required this.contactPoint,
    required this.equipment,
    required this.notes,
    required this.cards,
    required this.cardsWarning,
    required this.fields,
    required this.evacuation,
    required this.evacuationRoute,
    required this.evacuationPlaces,
    required this.communication,
    required this.radio,
    required this.autonomy,
    required this.folder,
    required this.folderCopiesReady,
    required this.folderTakeAlong,
  });

  final String title;
  final String generatedOn;

  /// One line on the cover saying what this is and where it belongs.
  final String intro;

  /// Printed under a heading that has nothing under it.
  final String empty;

  final String meetingPoints;
  final String contact;
  final String contactPoint;
  final String equipment;
  final String notes;

  final String cards;
  final String cardsWarning;
  final EmergencyCardFieldStrings fields;

  final String evacuation;
  final String evacuationRoute;
  final String evacuationPlaces;

  final String communication;
  final String radio;
  final String autonomy;

  final String folder;
  final String folderCopiesReady;
  final String folderTakeAlong;
}

class EmergencyFolderReport {
  const EmergencyFolderReport();

  /// [members] adds the emergency cards, and is empty unless somebody
  /// asked for them this time.
  ///
  /// The same trade `EmergencyPlanReport` describes: a printed card is
  /// the copy that works when the phone is dead, and it is also a loose
  /// sheet naming a person's blood group, allergies and medication, which
  /// no lock protects. Asked each time, never remembered.
  ///
  /// [autonomy] arrives already worded, because how a reach is phrased is
  /// a screen's business and this file has no localisations.
  Future<Uint8List> build({
    required String householdName,
    required EmergencyFolderReportStrings strings,
    HouseholdPlan? plan,
    List<HouseholdMember> members = const [],
    PreparednessHubData hub = const PreparednessHubData(),
    List<({String label, String value})> autonomy = const [],

    /// Overridden in tests, for the reason `EmergencyPlanReport` gives:
    /// the bundled Noto subsets itself into glyph indices, so a built-in
    /// font is the only way to read what actually reached the paper.
    pw.Font? font,
  }) async {
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
          ?plan?.meetingPointNear,
          ?plan?.meetingPointFar,
        ],
      ),
      (
        title: strings.contact,
        rows: [
          ?plan?.contactName,
          ?plan?.contactPhone,
        ],
      ),
      (
        title: strings.contactPoint,
        rows: [?plan?.localContactPoint],
      ),
      (
        title: strings.equipment,
        rows: [
          ?plan?.kitLocation,
          ?plan?.shutoffLocation,
        ],
      ),
      (title: strings.notes, rows: [?plan?.notes]),
      (
        title: strings.folder,
        rows: [
          if (hub.folder.location.trim().isNotEmpty) hub.folder.location.trim(),
          if (hub.folder.copiesReady) strings.folderCopiesReady,
          if (hub.folder.takeWhenLeaving) strings.folderTakeAlong,
        ],
      ),
      (
        title: strings.communication,
        rows: [
          if (hub.communication.text.trim().isNotEmpty)
            hub.communication.text.trim(),
        ],
      ),
      (
        title: strings.radio,
        rows: [
          for (final plan in hub.radioPlans)
            '${plan.station}: ${plan.band} ${plan.frequency} · '
                '${plan.receiver} · ${plan.power}',
        ],
      ),
      (
        title: strings.autonomy,
        rows: [for (final row in autonomy) '${row.label}: ${row.value}'],
      ),
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
          pw.SizedBox(height: 8),
          pw.Text(strings.intro, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 16),
          for (final section in sections) ...[
            pw.Header(level: 1, text: section.title),
            if (section.rows.isEmpty)
              pw.Text(strings.empty)
            else
              for (final row in section.rows) pw.Bullet(text: row),
          ],
          pw.Header(level: 1, text: strings.evacuation),
          if (hub.evacuationCards.isEmpty)
            pw.Text(strings.empty)
          else
            for (final card in hub.evacuationCards) ...[
              pw.Text(
                // An ASCII arrow, not U+2192: the bundled NotoSans is a
                // subset (see `tool/font_instance.py`) and does not carry
                // it, so a real arrow prints as nothing at all. Measured,
                // not assumed — and the crisis briefing had been shipping
                // an invisible one.
                '${card.label}: ${card.start} -> ${card.destination}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (card.route.trim().isNotEmpty)
                pw.Bullet(text: '${strings.evacuationRoute}: ${card.route}'),
              if (card.locations.trim().isNotEmpty)
                pw.Bullet(
                  text: '${strings.evacuationPlaces}: ${card.locations}',
                ),
              pw.SizedBox(height: 8),
            ],
          if (members.isNotEmpty) ...[
            pw.Header(level: 1, text: strings.cards),
            // On the sheet itself, not only in the dialog that offered
            // it: the dialog is gone once answered, the paper is what
            // somebody finds in a drawer two years from now.
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
              for (final row in emergencyCardRows(member, strings.fields))
                pw.Bullet(text: '${row.label}: ${row.value}'),
              pw.SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
    return document.save();
  }
}

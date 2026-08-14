import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../local_db/database.dart';

/// Localized strings for the report, gathered from `AppLocalizations` by
/// the caller — keeps this generator free of a `BuildContext` dependency.
class MissingEquipmentReportStrings {
  const MissingEquipmentReportStrings({
    required this.title,
    required this.generatedOn,
    required this.checklistSectionTitle,
    required this.noMissingChecklistItems,
    required this.inventorySectionTitle,
    required this.noLowStockItems,
    required this.columnItem,
    required this.columnQuantity,
    required this.columnMinQuantity,
    required this.columnUnit,
  });

  final String title;
  final String generatedOn;
  final String checklistSectionTitle;
  final String noMissingChecklistItems;
  final String inventorySectionTitle;
  final String noLowStockItems;
  final String columnItem;
  final String columnQuantity;
  final String columnMinQuantity;
  final String columnUnit;
}

/// Builds the "missing equipment" PDF: unchecked checklist items grouped by
/// checklist, plus inventory items below their configured minimum quantity.
/// Both queries are one-off snapshots (not live), matching what a printed
/// report should be.
class MissingEquipmentReport {
  const MissingEquipmentReport();

  Future<Uint8List> build({
    required AppDatabase db,
    required String householdId,
    required String householdName,
    required MissingEquipmentReportStrings strings,
  }) async {
    final uncheckedItems = await db.uncheckedChecklistItems(householdId);
    final templates = await db.allChecklistTemplates(householdId);
    final lowStockItems = await db.lowStockInventoryItems(householdId);

    final templateTitleByClientId = {
      for (final template in templates) template.clientId: template.title,
    };
    final itemsByTemplateTitle = <String, List<ChecklistItem>>{};
    for (final item in uncheckedItems) {
      final title = templateTitleByClientId[item.templateClientId] ?? '—';
      itemsByTemplateTitle.putIfAbsent(title, () => []).add(item);
    }
    final sortedTemplateTitles = itemsByTemplateTitle.keys.toList()..sort();

    // The bundled base-14 PDF fonts (Helvetica etc.) have no Unicode
    // support and mangle German umlauts/ß — embed a real Unicode font
    // instead. Same font used for regular and bold weight (only one static
    // weight is bundled); this loses bold *emphasis* but never garbles
    // text, which is the actual correctness requirement.
    final unicodeFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: unicodeFont, bold: unicodeFont),
    );
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(strings.title, style: const pw.TextStyle(fontSize: 24)),
          ),
          pw.Text(householdName, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            strings.generatedOn,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),

          pw.Header(level: 1, text: strings.checklistSectionTitle),
          if (itemsByTemplateTitle.isEmpty)
            pw.Text(strings.noMissingChecklistItems)
          else
            for (final templateTitle in sortedTemplateTitles) ...[
              pw.Text(
                templateTitle,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Bullet(
                text: itemsByTemplateTitle[templateTitle]!
                    .map((item) => item.title)
                    .join(', '),
              ),
              pw.SizedBox(height: 8),
            ],

          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: strings.inventorySectionTitle),
          if (lowStockItems.isEmpty)
            pw.Text(strings.noLowStockItems)
          else
            pw.TableHelper.fromTextArray(
              headers: [
                strings.columnItem,
                strings.columnQuantity,
                strings.columnMinQuantity,
                strings.columnUnit,
              ],
              data: [
                for (final item in lowStockItems)
                  [
                    item.name,
                    _formatNumber(item.quantity),
                    _formatNumber(item.minQuantity!),
                    item.unit,
                  ],
              ],
            ),
        ],
      ),
    );

    return document.save();
  }

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}

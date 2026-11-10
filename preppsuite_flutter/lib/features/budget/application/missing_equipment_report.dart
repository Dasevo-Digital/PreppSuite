import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/name_order.dart';
import '../../../core/pdf_blocks.dart';
import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../checklists/application/built_in_template_l10n.dart';
import '../../checklists/application/checklist_satisfaction.dart';
import '../../inventory/application/stock_today.dart';

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
    String languageCode = 'de',
  }) async {
    final templates = await db.allChecklistTemplates(householdId);
    final now = DateTime.now();
    final uncheckedItems = openEquipment(
      unchecked: await db.uncheckedChecklistItems(householdId),
      templates: templates,
      inventoryById: {
        for (final item in await db.watchInventoryItems(householdId).first)
          item.clientId: item,
      },
      now: now,
    );
    final lowStockItems = [
      for (final item in await db.inventoryItemsWithMinimum(householdId))
        if (isBelowMinimum(item, now: now)) item,
    ];

    final templateTitleByClientId = {
      for (final template in templates)
        template.clientId: template.titleIn(languageCode),
    };
    final itemsByTemplateTitle = <String, List<ChecklistItem>>{};
    for (final item in uncheckedItems) {
      final title = templateTitleByClientId[item.templateClientId] ?? '—';
      itemsByTemplateTitle.putIfAbsent(title, () => []).add(item);
    }
    final sortedTemplateTitles = itemsByTemplateTitle.keys.toList()
      ..sort(compareNames);

    // The bundled base-14 PDF fonts (Helvetica etc.) have no Unicode
    // support and mangle German umlauts/ß — embed a real Unicode font
    // instead. Same font used for regular and bold weight (only one static
    // weight is bundled); this loses bold *emphasis* but never garbles
    // text, which is the actual correctness requirement.
    // A static cut, deliberately: the theme below uses the same face for
    // base and bold, so no weight is ever interpolated, and the variable
    // NotoSans carried 1.25 MB of glyph variation data for that on every
    // platform. `tool/font_instance.py` produces the asset and
    // `font_asset_test.dart` guards it -- a fresh download from Google
    // Fonts is variable and would put the megabyte back.
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
              pdfLine(
                itemsByTemplateTitle[templateTitle]!
                    .map((item) => item.titleIn(languageCode))
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
                    _formatNumber(stockToday(item, now: now), languageCode),
                    _formatNumber(item.minQuantity!, languageCode),
                    item.unit,
                  ],
              ],
            ),
        ],
      ),
    );

    return document.save();
  }

  /// "2,5" where the language writes a decimal comma (#294); it printed
  /// "2.5" in every language.
  String _formatNumber(double value, String languageCode) =>
      NumberFormat.decimalPattern(languageCode).format(value);
}

/// What the report calls missing: the open lines of the lists of things
/// to have, in their own order (#290).
///
/// Not every unchecked line. One that the stock it is linked to covers
/// is shown as done on the checklist screen, so a report that listed it
/// never said "nothing open" while every list stood at 100 %. And the
/// lists about acting -- "Wenn der Strom ausfällt" -- are steps to take
/// while it happens, not equipment anybody can be short of.
List<ChecklistItem> openEquipment({
  required List<ChecklistItem> unchecked,
  required List<ChecklistTemplate> templates,
  required Map<String, InventoryItem> inventoryById,
  DateTime? now,
}) {
  final toHave = {
    for (final template in templates)
      if (ChecklistKind.fromName(template.kind) == ChecklistKind.preparation)
        template.clientId,
  };
  return [
    for (final item in unchecked)
      if (toHave.contains(item.templateClientId) &&
          !isChecklistItemSatisfied(item, inventoryById, now: now))
        item,
  ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

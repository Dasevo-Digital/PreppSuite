import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/content_swap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/adaptive_columns.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../household/application/household_providers.dart';
import '../../inventory/application/inventory_photo_service.dart';
import '../application/possession_controller.dart';
import '../application/possession_report.dart';
import 'possession_form_screen.dart';

/// What the household owns, written down before it is gone.
///
/// Not the supply list: that one answers how long the stores last, this
/// one answers what was lost. See [Possessions] for why they are kept
/// apart.
class PossessionsScreen extends ConsumerWidget {
  const PossessionsScreen({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = ref.watch(possessionsProvider(householdId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.possessionsTitle),
        actions: [
          if (rows.value?.isNotEmpty ?? false)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: l10n.possessionsExport,
              onPressed: () => _export(context, ref, rows.value!, l10n),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, rows.value),
        icon: const Icon(Icons.add),
        label: Text(l10n.possessionAdd),
      ),
      body: ContentSwap(
        child: rows.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (data) {
            if (data.isEmpty) {
              // Centred while it fits and scrollable when it does not. At
              // twice the system font size the explanation is taller than a
              // phone, and a plain centred Column clips it -- silently, in
              // a release build.
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.possessionsEmpty,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.possessionsWhy, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              );
            }

            final grouped = byRoom(data);
            final totals = totalCentsByCurrency(data);
            final missing = withoutPrice(data);

            return AdaptiveColumns(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              blocks: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.possessionsWhy),
                    const SizedBox(height: 12),
                    for (final entry in totals.entries)
                      Text(
                        l10n.possessionsTotal(
                          _money(l10n, entry.value, entry.key),
                        ),
                        style: theme.textTheme.titleMedium,
                      ),
                    if (missing > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.possessionsWithoutPrice(missing),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
                // A section and not a Column: at desktop width a room's name
                // must not end up in one column with its contents in the
                // next, but on a phone a room of two hundred things is one
                // block the list has to build whole. See [AdaptiveSection].
                for (final entry in grouped.entries)
                  AdaptiveSection(
                    heading: Text(
                      entry.key ?? l10n.possessionsNoRoom,
                      style: theme.textTheme.titleMedium,
                    ),
                    rows: [
                      for (final row in entry.value)
                        _PossessionTile(
                          row: row,
                          l10n: l10n,
                          householdId: householdId,
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _open(BuildContext context, List<Possession>? existing) {
    // The currency of the last entry that has one, so a household types
    // it once. Nothing is assumed when the list is empty -- guessing a
    // currency from the locale would be the app inventing a figure.
    final currency = existing
        ?.map((row) => row.currency)
        .whereType<String>()
        .lastOrNull;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PossessionFormScreen(
          householdId: householdId,
          defaultCurrency: currency,
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    List<Possession> rows,
    AppLocalizations l10n,
  ) async {
    final profile = ref.read(householdProfileProvider).value;
    final totals = totalCentsByCurrency(rows);
    final date = DateFormat.yMMMd(l10n.localeName);

    await Printing.layoutPdf(
      onLayout: (_) => const PossessionReport().build(
        rows: rows,
        householdName: profile?.name ?? '',
        money: (cents, currency) => _money(l10n, cents, currency ?? ''),
        date: date.format,
        strings: PossessionReportStrings(
          title: l10n.possessionsPdfTitle,
          generatedOn: l10n.pdfGeneratedOn(
            date.format(DateTime.now()),
          ),
          empty: l10n.possessionsEmpty,
          noRoom: l10n.possessionsNoRoom,
          columnName: l10n.possessionNameLabel,
          columnSerial: l10n.possessionSerialLabel,
          columnAcquired: l10n.possessionAcquiredLabel,
          columnPrice: l10n.possessionPriceLabel,
          columnNotes: l10n.notesLabel,
          total: [
            for (final entry in totals.entries)
              l10n.possessionsTotal(_money(l10n, entry.value, entry.key)),
          ].join('   '),
          withoutPrice: l10n.possessionsWithoutPrice(withoutPrice(rows)),
          keepElsewhere: l10n.possessionsKeepElsewhere,
        ),
      ),
    );
  }

  static String _money(AppLocalizations l10n, int cents, String currency) {
    final amount = NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 2,
    ).format(cents / 100);
    return currency.isEmpty ? amount : '$amount $currency';
  }
}

class _PossessionTile extends ConsumerWidget {
  const _PossessionTile({
    required this.row,
    required this.l10n,
    required this.householdId,
  });

  final Possession row;
  final AppLocalizations l10n;
  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = [
      ?row.serialNumber,
      if (row.acquiredOn case final acquired?)
        DateFormat.yMMMd(l10n.localeName).format(acquired),
      if (row.purchasePriceCents case final cents?)
        PossessionsScreen._money(l10n, cents, row.currency ?? ''),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: row.photoPath == null
            ? const Icon(Icons.inventory_2_outlined)
            : ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(
                    InventoryPhotoService.resolvePhotoPath(row.photoPath!),
                  ),
                  width: 48,
                  height: 48,
                  // Photos are stored at up to 2000 pixels wide, and what
                  // costs memory is the size they are decoded to, not the
                  // size they are drawn at: one of them is eleven
                  // megabytes of pixels. Every tile in this list is built
                  // at once, so without this a household that
                  // photographed forty things for its insurer fills
                  // Flutter's hundred-megabyte image cache several times
                  // over and re-decodes JPEGs on every rebuild.
                  //
                  // Width only: giving both axes would stretch the
                  // picture to a square before `cover` crops it. 192
                  // rather than 48 at triple density, because `cover`
                  // fills the square from the picture's *short* side —
                  // on a landscape photo that is the height, and asking
                  // for 144 across would leave only 108 down.
                  cacheWidth: 192,
                  fit: BoxFit.cover,
                  // A picture whose file is gone must not take the list
                  // down with it -- the row is still worth showing.
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.inventory_2_outlined),
                ),
              ),
        title: Text(row.name),
        subtitle: details.isEmpty ? null : Text(details),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.deleteButton,
          onPressed: () => _confirmRemove(context, ref),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PossessionFormScreen(
              householdId: householdId,
              existing: row,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.possessionRemoveTitle),
        content: Text(l10n.possessionRemoveBody(row.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(possessionControllerProvider(householdId)).remove(row);
  }
}

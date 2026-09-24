import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/adaptive_columns.dart';
import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/content_swap.dart';
import '../application/inventory_providers.dart';
import '../application/medication_range.dart';

/// How long the medicines last.
///
/// The reach calculation the emergency card cannot do: a card names the
/// medicine, this says whether there are three days of it or three months.
///
/// Everything on the screen is the household's own arithmetic — see
/// `medication_range.dart` for why no dose is ever guessed here.
class MedicationRangeScreen extends ConsumerWidget {
  const MedicationRangeScreen({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = ref.watch(inventoryItemsProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.medicationTitle)),
      body: ContentSwap(
        child: items.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(describeError(l10n, error))),
          data: (rows) {
            final ranges = medicationRanges(rows);
            final unanswered = medicationsWithoutDose(rows);
            final shortest = firstToRunOut(ranges);
            final decimal = NumberFormat.decimalPattern(l10n.localeName);
            final date = DateFormat.yMMMd(l10n.localeName);

            String number(double value) =>
                decimal.format(double.parse(value.toStringAsFixed(2)));

            String days(int count) => switch (count) {
              0 => l10n.medicationZeroDays,
              1 => l10n.medicationOneDay,
              _ => l10n.medicationDays(count),
            };

            return AdaptiveColumns(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              blocks: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.medicationIntro),
                    const SizedBox(height: 16),
                    if (ranges.isEmpty && unanswered.isEmpty) ...[
                      Text(
                        l10n.medicationNothingYet,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.medicationNothingYetWhy),
                    ] else if (shortest != null) ...[
                      Card(
                        margin: EdgeInsets.zero,
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.medicationShortest(
                                  shortest.item.name,
                                  days(shortest.wholeDays),
                                ),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.medicationRunsOut(
                                  date.format(
                                    shortest.runsOutOn(DateTime.now()),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(l10n.medicationShortestWhy),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      Text(l10n.medicationNoAnswer),
                  ],
                ),

                if (ranges.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final range in ranges)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(range.item.name),
                            subtitle: Text(
                              l10n.medicationStock(
                                number(range.item.quantity),
                                range.item.unit,
                                number(range.dailyDose),
                              ),
                            ),
                            trailing: Text(
                              days(range.wholeDays),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                    ],
                  ),

                if (unanswered.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.medicationWithoutDoseTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.medicationWithoutDoseWhy),
                      const SizedBox(height: 8),
                      for (final item in unanswered)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• ${item.name} — '
                            '${number(item.quantity)} ${item.unit}',
                          ),
                        ),
                    ],
                  ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.medicationSource,
                      style: theme.textTheme.bodySmall,
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
}

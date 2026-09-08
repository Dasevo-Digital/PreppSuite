import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/progress_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../../model/household_profile.dart';
import '../../inventory/application/inventory_category_l10n.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/presentation/inventory_item_form_screen.dart';
import '../../inventory/application/supply_calculator.dart';
import '../../checklists/application/checklist_providers.dart';
import '../../warnings/application/warning_providers.dart';
import '../../warnings/application/warning_relevance.dart';
import '../application/home_overview.dart';
import '../application/shell_layout.dart';

/// The first thing the app shows: what state this household is in.
///
/// Every card answers one question and then hands over to the screen that
/// can do something about it — this one shows and does not edit, so there
/// is never a second place where a number can be changed and drift out of
/// step with the first.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({
    super.key,
    required this.profile,
    required this.onNavigate,
  });

  final HouseholdProfile profile;
  final ValueChanged<ShellDestination> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inventory = ref.watch(inventoryItemsProvider(profile.id));
    final items = inventory.value ?? const <InventoryItem>[];
    final overview = summarizeInventory(items);

    final cards = <Widget>[
      _AttentionCard(
        overview: overview,
        onOpen: () => onNavigate(ShellDestination.inventory),
      ),
      _WarningCard(
        profile: profile,
        onOpen: () => onNavigate(ShellDestination.warnings),
      ),
      _ChecklistCard(
        householdId: profile.id,
        onOpen: () => onNavigate(ShellDestination.checklists),
      ),
      _ResourceCard(
        overview: overview,
        onOpen: () => onNavigate(ShellDestination.inventory),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navOverview)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 1000 &&
              MediaQuery.textScalerOf(context).scale(16) <= 22;
          final width = constraints.maxWidth - 32;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (inventory.hasValue && items.isEmpty) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.overviewStartTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.overviewStartHint),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text(l10n.overviewAddFirst),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => InventoryItemFormScreen(
                                householdId: profile.id,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _SupplyCard(
                profile: profile,
                items: items,
                onOpen: () => onNavigate(ShellDestination.inventory),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: wide ? (width - 12) / 2 : width,
                      child: card,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A card with a heading, a body and one place it leads.
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.onOpen,
    this.trailing,
    this.tone,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback onOpen;
  final Widget? trailing;

  /// Colours the heading when the card is reporting a problem. Left null
  /// for the ordinary case, so that a coloured heading means something.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: tone ?? theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tone,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 12),
              child,
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.overviewOpen,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Water and calories against ten days for this household.
class _SupplyCard extends StatelessWidget {
  const _SupplyCard({
    required this.profile,
    required this.items,
    required this.onOpen,
  });

  final HouseholdProfile profile;
  final List<InventoryItem> items;
  final VoidCallback onOpen;

  /// The BBK's own planning horizon, and the one every table in the app
  /// is written for. The inventory screen lets it be changed; here it is
  /// fixed, because an overview that answers a different question every
  /// time it is opened is not an overview.
  static const days = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final household = SupplyHousehold(
      adults: profile.personCount,
      children: profile.children,
      dogs: profile.dogs,
      cats: profile.cats,
    );
    final result = calculateSupply(
      items: items,
      days: days,
      household: household,
    );

    return _OverviewCard(
      icon: Icons.inventory_2_outlined,
      title: l10n.overviewSupplyTitle(days),
      onOpen: onOpen,
      child: Column(
        children: [
          _Meter(
            label: l10n.supplyCalculatorWaterLabel,
            current: result.waterCurrentLiters,
            target: result.waterTargetLiters,
            text: l10n.overviewSupplyWater(
              NumberFormat.decimalPatternDigits(
                locale: l10n.localeName,
                decimalDigits: 1,
              ).format(result.waterCurrentLiters),
              NumberFormat.decimalPatternDigits(
                locale: l10n.localeName,
                decimalDigits: 1,
              ).format(result.waterTargetLiters),
            ),
          ),
          const SizedBox(height: 12),
          _Meter(
            label: l10n.supplyCalculatorCaloriesLabel,
            current: result.caloriesCurrent.toDouble(),
            target: result.caloriesTarget.toDouble(),
            text: l10n.overviewSupplyCalories(
              result.caloriesCurrent,
              result.caloriesTarget,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled bar. Deliberately a bar and not a ring: two of them stacked
/// compare at a glance, and the number beside it is the actual answer.
class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.current,
    required this.target,
    required this.text,
  });

  final String label;
  final double current;
  final double target;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final short = progress < 1;

    // One gauge, so one thing to hear: without this a screen reader stops
    // three times — on the name, on the figure, and on the bar — and the
    // three only mean anything together. The bar keeps the percentage as
    // its value, which is what it adds over the figure beside it.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(label, style: theme.textTheme.labelLarge),
              Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: short
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              semanticsValue: percentValue(l10n, progress),
            ),
          ),
        ],
      ),
    );
  }
}

/// What is expired, running low or about to run out.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.overview, required this.onOpen});

  final InventoryOverview overview;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final wanted = overview.needsAttention > 0;

    return _OverviewCard(
      icon: wanted ? Icons.error_outline : Icons.check_circle_outline,
      title: l10n.overviewAttentionTitle,
      tone: wanted ? theme.colorScheme.error : null,
      onOpen: onOpen,
      child: overview.isEmpty
          ? Text(l10n.overviewNothingStored, style: theme.textTheme.bodyMedium)
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Stat(
                  value: overview.expired,
                  label: l10n.overviewExpired,
                  emphasise: overview.expired > 0,
                ),
                _Stat(
                  value: overview.lowStock,
                  label: l10n.overviewLowStock,
                  emphasise: overview.lowStock > 0,
                ),
                _Stat(
                  value: overview.expiringSoon,
                  label: l10n.overviewExpiringSoon,
                ),
              ],
            ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.emphasise = false,
  });

  final int value;
  final String label;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = emphasise
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.titleLarge?.copyWith(color: colour),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// How many warnings concern this household right now.
class _WarningCard extends ConsumerWidget {
  const _WarningCard({required this.profile, required this.onOpen});

  final HouseholdProfile profile;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final active = ref.watch(activeWarningsProvider).value ?? const [];

    // The same relevance rule the banner and the notifications use, so
    // the overview cannot claim "nothing" while the banner shows one.
    final mine = active
        .where(
          (warning) => isWarningRelevant(
            warning: warning,
            filter: profile.warningFilter,
          ),
        )
        .toList();

    return _OverviewCard(
      icon: mine.isEmpty
          ? Icons.notifications_none_outlined
          : Icons.warning_amber_rounded,
      title: l10n.navWarnings,
      tone: mine.isEmpty ? null : theme.colorScheme.error,
      onOpen: onOpen,
      trailing: mine.isEmpty
          ? null
          : Chip(
              visualDensity: VisualDensity.compact,
              label: Text('${mine.length}'),
            ),
      child: Text(
        mine.isEmpty ? l10n.overviewNoWarnings : mine.first.headline,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

/// How much of the checklists is ticked off.
class _ChecklistCard extends ConsumerWidget {
  const _ChecklistCard({required this.householdId, required this.onOpen});

  final String householdId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templates =
        ref.watch(checklistTemplatesProvider(householdId)).value ?? const [];
    final items =
        ref.watch(allChecklistItemsProvider(householdId)).value ?? const [];
    final overview = summarizeChecklists(templates: templates, items: items);

    return _OverviewCard(
      icon: Icons.checklist_outlined,
      title: l10n.navChecklists,
      onOpen: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Meter(
            label: l10n.overviewChecklistLists(
              overview.listsComplete,
              overview.lists,
            ),
            current: overview.done.toDouble(),
            target: overview.total.toDouble(),
            text: l10n.checklistProgress(overview.done, overview.total),
          ),
        ],
      ),
    );
  }
}

/// What is in the stores, by category.
class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.overview, required this.onOpen});

  final InventoryOverview overview;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return _OverviewCard(
      icon: Icons.category_outlined,
      title: l10n.overviewResourcesTitle,
      onOpen: onOpen,
      trailing: Text(
        l10n.overviewItemCount(overview.total),
        style: theme.textTheme.labelMedium,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in InventoryItemCategory.values)
            _CategoryChip(
              category: category,
              count: overview.countByCategory[category] ?? 0,
            ),
        ],
      ),
    );
  }
}

/// One category with its count. Shown even at zero — an empty category is
/// the thing worth noticing.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.count});

  final InventoryItemCategory category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final empty = count == 0;

    // `outline` is the token for borders and sits below the contrast a
    // label needs — at 12pt it measures 4.33:1 against the chip, under the
    // 4.5:1 WCAG asks for. `onSurfaceVariant` is the muted *text* token and
    // still reads as the quieter of the two states.
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        categoryIcon(category),
        size: 16,
        color: empty ? theme.colorScheme.onSurfaceVariant : null,
      ),
      label: Text('${localizeCategory(l10n, category)} · $count'),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: empty ? theme.colorScheme.onSurfaceVariant : null,
      ),
    );
  }
}

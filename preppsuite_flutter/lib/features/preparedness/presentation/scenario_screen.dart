import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/adaptive_columns.dart';
import '../../../core/content_swap.dart';
import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../energy/application/energy_l10n.dart';
import '../../energy/application/energy_store.dart';
import '../../household/application/household_providers.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/application/supply_calculator.dart';
import '../../inventory/presentation/shopping_file_share.dart';
import '../application/scenario_export.dart';
import '../application/scenario_gaps.dart';

/// A stretch without power, water or heating, and what the household is
/// short of to get through it (#149).
///
/// See `scenario_gaps.dart`: the need per person is the supply
/// calculator's, everything else the household's own, and where the
/// household has not said, the screen says so instead of filling a
/// number in.
class ScenarioScreen extends ConsumerStatefulWidget {
  const ScenarioScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends ConsumerState<ScenarioScreen> {
  static const _energyStore = EnergyPlanStore();

  var _days = scenarioHorizons.first;

  /// Kept by the energy screen; this one only divides it.
  EnergyPlan? _energy;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEnergy());
  }

  Future<void> _loadEnergy() async {
    final plan = await _energyStore.load();
    if (mounted) setState(() => _energy = plan);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(inventoryItemsProvider(widget.householdId));
    final profile = ref.watch(householdProfileProvider).value;
    final energy = _energy;
    final items = itemsAsync.value;
    final gaps = items == null || energy == null
        ? null
        : scenarioGaps(
            items: items,
            household: SupplyHousehold(
              adults: profile?.personCount ?? 1,
              children: profile?.children ?? 0,
              dogs: profile?.dogs ?? 0,
              cats: profile?.cats ?? 0,
            ),
            energy: energy,
            days: _days,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scenarioTitle),
        actions: [
          if (gaps != null && gaps.hasPurchasableGap)
            IconButton(
              tooltip: l10n.shoppingListExport,
              icon: const Icon(Icons.file_upload_outlined),
              onPressed: () => _export(gaps, l10n),
            ),
        ],
      ),
      body: ContentSwap(
        child: itemsAsync.hasError
            ? Center(child: Text(describeError(l10n, itemsAsync.error!)))
            : gaps == null || energy == null
            ? const Center(child: CircularProgressIndicator())
            : _Body(
                gaps: gaps,
                energy: energy,
                days: _days,
                onDays: (days) => setState(() => _days = days),
              ),
      ),
    );
  }

  Future<void> _export(ScenarioGaps gaps, AppLocalizations l10n) {
    final now = DateTime.now();
    return shareShoppingFile(
      context,
      now: now,
      content: buildScenarioFile(
        gaps,
        waterName: l10n.scenarioWaterLine,
        energyName: (kind) => localizeEnergyKind(l10n, kind),
        energyUnit: (kind) => localizeEnergyUnit(l10n, kind.unit),
        now: now,
        language: Localizations.localeOf(context).languageCode,
        formatAmount: (amount) => _format(l10n, amount),
      ),
    );
  }
}

String _format(AppLocalizations l10n, double value) =>
    NumberFormat.decimalPattern(
      l10n.localeName,
    ).format(double.parse(value.toStringAsFixed(value >= 100 ? 0 : 1)));

class _Body extends StatelessWidget {
  const _Body({
    required this.gaps,
    required this.energy,
    required this.days,
    required this.onDays,
  });

  final ScenarioGaps gaps;
  final EnergyPlan energy;
  final int days;
  final ValueChanged<int> onDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    String amount(double value, String unit) =>
        '${_format(l10n, value)} $unit'.trim();

    // In columns on a wide window (#47): the four resources side by side
    // read as the one comparison they are.
    return AdaptiveColumns(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      columnWidth: 420,
      spacing: 12,
      blocks: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.scenarioIntro),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: [
                for (final horizon in scenarioHorizons)
                  ButtonSegment(
                    value: horizon,
                    label: Text(
                      horizon == 3
                          ? l10n.scenarioHorizonHours
                          : l10n.scenarioHorizonDays(horizon),
                    ),
                  ),
              ],
              selected: {days},
              onSelectionChanged: (selection) => onDays(selection.single),
            ),
          ],
        ),
        _Section(
          icon: Icons.water_drop_outlined,
          title: l10n.scenarioWater,
          lines: [
            _GapLine(
              text: l10n.scenarioNeedHave(
                amount(gaps.waterNeeded, 'l'),
                amount(gaps.waterStored, 'l'),
              ),
              computed: true,
              missing: gaps.waterMissing > 0
                  ? amount(gaps.waterMissing, 'l')
                  : null,
            ),
          ],
        ),
        _Section(
          icon: Icons.restaurant_outlined,
          title: l10n.scenarioFood,
          lines: [
            _GapLine(
              text: l10n.scenarioNeedHave(
                amount(gaps.kcalNeeded.toDouble(), 'kcal'),
                amount(gaps.kcalStored.toDouble(), 'kcal'),
              ),
              computed: true,
              missing: gaps.kcalMissing > 0
                  ? amount(gaps.kcalMissing.toDouble(), 'kcal')
                  : null,
            ),
          ],
        ),
        _Section(
          icon: Icons.medication_outlined,
          title: l10n.scenarioMedicine,
          lines: [
            if (gaps.medicines.isEmpty && gaps.medicinesWithoutDose.isEmpty)
              _GapLine(text: l10n.scenarioNoMedicines),
            for (final medicine in gaps.medicines)
              _GapLine(
                title: medicine.item.name,
                text: l10n.scenarioNeedHave(
                  amount(medicine.needed, medicine.item.unit),
                  amount(medicine.available, medicine.item.unit),
                ),
                computed: true,
                missing: medicine.missing > 0
                    ? amount(medicine.missing, medicine.item.unit)
                    : null,
              ),
            if (gaps.medicinesWithoutDose.isNotEmpty)
              _GapLine(
                text: l10n.scenarioWithoutDose(
                  gaps.medicinesWithoutDose.map((item) => item.name).join(', '),
                ),
              ),
          ],
        ),
        _Section(
          icon: Icons.local_fire_department_outlined,
          title: l10n.scenarioEnergy,
          lines: [
            if (energy.draws.isEmpty) _GapLine(text: l10n.scenarioNoEnergyPlan),
            for (final kind in gaps.energy)
              _GapLine(
                title: [
                  localizeEnergyKind(l10n, kind.kind),
                  if (kind.uses.isNotEmpty)
                    l10n.scenarioEnergyUses(kind.uses.join(', ')),
                ].join(' '),
                text: l10n.scenarioNeedHave(
                  amount(kind.needed, localizeEnergyUnit(l10n, kind.kind.unit)),
                  amount(kind.stored, localizeEnergyUnit(l10n, kind.kind.unit)),
                ),
                computed: true,
                missing: kind.missing > 0
                    ? amount(
                        kind.missing,
                        localizeEnergyUnit(l10n, kind.kind.unit),
                      )
                    : null,
              ),
            if (gaps.energyUnused.isNotEmpty)
              _GapLine(
                text: l10n.scenarioEnergyUnused(
                  gaps.energyUnused
                      .map((kind) => localizeEnergyKind(l10n, kind))
                      .join(', '),
                ),
              ),
          ],
        ),
        Text(
          l10n.scenarioSource,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<Widget> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lines,
          ],
        ),
      ),
    );
  }
}

/// One thing over the stretch: what it needs against what there is, and
/// what is missing -- said in words, not only in red.
class _GapLine extends StatelessWidget {
  const _GapLine({
    this.title,
    required this.text,
    this.missing,
    this.computed = false,
  });

  final String? title;
  final String text;

  /// The amount missing, or null when it is covered or cannot be said.
  final String? missing;

  /// Whether this line is an answer at all, so that nothing missing can
  /// be said as "covered" rather than left blank.
  final bool computed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) Text(title!, style: theme.textTheme.titleSmall),
          Text(text),
          if (missing != null)
            Text(
              l10n.scenarioMissing(missing!),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (computed)
            Text(
              l10n.scenarioCovered,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

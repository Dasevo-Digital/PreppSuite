import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../household/application/household_providers.dart';
import '../application/package_nutrition.dart';
import '../application/storage_plan.dart';
import '../application/storage_plan_l10n.dart';
import 'inventory_item_form_screen.dart';
import 'prepper_recipes_screen.dart';

import 'package:url_launcher/url_launcher.dart';

/// The BLE's stockpiling tables, scaled to this household.
///
/// The table is printed for one person and ten days, which is not a
/// number anybody shops by. Scaling it here is the whole point of showing
/// it inside the app rather than linking to the PDF — and every row can
/// be carried straight into the inventory, so the list is a starting
/// point rather than a picture of one.
class StorageTipsScreen extends ConsumerStatefulWidget {
  const StorageTipsScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<StorageTipsScreen> createState() => _StorageTipsScreenState();
}

class _StorageTipsScreenState extends ConsumerState<StorageTipsScreen> {
  StorageDiet _diet = StorageDiet.mixed;
  int _days = StoragePlan.baseDays;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(householdProfileProvider).value;

    // Adults and children both eat; the pets in the profile do not eat
    // from this table, and adding them would overstate every row.
    final people = ((profile?.personCount ?? 1) + (profile?.children ?? 0))
        .clamp(1, 999);

    final plan = storagePlanFor(_diet);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storageTipsTitle),
        actions: [
          IconButton(
            tooltip: l10n.prepperRecipesTitle,
            icon: const Icon(Icons.soup_kitchen_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    PrepperRecipesScreen(householdId: widget.householdId),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(l10n.storageTipsIntro, style: _text(context).bodyMedium),
          const SizedBox(height: 16),
          SegmentedButton<StorageDiet>(
            segments: [
              for (final diet in StorageDiet.values)
                ButtonSegment(
                  value: diet,
                  label: Text(localizeDiet(l10n, diet)),
                ),
            ],
            selected: {_diet},
            onSelectionChanged: (selection) =>
                setState(() => _diet = selection.first),
          ),
          const SizedBox(height: 16),
          _ScaleCard(
            people: people,
            days: _days,
            onDaysChanged: (value) => setState(() => _days = value),
          ),
          const SizedBox(height: 16),
          for (final group in plan.groups)
            _GroupTile(
              group: group,
              people: people,
              days: _days,
              householdId: widget.householdId,
            ),
          const SizedBox(height: 16),
          const _GeneralTips(),
          const SizedBox(height: 8),
          const _VeganNote(),
          const SizedBox(height: 8),
          const _NutrientLegend(),
          const SizedBox(height: 8),
          const _SourceNote(),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://www.ernaehrungsvorsorge.de/private-vorsorge/notvorrat/vorratskalkulator',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: Text(l10n.storageOfficialCalculator),
              ),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://www.ernaehrungsvorsorge.de/private-vorsorge/empfehlungen-tipps/so-koennen-lebensmittel-haltbar-gemacht-werden',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.storageOfficialTips),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

TextTheme _text(BuildContext context) => Theme.of(context).textTheme;

/// Who and how long the amounts below are for.
///
/// The person count is shown, not edited: it belongs to the household,
/// and a second place to set it is exactly how the inventory screen's own
/// count came to disagree with it.
class _ScaleCard extends StatelessWidget {
  const _ScaleCard({
    required this.people,
    required this.days,
    required this.onDaysChanged,
  });

  final int people;
  final int days;
  final ValueChanged<int> onDaysChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.storagePeopleLine(people),
              style: _text(context).bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.storageDaysLabel(days),
                    style: _text(context).titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: l10n.storageFewerDays,
                  onPressed: days > 1 ? () => onDaysChanged(days - 1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: l10n.storageMoreDays,
                  onPressed: () => onDaysChanged(days + 1),
                ),
              ],
            ),
            if (days != StoragePlan.baseDays) ...[
              const SizedBox(height: 4),
              Text(l10n.storageScaledNote, style: _text(context).bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.people,
    required this.days,
    required this.householdId,
  });

  final StorageGroup group;
  final int people;
  final int days;
  final String householdId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = scaleAmount(group.totalAmount, group.totalUnit, people, days);
    final footnote = storageGroupFootnote(l10n, group);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(storageGroupName(l10n, group)),
        subtitle: Text(formatStorageAmount(l10n, total, group.totalUnit)),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (final food in group.foods)
            _FoodRow(
              food: food,
              people: people,
              days: days,
              householdId: householdId,
            ),
          if (footnote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(footnote, style: _text(context).bodySmall),
            ),
        ],
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({
    required this.food,
    required this.people,
    required this.days,
    required this.householdId,
  });

  final StorageFood food;
  final int people;
  final int days;
  final String householdId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = scaleAmount(food.amount, food.unit, people, days);
    final note = storageFoodNote(l10n, food);

    // A row that is only a heading for its alternatives has no energy of
    // its own; the amount belongs to whichever one is chosen.
    final kcal = _scaledKcal(food.totalKcal);

    return ListTile(
      dense: true,
      title: Text(storageFoodName(l10n, food)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              formatStorageAmount(l10n, amount, food.unit),
              if (kcal != null) l10n.storageKcal(kcal),
              ?note,
            ].join(' · '),
          ),
          if (food.nutrients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final nutrient in food.nutrients)
                    _NutrientChip(nutrient: nutrient),
                ],
              ),
            ),
          for (final variant in food.variants)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.storageVariantLine(
                  storageVariantName(l10n, variant),
                  _scaledKcal(variant.totalKcal)!,
                ),
                style: _text(context).bodySmall,
              ),
            ),
        ],
      ),
      isThreeLine: food.nutrients.isNotEmpty || food.variants.isNotEmpty,
      trailing: IconButton(
        icon: const Icon(Icons.add_shopping_cart_outlined),
        tooltip: l10n.storageAddToInventory,
        onPressed: () => _addToInventory(context, l10n, amount, _per100Kcal()),
      ),
    );
  }

  int? _scaledKcal(int? base) => base == null
      ? null
      : (base * people * days / (StoragePlan.basePeople * StoragePlan.baseDays))
            .round();

  /// The table's energy per 100 g, or per 100 ml for a drink.
  ///
  /// The basis the inventory stores, and the one the table already
  /// carries in `kcalPer100` — so for most rows this is simply that
  /// figure. It is derived from the total and the amount instead, because
  /// the two agree (a test holds them to it) and the quotient also
  /// answers the rows that print no per-100 value of their own.
  double? _per100Kcal() {
    final total = food.totalKcal;
    if (total == null || food.amount <= 0) return null;

    switch (food.unit) {
      // Grams: the total over the amount is per gram, so times 100.
      case StorageUnit.gram:
        return total / food.amount * 100;
      // Litres: the amount is in litres and the basis is 100 ml, so a
      // litre holds ten times the per-100-ml figure.
      case StorageUnit.liter:
        return total / food.amount / 10;
      // A piece has no per-100 basis of its own, so it goes through the
      // weight [_pieceGrams] gives it — the same weight [_forInventory]
      // uses to turn the row into grams, so the two cannot disagree.
      case StorageUnit.piece:
        final grams = _pieceGrams();
        if (grams == null || grams <= 0) return null;
        return total / (food.amount * grams) * 100;
    }
  }

  /// What one piece of this row weighs, from the table's own arithmetic.
  ///
  /// The BLE prints eggs as "5 Stück" inside a group it totals in grams,
  /// and the group total minus the other rows leaves 295 g — 59 g an egg,
  /// which is weight class M. The figure is the source's, not this app's.
  double? _pieceGrams() => food.unit == StorageUnit.piece ? 59 : null;

  /// The row's amount in the unit the inventory will hold it in.
  ///
  /// Pieces become grams, because food is counted in a measure now and a
  /// per-100 figure cannot be applied to an egg. Everything else is the
  /// table's own unit.
  (double amount, String unit) _forInventory(
    AppLocalizations l10n,
    double amount,
  ) => switch (food.unit) {
    StorageUnit.piece => (
      amount * (_pieceGrams() ?? 1),
      l10n.storageUnitGram,
    ),
    _ => (amount, _unitLabel(l10n, food.unit)),
  };

  Future<void> _addToInventory(
    BuildContext context,
    AppLocalizations l10n,
    double amount,
    double? kcalPer100,
  ) async {
    final forInventory = _forInventory(l10n, amount);
    // The form opens rather than the row being written straight in: the
    // table says nothing about where this household keeps things or how
    // long its tin will last, and both are required fields.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryItemFormScreen(
          householdId: householdId,
          draft: InventoryItemDraft(
            name: storageFoodName(l10n, food),
            quantity: forInventory.$1,
            unit: forInventory.$2,
            nutrition: PackageNutrition(kcal: kcalPer100),
            notes: l10n.storageFromTableNote,
          ),
        ),
      ),
    );
  }
}

String _unitLabel(AppLocalizations l10n, StorageUnit unit) => switch (unit) {
  StorageUnit.gram => l10n.storageUnitGram,
  StorageUnit.liter => l10n.storageUnitLiter,
  StorageUnit.piece => l10n.storageUnitPiece,
};

class _NutrientChip extends StatelessWidget {
  const _NutrientChip({required this.nutrient});

  final StorageNutrient nutrient;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(nutrientIcon(nutrient), size: 14),
      label: Text(localizeNutrient(l10n, nutrient)),
      labelStyle: _text(context).labelSmall,
      padding: EdgeInsets.zero,
    );
  }
}

class _GeneralTips extends StatelessWidget {
  const _GeneralTips();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tips = [
      l10n.storageTipRotate,
      l10n.storageTipCoolDryDark,
      l10n.storageTipEatWhatYouStore,
      l10n.storageTipNoPower,
      l10n.storageTipReadyToEat,
      l10n.storageTipCanOpener,
      l10n.storageTipSpecialNeeds,
    ];

    return Card(
      child: ExpansionTile(
        title: Text(l10n.storageTipsGeneralTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('· '),
                  Expanded(child: Text(tip, style: _text(context).bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VeganNote extends StatelessWidget {
  const _VeganNote();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ExpansionTile(
        title: Text(l10n.storageVeganTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(l10n.storageVeganBody, style: _text(context).bodyMedium),
        ],
      ),
    );
  }
}

class _NutrientLegend extends StatelessWidget {
  const _NutrientLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ExpansionTile(
        title: Text(l10n.storageNutrientLegendTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            l10n.storageNutrientLegendBody,
            style: _text(context).bodyMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final nutrient in StorageNutrient.values)
                _NutrientChip(nutrient: nutrient),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ExpansionTile(
        title: Text(l10n.storageSourceTitle),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(l10n.storageSourceBody, style: _text(context).bodyMedium),
        ],
      ),
    );
  }
}

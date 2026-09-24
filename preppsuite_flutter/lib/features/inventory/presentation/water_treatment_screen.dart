import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// What to do with water that is not drinkable yet.
///
/// The app counts litres, warns before they expire and puts "Wasserfilter
/// oder Entkeimungsmittel" on a shopping list. Nowhere did it say what
/// those things do — which is the one question that arrives on the day
/// the tap is off, and the one the household cannot answer from the
/// number in the inventory.
///
/// The order is deliberate: what no method fixes comes first. Boiling a
/// bucket of water from a flooded street is a way of feeling safer while
/// drinking the same chemicals, and that is worth saying before any
/// instruction that sounds reassuring.
class WaterTreatmentScreen extends StatelessWidget {
  const WaterTreatmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.waterTreatmentTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(l10n.waterTreatmentIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.science_outlined,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.waterTreatmentChemistryTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.waterTreatmentChemistryBody,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Method(
            icon: Icons.local_fire_department_outlined,
            title: l10n.waterTreatmentBoilTitle,
            lines: [
              l10n.waterTreatmentBoilCloudy,
              l10n.waterTreatmentBoilStep,
              l10n.waterTreatmentBoilStore,
            ],
          ),
          _Method(
            icon: Icons.medication_liquid_outlined,
            title: l10n.waterTreatmentChlorineTitle,
            lines: [
              l10n.waterTreatmentChlorineStep,
              l10n.waterTreatmentChlorineLimit,
            ],
          ),
          _Method(
            icon: Icons.filter_alt_outlined,
            title: l10n.waterTreatmentFilterTitle,
            lines: [l10n.waterTreatmentFilterBody],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.waterTreatmentSources,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            for (final line in lines) ...[
              const SizedBox(height: 10),
              Text(line),
            ],
          ],
        ),
      ),
    );
  }
}

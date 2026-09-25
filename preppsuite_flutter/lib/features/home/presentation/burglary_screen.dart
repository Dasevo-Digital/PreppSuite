import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../possessions/presentation/possessions_screen.dart';

/// What the police say about a burglary — while it is happening, after it,
/// and before it.
///
/// The acute half comes first, which is the opposite of how every leaflet
/// on the subject is laid out. A leaflet is read on a quiet afternoon; a
/// screen is opened by somebody who has just heard a noise downstairs, and
/// for them the first sentence has to be the one that keeps them alive.
/// Prevention is further down, where it is read on the quiet afternoon
/// after all.
///
/// Everything here is reproduced from the crime prevention body of the
/// federal states and the federation and from its K-EINBRUCH campaign.
/// This app states nothing of its own about it — the same rule the first
/// aid guides and the hazardous-release page follow.
class BurglaryScreen extends StatelessWidget {
  const BurglaryScreen({super.key, required this.householdId});

  /// Only needed to open the household inventory further down. The rest
  /// of the page is the same for everybody.
  final String householdId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.burglaryTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
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
                        Icons.shield_outlined,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.burglaryRuleTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.burglaryRuleBody,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Steps(
            icon: Icons.directions_run_outlined,
            title: l10n.burglaryCaughtTitle,
            steps: [
              l10n.burglaryCaughtLeave,
              l10n.burglaryCaughtWindow,
              l10n.burglaryCaughtCall,
              l10n.burglaryCaughtDescribe,
            ],
          ),
          const SizedBox(height: 16),
          _Steps(
            icon: Icons.fact_check_outlined,
            title: l10n.burglaryAfterTitle,
            steps: [
              l10n.burglaryAfterThreat,
              l10n.burglaryAfterReport,
              l10n.burglaryAfterNoTidy,
              l10n.burglaryAfterList,
              l10n.burglaryAfterKeys,
              l10n.burglaryAfterPhone,
            ],
          ),
          const SizedBox(height: 8),
          // The one place where a police leaflet and this app meet by
          // themselves: "Vielleicht haben Sie auch schon eine
          // Wertgegenstandsliste". The household inventory was built for
          // an insurer and turns out to be exactly that list.
          _PossessionsCard(l10n: l10n, householdId: householdId),
          const SizedBox(height: 16),
          Text(l10n.burglaryPreventTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final line in [
            l10n.burglaryPreventWho,
            l10n.burglaryPreventDay,
            l10n.burglaryPreventMechanical,
            l10n.burglaryPreventNew,
            l10n.burglaryPreventRetro,
            l10n.burglaryPreventSide,
            l10n.burglaryPreventFit,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(line),
            ),
          const SizedBox(height: 8),
          Text(l10n.burglarySource, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Opens the household inventory.
class _PossessionsCard extends StatelessWidget {
  const _PossessionsCard({required this.l10n, required this.householdId});

  final AppLocalizations l10n;
  final String householdId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.chair_outlined),
        title: Text(l10n.burglaryPossessionsLink),
        subtitle: Text(l10n.burglaryPossessionsHint),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PossessionsScreen(householdId: householdId),
          ),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.icon, required this.title, required this.steps});

  final IconData icon;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
          ],
        ),
        const SizedBox(height: 12),
        for (final (index, step) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(step)),
              ],
            ),
          ),
      ],
    );
  }
}

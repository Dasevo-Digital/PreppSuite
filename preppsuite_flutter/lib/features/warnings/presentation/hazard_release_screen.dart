import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'iodine_tablets_screen.dart';

/// What to do when a warning says something has been released.
///
/// The app already measures gamma radiation, shows an air quality index
/// and receives the official warnings — and said nothing at all about the
/// one sentence those warnings actually carry: close your windows. The
/// measurement screens are careful never to interpret a number; this
/// screen is the other half, and it interprets nothing either. Every line
/// is the BBK's own instruction, reproduced, with the source underneath.
///
/// The card in the middle is the reason this is one screen and not three
/// bullet lists. Chemical and radioactive releases give opposite answers
/// to the same question — cellar or not — and a household that remembers
/// the wrong half of that has been actively misled. The BBK resolves it
/// in one sentence, so this screen puts that sentence where it cannot be
/// missed.
class HazardReleaseScreen extends StatelessWidget {
  const HazardReleaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hazardReleaseTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(l10n.hazardReleaseIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          _Steps(
            icon: Icons.home_outlined,
            title: l10n.hazardReleaseHomeTitle,
            steps: [
              l10n.hazardReleaseHomeStay,
              l10n.hazardReleaseHomeWindows,
              l10n.hazardReleaseHomeVent,
              l10n.hazardReleaseHomeRoom,
              l10n.hazardReleaseHomeCandles,
              l10n.hazardReleaseHomeRadio,
              l10n.hazardReleaseHomePhone,
              l10n.hazardReleaseHomeMask,
              l10n.hazardReleaseHomeWait,
            ],
          ),
          const SizedBox(height: 16),
          // Between the two lists on purpose: whoever is outside is on
          // their way in, and this is the question they arrive with.
          Card(
            color: theme.colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.swap_vert,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.hazardReleaseCellarTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final line in [
                    l10n.hazardReleaseCellarChemical,
                    l10n.hazardReleaseCellarRadio,
                    l10n.hazardReleaseCellarNote,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        line,
                        style: TextStyle(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Steps(
            icon: Icons.directions_walk_outlined,
            title: l10n.hazardReleaseOutsideTitle,
            steps: [
              l10n.hazardReleaseOutsideCross,
              l10n.hazardReleaseOutsideBuilding,
              l10n.hazardReleaseOutsideClothes,
              l10n.hazardReleaseOutsideWash,
              l10n.hazardReleaseOutsideBio,
            ],
          ),
          const SizedBox(height: 16),
          _Steps(
            icon: Icons.directions_car_outlined,
            title: l10n.hazardReleaseCarTitle,
            steps: [
              l10n.hazardReleaseCarVent,
              l10n.hazardReleaseCarRadio,
              l10n.hazardReleaseCarBuilding,
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.medication_outlined),
              title: Text(l10n.hazardReleaseIodineLink),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const IodineTabletsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.hazardReleaseSource, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// A numbered list of instructions.
///
/// Numbered rather than bulleted because the BBK's order is the order to
/// do them in — closing the windows before finding the inner room is not
/// the same plan in a different sequence.
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
                // Fixed width so every line of text starts on the same
                // vertical, the same reason the first aid steps do it.
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

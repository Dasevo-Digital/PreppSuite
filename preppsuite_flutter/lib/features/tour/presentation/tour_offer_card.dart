import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/crisis_mode_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../preparedness/application/current_situation.dart';
import '../../warnings/application/warning_providers.dart';
import '../application/app_tour.dart';

/// The overview's offer of the tour, until it is taken or declined.
///
/// A card in the list and never a dialog: the overview is also what
/// opens when somebody reaches for the app because something is
/// happening, and a window to be dismissed first is the last thing they
/// need. For the same reason it stays away while crisis mode is on or a
/// severe warning concerns the household — it comes back once things are
/// quiet, because it has not been answered.
class TourOfferCard extends ConsumerWidget {
  const TourOfferCard({super.key, required this.profile});

  final HouseholdProfile profile;

  /// Whether the card would show now. The overview asks, so that it can
  /// leave out the gap below the card along with the card.
  static bool showsFor(WidgetRef ref, HouseholdProfile profile) {
    if (!ref.watch(tourOfferProvider)) return false;
    if (ref.watch(appTourProvider) != null) return false;
    if (ref.watch(crisisModeProvider)) return false;
    final warnings = ref.watch(activeWarningsProvider).value ?? const [];
    return currentSituation(warnings: warnings, profile: profile).isQuiet;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tour_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.tourOfferTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.tourOfferBody(TourStop.values.length)),
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () =>
                      ref.read(tourOfferProvider.notifier).answer(),
                  child: Text(l10n.tourOfferDismiss),
                ),
                FilledButton.icon(
                  onPressed: () => ref.read(appTourProvider.notifier).start(),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.tourOfferStart),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The question mark that starts the tour again, for the app bar.
class TourButton extends ConsumerWidget {
  const TourButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.help_outline),
      tooltip: l10n.tourOpen,
      onPressed: () => ref.read(appTourProvider.notifier).start(),
    );
  }
}

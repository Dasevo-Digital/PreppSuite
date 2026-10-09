import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/household_profile.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/warning_providers.dart';
import '../application/warning_relevance.dart';
import '../application/warning_severity_l10n.dart';
import '../application/warning_sync_controller.dart';
import 'warning_list_screen.dart';

/// App-wide banner showing the most severe active warning, if any. Meant to
/// sit above the tab content in [HomeShell] so it's visible regardless of
/// which tab is open.
class WarningBanner extends ConsumerWidget {
  const WarningBanner({super.key, required this.profile});

  final HouseholdProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the warning poll alive for as long as any screen is showing
    // (this widget lives above all tabs in HomeShell). Keyed by the whole
    // household rather than its id: the poll needs the country and the
    // region to know what to fetch.
    ref.watch(warningSyncControllerProvider(profile));
    final l10n = AppLocalizations.of(context)!;
    final warningsAsync = ref.watch(activeWarningsProvider);

    return warningsAsync.maybeWhen(
      data: (all) {
        // Only what concerns this household. Every other reader of
        // `activeWarningsProvider` — the overview card, the destination
        // badge, the emergency screen — already filters this way, and
        // this one did not: a minor bomb disposal in Dulmen sat across
        // the top of every tab of a household in Braunschweig, with
        // "+7 more" behind it, while the badge beside it showed 1. The
        // banner is the thing that must be seen without looking, which
        // makes it the worst place to put somebody else's warning.
        //
        // The screen behind it still lists them — that is where the ones
        // concerning somewhere else belong.
        //
        // And of those, what is happening here and now (#11): another
        // district of the same Land only when extreme, nothing that has
        // not begun yet. See [bannerWarnings].
        final sorted = bannerWarnings(
          warnings: all,
          filter: profile.warningFilter,
          now: DateTime.now(),
        );
        if (sorted.isEmpty) return const SizedBox.shrink();
        final mostSevere = sorted.first;
        final severity = warningSeverityFromName(mostSevere.severity);

        final colors = warningSeverityColors(context, severity);

        return Material(
          color: colors.background,
          // Both of these, or the highest severity is unreadable: `error`
          // is a saturated red and the inherited `onSurface` sits at
          // 1.32:1 on it in dark mode. Set on the Material rather than on
          // each Text, so a widget added here later cannot miss it.
          textStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.foreground),
          child: IconTheme.merge(
            data: IconThemeData(color: colors.foreground),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WarningListScreen(profile: profile),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      // The severity is spelled out rather than left to the
                      // colour. Red-green colour blindness is common enough
                      // that a civil-protection banner cannot encode
                      // "extreme" versus "minor" in hue alone — and a
                      // screen reader reads no colour at all.
                      child: Text(
                        l10n.warningBannerSeverity(
                          localizeWarningSeverity(l10n, severity),
                          mostSevere.headline,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sorted.length > 1) ...[
                      const SizedBox(width: 8),
                      Text(l10n.warningBannerMore(sorted.length - 1)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart' show Household;

import '../../../l10n/generated/app_localizations.dart';
import '../../household/application/household_providers.dart';
import '../application/warning_providers.dart';
import '../application/warning_relevance.dart';
import '../application/warning_severity_l10n.dart';
import '../application/warning_sync_controller.dart';
import 'warning_list_screen.dart';

/// App-wide banner showing the most severe active warning, if any. Meant to
/// sit above the tab content in [HomeShell] so it's visible regardless of
/// which tab is open.
class WarningBanner extends ConsumerWidget {
  const WarningBanner({super.key, required this.household});

  final Household household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the warning poll alive for as long as any screen is showing
    // (this widget lives above all tabs in HomeShell). Keyed by the whole
    // household rather than its id: the poll needs the country and the
    // region to know what to fetch.
    ref.watch(warningSyncControllerProvider(household));
    final l10n = AppLocalizations.of(context)!;
    final warningsAsync = ref.watch(activeWarningsProvider);
    final subscriptions =
        ref.watch(householdWarningRegionsProvider(household.id!)).value ??
        const [];

    return warningsAsync.maybeWhen(
      data: (warnings) {
        if (warnings.isEmpty) return const SizedBox.shrink();

        // Severity is still the primary sort key — an extreme nationwide
        // warning must never be buried behind a minor local one — but
        // among warnings of the same severity, the more regionally
        // relevant one surfaces first.
        final sorted = [...warnings]
          ..sort((a, b) {
            final severityCompare =
                warningSeverityRank(
                  warningSeverityFromName(b.severity),
                ).compareTo(
                  warningSeverityRank(warningSeverityFromName(a.severity)),
                );
            if (severityCompare != 0) return severityCompare;
            return warningRelevanceRank(
              warning: b,
              household: household,
              subscriptions: subscriptions,
            ).compareTo(
              warningRelevanceRank(
                warning: a,
                household: household,
                subscriptions: subscriptions,
              ),
            );
          });
        final mostSevere = sorted.first;
        final severity = warningSeverityFromName(mostSevere.severity);

        return Material(
          color: warningSeverityColor(context, severity),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WarningListScreen(household: household),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mostSevere.headline,
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
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/warning_providers.dart';
import '../application/warning_severity_l10n.dart';
import '../application/warning_sync_controller.dart';
import 'warning_list_screen.dart';

/// App-wide banner showing the most severe active warning, if any. Meant to
/// sit above the tab content in [HomeShell] so it's visible regardless of
/// which tab is open.
class WarningBanner extends ConsumerWidget {
  const WarningBanner({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the pull-only warning sync alive for as long as any screen is
    // showing (this widget lives above all tabs in HomeShell).
    ref.watch(warningSyncControllerProvider(householdId));
    final l10n = AppLocalizations.of(context)!;
    final warningsAsync = ref.watch(activeWarningsProvider);

    return warningsAsync.maybeWhen(
      data: (warnings) {
        if (warnings.isEmpty) return const SizedBox.shrink();

        final sorted = [...warnings]..sort(
          (a, b) => warningSeverityRank(
            warningSeverityFromName(b.severity),
          ).compareTo(warningSeverityRank(warningSeverityFromName(a.severity))),
        );
        final mostSevere = sorted.first;
        final severity = warningSeverityFromName(mostSevere.severity);

        return Material(
          color: warningSeverityColor(context, severity),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WarningListScreen()),
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

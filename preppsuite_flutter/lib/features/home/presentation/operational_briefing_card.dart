import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/app_ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../inventory/application/charge_reminder_provider.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../knowledge/application/knowledge_providers.dart';
import '../../maps/application/offline_map_providers.dart';
import '../../warnings/application/warning_providers.dart';
import '../../warnings/application/warning_relevance.dart';
import '../application/shell_layout.dart';

/// The single first answer on the overview: what needs attention now.
///
/// This intentionally combines only facts the app has already established.
/// It does not manufacture a risk score from an empty pantry or a quiet
/// warning feed. A quiet feed says just that, and an unopened readiness task
/// stays a concrete next action.
class OperationalBriefingCard extends ConsumerWidget {
  const OperationalBriefingCard({
    super.key,
    required this.profile,
    required this.onNavigate,
  });

  final HouseholdProfile profile;
  final ValueChanged<ShellDestination> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final inventory =
        ref.watch(inventoryItemsProvider(profile.id)).value ?? const [];
    final equipment = ref.watch(chargeCheckProvider);
    final mapReady = ref.watch(offlineMapProvider).value?.isReady ?? false;
    final knowledgeReady = ref.watch(knowledgeProvider).value?.isReady ?? false;
    final warnings = (ref.watch(activeWarningsProvider).value ?? const [])
        .where(
          (warning) => isWarningRelevant(
            warning: warning,
            filter: profile.warningFilter,
          ),
        )
        .toList();

    final _Briefing briefing;
    if (warnings.isNotEmpty) {
      briefing = _Briefing(
        icon: Icons.warning_amber_rounded,
        title: l10n.operationsWarning,
        detail: l10n.operationsWarningDetail,
        action: l10n.operationsOpenWarnings,
        destination: ShellDestination.warnings,
        foreground: theme.colorScheme.onErrorContainer,
        background: theme.colorScheme.errorContainer,
      );
    } else if (inventory.isEmpty) {
      briefing = _Briefing(
        icon: Icons.inventory_2_outlined,
        title: l10n.operationsQuiet,
        detail: l10n.operationsNextTask(l10n.operationsInventoryMissing),
        action: l10n.operationsOpenReadiness,
        destination: ShellDestination.inventory,
        foreground: theme.colorScheme.onPrimaryContainer,
        background: theme.colorScheme.primaryContainer,
      );
    } else if (!equipment.isOff &&
        (equipment.lastChecked == null || equipment.isDue())) {
      briefing = _Briefing(
        icon: Icons.battery_charging_full_outlined,
        title: l10n.operationsQuiet,
        detail: l10n.operationsNextTask(l10n.operationsChargeDue),
        action: l10n.operationsOpenReadiness,
        destination: ShellDestination.settings,
        foreground: theme.colorScheme.onPrimaryContainer,
        background: theme.colorScheme.primaryContainer,
      );
    } else {
      briefing = _Briefing(
        icon: Icons.verified_outlined,
        title: l10n.operationsQuiet,
        detail: l10n.operationsReady,
        action: l10n.operationsOpenReadiness,
        destination: ShellDestination.emergency,
        foreground: theme.colorScheme.onPrimaryContainer,
        background: theme.colorScheme.primaryContainer,
      );
    }

    // Two things the first version kept in one card. The red card held the
    // sentence about the warning *and* whether the map and the library are
    // there, which have nothing to do with it; and at a third of a phone's
    // height it left the rest of the page below the fold. The card answers
    // one question now, and what is there offline is a line under it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label:
              '${l10n.operationsTitle}: ${briefing.title}. ${briefing.detail}',
          child: Card(
            color: briefing.background,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(
                        briefing.icon,
                        background: briefing.foreground.withValues(alpha: 0.12),
                        foreground: briefing.foreground,
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.operationsTitle.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: briefing.foreground,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              briefing.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: briefing.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    briefing.detail,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: briefing.foreground,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: briefing.foreground,
                      ),
                      iconAlignment: IconAlignment.end,
                      onPressed: () => onNavigate(briefing.destination),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text(briefing.action),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Wrap(
          spacing: AppSpace.sm,
          children: [
            // Zwei Beschriftungen und nicht eine: der Eintrag steht für
            // sich, und „Offline-Wissen verfügbar" ist eine Behauptung. Sie
            // stand auf einem Telefon, auf dem gar keine Wissensdatei lag —
            // daneben nur ein graues Buchsymbol statt eines grünen Hakens.
            // Wer liest, liest den Satz.
            _ReadinessChip(
              icon: Icons.map_outlined,
              label: mapReady ? l10n.readinessMap : l10n.readinessMapMissing,
              ready: mapReady,
              onTap: () => onNavigate(ShellDestination.map),
            ),
            _ReadinessChip(
              icon: Icons.menu_book_outlined,
              label: knowledgeReady
                  ? l10n.readinessKnowledge
                  : l10n.readinessKnowledgeMissing,
              ready: knowledgeReady,
              onTap: () => onNavigate(ShellDestination.knowledge),
            ),
          ],
        ),
      ],
    );
  }
}

class _Briefing {
  const _Briefing({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
    required this.destination,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String action;
  final ShellDestination destination;
  final Color foreground;
  final Color background;
}

/// Whether the map or the library is there, and the way to it.
///
/// A plain row with a tap on it rather than a chip: there are two of them,
/// but they stand on the first screen of the app, and what is missing here
/// is a thing to go and fix, so the line leads there.
class _ReadinessChip extends StatelessWidget {
  const _ReadinessChip({
    required this.icon,
    required this.label,
    required this.ready,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool ready;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ready
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.small),
      onTap: onTap,
      // At least a finger high, though the text is small print: it is a
      // way somewhere, and 32 points of it failed the tap-target guideline.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ready ? Icons.check_circle_outline : icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: AppSpace.xs + 2),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

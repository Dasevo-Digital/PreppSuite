import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Semantics(
      container: true,
      label: '${l10n.operationsTitle}: ${briefing.title}. ${briefing.detail}',
      child: Card(
        color: briefing.background,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: briefing.foreground.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(briefing.icon, color: briefing.foreground),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      briefing.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: briefing.foreground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      briefing.detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: briefing.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: briefing.foreground,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () => onNavigate(briefing.destination),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(briefing.action),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Zwei Beschriftungen und nicht eine: der Chip
                        // steht fuer sich, und „Offline-Wissen
                        // verfuegbar" ist eine Behauptung. Sie stand auf
                        // einem Telefon, auf dem gar keine Wissensdatei
                        // lag — daneben nur ein graues Buchsymbol statt
                        // eines gruenen Hakens. Wer liest, liest den
                        // Satz.
                        _ReadinessChip(
                          icon: Icons.map_outlined,
                          label: mapReady
                              ? l10n.readinessMap
                              : l10n.readinessMapMissing,
                          ready: mapReady,
                        ),
                        _ReadinessChip(
                          icon: Icons.menu_book_outlined,
                          label: knowledgeReady
                              ? l10n.readinessKnowledge
                              : l10n.readinessKnowledgeMissing,
                          ready: knowledgeReady,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

class _ReadinessChip extends StatelessWidget {
  const _ReadinessChip({
    required this.icon,
    required this.label,
    required this.ready,
  });

  final IconData icon;
  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ready ? theme.colorScheme.primary : theme.colorScheme.outline;
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        ready ? Icons.check_circle_outline : icon,
        size: 16,
        color: color,
      ),
      label: Text(label),
    );
  }
}

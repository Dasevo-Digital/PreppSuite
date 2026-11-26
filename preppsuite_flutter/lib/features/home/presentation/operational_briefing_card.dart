import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/app_ui.dart';
import '../../../core/calendar_day.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../inventory/application/charge_reminder_provider.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/application/supply_calculator.dart';
import '../../knowledge/application/knowledge_providers.dart';
import '../../maps/application/offline_map_providers.dart';
import '../../warnings/application/warning_freshness.dart';
import '../../warnings/application/warning_providers.dart';
import '../../warnings/application/warning_relevance.dart';
import '../application/home_overview.dart';
import '../application/operational_briefing.dart';
import '../application/shell_layout.dart';
import '../application/status_lights.dart';
import 'readiness_screen.dart';

/// The single first answer on the overview: what needs attention now.
///
/// This intentionally combines only facts the app has already established.
/// It does not manufacture a risk score from an empty pantry or a quiet
/// warning feed. A quiet feed says just that, and an unopened readiness task
/// stays a concrete next action.
///
/// **No green and no tick** (#394). The card said "Lage für deine Orte
/// ruhig" in the app's green with a verified badge -- the "all well" that
/// the situation lamp is built never to say, because authorities publish
/// warnings and not all-clears. And it said so with the feeds a day out
/// of reach, while the lamp beside it read "out of date". Without a
/// warning the card is neutral and says "no official warning", and only
/// while the feeds are current; otherwise it says that they are not.
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
    // Counted from today, like the attention card below (#262).
    final today = ref.watch(calendarDayProvider);
    final stock = summarizeInventory(inventory, now: today);
    // The supply lamp's own figure, so the card cannot call the basics
    // done while the lamp beside it says "lasts 0 of 10 days".
    final supply = supplyStatus(
      items: inventory,
      household: SupplyHousehold(
        adults: profile.personCount,
        children: profile.children,
        dogs: profile.dogs,
        cats: profile.cats,
      ),
    );
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
    // Read again after every poll, answered or not, like the lamp.
    final status = ref.watch(warningPollStatusProvider).value;
    final now = DateTime.now();
    final fresh = status == null
        ? null
        : warningFreshness(
            status,
            countryCode: profile.countryCode,
            now: now,
          );

    final state = operationalBriefing(
      warnings: warnings.length,
      freshness: fresh?.freshness,
      inventoryEmpty: inventory.isEmpty,
      inventoryAttention: stock.needsAttention,
      supply: supply.light,
      chargeDue:
          !equipment.isOff &&
          (equipment.lastChecked == null || equipment.isDue()),
    );

    void openWarnings() => onNavigate(ShellDestination.warnings);
    void openInventory() => onNavigate(ShellDestination.inventory);
    // "Bereitschaft öffnen" opens the readiness overview, every point
    // with its state. It used to lead to the inventory, the settings or
    // the emergency tab, whichever the card was talking about, and never
    // there (#394).
    void openReadiness() => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReadinessScreen(profile: profile),
      ),
    );

    // Neutral whenever no warning is in force: the green of the app's
    // primary colour would be the "all well" this card has no source for.
    final quietForeground = theme.colorScheme.onSurface;
    final quietBackground = theme.colorScheme.surfaceContainerHigh;
    _Briefing quiet(
      IconData icon,
      String task,
      String action,
      void Function() open,
    ) => _Briefing(
      icon: icon,
      title: l10n.operationsQuiet,
      detail: l10n.operationsNextTask(task),
      action: action,
      open: open,
      foreground: quietForeground,
      background: quietBackground,
    );
    final _Briefing briefing = switch (state) {
      OperationalBriefing.warning => _Briefing(
        icon: Icons.warning_amber_rounded,
        title: l10n.operationsWarning,
        detail: l10n.operationsWarningDetail,
        action: l10n.operationsOpenWarnings,
        open: openWarnings,
        foreground: theme.colorScheme.onErrorContainer,
        background: theme.colorScheme.errorContainer,
      ),
      // The look of the warning list's own notice (#138): somebody who
      // reads only this card must not come away thinking all is quiet.
      OperationalBriefing.unheard => _Briefing(
        icon: Icons.cloud_off_outlined,
        title: l10n.warningsStaleTitle,
        detail: switch (fresh?.at) {
          final at? => l10n.statusSituationStaleHint(
            formatWarningTime(l10n, at, now),
          ),
          null => l10n.statusSituationNever,
        },
        action: l10n.operationsOpenWarnings,
        open: openWarnings,
        foreground: theme.colorScheme.onErrorContainer,
        background: theme.colorScheme.errorContainer,
      ),
      OperationalBriefing.inventoryMissing => quiet(
        Icons.inventory_2_outlined,
        l10n.operationsInventoryMissing,
        l10n.operationsOpenInventory,
        openInventory,
      ),
      OperationalBriefing.inventoryAttention => quiet(
        Icons.event_busy_outlined,
        l10n.operationsInventoryAttention,
        l10n.operationsOpenInventory,
        openInventory,
      ),
      OperationalBriefing.supplyUnknown => quiet(
        Icons.inventory_2_outlined,
        l10n.operationsSupplyUnknown,
        l10n.operationsOpenInventory,
        openInventory,
      ),
      OperationalBriefing.supplyShort => quiet(
        Icons.inventory_2_outlined,
        l10n.operationsSupplyShort(statusLightDays),
        l10n.operationsOpenInventory,
        openInventory,
      ),
      // Where the check is confirmed and its interval set.
      OperationalBriefing.chargeDue => quiet(
        Icons.battery_charging_full_outlined,
        l10n.operationsChargeDue,
        l10n.operationsOpenSettings,
        () => onNavigate(ShellDestination.settings),
      ),
      OperationalBriefing.ready => _Briefing(
        icon: Icons.notifications_none_outlined,
        title: l10n.operationsQuiet,
        detail: l10n.operationsReady,
        action: l10n.operationsOpenReadiness,
        open: openReadiness,
        foreground: quietForeground,
        background: quietBackground,
      ),
    };

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
                      onPressed: briefing.open,
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
    required this.open,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String action;
  final VoidCallback open;
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/application/supply_calculator.dart';
import '../../warnings/application/warning_providers.dart';
import '../../warnings/application/warning_relevance.dart';
import '../../warnings/application/warning_severity_l10n.dart';
import '../application/shell_layout.dart';
import '../application/status_lights.dart';
import '../../warnings/application/warning_freshness.dart';

/// The first thing on the first screen: two lamps, side by side.
///
/// Every card below answers one question well, and none of them answers
/// the one somebody actually opens this screen with. Until now that took
/// reading four cards and adding up.
///
/// Two lamps and never one — see [statusLightDays] and the library note
/// in `status_lights.dart` for why a single colour for both would be an
/// invented scale. Each is tappable and leads to the screen that can do
/// something about it.
class StatusLightsRow extends ConsumerWidget {
  const StatusLightsRow({
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

    final items =
        ref.watch(inventoryItemsProvider(profile.id)).value ?? const [];
    final supply = supplyStatus(
      items: items,
      household: SupplyHousehold(
        adults: profile.personCount,
        children: profile.children,
        dogs: profile.dogs,
        cats: profile.cats,
      ),
    );

    // The same relevance rule the banner and the notifications use, so
    // the lamp cannot say "quiet" while the banner shows one.
    final active = ref.watch(activeWarningsProvider).value ?? const [];
    final situation = situationStatus([
      for (final warning in active)
        if (isWarningRelevant(
          warning: warning,
          filter: profile.warningFilter,
        ))
          warning,
    ]);

    final (supplyColour, supplyOn) = switch (supply.light) {
      SupplyLight.covered => (theme.colorScheme.primary, true),
      SupplyLight.short => (const Color(0xFFE0A900), true),
      SupplyLight.unknown => (theme.colorScheme.outline, false),
    };

    final severity = situation.highest;
    // Quiet is only quiet when the feeds were heard from lately (#138).
    final status = ref.watch(warningPollStatusProvider).value;
    final fresh = status == null
        ? null
        : warningFreshness(
            status,
            countryCode: profile.countryCode,
            now: DateTime.now(),
          );
    final unheard =
        severity == null &&
        fresh != null &&
        fresh.freshness != WarningFreshness.current;
    final situationColour = severity == null
        ? theme.colorScheme.outline
        : warningSeverityColors(context, severity).background;

    // Both lamps the height of the taller one, without either of them
    // being told a number. Inside a `ListView` the row has no height to
    // stretch to, and asking for one is how this first went out as
    // "BoxConstraints forces an infinite height" -- caught by
    // `optimization_layout_test`, not by the test beside this file,
    // because that one had a bounded box to sit in.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Lamp(
              title: l10n.statusSupplyTitle,
              headline: switch (supply.light) {
                SupplyLight.covered => l10n.statusSupplyCovered(
                  supply.daysCovered ?? 0,
                ),
                SupplyLight.short => l10n.statusSupplyShort(
                  supply.daysCovered ?? 0,
                  statusLightDays,
                ),
                SupplyLight.unknown => l10n.statusSupplyUnknown,
              },
              // Whose number this is, said on the lamp rather than in a
              // footnote: ten days is the BBK's figure, not the app's.
              detail: _supplyDetail(l10n, supply),
              colour: supplyColour,
              filled: supplyOn,
              icon: Icons.inventory_2_outlined,
              onTap: () => onNavigate(ShellDestination.inventory),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Lamp(
              title: l10n.statusSituationTitle,
              headline: unheard
                  ? l10n.statusSituationStale
                  : severity == null
                  ? l10n.statusSituationQuiet
                  : localizeWarningSeverity(l10n, severity),
              // There is no green on this lamp. An authority publishes
              // warnings, not all-clears, and dressing the absence of one
              // up as "all well" would be the app saying something nobody
              // said to it.
              detail: unheard
                  ? switch (fresh.at) {
                      final at? => l10n.statusSituationStaleHint(
                        formatWarningTime(l10n, at, DateTime.now()),
                      ),
                      null => l10n.statusSituationNever,
                    }
                  : severity == null
                  ? l10n.statusSituationQuietHint
                  : l10n.statusSituationActive(situation.count),
              colour: situationColour,
              filled: severity != null,
              icon: Icons.warning_amber_outlined,
              onTap: () => onNavigate(ShellDestination.warnings),
            ),
          ),
        ],
      ),
    );
  }

  String _supplyDetail(AppLocalizations l10n, SupplyStatus supply) {
    final limit = switch (supply.limit) {
      SupplyLimit.water => l10n.statusSupplyLimitWater,
      SupplyLimit.calories => l10n.statusSupplyLimitCalories,
      SupplyLimit.both => l10n.statusSupplyLimitBoth,
      null => l10n.statusSupplyBasis(statusLightDays),
    };
    final details = <String>[
      limit,
      if (supply.limit != null) l10n.statusSupplyBasis(statusLightDays),
      if (supply.uncounted > 0) l10n.statusSupplyUncounted(supply.uncounted),
    ];
    return details.join('\n');
  }
}

class _Lamp extends StatelessWidget {
  const _Lamp({
    required this.title,
    required this.headline,
    required this.detail,
    required this.colour,
    required this.filled,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String headline;
  final String detail;
  final Color colour;

  /// Whether the lamp is lit at all. A grey outline says "no answer",
  /// which is a different thing from a colour and has to look like it.
  final bool filled;

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // The lamp itself: filled when there is an answer,
                  // a ring when there is not.
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? colour : Colors.transparent,
                      border: Border.all(color: colour, width: 2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                headline,
                style: theme.textTheme.titleMedium,
                maxLines: 2,
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

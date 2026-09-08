import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../checklists/application/checklist_providers.dart';
import '../../checklists/application/checklist_satisfaction.dart';
import '../../household/application/household_member_controller.dart';
import '../../household/application/household_plan_controller.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../knowledge/application/knowledge_providers.dart';
import '../../maps/application/offline_map_providers.dart';
import '../../warnings/application/warning_providers.dart';
import '../../warnings/application/warning_relevance.dart';
import '../application/shell_layout.dart';

/// The information that must remain quick to reach when time, power or a
/// data connection is scarce. All values are derived from existing records.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({
    super.key,
    required this.profile,
    required this.onNavigate,
  });

  final HouseholdProfile profile;
  final ValueChanged<ShellDestination> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inventory =
        ref.watch(inventoryItemsProvider(profile.id)).value ?? const [];
    final checklist =
        ref.watch(allChecklistItemsProvider(profile.id)).value ?? const [];
    final plan = ref.watch(householdPlanProvider(profile.id)).value;
    final members =
        ref.watch(householdMembersProvider(profile.id)).value ?? const [];
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

    final readiness = [
      (
        l10n.readinessInventory,
        inventory.isNotEmpty,
        ShellDestination.inventory,
      ),
      (
        l10n.readinessChecklists,
        checklist.any(
          (item) => isChecklistItemSatisfied(
            item,
            {for (final stock in inventory) stock.clientId: stock},
          ),
        ),
        ShellDestination.checklists,
      ),
      (l10n.readinessPlan, plan != null, ShellDestination.household),
      (l10n.readinessCards, members.isNotEmpty, ShellDestination.household),
      (l10n.readinessMap, mapReady, ShellDestination.map),
      (l10n.readinessKnowledge, knowledgeReady, ShellDestination.knowledge),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emergencyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CallButton(label: l10n.emergencyCall112, number: '112'),
              _CallButton(label: l10n.emergencyCall110, number: '110'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.emergencyCurrentWarnings,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: warnings.isEmpty
                ? ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: Text(l10n.emergencyNoWarnings),
                  )
                : Column(
                    children: [
                      for (final warning in warnings)
                        ListTile(
                          leading: const Icon(Icons.warning_amber_rounded),
                          title: Text(warning.headline),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => onNavigate(ShellDestination.warnings),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.readinessTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final entry in readiness)
                  ListTile(
                    leading: Icon(
                      entry.$2
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: entry.$2
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(entry.$1),
                    subtitle: Text(
                      entry.$2 ? l10n.readinessReady : l10n.readinessNeedsWork,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigate(entry.$3),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.emergencyPlanHeading,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: plan == null
                ? ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text(l10n.emergencyPlanMissing),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigate(ShellDestination.household),
                  )
                : Column(
                    children: [
                      if (plan.meetingPointNear != null)
                        _PlanRow(
                          icon: Icons.place,
                          value: plan.meetingPointNear!,
                        ),
                      if (plan.meetingPointFar != null)
                        _PlanRow(
                          icon: Icons.map_outlined,
                          value: plan.meetingPointFar!,
                        ),
                      if (plan.contactName != null)
                        _PlanRow(
                          icon: Icons.person_outline,
                          value:
                              '${plan.contactName}${plan.contactPhone == null ? '' : ' · ${plan.contactPhone}'}',
                        ),
                      if (plan.kitLocation != null)
                        _PlanRow(
                          icon: Icons.backpack_outlined,
                          value: plan.kitLocation!,
                        ),
                      if (plan.shutoffLocation != null)
                        _PlanRow(
                          icon: Icons.power_settings_new,
                          value: plan.shutoffLocation!,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.label, required this.number});
  final String label;
  final String number;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: () => launchUrl(Uri(scheme: 'tel', path: number)),
    icon: const Icon(Icons.call),
    label: Text(label),
  );
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(value),
  );
}

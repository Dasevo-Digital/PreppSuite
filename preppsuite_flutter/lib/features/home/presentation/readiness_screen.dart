import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../checklists/application/checklist_providers.dart';
import '../../checklists/application/checklist_satisfaction.dart';
import '../../household/application/household_member_controller.dart';
import '../../household/application/household_plan_controller.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../knowledge/application/knowledge_providers.dart';
import '../../maps/application/offline_map_providers.dart';
import '../../warnings/application/warning_poll_status_store.dart';

final _warningPollStatusProvider = FutureProvider(
  (ref) => const WarningPollStatusStore().load(),
);

/// Shows whether the data and offline packages on this device are ready for
/// use. It does not test the internet; the warning timestamp is the evidence
/// of the last successful complete refresh.
class ReadinessScreen extends ConsumerWidget {
  const ReadinessScreen({super.key, required this.profile});

  final HouseholdProfile profile;

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
    final knowledge = ref.watch(knowledgeProvider).value;
    final knowledgeReady = knowledge?.isReady ?? false;
    final warningStatus = ref.watch(_warningPollStatusProvider).value;
    // Built once, not once per checklist item. `any` short-circuits, so the
    // cost only shows in full when nothing is satisfied yet — which is the
    // fresh household this screen exists for, and 129 built-in items
    // against a stocked pantry is five figures of map insertions on every
    // rebuild. There are seven streams above; a write to any of them
    // rebuilds this.
    final inventoryById = {for (final item in inventory) item.clientId: item};

    final checks = [
      (l10n.readinessInventory, inventory.isNotEmpty),
      (
        l10n.readinessChecklists,
        checklist.any((item) => isChecklistItemSatisfied(item, inventoryById)),
      ),
      (l10n.readinessPlan, plan != null),
      (l10n.readinessCards, members.isNotEmpty),
      (l10n.readinessMap, mapReady),
      (l10n.readinessKnowledge, knowledgeReady),
    ];
    final readyCount = checks.where((check) => check.$2).length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.readinessTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.readinessSummary(readyCount, checks.length),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: readyCount / checks.length),
                  const SizedBox(height: 8),
                  Text(l10n.readinessSummaryHint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                for (final check in checks)
                  ListTile(
                    leading: Icon(
                      check.$2
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                    ),
                    title: Text(check.$1),
                    subtitle: Text(
                      check.$2 ? l10n.readinessReady : l10n.readinessNeedsWork,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.readinessOfflinePackages,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _StatusRow(
                  icon: Icons.map_outlined,
                  title: l10n.readinessMap,
                  value: mapReady
                      ? l10n.readinessPackageReady
                      : l10n.readinessPackageMissing,
                ),
                const Divider(height: 1),
                _StatusRow(
                  icon: Icons.menu_book_outlined,
                  title: l10n.readinessKnowledge,
                  value: knowledgeReady
                      ? l10n.readinessArchivesReady(knowledge!.library.length)
                      : l10n.readinessPackageMissing,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.readinessWarningData,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: _StatusRow(
              icon: Icons.warning_amber_outlined,
              title: l10n.readinessWarningData,
              value: warningStatus?.lastComplete == null
                  ? l10n.readinessWarningNeverUpdated
                  : l10n.readinessWarningUpdated(
                      _age(
                        l10n,
                        DateTime.now().toUtc().difference(
                          warningStatus!.lastComplete!,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(value),
  );
}

String _age(AppLocalizations l10n, Duration age) {
  if (age.inMinutes < 2) return l10n.readinessJustNow;
  if (age.inHours < 1) return l10n.readinessMinutesAgo(age.inMinutes);
  if (age.inDays < 1) return l10n.readinessHoursAgo(age.inHours);
  return l10n.readinessDaysAgo(age.inDays);
}

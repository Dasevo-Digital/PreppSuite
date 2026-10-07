import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../settings/application/local_encryption_readiness_store.dart';
import '../../checklists/application/checklist_providers.dart';
import '../../checklists/application/checklist_satisfaction.dart';
import '../../household/application/household_member_controller.dart';
import '../../household/application/household_plan_controller.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/application/charge_reminder_provider.dart';
import '../../knowledge/application/knowledge_providers.dart';
import '../../maps/application/offline_map_providers.dart';
import '../../maps/application/personal_place.dart';
import '../../maps/application/pmtiles_archive.dart';
import '../../warnings/application/warning_poll_status_store.dart';
import '../../settings/application/backup_reminder.dart';
import '../../settings/presentation/backup_card.dart' show backupAge;

final _warningPollStatusProvider = FutureProvider(
  (ref) => const WarningPollStatusStore().load(),
);

final _backupVerificationProvider = FutureProvider(
  (ref) => const LocalEncryptionReadinessStore().lastVerified(),
);

final _personalPlacesProvider = FutureProvider(
  (ref) => const PersonalPlaceStore().load(),
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
    final map = ref.watch(offlineMapProvider).value;
    final mapReady = map?.isReady ?? false;
    final places = ref.watch(_personalPlacesProvider).value ?? const [];
    final coveredPlaces = map?.archive == null
        ? 0
        : places.where((place) => _covers(map!.archive!, place)).length;
    final knowledge = ref.watch(knowledgeProvider).value;
    final knowledgeReady = knowledge?.isReady ?? false;
    final warningStatus = ref.watch(_warningPollStatusProvider).value;
    final backupVerifiedAt = ref.watch(_backupVerificationProvider).value;
    final backupReady = LocalEncryptionReadinessStore.isFresh(backupVerifiedAt);
    final backup = ref.watch(backupStatusProvider);
    final equipment = ref.watch(chargeCheckProvider);
    final equipmentReady =
        !equipment.isOff && equipment.lastChecked != null && !equipment.isDue();
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
      (l10n.readinessEquipment, equipmentReady),
      (l10n.readinessBackupMade, backup.isCurrent()),
      (l10n.readinessBackup, backupReady),
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
                      ? places.isEmpty
                            ? l10n.readinessMapReadyNoPlaces(map!.label ?? '')
                            : l10n.readinessMapCoverage(
                                coveredPlaces,
                                places.length,
                                map!.label ?? '',
                              )
                      : l10n.readinessPackageMissing,
                ),
                const Divider(height: 1),
                _StatusRow(
                  icon: Icons.battery_charging_full_outlined,
                  title: l10n.readinessEquipment,
                  value: switch (equipment) {
                    _ when equipment.isOff => l10n.readinessEquipmentOff,
                    _ when equipment.lastChecked == null =>
                      l10n.readinessEquipmentNotChecked,
                    _ when equipment.isDue() => l10n.readinessEquipmentDue,
                    _ => l10n.readinessEquipmentChecked,
                  },
                ),
                const Divider(height: 1),
                _StatusRow(
                  icon: Icons.menu_book_outlined,
                  title: l10n.readinessKnowledge,
                  value: knowledgeReady
                      ? l10n.readinessArchivesReady(knowledge!.library.length)
                      : l10n.readinessPackageMissing,
                ),
                const Divider(height: 1),
                _StatusRow(
                  icon: Icons.save_alt,
                  title: l10n.readinessBackupMade,
                  value: backup.lastBackup == null
                      ? l10n.readinessBackupMadeNever
                      : l10n.readinessBackupMadeAge(
                          backupAge(l10n, backup.daysSince() ?? 0),
                        ),
                ),
                const Divider(height: 1),
                _StatusRow(
                  icon: Icons.fact_check_outlined,
                  title: l10n.readinessBackup,
                  value: backupVerifiedAt == null
                      ? l10n.readinessBackupNeverVerified
                      : backupReady
                      ? l10n.readinessBackupVerified(
                          _age(
                            l10n,
                            DateTime.now().toUtc().difference(backupVerifiedAt),
                          ),
                        )
                      : l10n.readinessBackupStale(
                          _age(
                            l10n,
                            DateTime.now().toUtc().difference(backupVerifiedAt),
                          ),
                        ),
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
              value: _warningStatusText(l10n, warningStatus),
            ),
          ),
        ],
      ),
    );
  }

  /// Current is what the household's own feed says: the BBK in Germany.
  /// A MeteoAlarm outage is added as a sentence of its own, rather than
  /// making the official German state look stale (#92).
  String _warningStatusText(AppLocalizations l10n, WarningPollStatus? status) {
    final current = status?.currentAt(profile.countryCode);
    if (status == null || current == null) {
      return l10n.readinessWarningNeverUpdated;
    }
    if (status.isBlocked) return l10n.readinessWarningBlocked;
    final updated = l10n.readinessWarningUpdated(
      _age(l10n, DateTime.now().toUtc().difference(current)),
    );
    return status.lagging(profile.countryCode).contains('meteoalarm')
        ? '$updated\n${l10n.warningSourceLaggingMeteoAlarm}'
        : updated;
  }
}

bool _covers(PmTilesArchive archive, PersonalPlace place) {
  final header = archive.header;
  return place.longitude >= header.minLongitude &&
      place.longitude <= header.maxLongitude &&
      place.latitude >= header.minLatitude &&
      place.latitude <= header.maxLatitude;
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

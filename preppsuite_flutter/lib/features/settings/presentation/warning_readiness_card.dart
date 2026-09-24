import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../warnings/application/warning_poll_status_store.dart';

final warningReadinessProvider = FutureProvider.autoDispose<WarningPollStatus>(
  (ref) => const WarningPollStatusStore().load(),
);

/// Explains whether this device is prepared to surface a relevant warning.
///
/// This deliberately reports only facts the app can know locally. A platform
/// may postpone background work, so it must not claim a future refresh is
/// guaranteed.
class WarningReadinessCard extends ConsumerWidget {
  const WarningReadinessCard({
    super.key,
    required this.profile,
    required this.l10n,
    required this.onManagePlaces,
  });

  final HouseholdProfile profile;
  final AppLocalizations l10n;
  final VoidCallback onManagePlaces;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final status = ref.watch(warningReadinessProvider).value;
    final hasPrimaryRegion = profile.regionKey != null;
    final additionalRegions = profile.extraRegions.length;
    final refreshedAt = status?.lastComplete;
    final refreshText = refreshedAt == null
        ? l10n.settingsWarningReadinessNeverUpdated
        : _refreshText(
            DateTime.now().toUtc().difference(refreshedAt),
            l10n,
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(l10n.settingsWarningReadinessTitle),
              subtitle: Text(l10n.settingsWarningReadinessBody),
            ),
            _ReadinessRow(
              icon: notificationsEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              title: l10n.settingsWarningReadinessNotifications,
              value: notificationsEnabled
                  ? l10n.settingsWarningReadinessEnabled
                  : l10n.settingsWarningReadinessDisabled,
            ),
            const Divider(height: 1),
            _ReadinessRow(
              icon: Icons.location_on_outlined,
              title: l10n.settingsWarningReadinessRegions,
              value: hasPrimaryRegion
                  ? l10n.settingsWarningReadinessRegionsSet(additionalRegions)
                  : l10n.settingsWarningReadinessRegionsMissing,
            ),
            const Divider(height: 1),
            _ReadinessRow(
              icon: Icons.sync_outlined,
              title: l10n.settingsWarningReadinessRefresh,
              value: refreshText,
            ),
            // Only while it is the most recent thing that happened. A device
            // that has started refreshing again has nothing to report here,
            // and a permanent warning nobody can clear is one nobody reads.
            if (status?.isBlocked ?? false) ...[
              const Divider(height: 1),
              _ReadinessRow(
                icon: Icons.running_with_errors_outlined,
                title: l10n.settingsWarningReadinessBlockedTitle,
                value: l10n.settingsWarningReadinessBlockedBody,
                colour: Theme.of(context).colorScheme.error,
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onManagePlaces,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(l10n.followedPlacesOpen),
            ),
          ],
        ),
      ),
    );
  }

  String _refreshText(Duration age, AppLocalizations l10n) {
    if (age.inMinutes < 2) return l10n.settingsWarningReadinessJustNow;
    if (age.inHours < 1) {
      return l10n.settingsWarningReadinessMinutesAgo(age.inMinutes);
    }
    if (age.inDays < 1) {
      return l10n.settingsWarningReadinessHoursAgo(age.inHours);
    }
    return l10n.settingsWarningReadinessDaysAgo(age.inDays);
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.icon,
    required this.title,
    required this.value,
    this.colour,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? colour;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: colour),
    title: Text(title, style: TextStyle(color: colour)),
    subtitle: Text(value),
  );
}

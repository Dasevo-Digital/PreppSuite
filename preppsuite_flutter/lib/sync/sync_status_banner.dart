import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'sync_runner.dart';
import 'sync_status.dart';

/// Says, and only when it is worth saying, that this device's changes have
/// not reached the household.
///
/// Silence is the normal state. The app is built to work offline, so a
/// dropped request is not news — see [isSyncStale] for the two cases that
/// are. Before this existed, a failing sync was invisible: the controllers
/// held the error in their state and no screen ever read it, so someone
/// could go on believing their supplies were shared while the server had
/// been unreachable for days.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    if (!isSyncStale(status, DateTime.now())) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lastSuccess = status.lastSuccessAt;

    final detail = lastSuccess == null
        ? l10n.syncStaleNever
        : l10n.syncStaleSince(_ageLabel(l10n, lastSuccess));

    return Material(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.syncStaleTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () =>
                  ref.read(syncRunnerProvider).runPass(householdId),
              child: Text(l10n.syncRetryButton),
            ),
          ],
        ),
      ),
    );
  }

  String _ageLabel(AppLocalizations l10n, DateTime lastSuccess) {
    final age = syncAge(DateTime.now().difference(lastSuccess));
    return switch (age.unit) {
      SyncAgeUnit.minutes => l10n.syncAgeMinutes(age.value),
      SyncAgeUnit.hours => l10n.syncAgeHours(age.value),
      SyncAgeUnit.days => l10n.syncAgeDays(age.value),
    };
  }
}

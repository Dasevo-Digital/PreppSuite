import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../household/application/household_providers.dart';
import '../application/shared_folder_access.dart';
import '../application/shared_folder_sync_service.dart';
import '../../../core/app_database_providers.dart';
import '../../transfer/presentation/household_conflict_dialog.dart';
import '../application/household_file.dart';
import '../application/sharing_providers.dart';
import '../application/snapshot_exchange.dart';
import 'folder_encryption_section.dart';
import '../../../core/error_text.dart';

/// Settings card for sharing a household across devices.
///
/// Shows the folder, what the last run did, and the two things the user
/// can actually decide: which folder, and whether to keep using it.
class SharedFolderCard extends ConsumerWidget {
  const SharedFolderCard({
    super.key,
    required this.profile,
    required this.l10n,
  });

  final HouseholdProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sharedFolderProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.sharingIntro,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            switch (async) {
              AsyncLoading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              AsyncError(:final error) => Text(
                describeError(l10n, error),
              ),
              _ => _Body(
                state: async.requireValue,
                profile: profile,
                l10n: l10n,
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.state,
    required this.profile,
    required this.l10n,
  });

  final SharedFolderState state;
  final HouseholdProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.isSharing)
          Text(l10n.sharingInactive, style: theme.textTheme.bodyMedium)
        else ...[
          Text(
            l10n.sharingActiveFolder(state.folder!.label),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          _StatusLine(state: state, l10n: l10n),
          const FolderEncryptionSection(),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _pickFolder(context, ref),
              icon: const Icon(Icons.folder_open),
              label: Text(
                state.isSharing
                    ? l10n.sharingChangeFolderAction
                    : l10n.sharingChooseFolderAction,
              ),
            ),
            if (state.isSharing) ...[
              OutlinedButton.icon(
                onPressed: state.syncing
                    ? null
                    : () => ref.read(sharedFolderProvider.notifier).syncNow(),
                icon: const Icon(Icons.sync),
                label: Text(l10n.sharingSyncNowAction),
              ),
              TextButton(
                onPressed: () => _confirmLeave(context, ref),
                child: Text(l10n.sharingLeaveAction),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pickFolder(BuildContext context, WidgetRef ref) async {
    final picked = await pickSharedFolder(
      dialogTitle: l10n.settingsSharingTitle,
    );
    if (picked == null) return;
    if (!context.mounted) return;

    // Asked *before* joining, because `joinFolder` adopts whatever it
    // finds and re-stamps every local row onto it. That used to happen
    // here unannounced, with a line afterwards saying it had — which made
    // this the careless road into somebody else's household while the QR
    // code, doing the very same thing, asked first.
    if (!await _settleConflict(context, ref, picked)) return;
    if (!context.mounted) return;

    final previousId = profile.id;
    final error = await ref
        .read(sharedFolderProvider.notifier)
        .joinFolder(picked, profile: profile);
    if (!context.mounted) return;

    if (error != null) {
      _tell(context, switch (error) {
        SharedFolderJoinError.unwritable => l10n.sharingErrorUnwritable,
        SharedFolderJoinError.unreadable => l10n.sharingErrorUnreadable,
      });
      return;
    }

    // Only said when the id actually changed — that is the case where this
    // device's rows moved into someone else's household, which the user
    // should be told rather than left to discover.
    final adopted = ref.read(householdProfileProvider).value;
    if (adopted != null && adopted.id != previousId) {
      _tell(context, l10n.sharingJoinedOther(adopted.name));
    }
  }

  /// True when the join may go ahead.
  ///
  /// A folder that holds no household, or this one's, needs no question:
  /// the first is being founded and the second is a device coming back.
  Future<bool> _settleConflict(
    BuildContext context,
    WidgetRef ref,
    SharedFolderLocation location,
  ) async {
    final HouseholdFile? existing;
    try {
      final raw = await syncFolderFor(location.value).readHouseholdFile();
      existing = raw == null ? null : HouseholdFile.decode(raw);
    } on Object {
      // Unreadable is not this question's business: `joinFolder` reports
      // it properly a moment later, in the user's own words.
      return true;
    }
    if (existing == null || existing.householdId == profile.id) return true;

    final db = ref.read(appDatabaseProvider);
    final rows = (await readHouseholdSnapshot(
      db,
      deviceId: 'conflict',
      householdId: profile.id,
    )).rowCount;
    if (!context.mounted) return false;

    final choice = await askAboutHouseholdConflict(
      context,
      mine: profile.name,
      rows: rows,
    );
    switch (choice) {
      case null:
      case HouseholdConflictChoice.keep:
        return false;
      case HouseholdConflictChoice.merge:
        return true;
      case HouseholdConflictChoice.replace:
        // Before the join, or the rows would be re-stamped onto the new
        // household and travel along — which is what this answer says
        // not to do.
        await db.deleteHouseholdData(profile.id);
        return true;
    }
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sharingLeaveDialogTitle),
        content: Text(l10n.sharingLeaveDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.sharingLeaveDialogConfirm),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(sharedFolderProvider.notifier).leaveFolder();
    }
  }

  void _tell(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// What the last run did, in one or two lines.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state, required this.l10n});

  final SharedFolderState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = state.lastResult;

    if (state.syncing) {
      return Text(l10n.sharingSyncing, style: theme.textTheme.bodySmall);
    }

    final error = result?.error;
    if (error != null) {
      return Text(
        switch (error) {
          SharedFolderSyncError.unwritable => l10n.sharingErrorUnwritable,
          SharedFolderSyncError.differentHousehold =>
            l10n.sharingErrorDifferentHousehold,
          SharedFolderSyncError.unsupportedVersion => l10n.sharingErrorVersion,
          SharedFolderSyncError.locked => l10n.sharingErrorLocked,
          SharedFolderSyncError.encryptionChanged =>
            l10n.sharingErrorEncryptionChanged,
          SharedFolderSyncError.failed => l10n.sharingErrorFailed,
        },
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    final lastSynced = state.lastSyncedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lastSynced == null
              ? l10n.sharingNeverSynced
              : l10n.sharingLastSynced(
                  _age(l10n, DateTime.now().toUtc().difference(lastSynced)),
                ),
          style: theme.textTheme.bodySmall,
        ),
        if (result != null)
          Text(
            result.received > 0
                ? l10n.sharingReceived(result.received)
                : l10n.sharingUpToDate,
            style: theme.textTheme.bodySmall,
          ),
        if (result != null)
          Text(
            result.devicesSeen <= 1
                ? l10n.sharingDeviceCountOne
                : l10n.sharingDeviceCount(result.devicesSeen),
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  String _age(AppLocalizations l10n, Duration since) {
    if (since.inHours < 1) {
      return l10n.syncAgeMinutes(since.inMinutes.clamp(1, 59));
    }
    if (since.inDays < 1) return l10n.syncAgeHours(since.inHours);
    return l10n.syncAgeDays(since.inDays);
  }
}

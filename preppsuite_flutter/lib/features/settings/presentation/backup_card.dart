import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/backup_container.dart';
import '../application/backup_service.dart';
import 'backup_flow.dart';
import 'passphrase_dialog.dart';
import '../../household/application/household_providers.dart';

class BackupCard extends ConsumerWidget {
  const BackupCard({super.key, required this.householdId, required this.l10n});

  final String householdId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Column(
      children: [
        ListTile(
          leading: const Icon(Icons.save_alt),
          title: Text(l10n.backupCreate),
          subtitle: Text(l10n.backupHint),
          onTap: () => _export(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.ios_share),
          title: Text(l10n.backupShare),
          subtitle: Text(l10n.backupShareHint),
          onTap: () => _share(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: Text(l10n.backupRestore),
          onTap: () => _restore(context, ref),
        ),
      ],
    ),
  );

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final passphrase = await _askPassphrase(context, confirm: true);
      if (passphrase == null || !context.mounted) return;
      final written = await writeBackupWithProgress(
        context,
        ref,
        householdId: householdId,
        passphrase: passphrase,
        target: () => backupTarget(dialogTitle: l10n.backupCreate),
      );
      if (written == null) return;
      final saved = await saveOrShareBackup(
        written.file,
        dialogTitle: l10n.backupCreate,
        subject: l10n.backupShareSubject,
      );
      if (!saved) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_created(written.unreadable))),
      );
    } catch (error) {
      _reportFailure(messenger, error);
    }
  }

  /// Hands the backup to whatever the system offers.
  ///
  /// The saving road above goes through the file picker, and on Android
  /// that road does not reach OneDrive or Google Drive: neither
  /// registers a document tree, so neither appears. Both are perfectly
  /// ordinary *share* targets, and so is every messenger and mail app —
  /// which makes this the difference between a cloud being a usable
  /// transport for a household backup and not being one at all.
  ///
  /// What leaves the device is the same encrypted file `_export` writes.
  /// Sending it through somebody else's server is not a leak of the
  /// household; without the passphrase it is noise.
  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    File? file;
    try {
      final passphrase = await _askPassphrase(context, confirm: true);
      if (passphrase == null || !context.mounted) return;
      // The app's own temporary directory, not the documents folder: this
      // copy exists for the seconds it takes another app to pick it up.
      final written = await writeBackupWithProgress(
        context,
        ref,
        householdId: householdId,
        passphrase: passphrase,
        target: sharedBackupTarget,
      );
      if (written == null) return;
      file = written.file;
      await shareBackup(file, subject: l10n.backupShareSubject);
      if (written.unreadable.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(_created(written.unreadable))),
        );
      }
    } catch (error) {
      _reportFailure(messenger, error);
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    PickedBackup? picked;
    try {
      try {
        picked = await pickBackup(dialogTitle: l10n.backupRestore);
      } on BackupFormatException {
        messenger.showSnackBar(SnackBar(content: Text(l10n.backupInvalid)));
        return;
      }
      if (picked == null || !context.mounted) return;
      final passphrase = await _askPassphrase(context);
      if (passphrase == null || !context.mounted) return;

      final service = BackupService(ref.read(appDatabaseProvider));
      final opened = await service.open(
        picked.file,
        passphrase,
        householdId: householdId,
      );
      if (opened == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.backupInvalid)));
        return;
      }
      final count = await service.restoreOpened(
        opened,
        saveProfile: ref.read(householdProfileProvider.notifier).adopt,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.backupRestored(count))),
      );
      if (!context.mounted) return;

      final files = await restoreBackupFilesWithProgress(
        context,
        ref,
        opened: opened,
      );
      final said = describeFilesRestored(l10n, files);
      if (said != null) {
        messenger.showSnackBar(SnackBar(content: Text(said)));
      }
    } catch (error) {
      _reportFailure(messenger, error);
    } finally {
      await picked?.source.close();
    }
  }

  String _created(List<String> unreadable) => unreadable.isEmpty
      ? l10n.backupCreated
      : '${l10n.backupCreated} '
            '${l10n.backupFilesUnreadable(unreadable.join(', '))}';

  /// The reason, not just the fact. This is somebody's whole household
  /// failing to leave the device or failing to come back, and "could not
  /// be processed" alone gives them nothing to act on — a full disk and
  /// a refused folder need different answers. A wrong passphrase does not
  /// land here; `open` reports that as `backupInvalid` instead.
  void _reportFailure(ScaffoldMessengerState messenger, Object error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isBackupCancelled(error)
              ? l10n.backupCancelled
              : '${l10n.backupFailed} ${describeError(l10n, error)}',
        ),
      ),
    );
  }

  Future<String?> _askPassphrase(
    BuildContext context, {
    bool confirm = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          PassphraseDialog(l10n: l10n, confirm: confirm),
    );
  }
}

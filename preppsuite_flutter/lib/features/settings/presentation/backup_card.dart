import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:path_provider/path_provider.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/error_text.dart';
import '../../../core/save_file.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/backup_service.dart';
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
      if (passphrase == null) return;
      final raw = await BackupService(
        ref.read(appDatabaseProvider),
      ).exportHousehold(householdId, passphrase);
      final saved = await saveFileWithPicker(
        dialogTitle: l10n.backupCreate,
        fileName: 'preppsuite-backup.json',
        extension: 'json',
        bytes: utf8.encode(raw),
      );
      if (!saved) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupCreated)));
    } catch (error) {
      // The reason, not just the fact. This is somebody's whole household
      // failing to leave the device or failing to come back, and "could
      // not be processed" alone gives them nothing to act on — a full
      // disk and a refused folder need different answers. A wrong
      // passphrase does not land here; `restore` reports that as
      // `backupInvalid` instead.
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.backupFailed} ${describeError(l10n, error)}'),
        ),
      );
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
  /// What leaves the device is the same encrypted envelope `_export`
  /// writes. Sending it through somebody else's server is not a leak of
  /// the household; without the passphrase it is noise.
  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final passphrase = await _askPassphrase(context, confirm: true);
      if (passphrase == null) return;
      final raw = await BackupService(
        ref.read(appDatabaseProvider),
      ).exportHousehold(householdId, passphrase);

      // The app's own temporary directory, not the documents folder: this
      // copy exists for the seconds it takes another app to pick it up.
      final file = File(
        '${(await getTemporaryDirectory()).path}'
        '${Platform.pathSeparator}preppsuite-backup.json',
      );
      await file.writeAsBytes(utf8.encode(raw), flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: l10n.backupShareSubject,
        ),
      );
    } catch (error) {
      // The reason, not just the fact — the same as the two roads above.
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.backupFailed} ${describeError(l10n, error)}'),
        ),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await FilePicker.platform.pickFiles(
        dialogTitle: l10n.backupRestore,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (picked == null) return;
      if (!context.mounted) return;
      final passphrase = await _askPassphrase(context);
      if (passphrase == null) return;
      final file = picked.files.single;
      final raw = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await File(file.path!).readAsString();
      final count = await BackupService(ref.read(appDatabaseProvider)).restore(
        raw,
        householdId,
        passphrase,
        saveProfile: ref.read(householdProfileProvider.notifier).adopt,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count == null ? l10n.backupInvalid : l10n.backupRestored(count),
          ),
        ),
      );
    } catch (error) {
      // The reason, not just the fact. This is somebody's whole household
      // failing to leave the device or failing to come back, and "could
      // not be processed" alone gives them nothing to act on — a full
      // disk and a refused folder need different answers. A wrong
      // passphrase does not land here; `restore` reports that as
      // `backupInvalid` instead.
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.backupFailed} ${describeError(l10n, error)}'),
        ),
      );
    }
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

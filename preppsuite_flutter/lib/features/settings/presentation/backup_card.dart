import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/backup_service.dart';

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
      final bytes = utf8.encode(raw);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: l10n.backupCreate,
        fileName: 'preppsuite-backup.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (path == null) return;
      final file = File(path);
      if (!file.existsSync() || file.lengthSync() == 0) {
        await file.writeAsBytes(bytes, flush: true);
      }
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
      final count = await BackupService(
        ref.read(appDatabaseProvider),
      ).restore(raw, householdId, passphrase);
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
  }) async {
    final first = TextEditingController();
    final second = TextEditingController();
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.backupPassphraseTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: first,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.backupPassphrase,
                  errorText: error,
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: second,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.backupPassphraseRepeat,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                // Twelve, not eight. This file can be carried off and
                // attacked offline for as long as somebody likes, and it
                // holds the whole household — emergency cards with blood
                // group, medication and conditions included. Argon2id at
                // 64 MB makes each guess expensive; the passphrase decides
                // how many guesses are needed.
                if (first.text.length < 12 ||
                    (confirm && first.text != second.text)) {
                  setState(() => error = l10n.backupPassphraseInvalid);
                  return;
                }
                Navigator.pop(dialogContext, first.text);
              },
              child: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ],
        ),
      ),
    );
    first.dispose();
    second.dispose();
    return result;
  }
}

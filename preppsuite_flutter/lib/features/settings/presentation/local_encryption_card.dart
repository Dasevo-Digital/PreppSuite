import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/error_text.dart';
import '../../../core/local_database_encryption.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/backup_service.dart';
import '../application/local_encryption_readiness_store.dart';
import 'passphrase_dialog.dart';

/// What the card needs to know, read in one go so the two halves cannot
/// disagree on screen.
typedef LocalEncryptionStatus = ({
  LocalDatabaseEncryptionMode mode,
  List<String> pending,
  DateTime? backupVerifiedAt,
});

final localEncryptionStatusProvider =
    FutureProvider.autoDispose<LocalEncryptionStatus>((ref) async {
      final encryption = LocalDatabaseEncryption.instance;
      return (
        mode: encryption.isInitialized
            ? encryption.mode
            : LocalDatabaseEncryptionMode.plaintext,
        pending: await encryption.pendingPlaintextDatabases(),
        backupVerifiedAt: await const LocalEncryptionReadinessStore()
            .lastVerified(),
      );
    });

/// Turns the at-rest encryption from something that happens to somebody
/// into something somebody does.
///
/// Two deliberate refusals. It never starts on its own — an app update
/// that silently rewrites every database is the one way this feature can
/// destroy a household. And it will not start before a backup has been
/// read back in front of the person: the upgrade is safe in every path
/// that was thought of, and a backup is what covers the ones that were
/// not.
class LocalEncryptionCard extends ConsumerStatefulWidget {
  const LocalEncryptionCard({
    super.key,
    required this.householdId,
    required this.l10n,
  });

  final String householdId;
  final AppLocalizations l10n;

  @override
  ConsumerState<LocalEncryptionCard> createState() =>
      _LocalEncryptionCardState();
}

class _LocalEncryptionCardState extends ConsumerState<LocalEncryptionCard> {
  bool _busy = false;

  AppLocalizations get l10n => widget.l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(localEncryptionStatusProvider).value;
    final mode = status?.mode ?? LocalDatabaseEncryptionMode.plaintext;
    final pending = status?.pending ?? const <String>[];
    final verifiedAt = status?.backupVerifiedAt;
    final backupIsFresh = LocalEncryptionReadinessStore.isFresh(verifiedAt);
    final cipher = LocalDatabaseEncryption.cipherAvailable;

    final canStart =
        cipher &&
        !_busy &&
        pending.isNotEmpty &&
        backupIsFresh &&
        mode != LocalDatabaseEncryptionMode.recoveryRequired;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              switch (mode) {
                LocalDatabaseEncryptionMode.encrypted when pending.isEmpty =>
                  Icons.lock_outline,
                LocalDatabaseEncryptionMode.recoveryRequired =>
                  Icons.key_off_outlined,
                _ => Icons.lock_open_outlined,
              },
            ),
            title: Text(l10n.settingsLocalEncryptionTitle),
            subtitle: Text(_stateText(mode, pending, cipher)),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.info_outline),
            // Said on the card rather than in a help page: somebody who
            // has just read "encrypted" would otherwise reasonably assume
            // it covers the PDFs and photos they put there themselves.
            title: Text(
              l10n.settingsLocalEncryptionScope,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: Text(l10n.settingsLocalEncryptionTestBackup),
            subtitle: Text(
              verifiedAt == null
                  ? l10n.settingsLocalEncryptionTestBackupHint
                  : backupIsFresh
                  ? l10n.settingsLocalEncryptionTestBackupHint
                  : l10n.settingsLocalEncryptionBackupStale,
            ),
            onTap: _busy ? null : _testBackup,
          ),
          if (pending.isNotEmpty) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.enhanced_encryption_outlined),
              title: Text(l10n.settingsLocalEncryptionStart),
              subtitle: Text(
                !cipher
                    ? l10n.settingsLocalEncryptionUnsupported
                    : backupIsFresh
                    ? l10n.settingsLocalEncryptionConfirmBody
                    : l10n.settingsLocalEncryptionBackupNever,
              ),
              enabled: canStart,
              onTap: canStart ? _migrate : null,
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  String _stateText(
    LocalDatabaseEncryptionMode mode,
    List<String> pending,
    bool cipher,
  ) {
    if (!cipher) return l10n.settingsLocalEncryptionUnsupported;
    return switch (mode) {
      LocalDatabaseEncryptionMode.recoveryRequired =>
        l10n.settingsLocalEncryptionStateRecovery,
      LocalDatabaseEncryptionMode.encrypted when pending.isEmpty =>
        l10n.settingsLocalEncryptionStateEncrypted,
      LocalDatabaseEncryptionMode.encrypted =>
        l10n.settingsLocalEncryptionStatePartial(pending.length),
      LocalDatabaseEncryptionMode.plaintext =>
        l10n.settingsLocalEncryptionStatePlain,
    };
  }

  Future<void> _testBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await FilePicker.platform.pickFiles(
        dialogTitle: l10n.settingsLocalEncryptionTestBackup,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (picked == null || !mounted) return;
      final passphrase = await showDialog<String>(
        context: context,
        builder: (_) => PassphraseDialog(l10n: l10n, confirm: false),
      );
      if (passphrase == null) return;

      final file = picked.files.single;
      final raw = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await File(file.path!).readAsString();
      final check = await BackupService(
        ref.read(appDatabaseProvider),
      ).verify(raw, widget.householdId, passphrase);

      if (check == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.settingsLocalEncryptionBackupUnreadable),
          ),
        );
        return;
      }
      await const LocalEncryptionReadinessStore().recordVerified();
      ref.invalidate(localEncryptionStatusProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.settingsLocalEncryptionBackupVerified(check.rows),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(l10n, error))),
      );
    }
  }

  Future<void> _migrate() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsLocalEncryptionConfirmTitle),
        content: Text(l10n.settingsLocalEncryptionConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsLocalEncryptionStart),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.settingsLocalEncryptionRunning)),
    );
    try {
      // The household database has to let go of the file first: the
      // migration swaps it for a new one under a rename, and a connection
      // still holding the old one would keep writing into a file that is
      // about to be deleted.
      //
      // The knowledge and document indexes are opened by whoever needs
      // them and closed again, so there is nothing here to close -- but
      // that also means an indexing run started elsewhere would write into
      // the wrong file. Hence the wording in the confirmation and the
      // restart at the end: this is a thing somebody does while the app is
      // otherwise idle, not something it survives in the background.
      // Closed, not invalidated: invalidating hands the next reader a new
      // connection, and any screen still listening would open the file
      // again in the middle of the swap.
      await ref.read(appDatabaseProvider).close();

      await LocalDatabaseEncryption.instance.migrateExistingDatabases();
      if (!mounted) return;
      await _showRestartRequired(
        l10n.settingsLocalEncryptionDoneTitle,
        l10n.settingsLocalEncryptionDoneBody,
      );
    } catch (error) {
      if (!mounted) return;
      // A restart is needed either way. The files are readable again, but
      // this process has closed the household database and can no longer
      // be sure which door the others need.
      await _showRestartRequired(
        l10n.settingsLocalEncryptionTitle,
        '${l10n.settingsLocalEncryptionFailed} '
        '${describeError(l10n, error)} '
        '${l10n.settingsLocalEncryptionDoneBody}',
      );
    }
  }

  /// The app cannot carry on in this process: every provider that held a
  /// database is now holding a file that has been replaced. Rather than
  /// let the next screen fail in its own way, the app says so and stops.
  Future<void> _showRestartRequired(String title, String message) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: AlertDialog(
            icon: const Icon(Icons.lock_outline),
            title: Text(title),
            content: Text(message),
          ),
        ),
      );
}

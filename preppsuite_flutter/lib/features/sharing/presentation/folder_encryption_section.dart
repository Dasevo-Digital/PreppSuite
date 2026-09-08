import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../household/application/household_providers.dart';
import '../application/folder_encryption.dart';
import '../application/shared_folder_access.dart';
import '../application/shared_folder_sync_service.dart';
import '../application/sharing_providers.dart';

/// Whether the folder this device shares through is encrypted.
final folderEncryptedProvider = FutureProvider.autoDispose<bool?>((ref) async {
  final folder = ref.watch(sharedFolderProvider).value?.folder;
  if (folder == null) return null;
  return FolderEncryption(folder: syncFolderFor(folder.value)).isEncrypted();
});

/// The encryption line in the sharing card.
///
/// Deliberately says what is true today rather than only offering a
/// button: a folder in the clear is the normal state for an app that has
/// always worked that way, and someone has to be told what that means
/// before they can decide it is fine.
class FolderEncryptionSection extends ConsumerStatefulWidget {
  const FolderEncryptionSection({super.key});

  @override
  ConsumerState<FolderEncryptionSection> createState() =>
      _FolderEncryptionSectionState();
}

class _FolderEncryptionSectionState
    extends ConsumerState<FolderEncryptionSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final syncError = ref.watch(sharedFolderProvider).value?.lastResult?.error;
    if (syncError == SharedFolderSyncError.encryptionChanged) {
      return const SizedBox.shrink(); // The sharing card explains the blocked sync.
    }
    final encrypted = ref.watch(folderEncryptedProvider).value;
    if (encrypted == null) return const SizedBox.shrink();

    final locked =
        encrypted &&
        ref.watch(sharedFolderProvider).value?.lastResult?.error ==
            SharedFolderSyncError.locked;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                encrypted ? Icons.lock_outline : Icons.lock_open_outlined,
                size: 20,
                color: encrypted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  encrypted
                      ? l10n.folderEncryptionOn
                      : l10n.folderEncryptionOff,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (!encrypted || locked) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _open(encrypted: encrypted),
              icon: Icon(encrypted ? Icons.key : Icons.lock_outline),
              label: Text(
                encrypted
                    ? l10n.folderEncryptionUnlock
                    : l10n.folderEncryptionEnable,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open({required bool encrypted}) async {
    final l10n = AppLocalizations.of(context)!;
    final passphrase = await showDialog<String>(
      context: context,
      builder: (_) => _PassphraseDialog(enabling: !encrypted, l10n: l10n),
    );
    if (passphrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final state = ref.read(sharedFolderProvider).value;
      final profile = ref.read(householdProfileProvider).value;
      final folder = state?.folder;
      if (folder == null || profile == null) return;

      final encryption = FolderEncryption(folder: syncFolderFor(folder.value));
      final error = encrypted
          ? await encryption.unlock(
              householdId: profile.id,
              passphrase: passphrase,
            )
          : await encryption.enable(
              householdId: profile.id,
              passphrase: passphrase,
            );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      if (error != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(_message(l10n, error))),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            encrypted
                ? l10n.folderEncryptionUnlocked
                : l10n.folderEncryptionEnabled,
          ),
        ),
      );
      ref.invalidate(folderEncryptedProvider);
      // Straight away, and republishing: this device's own file is still
      // in the clear until it is written again, and nothing about its
      // rows is dirty, so an ordinary run would leave it there.
      await ref
          .read(sharedFolderProvider.notifier)
          .syncNow(republish: !encrypted);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(AppLocalizations l10n, FolderEncryptionError error) =>
      switch (error) {
        FolderEncryptionError.noFolder => l10n.sharingErrorUnwritable,
        FolderEncryptionError.wrongPassphrase => l10n.folderEncryptionWrong,
        FolderEncryptionError.tooShort => l10n.folderEncryptionTooShort(
          minimumPassphraseLength,
        ),
        FolderEncryptionError.alreadyEncrypted => l10n.folderEncryptionOn,
        FolderEncryptionError.failed => l10n.sharingErrorFailed,
      };
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.enabling, required this.l10n});

  /// Turning encryption on asks twice and warns; unlocking asks once.
  final bool enabling;
  final AppLocalizations l10n;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
        widget.enabling
            ? l10n.folderEncryptionEnable
            : l10n.folderEncryptionUnlock,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.enabling) ...[
              // Said before the field, not after: someone who reads it
              // afterwards has already chosen.
              Text(
                l10n.folderEncryptionNoRecovery,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.folderEncryptionOtherDevices,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _first,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.folderEncryptionPassphrase,
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            if (widget.enabling) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _second,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.folderEncryptionRepeat,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.saveButton)),
      ],
    );
  }

  void _submit() {
    final l10n = widget.l10n;
    final passphrase = _first.text;

    if (widget.enabling) {
      if (passphrase.length < minimumPassphraseLength) {
        setState(
          () => _error = l10n.folderEncryptionTooShort(minimumPassphraseLength),
        );
        return;
      }
      if (passphrase != _second.text) {
        setState(() => _error = l10n.folderEncryptionMismatch);
        return;
      }
    } else if (passphrase.isEmpty) {
      return;
    }

    Navigator.of(context).pop(passphrase);
  }
}

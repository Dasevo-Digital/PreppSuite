import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'local_database_encryption.dart';

/// Stands in front of the app when the local databases cannot be opened.
///
/// Without it this state reaches the user as whatever screen happens to
/// touch the database first, failing with a sentence that says nothing.
/// It is not a rare state to plan for on paper: a reinstalled system, a
/// restored device, a Linux session whose keyring never started. The
/// files are all still there, and saying so is most of the help.
class LocalDataGate extends StatefulWidget {
  const LocalDataGate({super.key, required this.child, this.encryption});

  final Widget child;

  /// Only ever passed by tests. The app has exactly one of these, and a
  /// gate that read a different one would be guarding nothing.
  final LocalDatabaseEncryption? encryption;

  @override
  State<LocalDataGate> createState() => _LocalDataGateState();
}

class _LocalDataGateState extends State<LocalDataGate> {
  bool _busy = false;

  LocalDatabaseEncryption get _encryption =>
      widget.encryption ?? LocalDatabaseEncryption.instance;

  bool get _locked {
    final encryption = _encryption;
    return encryption.isInitialized &&
        encryption.mode == LocalDatabaseEncryptionMode.recoveryRequired;
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    await _encryption.retryInitialization();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _startOver() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.localDataRecoveryStartOver),
        content: Text(l10n.localDataRecoveryStartOverBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.localDataRecoveryStartOver),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    await _encryption.startOverKeepingUnreadableFiles();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.key_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.localDataRecoveryTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.localDataRecoveryBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (_busy)
                  const LinearProgressIndicator()
                else ...[
                  FilledButton(
                    onPressed: _retry,
                    child: Text(l10n.localDataRecoveryRetry),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _startOver,
                    child: Text(l10n.localDataRecoveryStartOver),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

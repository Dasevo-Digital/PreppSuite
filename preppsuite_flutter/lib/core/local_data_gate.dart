import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_lock.dart';
import 'local_database_encryption.dart';
import 'emergency_access.dart';
import 'protected_navigation.dart';

/// What "start over" does once it is confirmed.
///
/// The app lock goes with the household it guarded (#222). Its verifier
/// sat in the same key store that no longer opens the databases, and the
/// fresh installation behind it must reach setup, where the household
/// comes back from a backup. After the files and only if they really were
/// set aside: a household still in place keeps its lock.
Future<void> startOverLocalData(
  LocalDatabaseEncryption encryption, {
  AppLockStore? appLock,
}) async {
  await encryption.startOverKeepingUnreadableFiles();
  if (!encryption.isInitialized ||
      encryption.mode == LocalDatabaseEncryptionMode.recoveryRequired) {
    return;
  }
  await (appLock ?? AppLockStore()).forgetForFreshStart();
}

/// Stands in front of the app when the local databases cannot be opened.
///
/// Without it this state reaches the user as whatever screen happens to
/// touch the database first, failing with a sentence that says nothing.
/// It is not a rare state to plan for on paper: a reinstalled system, a
/// restored device, a Linux session whose keyring never started. The
/// files are all still there, and saying so is most of the help.
class LocalDataGate extends StatefulWidget {
  const LocalDataGate({
    super.key,
    required this.child,
    this.encryption,
    this.gateNavigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState>? gateNavigatorKey;

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

  Future<void> _startOver(BuildContext context) async {
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
    await startOverLocalData(_encryption);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedNavigation(
      gate: _locked ? Builder(builder: _recovery) : null,
      gateNavigatorKey: widget.gateNavigatorKey,
      child: widget.child,
    );
  }

  Widget _recovery(BuildContext context) {
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
                    onPressed: () => _startOver(context),
                    child: Text(l10n.localDataRecoveryStartOver),
                  ),
                ],
                // Whatever the key is doing, 112 is not waiting for it
                // (#136).
                const SizedBox(height: 24),
                const EmergencyAccessButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

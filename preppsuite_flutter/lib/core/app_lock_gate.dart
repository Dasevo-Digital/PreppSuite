import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_lock.dart';
import 'app_lock_provider.dart';
import 'biometric_unlock.dart';
import 'emergency_access.dart';
import 'protected_navigation.dart';

/// Locks the whole UI after the app leaves the foreground.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child, this.gateNavigatorKey});

  final Widget child;
  final GlobalKey<NavigatorState>? gateNavigatorKey;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;
  final _controller = TextEditingController();
  bool _unlocked = false;
  bool _checking = false;
  bool _wrongPassphrase = false;
  int _generation = 0;
  bool _foreground = true;

  /// Whether face or fingerprint has been asked for since the app was last
  /// locked: once by itself, then only on the button (#143).
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: _lock,
      onPause: _lock,
      onDetach: _lock,
      onResume: () {
        if (mounted) setState(() => _foreground = true);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _lock() {
    if (mounted) {
      setState(() {
        _generation++;
        _foreground = false;
        _unlocked = false;
        _prompted = false;
        _checking = false;
        _controller.clear();
      });
    }
  }

  Future<void> _unlockWithBiometrics() async {
    final generation = _generation;
    _prompted = true;
    final l10n = AppLocalizations.of(context)!;
    final recognised = await ref
        .read(biometricAuthProvider)
        .authenticate(l10n.appLockBiometricReason);
    if (!mounted || !recognised || generation != _generation) return;
    setState(() {
      _unlocked = true;
      _controller.clear();
    });
  }

  Future<void> _unlock() async {
    if (_checking) return;
    final generation = _generation;
    setState(() {
      _checking = true;
      _wrongPassphrase = false;
    });
    final accepted = await AppLockStore().verify(_controller.text);
    if (!mounted || generation != _generation) return;
    setState(() {
      _checking = false;
      _wrongPassphrase = !accepted;
      _unlocked = accepted;
      if (accepted) _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(appLockProvider);
    final gate = enabled.when<Widget?>(
      loading: () => const LoadingWithEmergencyAccess(),
      // A lock whose state cannot be read must never reveal the protected
      // surface. Secure storage can temporarily be unavailable after an OS
      // update or a restored device; offer recovery, but fail closed.
      error: (_, _) => _LockStatusUnavailable(
        onRetry: () => ref.invalidate(appLockProvider),
      ),
      data: (isEnabled) {
        if (!isEnabled || _unlocked) return null;
        final l10n = AppLocalizations.of(context)!;
        final biometric = ref.watch(appLockBiometricProvider).value ?? false;
        if (biometric && !_prompted && _foreground) {
          _prompted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _unlockWithBiometrics();
          });
        }
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
                    const Icon(Icons.lock_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      l10n.appLockUnlockTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _unlock(),
                      decoration: InputDecoration(
                        labelText: l10n.appLockPassphraseLabel,
                        errorText: _wrongPassphrase
                            ? l10n.appLockIncorrectPassphrase
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _checking ? null : _unlock,
                      child: _checking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.appLockUnlockButton),
                    ),
                    if (biometric) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _unlockWithBiometrics,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(l10n.appLockBiometricButton),
                      ),
                    ],
                    // As on a locked phone: the emergency help needs no
                    // passphrase and shows nothing private (#137).
                    const SizedBox(height: 24),
                    const EmergencyAccessButton(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    return ProtectedNavigation(
      gate: gate,
      gateNavigatorKey: widget.gateNavigatorKey,
      child: widget.child,
    );
  }
}

/// The lock is known to be set, and its state cannot be read.
///
/// Usually that passes: a key store that is busy after an update answers
/// again on the next try. On a device the household moved to it does not.
/// The marker that a lock exists came across, and the verifier, which the
/// key store keeps, did not -- Android's secure storage deletes what it can
/// no longer decrypt. Where the database is encrypted, "start over" in the
/// data gate takes the lock with it (#222). An unencrypted household opens
/// its database fine and then stood here for good, with no passphrase that
/// could ever open it (#223). The device's own screen lock is the way out.
class _LockStatusUnavailable extends ConsumerStatefulWidget {
  const _LockStatusUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  ConsumerState<_LockStatusUnavailable> createState() =>
      _LockStatusUnavailableState();
}

class _LockStatusUnavailableState
    extends ConsumerState<_LockStatusUnavailable> {
  bool _resetting = false;
  String? _problem;

  Future<void> _reset() async {
    if (_resetting) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _resetting = true;
      _problem = null;
    });
    final answer = await ref
        .read(deviceOwnerCheckProvider)
        .confirm(l10n.appLockResetReason);
    if (!mounted) return;
    var reset = answer == DeviceOwnerAnswer.confirmed;
    if (answer == DeviceOwnerAnswer.cannotAsk) {
      // Nothing to prove it with. Whoever holds such a device can already
      // do anything else on it, and the lock cannot be opened by anyone.
      reset = await _confirmWithoutScreenLock(l10n);
      if (!mounted) return;
    }
    if (!reset) {
      setState(() {
        _resetting = false;
        _problem = answer == DeviceOwnerAnswer.refused
            ? l10n.appLockResetRefused
            : null;
      });
      return;
    }
    final open = await ref.read(appLockProvider.notifier).forgetUnreadable();
    if (open) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.appLockResetDone)));
    }
    if (!mounted) return;
    setState(() {
      _resetting = false;
      _problem = open ? null : l10n.appLockResetFailed;
    });
  }

  Future<bool> _confirmWithoutScreenLock(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.appLockResetConfirmTitle),
        content: Text(l10n.appLockResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.appLockResetConfirmAction),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final problem = _problem;
    return Scaffold(
      body: Center(
        // Scrolls: with the way out added it no longer fits a small
        // phone in landscape, nor any phone in crisis mode's large text.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.appLockStatusUnavailableTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appLockStatusUnavailableBody,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _resetting ? null : widget.onRetry,
                  child: Text(l10n.appLockRetry),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.appLockResetHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _resetting ? null : _reset,
                  child: Text(l10n.appLockResetButton),
                ),
                if (problem != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    problem,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
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

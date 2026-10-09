import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_lock.dart';
import 'app_lock_provider.dart';
import 'biometric_unlock.dart';
import 'emergency_access.dart';

/// Locks the whole UI after the app leaves the foreground.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;
  final _controller = TextEditingController();
  bool _unlocked = false;
  bool _checking = false;
  bool _wrongPassphrase = false;

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
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _lock() {
    if (_unlocked && mounted) {
      setState(() {
        _unlocked = false;
        _prompted = false;
      });
    }
  }

  Future<void> _unlockWithBiometrics() async {
    _prompted = true;
    final l10n = AppLocalizations.of(context)!;
    final recognised = await ref
        .read(biometricAuthProvider)
        .authenticate(l10n.appLockBiometricReason);
    if (!mounted || !recognised) return;
    setState(() {
      _unlocked = true;
      _controller.clear();
    });
  }

  Future<void> _unlock() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _wrongPassphrase = false;
    });
    final accepted = await AppLockStore().verify(_controller.text);
    if (!mounted) return;
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
    return enabled.when(
      loading: () => const LoadingWithEmergencyAccess(),
      // A lock whose state cannot be read must never reveal the protected
      // surface. Secure storage can temporarily be unavailable after an OS
      // update or a restored device; offer recovery, but fail closed.
      error: (_, _) => _LockStatusUnavailable(
        onRetry: () => ref.invalidate(appLockProvider),
      ),
      data: (isEnabled) {
        if (!isEnabled || _unlocked) return widget.child;
        final l10n = AppLocalizations.of(context)!;
        final biometric = ref.watch(appLockBiometricProvider).value ?? false;
        if (biometric && !_prompted) {
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
  }
}

class _LockStatusUnavailable extends StatelessWidget {
  const _LockStatusUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
                  onPressed: onRetry,
                  child: Text(l10n.appLockRetry),
                ),
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

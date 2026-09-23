import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_lock.dart';
import 'app_lock_provider.dart';

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
    if (_unlocked && mounted) setState(() => _unlocked = false);
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => widget.child,
      data: (isEnabled) {
        if (!isEnabled || _unlocked) return widget.child;
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

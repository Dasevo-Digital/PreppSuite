import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_lock.dart';
import '../../../core/app_lock_provider.dart';
import '../../../core/biometric_unlock.dart';
import '../../../l10n/generated/app_localizations.dart';

class AppLockCard extends ConsumerWidget {
  const AppLockCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appLockProvider);
    final enabled = status.when(
      data: (value) => value,
      loading: () => false,
      error: (_, _) => false,
    );
    final unavailable = status.hasError;
    // Offered only with the lock on and a sensor this device can ask.
    final offerBiometric =
        enabled && (ref.watch(biometricAvailableProvider).value ?? false);
    final biometric = ref.watch(appLockBiometricProvider).value ?? false;
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              enabled ? Icons.lock_outline : Icons.lock_open_outlined,
            ),
            title: Text(l10n.appLockTitle),
            subtitle: Text(
              unavailable
                  ? l10n.appLockSettingsUnavailable
                  : enabled
                  ? l10n.appLockEnabledHint
                  : l10n.appLockDisabledHint,
            ),
            trailing: Switch(
              value: enabled,
              onChanged: unavailable || status.isLoading
                  ? null
                  : (value) async {
                      if (value) {
                        final passphrase = await _choosePassphrase(context);
                        if (passphrase == null || !context.mounted) return;
                        await ref
                            .read(appLockProvider.notifier)
                            .enable(passphrase);
                        if (context.mounted) {
                          _show(context, l10n.appLockEnabled);
                        }
                        return;
                      }

                      final passphrase = await _askPassphrase(
                        context,
                        title: l10n.appLockDisableTitle,
                        confirmLabel: l10n.appLockDisableButton,
                      );
                      if (passphrase == null || !context.mounted) return;
                      final verified = await AppLockStore().verify(passphrase);
                      if (!context.mounted) return;
                      if (!verified) {
                        _show(context, l10n.appLockIncorrectPassphrase);
                        return;
                      }
                      await ref.read(appLockProvider.notifier).disable();
                      if (context.mounted) _show(context, l10n.appLockDisabled);
                    },
            ),
          ),
          if (offerBiometric)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(l10n.appLockBiometricTitle),
              subtitle: Text(l10n.appLockBiometricHint),
              value: biometric,
              onChanged: (value) async {
                final controller = ref.read(appLockBiometricProvider.notifier);
                if (!value) {
                  await controller.disable();
                  return;
                }
                final confirmed = await controller.enable(
                  l10n.appLockBiometricReason,
                );
                if (!confirmed && context.mounted) {
                  _show(context, l10n.appLockBiometricNotConfirmed);
                }
              },
            ),
        ],
      ),
    );
  }

  void _show(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> _choosePassphrase(BuildContext context) async {
    final first = TextEditingController();
    final second = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => _PassphraseDialog(
          title: l10n.appLockSetTitle,
          confirmLabel: l10n.appLockEnableButton,
          confirmation: second,
          passphrase: first,
          l10n: l10n,
        ),
      );
    } finally {
      first.dispose();
      second.dispose();
    }
  }

  Future<String?> _askPassphrase(
    BuildContext context, {
    required String title,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => _PassphraseDialog(
          title: title,
          confirmLabel: confirmLabel,
          passphrase: controller,
          l10n: l10n,
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({
    required this.title,
    required this.confirmLabel,
    required this.passphrase,
    required this.l10n,
    this.confirmation,
  });

  final String title;
  final String confirmLabel;
  final TextEditingController passphrase;
  final TextEditingController? confirmation;
  final AppLocalizations l10n;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  String? _error;

  void _submit() {
    if (widget.passphrase.text.runes.length < 12) {
      setState(() => _error = widget.l10n.appLockPassphraseTooShort);
      return;
    }
    if (widget.confirmation != null &&
        widget.passphrase.text != widget.confirmation!.text) {
      setState(() => _error = widget.l10n.appLockPassphraseMismatch);
      return;
    }
    Navigator.pop(context, widget.passphrase.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.l10n.appLockDialogHint),
        const SizedBox(height: 12),
        TextField(
          controller: widget.passphrase,
          autofocus: true,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: widget.confirmation == null
              ? TextInputAction.done
              : TextInputAction.next,
          onSubmitted: (_) {
            if (widget.confirmation == null) _submit();
          },
          decoration: InputDecoration(
            labelText: widget.l10n.appLockPassphraseLabel,
            errorText: _error,
          ),
        ),
        if (widget.confirmation != null) ...[
          const SizedBox(height: 8),
          TextField(
            controller: widget.confirmation,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: widget.l10n.appLockConfirmLabel,
            ),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../main.dart';
import 'server_url.dart';

/// Asks for the address of the server to talk to.
///
/// Reachable from the sign-in screen as well as from Settings, and that is
/// the point: Settings sits behind sign-in, so someone whose address is
/// wrong could never have reached it — they would have been stuck at a
/// sign-in screen that can never succeed, with no way out but rebuilding
/// the app.
class ServerUrlDialog extends ConsumerStatefulWidget {
  const ServerUrlDialog({super.key});

  /// Shows the dialog and reconnects if the address changed. Returns true
  /// when a new address was applied.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const ServerUrlDialog(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<ServerUrlDialog> createState() => _ServerUrlDialogState();
}

class _ServerUrlDialogState extends ConsumerState<ServerUrlDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(serverUrlProvider),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);

    final accepted = await ref
        .read(serverUrlProvider.notifier)
        .setServerUrl(_controller.text);

    if (!mounted) return;
    if (!accepted) {
      setState(() => _error = l10n.serverAddressInvalid);
      return;
    }

    // Rebuild the client against the new address. It carries the auth
    // session, so this signs the user out — an account on one server says
    // nothing about another.
    connectToServer(ref.read(serverUrlProvider));
    navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.serverAddressLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.serverAddressHint),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'preppsuite.example.com',
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.serverAddressSignOutHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}

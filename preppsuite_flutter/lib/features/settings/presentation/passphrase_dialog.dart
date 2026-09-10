import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../sharing/application/folder_encryption.dart'
    show minimumPassphraseLength;

/// Asks for the passphrase that protects a backup.
///
/// A widget of its own so it owns its controllers. Created beside
/// `showDialog` and disposed once it returned, they were being disposed
/// while the closing animation still had the fields mounted -- which
/// throws "A TextEditingController was used after being disposed". The
/// charge reminder had the same shape and did throw.
class PassphraseDialog extends StatefulWidget {
  const PassphraseDialog({
    super.key,
    required this.l10n,
    required this.confirm,
  });

  final AppLocalizations l10n;

  /// True when a backup is being written, i.e. the passphrase is being
  /// chosen rather than recalled. Only then is a second field shown, and
  /// only then does the warning below make sense.
  final bool confirm;

  @override
  State<PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<PassphraseDialog> {
  late final TextEditingController _first = TextEditingController();
  late final TextEditingController _second = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _submit() {
    // Twelve, not eight. This file can be carried off and attacked
    // offline for as long as somebody likes, and it holds the whole
    // household — emergency cards with blood group, medication and
    // conditions included. Argon2id at 64 MB makes each guess expensive;
    // the passphrase decides how many guesses are needed.
    //
    // The same constant the encrypted shared folder uses, rather than a
    // second twelve written next to it: both protect the same household
    // under the same KDF, and two numbers for one rule drift apart.
    if (_first.text.length < minimumPassphraseLength ||
        (widget.confirm && _first.text != _second.text)) {
      setState(
        () => _error = widget.l10n.backupPassphraseInvalid(
          minimumPassphraseLength,
        ),
      );
      return;
    }
    Navigator.pop(context, _first.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.backupPassphraseTitle),
      // Scrollable, because the warning above the fields is several lines
      // of prose and an AlertDialog does not grow past the screen. At
      // twice the font size the column overflowed the dialog and the
      // second field went off the bottom — where somebody who needs large
      // type cannot confirm a passphrase they are being made to type
      // twice.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Said where the passphrase is chosen, not only in the hint on
            // the card. Argon2id at 64 MB is exactly what makes a forgotten
            // passphrase final: there is no recovery, and the file is the
            // household's own copy of everything.
            if (widget.confirm) ...[
              Text(
                l10n.backupPassphraseWarning,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _first,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.backupPassphrase,
                errorText: _error,
              ),
            ),
            if (widget.confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _second,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.backupPassphraseRepeat,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

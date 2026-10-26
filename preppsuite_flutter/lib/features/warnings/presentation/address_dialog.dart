import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Asks for an address or a place, or null when the dialog was closed.
///
/// A widget of its own because the field's controller has to live exactly
/// as long as the dialog. The three screens that asked for an address
/// each disposed theirs as soon as `showDialog` returned -- while the
/// dialog was still fading out and building the field again, now with a
/// controller that was gone. A debug build stopped on it; the widget test
/// for #217 was the first to type into one of them.
Future<String?> askAddress(BuildContext context, {required String title}) =>
    showDialog<String>(
      context: context,
      builder: (_) => _AddressDialog(title: title),
    );

class _AddressDialog extends StatefulWidget {
  const _AddressDialog({required this.title});

  final String title;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.heavyRainAddressHint),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.heavyRainCheck),
        ),
      ],
    );
  }
}

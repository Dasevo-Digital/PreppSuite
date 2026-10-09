import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';

/// Calls a number, and says so plainly when this device cannot (#135).
///
/// Every call button in the app used to hand `tel:` to the system and
/// stop there. On a phone that is a call. On a Mac without an iPhone
/// paired, on Windows and Linux, on an iPad without a SIM, the system has
/// nothing to hand it to -- and the button that says "112" did nothing,
/// without a word, in the minute somebody pressed it because they needed
/// it. Now a call that does not start is a dialog with the number in large
/// figures, to be dialled on whatever phone is there.
///
/// [launch] is injectable for tests; it is `launchUrl` otherwise. Whether
/// the call starts is its answer, and a throw counts as no.
Future<void> callNumber(
  BuildContext context,
  String number, {
  Future<bool> Function(Uri uri)? launch,
}) async {
  final dialable = dialableNumber(number);
  if (dialable.isEmpty) return;
  bool started;
  try {
    started = await (launch ?? launchUrl)(Uri(scheme: 'tel', path: dialable));
  } on Object {
    started = false;
  }
  if (started || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => CannotCallDialog(number: number.trim()),
  );
}

/// [number] as a `tel:` link wants it: digits, and a leading plus.
String dialableNumber(String number) {
  final trimmed = number.trim();
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  return trimmed.startsWith('+') ? '+$digits' : digits;
}

/// What is shown when this device cannot place the call.
class CannotCallDialog extends StatelessWidget {
  const CannotCallDialog({super.key, required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.phone_disabled_outlined),
      title: Text(l10n.callUnavailableTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.callUnavailableBody, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          SelectableText(
            number,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Clipboard.setData(ClipboardData(text: number)),
          icon: const Icon(Icons.copy),
          label: Text(l10n.callUnavailableCopy),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

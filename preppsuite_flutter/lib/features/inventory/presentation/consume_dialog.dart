import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';

/// Asks how much of an item was used up. Pre-filled with 1, since
/// deducting a single unit is the common case and should take one tap.
class ConsumeDialog extends StatefulWidget {
  const ConsumeDialog({super.key, required this.item, required this.l10n});

  final InventoryItem item;
  final AppLocalizations l10n;

  @override
  State<ConsumeDialog> createState() => _ConsumeDialogState();
}

class _ConsumeDialogState extends State<ConsumeDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.item.quantity >= 1 ? '1' : _format(widget.item.quantity),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  void _submit() {
    // Accepts a comma as decimal separator — the German keyboard offers
    // that one, and the CSV importer is lenient about it for the same
    // reason.
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || parsed <= 0 || parsed > widget.item.quantity) {
      setState(() => _error = widget.l10n.consumeInvalidAmount);
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return AlertDialog(
      title: Text(l10n.consumeDialogTitle(widget.item.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.consumeDialogRemaining(
              _format(widget.item.quantity),
              widget.item.unit,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.consumeDialogAmountLabel,
              suffixText: widget.item.unit,
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.item.quantity),
          child: Text(l10n.consumeDialogAll),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.consumeDialogConfirm),
        ),
      ],
    );
  }
}

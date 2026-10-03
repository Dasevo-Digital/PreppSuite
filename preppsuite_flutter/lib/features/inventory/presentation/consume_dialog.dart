import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/food_amount.dart';
import '../application/item_package.dart';

/// Asks how much of an item was used up, and answers in the item's unit.
///
/// Callers only ever get the item's unit back, whatever was typed: the
/// stock, and with it the supply calculator's calories, is kept in that
/// unit and nothing else.
///
/// **What it suggests is the point.** It used to suggest "1" for every
/// item, which suited a time when stock was counted in pieces. Food is
/// counted in grams now, so the quick tap took one gram off a kilo of
/// rice — and the calorie total moved by four, which read as "consuming
/// does not reduce the calories" (#90). So:
///
/// * an item with a package suggests one package, and says what that is
///   in the unit — "Das sind 370 g." — so nobody has to work it out;
/// * an item counted in a measure without a package suggests nothing,
///   because there is no amount of grams that is usually right;
/// * anything counted in pieces keeps the one, which was right for it.
class ConsumeDialog extends StatefulWidget {
  const ConsumeDialog({super.key, required this.item, required this.l10n});

  final InventoryItem item;
  final AppLocalizations l10n;

  @override
  State<ConsumeDialog> createState() => _ConsumeDialogState();
}

class _ConsumeDialogState extends State<ConsumeDialog> {
  late final ItemPackage? _package = ItemPackage.of(widget.item);

  /// Whether the field is read as packages rather than in the unit.
  late bool _inPackages = _package != null;

  late final TextEditingController _controller = TextEditingController(
    text: _suggestion(),
  );
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _quantity => widget.item.quantity;

  String _suggestion() {
    final package = _package;
    if (package != null) {
      // One package, or what is left when that is less than one.
      final available = package.toPackages(_quantity);
      return _format(available >= 1 ? 1 : available);
    }
    if (isMeasurableUnit(widget.item.unit)) return '';
    return _quantity >= 1 ? '1' : _format(_quantity);
  }

  String _format(double value) {
    final rounded = (value * 1000).round() / 1000;
    final text = rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toString();
    // The field takes a comma, and a German reader expects one back.
    return widget.l10n.localeName.startsWith('de')
        ? text.replaceAll('.', ',')
        : text;
  }

  double? get _typed =>
      double.tryParse(_controller.text.trim().replaceAll(',', '.'));

  /// What the field comes to in the item's unit, or null.
  double? get _amount {
    final typed = _typed;
    if (typed == null) return null;
    final package = _package;
    return _inPackages && package != null ? package.toUnits(typed) : typed;
  }

  void _switchTo(bool inPackages) {
    final package = _package;
    if (package == null || inPackages == _inPackages) return;
    // Carries what was typed across, so switching to grams to check
    // shows the same amount rather than a different one.
    final typed = _typed;
    setState(() {
      _inPackages = inPackages;
      _error = null;
      if (typed != null) {
        _controller.text = _format(
          inPackages ? package.toPackages(typed) : package.toUnits(typed),
        );
      }
    });
  }

  void _submit() {
    final amount = _amount;
    // A hair of tolerance: three jars of 370 g against a stock of 1110 g
    // must not be refused over the last bit of a floating-point product.
    if (amount == null || amount <= 0 || amount > _quantity + 1e-6) {
      setState(() => _error = widget.l10n.consumeInvalidAmount);
      return;
    }
    Navigator.of(context).pop(amount > _quantity ? _quantity : amount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final package = _package;
    final unit = widget.item.unit;
    final amount = _amount;

    return AlertDialog(
      // The package switch and the "Das sind 370 g." line make this
      // taller than it was; at twice the font size it no longer fitted
      // and the bottom was cut off.
      scrollable: true,
      title: Text(l10n.consumeDialogTitle(widget.item.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.consumeDialogRemaining(_format(_quantity), unit)),
          if (package != null) ...[
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(package.name)),
                ButtonSegment(value: false, label: Text(unit)),
              ],
              selected: {_inPackages},
              showSelectedIcon: false,
              onSelectionChanged: (selection) => _switchTo(selection.single),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.consumeDialogAmountLabel,
              hintText: _controller.text.isEmpty
                  ? l10n.consumeDialogAmountHint(unit)
                  : null,
              suffixText: _inPackages && package != null ? package.name : unit,
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_inPackages && package != null && amount != null) ...[
            const SizedBox(height: 8),
            Text(l10n.consumeDialogEquals(_format(amount), unit)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_quantity),
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

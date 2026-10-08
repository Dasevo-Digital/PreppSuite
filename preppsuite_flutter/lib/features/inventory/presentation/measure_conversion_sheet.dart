import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/inventory_controller.dart';
import '../application/inventory_providers.dart';
import '../application/supply_calculator.dart';
import 'unit_info_dialog.dart';

/// The food the supply calculator cannot count, each with a way to make it
/// count (#109).
///
/// It used to stop at saying so: "6 Dosen" carries no weight, so it adds
/// no calories, and the notice explained why. The household then had to
/// open each item, convert six tins to grams by hand and remember to name
/// the tin as the package. Here it is one number per item -- what one tin
/// holds -- and `InventoryController.countInMeasure` does the rest.
Future<void> showMeasureConversion(BuildContext context, String householdId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MeasureConversionSheet(householdId: householdId),
    );

class _MeasureConversionSheet extends ConsumerWidget {
  const _MeasureConversionSheet({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = foodWithoutMeasure(
      ref.watch(inventoryItemsProvider(householdId)).value ?? const [],
    );
    final number = NumberFormat.decimalPattern(l10n.localeName);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(l10n.measureConvertTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.measureConvertIntro),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => showUnitInfo(context, uncounted: items.length),
                child: Text(l10n.unitInfoAction),
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.measureConvertNoneLeft),
              ),
            for (final item in items)
              Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text(
                    '${number.format(item.quantity)} ${item.unit}',
                  ),
                  trailing: TextButton(
                    onPressed: () => _convert(context, ref, item),
                    child: Text(l10n.measureConvertAction),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _convert(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final answer = await showDialog<(double, String)>(
      context: context,
      builder: (_) => _PerPackageDialog(package: item.unit),
    );
    if (answer == null || !context.mounted) return;
    final (size, measure) = answer;
    await ref
        .read(inventoryControllerProvider(householdId))
        .countInMeasure(item, perPackage: size, measure: measure);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.measureConvertDone(item.name))));
  }
}

/// Asks what one package holds, in grams or millilitres.
class _PerPackageDialog extends StatefulWidget {
  const _PerPackageDialog({required this.package});

  final String package;

  @override
  State<_PerPackageDialog> createState() => _PerPackageDialogState();
}

class _PerPackageDialogState extends State<_PerPackageDialog> {
  final _controller = TextEditingController();
  var _measure = 'g';
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final value = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (value == null || !value.isFinite || value <= 0) {
      setState(() => _error = l10n.measureConvertInvalid);
      return;
    }
    Navigator.of(context).pop((value, _measure));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.measureConvertPrompt(widget.package)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: l10n.measureConvertHint,
              errorText: _error,
              suffixText: _measure,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'g', label: Text('g')),
              ButtonSegment(value: 'ml', label: Text('ml')),
            ],
            selected: {_measure},
            onSelectionChanged: (chosen) =>
                setState(() => _measure = chosen.single),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/categories.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/inventory_category_l10n.dart';
import '../application/inventory_controller.dart';
import '../application/inventory_csv_import.dart';
import '../application/inventory_csv_import_l10n.dart';

/// Lets the user pick a CSV file, review every parsed row, fix up ones that
/// didn't parse cleanly (or edit/remove ones that did), and import the
/// resulting valid set as inventory items. Pops with the number of
/// imported items so the caller can show a confirmation.
class InventoryCsvImportScreen extends ConsumerStatefulWidget {
  const InventoryCsvImportScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<InventoryCsvImportScreen> createState() =>
      _InventoryCsvImportScreenState();
}

class _InventoryCsvImportScreenState
    extends ConsumerState<InventoryCsvImportScreen> {
  String? _fileName;

  /// Every data row from the last parsed file, valid or not. The user can
  /// edit (fixing invalid ones, or tweaking valid ones) or remove entries
  /// from here before committing.
  List<InventoryCsvRow>? _rows;

  bool _missingColumns = false;
  String? _readError;
  bool _isParsing = false;
  bool _isImporting = false;

  Future<void> _pickFile() async {
    setState(() {
      _readError = null;
      _rows = null;
      _missingColumns = false;
    });

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _fileName = file.name;
      _isParsing = true;
    });

    try {
      final content = decodeCsvBytes(bytes);
      final result = parseInventoryCsv(content);
      if (!mounted) return;
      setState(() {
        _rows = List.of(result.rows);
        _missingColumns = result.missingColumns;
        _isParsing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _readError = error.toString();
        _isParsing = false;
      });
    }
  }

  Future<void> _editRow(int index) async {
    final rows = _rows;
    if (rows == null) return;

    final edited = await showDialog<ParsedInventoryRow>(
      context: context,
      builder: (context) => _EditRowDialog(row: rows[index]),
    );
    if (edited == null || !mounted) return;

    setState(() => rows[index] = rows[index].withParsed(edited));
  }

  void _removeRow(int index) {
    setState(() => _rows?.removeAt(index));
  }

  Future<void> _import() async {
    final validRows = [
      for (final row in _rows ?? const <InventoryCsvRow>[]) ?row.parsed,
    ];
    if (validRows.isEmpty) return;

    setState(() => _isImporting = true);
    await ref
        .read(inventoryControllerProvider(widget.householdId))
        .addItemsBulk(validRows);

    if (mounted) Navigator.of(context).pop(validRows.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = _rows;
    final validCount = rows?.where((row) => row.isValid).length ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.csvImportTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.csvImportInstructionsTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.csvImportInstructionsBody),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isParsing || _isImporting ? null : _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _fileName == null
                        ? l10n.csvImportPickFileButton
                        : l10n.csvImportChangeFileButton,
                  ),
                ),
                if (_fileName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _fileName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_isParsing) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(l10n.csvImportParsing),
                      ],
                    ),
                  ),
                ],
                if (_readError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.csvImportFileReadError(_readError!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_missingColumns) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.csvImportReasonMissingColumns,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (rows != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.csvImportSummary(validCount, rows.length),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (rows.isEmpty) ...[
                    const SizedBox(height: 16),
                    Text(l10n.csvImportNoValidRows),
                  ] else ...[
                    const SizedBox(height: 16),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < rows.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _ImportRowTile(
                              row: rows[i],
                              l10n: l10n,
                              onTap: () => _editRow(i),
                              onRemove: () => _removeRow(i),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: validCount == 0 || _isImporting ? null : _import,
                    child: _isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.csvImportImportButton(validCount)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportRowTile extends StatelessWidget {
  const _ImportRowTile({
    required this.row,
    required this.l10n,
    required this.onTap,
    required this.onRemove,
  });

  final InventoryCsvRow row;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final parsed = row.parsed;
    final error = row.error;

    if (parsed != null) {
      return ListTile(
        leading: Icon(categoryIcon(parsed.category)),
        title: Text(parsed.name),
        subtitle: Text(
          '${_formatNumber(parsed.quantity)} ${parsed.unit} · ${parsed.storageLocation}',
        ),
        onTap: onTap,
        trailing: _RowActions(l10n: l10n, onTap: onTap, onRemove: onRemove),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.error_outline, color: colorScheme.error),
      title: Text(
        row.nameRaw.isNotEmpty
            ? row.nameRaw
            : l10n.csvImportRowLabel(row.rowNumber),
      ),
      subtitle: Text(
        error != null
            ? l10n.csvImportRowError(
                row.rowNumber,
                localizeCsvErrorReason(l10n, error),
              )
            : l10n.csvImportRowLabel(row.rowNumber),
        style: TextStyle(color: colorScheme.error),
      ),
      onTap: onTap,
      trailing: _RowActions(l10n: l10n, onTap: onTap, onRemove: onRemove),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.l10n,
    required this.onTap,
    required this.onRemove,
  });

  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: l10n.csvImportEditRowTooltip,
          onPressed: onTap,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.csvImportRemoveRowTooltip,
          onPressed: onRemove,
        ),
      ],
    );
  }
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

/// A form, scoped to a single pending CSV row, that lets the user fill in
/// or correct its fields before import. Works equally for a row that
/// already parsed cleanly (editing it further) and one that didn't (fixing
/// it), seeding each field from the parsed value if there is one, or the
/// raw CSV text otherwise. Returns the resulting row via [Navigator.pop],
/// or `null` if cancelled.
class _EditRowDialog extends StatefulWidget {
  const _EditRowDialog({required this.row});

  final InventoryCsvRow row;

  @override
  State<_EditRowDialog> createState() => _EditRowDialogState();
}

class _EditRowDialogState extends State<_EditRowDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _storageLocationController;
  late final TextEditingController _minQuantityController;
  late final TextEditingController _notesController;
  late InventoryItemCategory _category;
  DateTime? _expirationDate;

  @override
  void initState() {
    super.initState();
    final row = widget.row;
    final parsed = row.parsed;

    _nameController = TextEditingController(text: parsed?.name ?? row.nameRaw);
    _quantityController = TextEditingController(
      text: parsed != null ? _formatNumber(parsed.quantity) : row.quantityRaw,
    );
    _unitController = TextEditingController(text: parsed?.unit ?? row.unitRaw);
    _storageLocationController = TextEditingController(
      text: parsed?.storageLocation ?? row.storageLocationRaw,
    );
    _minQuantityController = TextEditingController(
      text: parsed?.minQuantity != null
          ? _formatNumber(parsed!.minQuantity!)
          : row.minQuantityRaw,
    );
    _notesController = TextEditingController(
      text: parsed?.notes ?? row.notesRaw,
    );
    _category =
        parsed?.category ??
        matchCategory(row.categoryRaw) ??
        InventoryItemCategory.other;
    _expirationDate =
        parsed?.expirationDate ??
        (row.expirationDateRaw.isEmpty
            ? null
            : parseCsvDate(row.expirationDateRaw));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _storageLocationController.dispose();
    _minQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final minQuantityText = _minQuantityController.text.trim();
    final notes = _notesController.text.trim();

    Navigator.of(context).pop(
      ParsedInventoryRow(
        name: _nameController.text.trim(),
        category: _category,
        quantity: double.parse(_quantityController.text.trim()),
        unit: _unitController.text.trim(),
        storageLocation: _storageLocationController.text.trim(),
        expirationDate: _expirationDate,
        minQuantity: minQuantityText.isEmpty
            ? null
            : double.parse(minQuantityText),
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  String? Function(String?) _numberValidator(
    AppLocalizations l10n, {
    required bool required,
  }) {
    return (value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) {
        return required ? l10n.fieldRequired : null;
      }
      return double.tryParse(trimmed) == null ? l10n.invalidNumber : null;
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = widget.row.error;

    return AlertDialog(
      title: Text(l10n.csvImportEditRowTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) ...[
                  Text(
                    localizeCsvErrorReason(l10n, error),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.itemNameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.fieldRequired
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<InventoryItemCategory>(
                  isExpanded: true,
                  initialValue: _category,
                  decoration: InputDecoration(labelText: l10n.categoryLabel),
                  items: [
                    for (final category in InventoryItemCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(localizeCategory(l10n, category)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: l10n.quantityLabel,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _numberValidator(l10n, required: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: InputDecoration(labelText: l10n.unitLabel),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? l10n.fieldRequired
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _storageLocationController,
                  decoration: InputDecoration(
                    labelText: l10n.storageLocationLabel,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.fieldRequired
                      : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.expirationDateLabel),
                  subtitle: Text(
                    _expirationDate == null
                        ? '—'
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(_expirationDate!),
                  ),
                  trailing: _expirationDate == null
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: l10n.clearDateButton,
                          onPressed: () =>
                              setState(() => _expirationDate = null),
                        ),
                  onTap: _pickExpirationDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _minQuantityController,
                  decoration: InputDecoration(labelText: l10n.minQuantityLabel),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _numberValidator(l10n, required: false),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: l10n.notesLabel),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}

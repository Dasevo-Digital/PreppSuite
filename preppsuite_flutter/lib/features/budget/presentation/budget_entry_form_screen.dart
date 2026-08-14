import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart' show InventoryItemCategory;

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../inventory/application/inventory_category_l10n.dart';
import '../application/budget_controller.dart';

const _currencies = ['EUR', 'CHF', 'GBP', 'NOK', 'SEK', 'DKK'];

class BudgetEntryFormScreen extends ConsumerStatefulWidget {
  const BudgetEntryFormScreen({
    super.key,
    required this.householdId,
    this.existing,
  });

  final String householdId;
  final BudgetEntry? existing;

  @override
  ConsumerState<BudgetEntryFormScreen> createState() =>
      _BudgetEntryFormScreenState();
}

class _BudgetEntryFormScreenState extends ConsumerState<BudgetEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _amountController;
  late String _currency;
  late InventoryItemCategory _category;
  DateTime? _purchaseDate;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _amountController = TextEditingController(
      text: existing != null ? (existing.amountCents / 100).toStringAsFixed(2) : '',
    );
    _currency = existing?.currency ?? 'EUR';
    _category = existing != null
        ? InventoryItemCategoryX.fromName(existing.category)
        : InventoryItemCategory.other;
    _purchaseDate = existing?.purchaseDate;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final controller = ref.read(budgetControllerProvider(widget.householdId));
    final amountCents = (double.parse(_amountController.text.trim()) * 100)
        .round();

    if (_isEditing) {
      await controller.updateEntry(
        widget.existing!,
        label: _labelController.text.trim(),
        amountCents: amountCents,
        currency: _currency,
        category: _category,
        purchaseDate: _purchaseDate,
      );
    } else {
      await controller.addEntry(
        label: _labelController.text.trim(),
        amountCents: amountCents,
        currency: _currency,
        category: _category,
        purchaseDate: _purchaseDate,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref
        .read(budgetControllerProvider(widget.householdId))
        .deleteEntry(widget.existing!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? l10n.editBudgetEntryTitle : l10n.addBudgetEntryTitle,
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteButton,
              onPressed: _isSubmitting ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _labelController,
                      decoration: InputDecoration(labelText: l10n.budgetLabelLabel),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? l10n.fieldRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(labelText: l10n.amountLabel),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) return l10n.fieldRequired;
                              return double.tryParse(trimmed) == null
                                  ? l10n.invalidNumber
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            decoration: InputDecoration(labelText: l10n.currencyLabel),
                            items: [
                              for (final currency in _currencies)
                                DropdownMenuItem(
                                  value: currency,
                                  child: Text(currency),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) setState(() => _currency = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<InventoryItemCategory>(
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
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.purchaseDateLabel),
                      subtitle: Text(
                        _purchaseDate == null
                            ? '—'
                            : MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(_purchaseDate!),
                      ),
                      trailing: _purchaseDate == null
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: l10n.clearDateButton,
                              onPressed: () =>
                                  setState(() => _purchaseDate = null),
                            ),
                      onTap: _pickPurchaseDate,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.saveButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

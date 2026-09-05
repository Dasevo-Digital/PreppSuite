import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/categories.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/inventory_category_l10n.dart';
import '../application/inventory_controller.dart';
import '../application/inventory_photo_service.dart';
import '../application/open_food_facts_service.dart';
import 'barcode_scanner_screen.dart';

class InventoryItemFormScreen extends ConsumerStatefulWidget {
  const InventoryItemFormScreen({
    super.key,
    required this.householdId,
    this.existing,
  });

  final String householdId;
  final InventoryItem? existing;

  @override
  ConsumerState<InventoryItemFormScreen> createState() =>
      _InventoryItemFormScreenState();
}

class _InventoryItemFormScreenState
    extends ConsumerState<InventoryItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _storageLocationController;
  late final TextEditingController _minQuantityController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _notesController;
  late InventoryItemCategory _category;
  DateTime? _expirationDate;
  String? _barcode;
  String? _offProductId;
  String? _photoPath;
  bool _isSubmitting = false;
  bool _isScanning = false;

  /// Camera capture needs a platform delegate `image_picker` doesn't wire
  /// up on desktop (see `InventoryPhotoService.pickFromCamera`) — offer it
  /// only where it actually works out of the box.
  bool get _cameraAvailable =>
      !kIsWeb && !Platform.isMacOS && !Platform.isWindows && !Platform.isLinux;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _quantityController = TextEditingController(
      text: existing != null ? _formatNumber(existing.quantity) : '',
    );
    _unitController = TextEditingController(text: existing?.unit ?? '');
    _storageLocationController = TextEditingController(
      text: existing?.storageLocation ?? '',
    );
    _minQuantityController = TextEditingController(
      text: existing?.minQuantity != null
          ? _formatNumber(existing!.minQuantity!)
          : '',
    );
    _caloriesController = TextEditingController(
      text: existing?.calories != null ? '${existing!.calories}' : '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _category = existing != null
        ? InventoryItemCategoryX.fromName(existing.category)
        : InventoryItemCategory.food;
    _expirationDate = existing?.expirationDate;
    _barcode = existing?.barcode;
    _offProductId = existing?.offProductId;
    _photoPath = existing?.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _storageLocationController.dispose();
    _minQuantityController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  Future<void> _pickExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (barcode == null || !mounted) return;

    setState(() {
      _barcode = barcode;
      _isScanning = true;
    });

    final product = await const OpenFoodFactsService().lookup(barcode);
    if (!mounted) return;

    setState(() {
      _isScanning = false;
      if (product != null) {
        _nameController.text = product.name;
        _offProductId = product.barcode;

        // Only ever fills an empty field: a value already typed in is the
        // user's own correction and outranks the estimate from the label.
        final kcal = product.totalKcal;
        if (kcal != null && _caloriesController.text.trim().isEmpty) {
          _caloriesController.text = '$kcal';
        }
      }
    });

    if (product == null && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.productNotFound)));
    }
  }

  Future<void> _replacePhoto(String? newPath) async {
    if (newPath == null) return;
    final oldPath = _photoPath;
    setState(() => _photoPath = newPath);
    // Only delete the old file once the new one is confirmed in place, so a
    // failed pick never loses an existing photo.
    if (oldPath != null && oldPath != newPath) {
      await const InventoryPhotoService().delete(oldPath);
    }
  }

  Future<void> _removePhoto() async {
    final oldPath = _photoPath;
    setState(() => _photoPath = null);
    await const InventoryPhotoService().delete(oldPath);
  }

  Future<void> _showPhotoOptions() async {
    final l10n = AppLocalizations.of(context)!;
    const service = InventoryPhotoService();

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_cameraAvailable)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.takePhotoButton),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _replacePhoto(await service.pickFromCamera());
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGalleryButton),
              onTap: () async {
                Navigator.of(context).pop();
                await _replacePhoto(await service.pickFromGallery());
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.removePhotoButton),
                onTap: () {
                  Navigator.of(context).pop();
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final controller = ref.read(
      inventoryControllerProvider(widget.householdId),
    );
    final quantity = double.parse(_quantityController.text.trim());
    final minQuantityText = _minQuantityController.text.trim();
    final minQuantity = minQuantityText.isEmpty
        ? null
        : double.parse(minQuantityText);
    final caloriesText = _caloriesController.text.trim();
    final calories = caloriesText.isEmpty ? null : int.parse(caloriesText);
    final notes = _notesController.text.trim();

    if (_isEditing) {
      await controller.updateItem(
        widget.existing!,
        name: _nameController.text.trim(),
        category: _category,
        quantity: quantity,
        unit: _unitController.text.trim(),
        storageLocation: _storageLocationController.text.trim(),
        expirationDate: _expirationDate,
        minQuantity: minQuantity,
        notes: notes.isEmpty ? null : notes,
        barcode: _barcode,
        offProductId: _offProductId,
        photoPath: _photoPath,
        calories: calories,
      );
    } else {
      await controller.addItem(
        name: _nameController.text.trim(),
        category: _category,
        quantity: quantity,
        unit: _unitController.text.trim(),
        storageLocation: _storageLocationController.text.trim(),
        expirationDate: _expirationDate,
        minQuantity: minQuantity,
        notes: notes.isEmpty ? null : notes,
        barcode: _barcode,
        offProductId: _offProductId,
        photoPath: _photoPath,
        calories: calories,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final controller = ref.read(
      inventoryControllerProvider(widget.householdId),
    );
    await controller.deleteItem(widget.existing!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editItemTitle : l10n.addItemTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: l10n.scanBarcodeButton,
            onPressed: _isSubmitting ? null : _scanBarcode,
          ),
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
                    Center(
                      child: _PhotoPicker(
                        photoPath: _photoPath,
                        onTap: _isSubmitting ? null : _showPhotoOptions,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_barcode != null) ...[
                      Chip(
                        avatar: _isScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.qr_code, size: 18),
                        label: Text(l10n.scannedBarcodeLabel(_barcode!)),
                        onDeleted: () => setState(() {
                          _barcode = null;
                          _offProductId = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.itemNameLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? l10n.fieldRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<InventoryItemCategory>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        labelText: l10n.categoryLabel,
                      ),
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
                            decoration: InputDecoration(
                              labelText: l10n.unitLabel,
                            ),
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
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
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
                      decoration: InputDecoration(
                        labelText: l10n.minQuantityLabel,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _numberValidator(l10n, required: false),
                    ),
                    if (_category == InventoryItemCategory.food) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _caloriesController,
                        decoration: InputDecoration(
                          labelText: l10n.caloriesLabel,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) return null;
                          return int.tryParse(trimmed) == null
                              ? l10n.invalidNumber
                              : null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(labelText: l10n.notesLabel),
                      maxLines: 3,
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
}

/// A tappable square that shows the item's photo, or a placeholder icon
/// with an "add photo" affordance if there isn't one yet.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoPath, required this.onTap});

  final String? photoPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final photoPath = this.photoPath;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        label: l10n.itemPhotoLabel,
        image: photoPath != null,
        button: true,
        child: Container(
          width: 120,
          height: 120,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainerHighest,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: photoPath != null
              ? Image.file(File(photoPath), fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.addPhotoButton,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

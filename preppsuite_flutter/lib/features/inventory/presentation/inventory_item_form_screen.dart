import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'item_expiry_lead_days_dialog.dart';
import 'unit_info_dialog.dart';

import '../../../core/feel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/categories.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/error_text.dart';
import '../../../local_db/database.dart';
import '../application/inventory_category_l10n.dart';
import '../application/expiry_reminder_provider.dart';
import '../application/supply_group_l10n.dart';
import '../application/supply_groups.dart';
import '../application/inventory_controller.dart';
import '../application/inventory_photo_service.dart';
import '../application/open_food_facts_service.dart';
import '../application/package_nutrition.dart';
import 'barcode_scanner_screen.dart';
import 'photo_editor_screen.dart';
import '../application/food_amount.dart';
import 'stored_photo_image.dart';

/// A form filled in from somewhere other than an existing row — the
/// stockpiling table hands one over when a food is added from it.
class InventoryItemDraft {
  const InventoryItemDraft({
    required this.name,
    required this.quantity,
    required this.unit,
    this.category = InventoryItemCategory.food,
    this.nutrition = const PackageNutrition(),
    this.notes,
  });

  final String name;
  final double quantity;
  final String unit;
  final InventoryItemCategory category;
  final PackageNutrition nutrition;
  final String? notes;
}

class InventoryItemFormScreen extends ConsumerStatefulWidget {
  const InventoryItemFormScreen({
    super.key,
    required this.householdId,
    this.existing,
    this.draft,
  });

  final String householdId;
  final InventoryItem? existing;

  /// Ignored when [existing] is set — editing a row always wins over a
  /// suggestion.
  final InventoryItemDraft? draft;

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
  late final TextEditingController _dailyDoseController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbohydrateController;
  late final TextEditingController _fatController;
  late final TextEditingController _fiberController;
  late final TextEditingController _notesController;
  late InventoryItemCategory _category;
  DateTime? _expirationDate;

  /// Null means this item follows the household setting; see
  /// `InventoryItems.expiryLeadDays`.
  String? _expiryLeadDays;

  /// Which BLE supply group this row counts towards, or null.
  SupplyGroup? _foodGroup;
  String? _barcode;
  String? _offProductId;
  String? _photoPath;
  bool _isSubmitting = false;
  bool _isScanning = false;
  bool _allowPop = false;
  bool _discardDialogOpen = false;
  late String _initialSignature;
  final _sessionPhotos = <String>{};
  List<TextEditingController> get _controllers => [
    _nameController,
    _quantityController,
    _unitController,
    _storageLocationController,
    _minQuantityController,
    _dailyDoseController,
    _caloriesController,
    _proteinController,
    _carbohydrateController,
    _fatController,
    _fiberController,
    _notesController,
  ];
  String get _signature => jsonEncode([
    for (final controller in _controllers) controller.text,
    _category.name,
    _expirationDate?.toIso8601String(),
    _expiryLeadDays,
    _foodGroup?.name,
    _barcode,
    _offProductId,
    _photoPath,
  ]);
  bool get _hasChanges => _signature != _initialSignature;
  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _finish() async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _requestLeave() async {
    if (_isSubmitting || _discardDialogOpen) return;
    final l10n = AppLocalizations.of(context)!;
    _discardDialogOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discardChanges),
          ),
        ],
      ),
    );
    _discardDialogOpen = false;
    if (discard == true && mounted) await _finish();
  }

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
    final draft = existing == null ? widget.draft : null;
    final nutrition = existing != null
        ? PackageNutrition.ofItem(existing)
        : draft?.nutrition ?? const PackageNutrition();

    _nameController = TextEditingController(
      text: existing?.name ?? draft?.name ?? '',
    );
    _quantityController = TextEditingController(
      text: switch ((existing, draft)) {
        (final InventoryItem item, _) => _formatNumber(item.quantity),
        (_, final InventoryItemDraft d) => _formatNumber(d.quantity),
        _ => '',
      },
    );
    _unitController = TextEditingController(
      text: existing?.unit ?? draft?.unit ?? '',
    );
    _storageLocationController = TextEditingController(
      text: existing?.storageLocation ?? '',
    );
    _minQuantityController = TextEditingController(
      text: existing?.minQuantity != null
          ? _formatNumber(existing!.minQuantity!)
          : '',
    );
    _dailyDoseController = TextEditingController(
      text: existing?.dailyDose != null
          ? _formatNumber(existing!.dailyDose!)
          : '',
    );
    _caloriesController = TextEditingController(
      text: nutrition.kcal != null ? _formatNumber(nutrition.kcal!) : '',
    );
    _proteinController = _gramsController(nutrition.proteinGrams);
    _carbohydrateController = _gramsController(nutrition.carbohydrateGrams);
    _fatController = _gramsController(nutrition.fatGrams);
    _fiberController = _gramsController(nutrition.fiberGrams);
    _notesController = TextEditingController(
      text: existing?.notes ?? draft?.notes ?? '',
    );
    _category = existing != null
        ? InventoryItemCategoryX.fromName(existing.category)
        : draft?.category ?? InventoryItemCategory.food;
    _expirationDate = existing?.expirationDate;
    _expiryLeadDays = existing?.expiryLeadDays;
    _foodGroup = supplyGroupFromName(existing?.foodGroup);
    _barcode = existing?.barcode;
    _offProductId = existing?.offProductId;
    _photoPath = existing?.photoPath;
    _initialSignature = _signature;
    for (final controller in _controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  /// Grams are shown to one decimal: Open Food Facts reports them to two
  /// or three, and "12,7 g" is as precise as a shelf ever needs.
  TextEditingController _gramsController(double? grams) =>
      TextEditingController(
        text: grams == null ? '' : _formatNumber(_roundGrams(grams)),
      );

  static double _roundGrams(double grams) => (grams * 10).round() / 10;

  @override
  void dispose() {
    for (final path in _sessionPhotos) {
      unawaited(const InventoryPhotoService().delete(path));
    }
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _storageLocationController.dispose();
    _minQuantityController.dispose();
    _dailyDoseController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbohydrateController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
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
        _fillNutrition(product.nutrition);
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
    if (!mounted) {
      await const InventoryPhotoService().delete(newPath);
      return;
    }
    final oldPath = _photoPath;
    if (newPath != widget.existing?.photoPath) _sessionPhotos.add(newPath);
    setState(() => _photoPath = newPath);
    // Persisted photos remain available if the user discards this form.
    if (oldPath != newPath && _sessionPhotos.remove(oldPath)) {
      await const InventoryPhotoService().delete(oldPath);
    }
  }

  /// Picks a photo and offers to trim it before it is kept.
  ///
  /// The editor runs on the copy that was just saved, and backing out of
  /// it keeps that copy — the picture is already the one the user chose,
  /// and throwing it away because they decided not to crop would be a
  /// surprise.
  Future<void> _addPhoto(Future<String?> Function() pick) async {
    final picked = await pick();
    if (picked == null) return;
    await _replacePhoto(picked);
    if (mounted) await _editPhoto();
  }

  Future<void> _editPhoto() async {
    final path = _photoPath;
    if (path == null) return;

    final edited = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => PhotoEditorScreen(
          file: File(InventoryPhotoService.resolvePhotoPath(path)),
        ),
      ),
    );
    if (edited == null || !mounted) return;

    await _replacePhoto(await const InventoryPhotoService().saveBytes(edited));
  }

  Future<void> _removePhoto() async {
    final oldPath = _photoPath;
    setState(() => _photoPath = null);
    if (_sessionPhotos.remove(oldPath)) {
      await const InventoryPhotoService().delete(oldPath);
    }
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
                  await _addPhoto(service.pickFromCamera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGalleryButton),
              onTap: () async {
                Navigator.of(context).pop();
                await _addPhoto(service.pickFromGallery);
              },
            ),
            if (_photoPath != null) ...[
              ListTile(
                leading: const Icon(Icons.crop),
                title: Text(l10n.editPhotoButton),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _editPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.removePhotoButton),
                onTap: () {
                  Navigator.of(context).pop();
                  _removePhoto();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Writes what the label says into the nutrition fields.
  ///
  /// Only ever fills an empty one: a value already typed in is the user's
  /// own correction and outranks the label.
  void _fillNutrition(PackageNutrition nutrition) {
    void fill(TextEditingController controller, String? value) {
      if (value != null && controller.text.trim().isEmpty) {
        controller.text = value;
      }
    }

    // Nothing is converted here any more. The column holds what the
    // label says — per 100 g, or per 100 ml on a drink — and the scan
    // hands over exactly that. The screen used to redo the conversion
    // because the basis depended on the unit the household counted in;
    // it does not any more, and both bugs that came out of that
    // conversion went with it.
    fill(_caloriesController, _grams(nutrition.kcal));
    fill(_proteinController, _grams(nutrition.proteinGrams));
    fill(_carbohydrateController, _grams(nutrition.carbohydrateGrams));
    fill(_fatController, _grams(nutrition.fatGrams));
    fill(_fiberController, _grams(nutrition.fiberGrams));
  }

  /// Whether this row's unit has to name a measure.
  ///
  /// Food, because nutrition is printed per 100 g and a tin has no weight
  /// until somebody reads it. Water, because the reach calculation has
  /// always needed litres and quietly skipped anything else — this only
  /// says so at the moment it can still be fixed.
  /// Says why the field is fussy, and fills it in if the answer was a
  /// tap on one of the units rather than a read of the sentence.
  /// The lead times for this one item.
  ///
  /// Only reachable where the item has an expiration date, because a lead
  /// time without one counts down from nothing.
  Future<void> _pickLeadDays() async {
    final choice = await showItemLeadDays(
      context,
      current: _expiryLeadDays,
      householdLeadDays: ref.read(expiryLeadDaysProvider),
    );
    if (choice == null || !mounted) return;
    setState(() => _expiryLeadDays = choice.value);
  }

  Future<void> _explainUnit() async {
    final chosen = await showUnitInfo(context);
    if (chosen == null || !mounted) return;
    setState(() {
      _unitController.text = chosen;
    });
    // The field was refused a moment ago; saying so again about the
    // answer it was just handed would be absurd.
    _formKey.currentState?.validate();
  }

  bool get _needsMeasure =>
      _category == InventoryItemCategory.food ||
      _category == InventoryItemCategory.water;

  /// The basis the nutrition fields are labelled with: "100 g" or
  /// "100 ml", following the unit the household typed.
  String get _per100Unit => switch (oneOf(_unitController.text)?.base) {
    FoodBase.volume => '100 ml',
    _ => '100 g',
  };

  /// The stock reduced to grams or millilitres, or null where it cannot
  /// be.
  FoodAmount? _stock() {
    final quantity = _decimal(_quantityController.text);
    if (quantity == null || quantity <= 0) return null;
    return measure(quantity, _unitController.text);
  }

  /// What the stock comes to in kilocalories, or null while anything is
  /// missing.
  int? _caloriesTotal() {
    final per100 = _decimal(_caloriesController.text);
    final stock = _stock();
    if (per100 == null || stock == null) return null;
    return stock.per100(per100).round();
  }

  /// A number as this form's other fields read one: comma or point, both
  /// meaning the same thing.
  ///
  /// The calorie field used to read its own with `int.tryParse` and no
  /// comma handling, which is two refusals in one. A household counting
  /// in grams has to write 2.13, and neither "2,13" nor "2.13" was
  /// accepted — so the field asked for a figure it would not take.
  static double? _decimal(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  String? _grams(double? value) =>
      value == null ? null : _formatNumber(_roundGrams(value));

  /// Reads the nutrition fields back. An empty field means "not known"
  /// and is stored as null rather than zero — the supply calculator adds
  /// these up, and a guessed zero would be indistinguishable from a real
  /// one.
  PackageNutrition _readNutrition() {
    double? asDouble(TextEditingController c) {
      final text = c.text.trim().replaceAll(',', '.');
      return text.isEmpty ? null : double.parse(text);
    }

    return PackageNutrition(
      kcal: asDouble(_caloriesController),
      proteinGrams: asDouble(_proteinController),
      carbohydrateGrams: asDouble(_carbohydrateController),
      fatGrams: asDouble(_fatController),
      fiberGrams: asDouble(_fiberController),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final controller = ref.read(
        inventoryControllerProvider(widget.householdId),
      );
      final quantity = double.parse(_quantityController.text.trim());
      final minQuantityText = _minQuantityController.text.trim();
      final minQuantity = minQuantityText.isEmpty
          ? null
          : double.parse(minQuantityText);
      final nutrition = _readNutrition();
      // Only for a medicine. A dose left behind on an item whose category
      // was changed afterwards would put a tin of beans into the
      // medication reach with a straight face.
      final doseText = _dailyDoseController.text.trim();
      final dailyDose =
          _category == InventoryItemCategory.medical && doseText.isNotEmpty
          ? double.parse(doseText)
          : null;
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
          dailyDose: dailyDose,
          expiryLeadDays: _expiryLeadDays,
          foodGroup: _needsMeasure ? _foodGroup?.name : null,
          notes: notes.isEmpty ? null : notes,
          barcode: _barcode,
          offProductId: _offProductId,
          photoPath: _photoPath,
          nutrition: nutrition,
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
          dailyDose: dailyDose,
          expiryLeadDays: _expiryLeadDays,
          foodGroup: _needsMeasure ? _foodGroup?.name : null,
          notes: notes.isEmpty ? null : notes,
          barcode: _barcode,
          offProductId: _offProductId,
          photoPath: _photoPath,
          nutrition: nutrition,
        );
      }

      _sessionPhotos.remove(_photoPath);
      final originalPhoto = widget.existing?.photoPath;
      if (originalPhoto != null && originalPhoto != _photoPath) {
        await const InventoryPhotoService().delete(originalPhoto);
      }
      await _finish();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(describeError(AppLocalizations.of(context)!, error)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete() async {
    if (_isSubmitting) return;
    final controller = ref.read(
      inventoryControllerProvider(widget.householdId),
    );
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSubmitting = true);
    try {
      await controller.deleteItem(widget.existing!);
      await _finish();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.inventoryItemDeleted),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: l10n.undoAction,
            onPressed: () async {
              try {
                await controller.restoreItem(widget.existing!.clientId);
              } catch (error) {
                messenger.showSnackBar(
                  SnackBar(content: Text(describeError(l10n, error))),
                );
              }
            },
          ),
        ),
      );
    } catch (error) {
      Feel.failed();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(describeError(l10n, error))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: _allowPop || (!_hasChanges && !_isSubmitting),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () async {
              if (_isSubmitting) return;
              if (_hasChanges) {
                await _requestLeave();
              } else {
                await _finish();
              }
            },
          ),
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
                        isExpanded: true,
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
                      // Nur bei Lebensmitteln und Wasser, und direkt
                      // unter der Kategorie, weil es an ihr haengt: eine
                      // Taschenlampe gehoert in keine Vorratsgruppe und
                      // vermisst auch keine.
                      if (_needsMeasure) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<SupplyGroup?>(
                          isExpanded: true,
                          initialValue: _foodGroup,
                          decoration: InputDecoration(
                            labelText: l10n.supplyGroupLabel,
                            helperText: l10n.supplyGroupHelper,
                            helperMaxLines: 2,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l10n.supplyGroupNone),
                            ),
                            for (final group in SupplyGroup.values)
                              DropdownMenuItem(
                                value: group,
                                child: Text(localizeSupplyGroup(l10n, group)),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _foodGroup = value),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: InputDecoration(
                                labelText: l10n.quantityLabel,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                                // No helper text under the field. It
                                // said the same as the dialog behind the
                                // (i), and three lines of it pushed the
                                // row out of line with everything else
                                // on the form. The rule is still
                                // reachable two ways: the icon, and the
                                // validator that refuses a unit which is
                                // not a measure.
                                //
                                // The icon is shown only where the rule
                                // applies. On a medicine there is
                                // nothing to explain, and a question
                                // mark beside a field that takes
                                // anything is a question nobody asked.
                                suffixIcon: _needsMeasure
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          size: 20,
                                        ),
                                        tooltip: l10n.unitInfoAction,
                                        onPressed: _explainUnit,
                                      )
                                    : null,
                              ),
                              validator: (value) {
                                final trimmed = value?.trim() ?? '';
                                if (trimmed.isEmpty) return l10n.fieldRequired;
                                // Only food and water. A medicine is
                                // counted in tablets and its daily dose
                                // with it; a tool is counted in pieces.
                                // Neither has a label to apply.
                                if (!_needsMeasure) return null;
                                return isMeasurableUnit(trimmed)
                                    ? null
                                    : l10n.unitMeasureRequired;
                              },
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
                      // Only with a date. A lead time counts backwards
                      // from the expiration, so without one there is
                      // nothing for it to count from and the row would be
                      // a control that does nothing.
                      if (_expirationDate != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.notifications_outlined,
                          ),
                          title: Text(l10n.itemExpiryRemindersLabel),
                          subtitle: Text(
                            itemLeadDaysSummary(
                              l10n,
                              _expiryLeadDays,
                              ref.watch(expiryLeadDaysProvider),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _pickLeadDays,
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
                      if (_category == InventoryItemCategory.medical) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _dailyDoseController,
                          decoration: InputDecoration(
                            labelText: l10n.dailyDoseLabel,
                            helperText: l10n.dailyDoseHelper,
                            helperMaxLines: 3,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _numberValidator(l10n, required: false),
                        ),
                      ],
                      if (_category == InventoryItemCategory.food) ...[
                        const SizedBox(height: 24),
                        Text(
                          l10n.nutritionSectionTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.nutritionSectionHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _caloriesController,
                          decoration: InputDecoration(
                            // Named after the basis, because the basis is
                            // the whole point: a figure whose basis is
                            // not on the label is how this was misread
                            // twice before.
                            labelText: l10n.caloriesPer100Label(_per100Unit),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return null;
                            return _decimal(trimmed) == null
                                ? l10n.invalidNumber
                                : null;
                          },
                        ),
                        // The multiplication, spelled out. A number that
                        // means something else than the household thinks
                        // is invisible in a total and obvious here.
                        if (_caloriesTotal() case final total?) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.caloriesTotalHint(total),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _GramsField(
                                controller: _proteinController,
                                label: l10n.nutritionPer100Label(
                                  l10n.proteinLabel,
                                  _per100Unit,
                                ),
                                validator: _gramsValidator(l10n),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GramsField(
                                controller: _carbohydrateController,
                                label: l10n.nutritionPer100Label(
                                  l10n.carbohydrateLabel,
                                  _per100Unit,
                                ),
                                validator: _gramsValidator(l10n),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _GramsField(
                                controller: _fatController,
                                label: l10n.nutritionPer100Label(
                                  l10n.fatLabel,
                                  _per100Unit,
                                ),
                                validator: _gramsValidator(l10n),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _GramsField(
                                controller: _fiberController,
                                label: l10n.nutritionPer100Label(
                                  l10n.fiberLabel,
                                  _per100Unit,
                                ),
                                validator: _gramsValidator(l10n),
                              ),
                            ),
                          ],
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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

  /// Accepts a comma as the decimal mark, because a German keyboard puts
  /// one there and `double.parse` does not take it.
  String? Function(String?) _gramsValidator(AppLocalizations l10n) {
    return (value) {
      final trimmed = (value ?? '').trim().replaceAll(',', '.');
      if (trimmed.isEmpty) return null;
      final parsed = double.tryParse(trimmed);
      if (parsed == null || parsed < 0) return l10n.invalidNumber;
      return null;
    };
  }
}

/// One of the four macronutrient fields, all of which are grams for the
/// whole item and all of which may be left blank.
class _GramsField extends StatelessWidget {
  const _GramsField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, suffixText: 'g'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
    );
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

    final side = MediaQuery.textScalerOf(
      context,
    ).clamp(maxScaleFactor: 1.5).scale(120);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        label: l10n.itemPhotoLabel,
        image: photoPath != null,
        button: true,
        child: Container(
          // A square by design — it stands in for a photograph, and a
          // photograph does not get bigger with the system font. But it
          // holds a label as well, so it has to give a little: at twice the
          // font size the icon and two lines of text were 6 pixels taller
          // than the tile and got clipped. Capped at 1.5, because past that
          // a thumbnail starts taking over the form it belongs to.
          width: side,
          height: side,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainerHighest,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: photoPath != null
              ? Image(
                  image: ResizeImage.resizeIfNeeded(
                    600,
                    null,
                    StoredPhotoImage(
                      InventoryPhotoService.resolvePhotoPath(photoPath),
                    ),
                  ),
                  fit: BoxFit.cover,
                )
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

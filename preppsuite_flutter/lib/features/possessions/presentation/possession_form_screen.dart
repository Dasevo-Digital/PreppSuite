import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/feel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../inventory/application/inventory_photo_service.dart';
import '../application/possession_controller.dart';
import '../../inventory/presentation/stored_photo_image.dart';

/// One entry in the household's list of what it owns.
///
/// Every field but the name is optional, deliberately. A list of forty
/// things with nothing but names is worth having; a form that insisted on
/// a receipt for each would be a list of four.
class PossessionFormScreen extends ConsumerStatefulWidget {
  const PossessionFormScreen({
    super.key,
    required this.householdId,
    this.existing,
    this.defaultCurrency,
  });

  final String householdId;
  final Possession? existing;

  /// Prefilled on a new entry so nobody types "EUR" forty times.
  final String? defaultCurrency;

  @override
  ConsumerState<PossessionFormScreen> createState() =>
      _PossessionFormScreenState();
}

class _PossessionFormScreenState extends ConsumerState<PossessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _room;
  late final TextEditingController _serial;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  late final TextEditingController _notes;
  DateTime? _acquiredOn;
  String? _photoPath;
  var _submitting = false;

  /// Pictures taken in this form and not yet saved to a row. Deleted on
  /// the way out unless the row was saved — otherwise a household that
  /// changes its mind three times leaves three orphaned files behind.
  final _sessionPhotos = <String>{};

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _room = TextEditingController(text: existing?.room ?? '');
    _serial = TextEditingController(text: existing?.serialNumber ?? '');
    _price = TextEditingController(
      text: existing?.purchasePriceCents != null
          ? (existing!.purchasePriceCents! / 100).toStringAsFixed(2)
          : '',
    );
    _currency = TextEditingController(
      text: existing?.currency ?? widget.defaultCurrency ?? '',
    );
    _notes = TextEditingController(text: existing?.notes ?? '');
    _acquiredOn = existing?.acquiredOn;
    _photoPath = existing?.photoPath;
  }

  @override
  void dispose() {
    for (final path in _sessionPhotos) {
      unawaited(const InventoryPhotoService().delete(path));
    }
    _name.dispose();
    _room.dispose();
    _serial.dispose();
    _price.dispose();
    _currency.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(bool fromCamera) async {
    const service = InventoryPhotoService();
    final path = fromCamera
        ? await service.pickFromCamera()
        : await service.pickFromGallery();
    if (path == null || !mounted) return;
    final previous = _photoPath;
    setState(() {
      _photoPath = path;
      _sessionPhotos.add(path);
    });
    // A replaced picture that this form itself produced is rubbish now.
    // One that came from the stored row is left alone until the row is
    // actually saved without it.
    if (previous != null && _sessionPhotos.remove(previous)) {
      await service.delete(previous);
    }
  }

  Future<void> _removePhoto() async {
    final path = _photoPath;
    setState(() => _photoPath = null);
    if (path != null && _sessionPhotos.remove(path)) {
      await const InventoryPhotoService().delete(path);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _acquiredOn ?? now,
      firstDate: DateTime(now.year - 60),
      lastDate: now,
    );
    if (picked != null) setState(() => _acquiredOn = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final priceText = _price.text.trim().replaceAll(',', '.');
      await ref
          .read(possessionControllerProvider(widget.householdId))
          .save(
            PossessionDraft(
              name: _name.text,
              room: _room.text,
              serialNumber: _serial.text,
              acquiredOn: _acquiredOn,
              purchasePriceCents: priceText.isEmpty
                  ? null
                  : (double.parse(priceText) * 100).round(),
              currency: _currency.text,
              notes: _notes.text,
              photoPath: _photoPath,
            ),
            existing: widget.existing,
          );
      // Saved, so nothing here is an orphan any more.
      _sessionPhotos.clear();
      final dropped = widget.existing?.photoPath;
      if (dropped != null && dropped != _photoPath) {
        await const InventoryPhotoService().delete(dropped);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // A message that slides away by itself is the only sign otherwise.
      Feel.failed();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeError(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photoPath = _photoPath;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? l10n.possessionAddTitle
              : l10n.possessionEditTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              autofocus: widget.existing == null,
              decoration: InputDecoration(labelText: l10n.possessionNameLabel),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? l10n.possessionNameNeeded
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _room,
              decoration: InputDecoration(
                labelText: l10n.possessionRoomLabel,
                helperText: l10n.possessionRoomHelper,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serial,
              decoration: InputDecoration(
                labelText: l10n.possessionSerialLabel,
                helperText: l10n.possessionSerialHelper,
                helperMaxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _price,
                    decoration: InputDecoration(
                      labelText: l10n.possessionPriceLabel,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final trimmed = value?.trim().replaceAll(',', '.') ?? '';
                      if (trimmed.isEmpty) return null;
                      return double.tryParse(trimmed) == null
                          ? l10n.invalidNumber
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _currency,
                    decoration: InputDecoration(
                      labelText: l10n.possessionCurrencyLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.possessionAcquiredLabel),
              subtitle: Text(
                _acquiredOn == null
                    ? l10n.possessionAcquiredNone
                    : DateFormat.yMMMd(l10n.localeName).format(_acquiredOn!),
              ),
              trailing: _acquiredOn == null
                  ? const Icon(Icons.calendar_today_outlined)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.clearDateButton,
                      onPressed: () => setState(() => _acquiredOn = null),
                    ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.possessionPhotoTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.possessionPhotoWhy,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (photoPath != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: ResizeImage.resizeIfNeeded(
                        1080,
                        null,
                        StoredPhotoImage(
                          InventoryPhotoService.resolvePhotoPath(photoPath),
                        ),
                      ),
                      height: 180,
                      width: double.infinity,
                      // The stored picture is up to 2000 pixels wide; this
                      // strip is 180 tall. 1080 covers a phone at triple
                      // density and a desktop card at its widest, for a
                      // third of the memory.
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.possessionPhotoRemove,
                    onPressed: _removePhoto,
                  ),
                ],
              )
            else
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _addPhoto(true),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(l10n.possessionPhotoCamera),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _addPhoto(false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l10n.possessionPhotoGallery),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              decoration: InputDecoration(labelText: l10n.notesLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/personal_place.dart';

/// A compact, device-local situation map directory.
class PersonalPlacesScreen extends StatefulWidget {
  const PersonalPlacesScreen({super.key, required this.places});

  final List<PersonalPlace> places;

  @override
  State<PersonalPlacesScreen> createState() => _PersonalPlacesScreenState();
}

class _PersonalPlacesScreenState extends State<PersonalPlacesScreen> {
  static const _store = PersonalPlaceStore();
  late List<PersonalPlace> _places = [...widget.places];

  Future<void> _edit({PersonalPlace? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final label = TextEditingController(text: existing?.label ?? '');
    final latitude = TextEditingController(
      text: existing?.latitude.toString() ?? '',
    );
    final longitude = TextEditingController(
      text: existing?.longitude.toString() ?? '',
    );
    final note = TextEditingController(text: existing?.note ?? '');
    String? error;

    final result = await showDialog<PersonalPlace>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? l10n.mapPlaceAdd : l10n.mapPlaceEdit,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.mapPlacePrivacy,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: label,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.mapPlaceLabel),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: latitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: l10n.mapPlaceLatitude),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: longitude,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.mapPlaceLongitude,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: note,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.mapPlaceNote,
                    hintText: l10n.mapPlaceNoteHint,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final lat = double.tryParse(
                  latitude.text.trim().replaceAll(',', '.'),
                );
                final lon = double.tryParse(
                  longitude.text.trim().replaceAll(',', '.'),
                );
                if (label.text.trim().isEmpty ||
                    !PersonalPlace.isValidCoordinates(lat, lon)) {
                  setDialogState(() => error = l10n.mapPlaceCoordinatesInvalid);
                  return;
                }
                Navigator.of(dialogContext).pop(
                  PersonalPlace(
                    id: existing?.id ?? const Uuid().v4(),
                    label: label.text.trim(),
                    latitude: lat!,
                    longitude: lon!,
                    note: note.text.trim().isEmpty ? null : note.text.trim(),
                  ),
                );
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    latitude.dispose();
    longitude.dispose();
    note.dispose();
    if (result == null || !mounted) return;

    setState(() {
      _places = existing == null
          ? [..._places, result]
          : [
              for (final place in _places)
                if (place.id == existing.id) result else place,
            ];
    });
    await _store.save(_places);
  }

  Future<void> _delete(PersonalPlace place) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.mapPlaceDeleteConfirm(place.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _places.removeWhere((item) => item.id == place.id));
    await _store.save(_places);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_places);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.mapPlacesTitle)),
        body: _places.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.mapPlacesEmpty,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.mapPlacesIntro),
                  const SizedBox(height: 8),
                  for (final place in _places)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(place.label),
                        subtitle: Text(
                          [
                            '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
                            if (place.note != null) place.note!,
                          ].join('\n'),
                        ),
                        isThreeLine: place.note != null,
                        onTap: () => _edit(existing: place),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.deleteButton,
                          onPressed: () => _delete(place),
                        ),
                      ),
                    ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _edit,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(l10n.mapPlaceAdd),
        ),
      ),
    );
  }
}

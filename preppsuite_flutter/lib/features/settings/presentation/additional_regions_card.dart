import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geolocation_service.dart';
import '../../../core/location_capabilities.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../household/application/german_states.dart';
import '../../household/application/household_providers.dart';
import '../../warnings/application/warning_region_filter.dart';

/// Regions followed beyond the household's own.
class AdditionalRegionsCard extends ConsumerWidget {
  const AdditionalRegionsCard({
    super.key,
    required this.profile,
    required this.l10n,
  });

  final HouseholdProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          if (profile.extraRegions.isEmpty)
            ListTile(subtitle: Text(l10n.settingsNoAdditionalRegions))
          else
            for (final region in profile.extraRegions)
              ListTile(
                leading: Icon(
                  region.kind == WarningRegionKind.kreis
                      ? Icons.location_city
                      : Icons.map_outlined,
                ),
                title: Text(_regionTitle(region)),
                subtitle: Text(
                  region.kind == WarningRegionKind.kreis
                      ? l10n.settingsRegionTypeKreis
                      : l10n.settingsRegionTypeBundesland,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.csvImportRemoveRowTooltip,
                  onPressed: () => ref
                      .read(householdProfileProvider.notifier)
                      .removeRegion(region),
                ),
              ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => const _AddRegionDialog(),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.settingsAddRegionButton),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "NI" is what gets stored and what the BBK feed says; it is not what
/// anyone calls the place they live.
String _regionTitle(WarningRegion region) {
  if (region.kind == WarningRegionKind.kreis) return region.value;
  return germanStateByBbkCode(region.value)?.nameDe ?? region.value;
}

class _AddRegionDialog extends ConsumerStatefulWidget {
  const _AddRegionDialog();

  @override
  ConsumerState<_AddRegionDialog> createState() => _AddRegionDialogState();
}

class _AddRegionDialogState extends ConsumerState<_AddRegionDialog> {
  final _kreisController = TextEditingController();
  WarningRegionKind _kind = WarningRegionKind.kreis;

  /// Picked from a list rather than typed. There are sixteen of them and
  /// what gets stored is a two-letter code nobody knows by heart — asking
  /// for it in a text field only ever produced a rejected form.
  GermanState? _state;

  String? _error;
  bool _locating = false;

  @override
  void dispose() {
    _kreisController.dispose();
    super.dispose();
  }

  Future<void> _add(AppLocalizations l10n) async {
    final WarningRegion region;

    switch (_kind) {
      case WarningRegionKind.kreis:
        final value = _kreisController.text.trim();
        // A Kreisschlüssel is exactly five digits; anything else silently
        // matches nothing, which looks like the feature being broken
        // rather than the input being wrong.
        if (!RegExp(r'^\d{5}$').hasMatch(value)) {
          setState(() => _error = l10n.settingsKreisSchluesselInvalid);
          return;
        }
        region = WarningRegion(kind: _kind, value: value);

      case WarningRegionKind.bundesland:
        final state = _state;
        if (state == null) {
          setState(() => _error = l10n.settingsBundeslandRequired);
          return;
        }
        region = WarningRegion(kind: _kind, value: state.bbkCode);
    }

    await ref.read(householdProfileProvider.notifier).addRegion(region);
    if (mounted) Navigator.of(context).pop();
  }

  /// Fills in the Bundesland the device is currently in. Kreis-level
  /// precision is not available this way — Nominatim answers with a state
  /// name, which is what the original server-side version used too.
  Future<void> _useLocation(AppLocalizations l10n) async {
    setState(() {
      _locating = true;
      _error = null;
    });

    final geolocation = GeolocationService();
    try {
      final state = await geolocation.determineBundesland();
      if (!mounted) return;
      setState(() {
        _locating = false;
        if (state == null) {
          _error = l10n.settingsLocationNoMatchMessage;
        } else {
          _kind = WarningRegionKind.bundesland;
          _state = state;
        }
      });
    } on LocationUnavailableException catch (refusal) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _error = switch (refusal.reason) {
          LocationRefusal.servicesOff => l10n.settingsLocationServicesOff,
          LocationRefusal.deniedForever => l10n.settingsLocationDeniedForever,
          LocationRefusal.denied => l10n.settingsLocationDenied,
          LocationRefusal.unavailable => l10n.settingsLocationUnavailable(
            refusal.detail ?? '',
          ),
        };
      });
    } catch (_) {
      if (mounted) setState(() => _error = l10n.searchUnavailable);
    } finally {
      geolocation.close();
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.settingsAddRegionDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<WarningRegionKind>(
            segments: [
              ButtonSegment(
                value: WarningRegionKind.kreis,
                label: Text(l10n.settingsRegionTypeKreis),
              ),
              ButtonSegment(
                value: WarningRegionKind.bundesland,
                label: Text(l10n.settingsRegionTypeBundesland),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (selection) => setState(() {
              _kind = selection.first;
              // The old error belongs to the other kind of input.
              _error = null;
            }),
          ),
          const SizedBox(height: 16),
          if (_kind == WarningRegionKind.kreis)
            TextField(
              controller: _kreisController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.settingsKreisSchluesselLabel,
                helperText: l10n.settingsKreisSchluesselHelper,
                errorText: _error,
              ),
            )
          else
            DropdownButtonFormField<GermanState>(
              // A FormField reads `initialValue` once and never again, so
              // the state the location button finds would not show up
              // without rebuilding the field around it.
              key: ValueKey(_state?.bbkCode),
              initialValue: _state,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.settingsBundeslandLabel,
                errorText: _error,
              ),
              items: [
                for (final state in germanStates)
                  DropdownMenuItem(value: state, child: Text(state.nameDe)),
              ],
              onChanged: (value) => setState(() {
                _state = value;
                _error = null;
              }),
            ),
          // Linux has no location implementation at all, so the button
          // would only ever produce an error.
          if (supportsDeviceLocation) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _locating ? null : () => _useLocation(l10n),
                icon: const Icon(Icons.my_location),
                label: Text(l10n.settingsUseLocationButton),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => _add(l10n),
          child: Text(l10n.settingsAddRegionButton),
        ),
      ],
    );
  }
}

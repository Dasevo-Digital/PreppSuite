import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error_text.dart';
import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'base_map_layer.dart';

/// Roughly the centre of Germany, for a map with nothing to show yet.
const _germanyCentre = LatLng(51.1657, 10.4515);

/// A point chosen on the map, handed back to whoever asked (#204).
///
/// The same map as everywhere else -- the downloaded archive where there
/// is one, so a meeting point can be set with no network -- and a tap
/// puts the pin. "My location" puts it where the device is, for somebody
/// standing at the spot.
class PlacePickerScreen extends StatefulWidget {
  const PlacePickerScreen({
    super.key,
    required this.title,
    this.initial,
    this.geolocation,
  });

  final String title;
  final LatLng? initial;

  /// Injectable for tests.
  final GeolocationService? geolocation;

  @override
  State<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  final _map = MapController();
  late final _geolocation = widget.geolocation ?? GeolocationService();
  late LatLng? _point = widget.initial;
  var _locating = false;

  @override
  void dispose() {
    if (widget.geolocation == null) _geolocation.close();
    super.dispose();
  }

  Future<void> _locate(AppLocalizations l10n) async {
    setState(() => _locating = true);
    try {
      final here = await _geolocation.getCurrentLatLng();
      if (!mounted) return;
      setState(() => _point = here);
      _map.move(here, 17);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(describeError(l10n, error))));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final point = _point;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: l10n.mapMyLocationAction,
            onPressed: _locating ? null : () => _locate(l10n),
            icon: _locating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: widget.initial ?? _germanyCentre,
              initialZoom: widget.initial == null ? 5.5 : 16,
              onTap: (_, tapped) => setState(() => _point = tapped),
            ),
            children: [
              const BaseMapLayer(),
              if (point != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(l10n.placePickerHint),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: point == null
            ? null
            : () => Navigator.of(context).pop(point),
        icon: const Icon(Icons.check),
        label: Text(l10n.placePickerUse),
      ),
    );
  }
}

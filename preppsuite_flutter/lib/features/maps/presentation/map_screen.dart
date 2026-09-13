import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/offline_map_providers.dart';
import 'base_map_layer.dart';
import 'map_download_screen.dart';
import 'map_source_bar.dart';
import 'map_zoom_buttons.dart';
import 'nearby_screen.dart';
import 'swipe_zoom.dart';

/// Roughly the centre of Germany, so the map opens on something before a
/// position or a search has resolved.
const _germanyCentre = LatLng(51.1657, 10.4515);

/// The map as a place of its own.
///
/// It used to exist only 260 pixels high inside the shelter search, with
/// the download hidden in the settings — which is a strange place for the
/// one feature that keeps working when nothing else does. Here it gets
/// the whole window, and the choice between the archive and the network
/// is a control rather than a consequence.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focus, this.focusLabel});

  /// A point the map should open on, rather than the whole country.
  ///
  /// Used by the nearby search: a list saying "Trinkwasser, 400 m
  /// nordwestlich" answers how far, not which way round the corner. The
  /// point is drawn with the same labelled marker a place search uses, so
  /// there is one way a found place looks.
  final LatLng? focus;
  final String? focusLabel;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _geolocation = GeolocationService();

  LatLng? _position;
  LatLng? _searchPosition;
  String? _searchLabel;
  bool _locating = false;
  int _lookupGeneration = 0;

  @override
  void initState() {
    super.initState();
    _searchPosition = widget.focus;
    _searchLabel = widget.focusLabel;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _lookupGeneration++;
    _geolocation.close();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation(AppLocalizations l10n) async {
    final generation = ++_lookupGeneration;
    setState(() => _locating = true);
    try {
      final position = await _geolocation.getCurrentLatLng();
      if (!mounted || generation != _lookupGeneration) return;
      setState(() => _position = position);
      _mapController.move(position, 13);
    } on LocationUnavailableException catch (error) {
      if (mounted && generation == _lookupGeneration) _say('$error');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _search(AppLocalizations l10n) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final generation = ++_lookupGeneration;
    try {
      final result = await _geolocation.searchPlace(query);
      if (!mounted || generation != _lookupGeneration) return;
      if (result == null) {
        _say(l10n.shelterSearchNoResult);
        return;
      }
      setState(() {
        _searchPosition = result;
        _searchLabel = query;
      });
      _mapController.move(result, 12);
    } catch (_) {
      if (mounted && generation == _lookupGeneration) {
        _say(l10n.searchUnavailable);
      }
    }
  }

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final offlineState = ref.watch(offlineMapProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navMap),
        actions: [
          // From here rather than from a position lookup: the map's
          // centre is already the place being looked at, it costs no
          // permission and no network, and panning is how somebody says
          // "over there" without having to be there.
          IconButton(
            icon: const Icon(Icons.travel_explore_outlined),
            tooltip: l10n.nearbyTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => NearbyScreen(
                  centre: _mapController.camera.center,
                  centreLabel: l10n.nearbyMapCentre,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: l10n.mapDownloadAction,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const MapDownloadScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: l10n.mapDownloadSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(l10n),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _locating ? null : () => _goToMyLocation(l10n),
                  tooltip: l10n.mapMyLocationAction,
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
          Expanded(
            child: SwipeZoom(
              // A Magic Mouse has no wheel; see swipe_zoom.dart.
              controller: _mapController,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.focus ?? _germanyCentre,
                  // Close enough to see which side of the street it is on.
                  // The country-wide view is what the map opens on with
                  // nothing to show; arriving there after tapping a point
                  // 400 m away would be an answer to a different question.
                  initialZoom: widget.focus == null ? 5.5 : 16,
                ),
                children: [
                  const BaseMapLayer(),
                  if (_position case final position?)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_searchPosition case final position?)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 180,
                          height: 48,
                          alignment: Alignment.bottomCenter,
                          child: Semantics(
                            label: _searchLabel,
                            child: Card(
                              color: theme.colorScheme.surfaceContainerHigh,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Text(
                                  _searchLabel!,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  MapZoomButtons(controller: _mapController),
                  BaseMapAttribution(l10n: l10n),
                ],
              ),
            ),
          ),
          MapSourceBar(state: offlineState, l10n: l10n),
        ],
      ),
    );
  }
}

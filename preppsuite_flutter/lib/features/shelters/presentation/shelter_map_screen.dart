import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/geo_bounds.dart';
import '../application/overpass_shelter_client.dart';
import '../application/shelter_classification.dart';
import '../application/wwbota_client.dart';

/// Roughly the center of Germany — used as the map's fallback view before
/// any location/search has resolved, so the map isn't blank.
const _germanyFallbackCenter = LatLng(51.1657, 10.4515);

class ShelterMapScreen extends StatefulWidget {
  const ShelterMapScreen({super.key});

  @override
  State<ShelterMapScreen> createState() => _ShelterMapScreenState();
}

class _ShelterMapScreenState extends State<ShelterMapScreen> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _geolocationService = GeolocationService();
  final _wwbotaClient = WwbotaClient();
  final _overpassClient = OverpassShelterClient();

  LatLng? _center;
  double _radiusKm = 25;
  ShelterConfidence? _filter;
  List<ClassifiedShelter> _shelters = const [];
  bool _isLoading = false;
  bool _wwbotaFailed = false;
  bool _overpassFailed = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _useCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locationError = null);
    try {
      final position = await _geolocationService.getCurrentLatLng();
      if (!mounted) return;
      _setCenter(position);
    } on LocationUnavailableException catch (error) {
      if (mounted) setState(() => _locationError = '$error');
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final result = await _geolocationService.searchPlace(query);
    if (!mounted) return;
    if (result == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.shelterSearchNoResult)));
      return;
    }
    _setCenter(result);
  }

  void _setCenter(LatLng center) {
    setState(() => _center = center);
    _mapController.move(center, _zoomForRadius(_radiusKm));
    unawaited(_fetchShelters());
  }

  Future<void> _fetchShelters() async {
    final center = _center;
    if (center == null) return;

    setState(() => _isLoading = true);
    final bounds = boundingBoxForRadius(center, _radiusKm);

    final combined = <ClassifiedShelter>[];
    var wwbotaFailed = false;
    var overpassFailed = false;

    try {
      final bunkers = await _wwbotaClient.fetchBunkers(bounds);
      combined.addAll(classifyWwbota(bunkers));
    } catch (_) {
      wwbotaFailed = true;
    }

    try {
      final features = await _overpassClient.fetchShelters(bounds);
      combined.addAll(classifyOverpassFeatures(features));
    } catch (_) {
      overpassFailed = true;
    }

    if (!mounted) return;
    setState(() {
      _shelters = combined;
      _wwbotaFailed = wwbotaFailed;
      _overpassFailed = overpassFailed;
      _isLoading = false;
    });
  }

  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 10) return 11;
    if (radiusKm <= 25) return 10;
    return 9;
  }

  Map<ShelterConfidence, int> get _counts {
    final counts = {for (final c in ShelterConfidence.values) c: 0};
    for (final shelter in _shelters) {
      counts[shelter.confidence] = (counts[shelter.confidence] ?? 0) + 1;
    }
    return counts;
  }

  Color _colorFor(ShelterConfidence confidence) {
    return switch (confidence) {
      ShelterConfidence.green => Colors.green,
      ShelterConfidence.yellow => Colors.amber,
      ShelterConfidence.red => Colors.red,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final counts = _counts;
    final visibleShelters = _filter == null
        ? _shelters
        : _shelters.where((s) => s.confidence == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shelterMapTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shelterInfoLine(_radiusKm.round()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendRow(
                        color: _colorFor(ShelterConfidence.green),
                        label: l10n.shelterLegendGreenLabel,
                        count: counts[ShelterConfidence.green] ?? 0,
                        description: l10n.shelterLegendGreenDescription,
                      ),
                      _LegendRow(
                        color: _colorFor(ShelterConfidence.yellow),
                        label: l10n.shelterLegendYellowLabel,
                        count: counts[ShelterConfidence.yellow] ?? 0,
                        description: l10n.shelterLegendYellowDescription,
                      ),
                      _LegendRow(
                        color: _colorFor(ShelterConfidence.red),
                        label: l10n.shelterLegendRedLabel,
                        count: counts[ShelterConfidence.red] ?? 0,
                        description: l10n.shelterLegendRedDescription,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.shelterDisclaimer,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if ((counts[ShelterConfidence.green] ?? 0) == 0 &&
                    _shelters.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.shelterNoConfirmedShelters,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center ?? _germanyFallbackCenter,
                    initialZoom: _center != null
                        ? _zoomForRadius(_radiusKm)
                        : 5.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'de.preppsuite.app',
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(l10n.shelterAttribution),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        if (_center != null)
                          Marker(
                            point: _center!,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        for (final shelter in visibleShelters)
                          Marker(
                            point: LatLng(shelter.lat, shelter.lon),
                            width: 28,
                            height: 28,
                            child: Tooltip(
                              message:
                                  '${shelter.name} · ${shelter.sourceLabel}',
                              child: Icon(
                                Icons.shield,
                                color: _colorFor(shelter.confidence),
                                size: 28,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_center == null && !_isLoading)
                  Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.shelterEmptyPrompt,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                if (_isLoading)
                  const Positioned(
                    top: 12,
                    right: 12,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.shelterFilterAll(_shelters.length)),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                      for (final confidence in ShelterConfidence.values)
                        ChoiceChip(
                          label: Text(
                            l10n.shelterFilterCount(
                              switch (confidence) {
                                ShelterConfidence.green =>
                                  l10n.shelterLegendGreenLabel,
                                ShelterConfidence.yellow =>
                                  l10n.shelterLegendYellowLabel,
                                ShelterConfidence.red =>
                                  l10n.shelterLegendRedLabel,
                              },
                              counts[confidence] ?? 0,
                            ),
                          ),
                          selected: _filter == confidence,
                          onSelected: (_) =>
                              setState(() => _filter = confidence),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: l10n.shelterSearchHint,
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _search,
                        child: Text(l10n.shelterSearchButton),
                      ),
                    ],
                  ),
                  if (_locationError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _locationError!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final km in [10.0, 25.0, 50.0])
                        ChoiceChip(
                          label: Text('${km.round()} km'),
                          selected: _radiusKm == km,
                          onSelected: (_) {
                            setState(() => _radiusKm = km);
                            if (_center != null) {
                              _mapController.move(
                                _center!,
                                _zoomForRadius(km),
                              );
                              unawaited(_fetchShelters());
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _useCurrentLocation,
                    child: Text(l10n.shelterUseLocationButton),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _center == null ? null : _fetchShelters,
                    child: Text(l10n.shelterRefreshButton),
                  ),
                  if (_wwbotaFailed) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.shelterWwbotaErrorMessage,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                  if (_overpassFailed) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.shelterOverpassErrorMessage,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.description,
  });

  final Color color;
  final String label;
  final int count;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label ($count)  ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error_text.dart';
import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../maps/presentation/base_map_layer.dart';
import '../../maps/application/offline_map_providers.dart';
import '../../maps/presentation/map_coverage_notice.dart';
import '../../maps/presentation/map_source_bar.dart';
import '../../maps/presentation/map_zoom_buttons.dart';
import '../application/geo_bounds.dart';
import '../application/shelter_cache.dart';
import '../application/shelter_search.dart';
import '../application/overpass_shelter_client.dart';
import '../application/shelter_classification.dart';
import '../application/shelter_l10n.dart';
import '../application/wwbota_client.dart';
import '../../maps/presentation/swipe_zoom.dart';
import 'shelter_list.dart';

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
  final _cache = const ShelterCache();

  LatLng? _center;
  double _radiusKm = 25;
  ShelterConfidence? _filter;
  List<ClassifiedShelter> _shelters = const [];
  bool _isLoading = false;
  Object? _wwbotaError;
  Object? _overpassError;
  DateTime? _cachedAt;
  String? _locationError;

  int _lookupGeneration = 0;
  late final _shelterSearch = ShelterSearch(
    wwbota: (bounds) async =>
        classifyWwbota(await _wwbotaClient.fetchBunkers(bounds)),
    overpass: (bounds) async =>
        classifyOverpassFeatures(await _overpassClient.fetchShelters(bounds)),
  );

  @override
  void dispose() {
    _lookupGeneration++;
    _shelterSearch.cancel();
    _mapController.dispose();
    _searchController.dispose();
    _geolocationService.close();
    _wwbotaClient.close();
    _overpassClient.close();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    final generation = ++_lookupGeneration;
    _shelterSearch.cancel();
    setState(() {
      _locationError = null;
      _isLoading = false;
    });
    try {
      final position = await _geolocationService.getCurrentLatLng();
      if (!mounted || generation != _lookupGeneration) return;
      _setCenter(position);
    } on LocationUnavailableException catch (error) {
      if (mounted && generation == _lookupGeneration) {
        setState(() => _locationError = '$error');
      }
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final generation = ++_lookupGeneration;
    _shelterSearch.cancel();
    setState(() {
      _isLoading = false;
      _locationError = null;
    });
    try {
      final result = await _geolocationService.searchPlace(query);
      if (!mounted || generation != _lookupGeneration) return;
      if (result == null) {
        setState(
          () => _locationError = AppLocalizations.of(
            context,
          )!.shelterSearchNoResult,
        );
        return;
      }
      _setCenter(result);
    } catch (_) {
      if (mounted && generation == _lookupGeneration) {
        setState(
          () =>
              _locationError = AppLocalizations.of(context)!.searchUnavailable,
        );
      }
    }
  }

  void _setCenter(LatLng center) {
    setState(() => _center = center);
    _mapController.move(center, _zoomForRadius(_radiusKm));
    unawaited(_fetchShelters());
  }

  Future<void> _fetchShelters() async {
    final center = _center;
    if (center == null) return;
    final generation = ++_lookupGeneration;
    _shelterSearch.cancel();

    final bounds = boundingBoxForRadius(center, _radiusKm);
    final cached = await _cache.load(bounds);
    if (!mounted || generation != _lookupGeneration) return;
    if (cached != null) {
      setState(() {
        _shelters = cached.shelters;
        _cachedAt = cached.savedAt;
      });
    }

    await _shelterSearch.search(bounds, (result) {
      if (!mounted || generation != _lookupGeneration) return;
      setState(() {
        if (result.hasSuccessfulSource) {
          _shelters = result.shelters;
          _cachedAt = null;
        }
        _wwbotaError = result.wwbotaError;
        _overpassError = result.overpassError;
        _isLoading = result.pending > 0;
      });
      if (result.pending == 0 && result.hasSuccessfulSource) {
        unawaited(_cache.save(bounds, result.shelters));
      }
    });
  }

  /// What to say about Overpass having refused.
  ///
  /// The rate limit gets its own sentence and no reason under it: the
  /// message already says exactly what happened, and `describeError`
  /// would add "the service cannot be reached", which is the opposite of
  /// true — it answered, it was full.
  Widget _overpassFailure(AppLocalizations l10n) {
    final error = _overpassError!;
    final busy = error is OverpassException && error.isBusy;

    return _SourceFailure(
      message: busy
          ? l10n.shelterOverpassBusyMessage
          : l10n.shelterOverpassErrorMessage,
      reason: busy ? null : describeError(l10n, error),
      transient: busy,
      l10n: l10n,
    );
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

    // The same box the shelters are looked for in, which is also the
    // one the map is showing.
    final bounds = _center == null
        ? null
        : boundingBoxForRadius(_center!, _radiusKm);

    final mapHeight = (MediaQuery.sizeOf(context).height * 0.26)
        .clamp(176.0, 240.0)
        .toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shelterMapTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            l10n.shelterInfoLine(_radiusKm.round()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              title: Text(l10n.shelterLegendTitle),
              subtitle: Text(
                l10n.shelterLegendSummary(
                  counts[ShelterConfidence.green] ?? 0,
                  counts[ShelterConfidence.yellow] ?? 0,
                  counts[ShelterConfidence.red] ?? 0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          const SizedBox(height: 12),
          SizedBox(
            height: mapHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SwipeZoom(
                    // A Magic Mouse has no wheel; see swipe_zoom.dart.
                    controller: _mapController,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _center ?? _germanyFallbackCenter,
                        initialZoom: _center != null
                            ? _zoomForRadius(_radiusKm)
                            : 5.5,
                      ),
                      children: [
                        const BaseMapLayer(),
                        MapZoomButtons(controller: _mapController),
                        BaseMapAttribution(l10n: l10n),
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
                                // The grade belongs in the words, not only in
                                // the colour: three shields that differ in
                                // nothing but green, amber and red are three
                                // identical shields to anyone who cannot tell
                                // those apart.
                                child: Tooltip(
                                  message: l10n.shelterMarkerTooltip(
                                    shelter.name,
                                    localizeShelterConfidence(
                                      l10n,
                                      shelter.confidence,
                                    ),
                                    shelter.sourceLabel,
                                  ),
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
                  ),
                  if (_center == null && !_isLoading)
                    Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
          ),
          // Which map is being drawn, and why it may not be all there.
          // The shelter map is the one people open in a hurry, and a
          // half-drawn map with nothing said about it is the kind of
          // thing that gets blamed on the wrong part of the house.
          Consumer(
            builder: (context, ref, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MapCoverageNotice(
                  west: bounds?.west,
                  south: bounds?.south,
                  east: bounds?.east,
                  north: bounds?.north,
                  zoom: _zoomForRadius(_radiusKm).round(),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MapSourceBar(
                    state: ref.watch(offlineMapProvider).value,
                    l10n: l10n,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                      localizeShelterConfidence(l10n, confidence),
                      counts[confidence] ?? 0,
                    ),
                  ),
                  selected: _filter == confidence,
                  onSelected: (_) => setState(() => _filter = confidence),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ShelterList(
            shelters: visibleShelters,
            center: _center,
            l10n: l10n,
            colorFor: _colorFor,
            onShow: (shelter) => _mapController.move(
              LatLng(shelter.lat, shelter.lon),
              14,
            ),
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
            // Disabled while a search runs. Overpass allows two concurrent
            // queries per address and refuses the third, so a button that can
            // be pressed five times in a row is a button that produces the
            // rate-limit failure it is meant to clear.
            onPressed: _center == null || _isLoading ? null : _fetchShelters,
            child: Text(l10n.shelterRefreshButton),
          ),
          if (_wwbotaError != null) ...[
            const SizedBox(height: 8),
            _SourceFailure(
              message: l10n.shelterWwbotaErrorMessage,
              reason: describeError(l10n, _wwbotaError!),
              l10n: l10n,
            ),
          ],
          if (_overpassError != null) ...[
            const SizedBox(height: 8),
            _overpassFailure(l10n),
          ],
          if (_cachedAt != null &&
              _wwbotaError != null &&
              _overpassError != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.shelterCachedAt(
                MaterialLocalizations.of(
                  context,
                ).formatFullDate(_cachedAt!.toLocal()),
                MaterialLocalizations.of(context).formatTimeOfDay(
                  TimeOfDay.fromDateTime(_cachedAt!.toLocal()),
                ),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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

/// One source that would not answer, with the reason under it.
///
/// The reason is the point. This screen is opened when somebody wants to
/// know where they could go, and "could not be loaded" with nothing
/// behind it leaves them unable to tell a moment's rate limit from a
/// missing connection — the first clears itself, the second does not.
class _SourceFailure extends StatelessWidget {
  const _SourceFailure({
    required this.message,
    required this.reason,
    this.transient = false,
    required this.l10n,
  });

  final String message;

  /// Null where the message above already is the reason.
  final String? reason;

  /// A busy public service has not made the map or already found shelters
  /// unusable. Present it as a temporary notice rather than an alarm.
  final bool transient;

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = transient
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: color)),
        if (reason != null && reason != message)
          Text(
            l10n.shelterSourceFailureReason(reason!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
      ],
    );
  }
}

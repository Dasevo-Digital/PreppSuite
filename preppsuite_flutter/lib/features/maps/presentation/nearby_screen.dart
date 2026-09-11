import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shelters/application/shelter_l10n.dart';
import '../application/offline_map_providers.dart';
import '../application/offline_poi_search.dart';
import '../application/pmtiles_archive.dart';
import '../application/poi_labels.dart';
import 'map_download_screen.dart';

/// What is nearby, read out of the downloaded map.
///
/// Every other search in this app asks somebody: the shelter map asks
/// Overpass, the warnings ask the BBK, the gauge asks the water authority.
/// This one asks nothing. It reads the same archive the map draws from,
/// which is on this device and stays there — so it is the search that
/// still answers on the day the rest stop.
///
/// It promises no more than it can keep, and says so on the screen:
/// coverage is exactly what was downloaded, the data is OpenStreetMap's,
/// and a point on a map is not a shop that is open.
class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key, this.centre, this.centreLabel});

  /// Where to search around. Usually the map's centre, handed over when
  /// this is opened from there — no position lookup, no network, nothing
  /// to permit.
  final LatLng? centre;

  /// What to call that point on screen.
  final String? centreLabel;

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

/// The radii offered, in metres.
///
/// Ten kilometres is the top not because the search could not do more but
/// because it stops being an answer: past an hour's walk, "which way and
/// how far" is a different question than this screen is asking.
const _radii = [2000.0, 5000.0, 10000.0];

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  final _geolocation = GeolocationService();

  late LatLng? _centre = widget.centre;
  late String? _centreLabel = widget.centreLabel;

  double _radius = 2000;
  var _kinds = {...PoiKind.values};

  StreamSubscription<PoiSearchProgress>? _subscription;

  /// The archive the current results came out of.
  ///
  /// The controller that opens it is asynchronous, so arriving here from
  /// anywhere but the map usually means the first frame has no archive
  /// yet. Without this the search would run once against nothing and
  /// report "no map downloaded" for a map that was about to open.
  PmTilesArchive? _searchedWith;
  var _places = <NearbyPlace>[];
  PoiSearchProgress? _progress;
  PoiSearchProblem? _problem;
  var _locating = false;

  @override
  void dispose() {
    _subscription?.cancel();
    _geolocation.close();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final position = await _geolocation.getCurrentLatLng();
      if (!mounted) return;
      setState(() {
        _centre = position;
        _centreLabel = null;
      });
      await _run();
    } on LocationUnavailableException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Starts a search, throwing away whatever the last one was doing.
  Future<void> _run() async {
    final centre = _centre;
    final archive = ref.read(offlineMapProvider).value?.archive;
    if (centre == null) return;
    _searchedWith = archive;

    await _subscription?.cancel();
    setState(() {
      _places = const [];
      _progress = null;
      _problem = archive == null ? PoiSearchProblem.noArchive : null;
    });
    if (archive == null) return;

    final Stream<PoiSearchProgress> stream;
    try {
      stream = OfflinePoiSearch(archive).search(
        centre: centre,
        radiusMeters: _radius,
        kinds: _kinds,
      );
    } on PoiSearchException catch (error) {
      setState(() => _problem = error.problem);
      return;
    }

    _subscription = stream.listen(
      (progress) => setState(() {
        _places = progress.places;
        _progress = progress;
      }),
      // The stream is built lazily, so the two refusals — an archive that
      // stops above zoom 14, a point outside it — arrive here rather than
      // from the call above.
      onError: (Object error) => setState(() {
        _problem = error is PoiSearchException
            ? error.problem
            : PoiSearchProblem.noArchive;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final archive = ref.watch(offlineMapProvider).value?.archive;

    // Starts the first search, and starts it again if the archive is
    // swapped for another while this screen is open. Deferred to after
    // the frame, because nothing may change state during a build.
    if (archive != null && !identical(archive, _searchedWith)) {
      _searchedWith = archive;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _run();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbyTitle),
        actions: [
          IconButton(
            tooltip: l10n.nearbyUseMyLocation,
            onPressed: _locating ? null : _useMyLocation,
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
      body: archive == null
          ? _Explanation(
              title: l10n.nearbyNoArchive,
              body: l10n.nearbyNoArchiveWhy,
              action: l10n.nearbyDownloadMap,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MapDownloadScreen(),
                ),
              ),
            )
          : _centre == null
          ? _Explanation(
              title: l10n.nearbyNoCentre,
              body: l10n.nearbyNoCentreWhy,
              action: l10n.nearbyUseMyLocation,
              onAction: _locating ? null : _useMyLocation,
            )
          : _results(l10n),
    );
  }

  Widget _results(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final progress = _progress;

    if (_problem case final problem?
        when problem != PoiSearchProblem.noArchive) {
      return _Explanation(
        title: switch (problem) {
          PoiSearchProblem.tooShallow => l10n.nearbyTooShallow,
          PoiSearchProblem.outsideArchive => l10n.nearbyOutsideArchive,
          PoiSearchProblem.noArchive => l10n.nearbyNoArchive,
        },
        body: switch (problem) {
          PoiSearchProblem.tooShallow => l10n.nearbyTooShallowWhy,
          PoiSearchProblem.outsideArchive => l10n.nearbyOutsideArchiveWhy,
          PoiSearchProblem.noArchive => l10n.nearbyNoArchiveWhy,
        },
        action: l10n.nearbyDownloadMap,
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MapDownloadScreen()),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Text(
          l10n.nearbySearchFrom(
            _centreLabel ?? l10n.nearbyMyPosition,
          ),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SegmentedButton<double>(
          segments: [
            for (final radius in _radii)
              ButtonSegment(
                value: radius,
                label: Text(l10n.nearbyRadiusKm((radius / 1000).round())),
              ),
          ],
          selected: {_radius},
          onSelectionChanged: (selected) {
            setState(() => _radius = selected.single);
            _run();
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final kind in PoiKind.values)
              FilterChip(
                label: Text(localizePoiKind(l10n, kind)),
                selected: _kinds.contains(kind),
                onSelected: (on) {
                  setState(() {
                    final next = {..._kinds};
                    if (on) {
                      next.add(kind);
                    } else {
                      next.remove(kind);
                    }
                    // Never all of them off: an empty filter would read
                    // as "nothing is nearby" rather than "nothing was
                    // asked for".
                    if (next.isNotEmpty) _kinds = next;
                  });
                  _run();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (progress != null && !progress.isComplete) ...[
          LinearProgressIndicator(
            value: progress.tilesTotal == 0
                ? null
                : progress.tilesRead / progress.tilesTotal,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.nearbySearching(progress.tilesRead, progress.tilesTotal),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        if (_places.isEmpty && (progress?.isComplete ?? false)) ...[
          Text(l10n.nearbyNothingFound, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.nearbyNothingFoundWhy),
          const SizedBox(height: 16),
        ],
        for (final kind in PoiKind.values)
          if (_kinds.contains(kind)) ?_group(l10n, kind),
        const SizedBox(height: 8),
        Text(l10n.nearbyCaveats, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(l10n.nearbyShelterNote, style: theme.textTheme.bodySmall),
      ],
    );
  }

  /// One group's section, or nothing at all when it found nothing.
  Widget? _group(AppLocalizations l10n, PoiKind kind) {
    final matching = [
      for (final place in _places)
        if (place.kind == kind) place,
    ];
    if (matching.isEmpty) return null;

    // Ten is what fits a decision. A city block holds a hundred and
    // eighty surgeries and nobody reads past the nearest few — but the
    // count is still said out loud, because "10" and "10 of 187" are
    // different facts.
    const shown = 10;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${localizePoiKind(l10n, kind)} · ${matching.length}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < matching.length && index < shown;
                  index++
                ) ...[
                  if (index > 0) const Divider(height: 1),
                  _PlaceTile(place: matching[index], l10n: l10n),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({required this.place, required this.l10n});

  final NearbyPlace place;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final what = localizePoiSubclass(l10n, place.subclass);
    return ListTile(
      dense: true,
      // A nameless point is shown by what it is. Of sixty-seven
      // drinking-water points in the measured sample, seven carried a
      // name — dropping the rest would empty the one category that
      // matters most.
      title: Text(place.name ?? what),
      subtitle: place.name == null ? null : Text(what),
      trailing: Text(
        formatShelterDistance(l10n, place.distanceMeters, place.bearing),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String body;
  final String action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(body),
      const SizedBox(height: 16),
      FilledButton(onPressed: onAction, child: Text(action)),
    ],
  );
}

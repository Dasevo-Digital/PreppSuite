import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/map_source_preference.dart';
import '../application/offline_map_coverage.dart';
import '../application/offline_map_providers.dart';
import 'base_map_layer.dart';

/// Why the map on this screen is not all there.
///
/// Two different reasons produce the same picture — half a map and half
/// nothing — and the app knows which one it is in both cases:
///
///  * the archive was downloaded for somewhere else, or for a smaller
///    area than the one on screen. Nothing is wrong and nothing will
///    improve by waiting.
///  * the tile server did not answer. Nothing is wrong with the app
///    either, and this one may well fix itself.
///
/// Saying neither is what turns "the map does not load" into an evening
/// spent restarting things. Each case also carries the one useful
/// action: the other source.
class MapCoverageNotice extends ConsumerStatefulWidget {
  const MapCoverageNotice({
    super.key,
    required this.west,
    required this.south,
    required this.east,
    required this.north,
    required this.zoom,
  });

  /// The view the notice is about. Null bounds mean the screen has not
  /// settled on a place yet, and there is nothing to report about one.
  final double? west;
  final double? south;
  final double? east;
  final double? north;
  final int zoom;

  @override
  ConsumerState<MapCoverageNotice> createState() => _MapCoverageNoticeState();
}

class _MapCoverageNoticeState extends ConsumerState<MapCoverageNotice> {
  OfflineMapCoverage? _coverage;

  /// What the last answer was about, so an unchanged view is not
  /// re-measured on every rebuild.
  Object? _measured;

  @override
  void initState() {
    super.initState();
    onlineTileFailures.addListener(_onFailure);
  }

  @override
  void dispose() {
    onlineTileFailures.removeListener(_onFailure);
    super.dispose();
  }

  void _onFailure() {
    if (mounted) setState(() {});
  }

  Future<void> _measure() async {
    final archive = ref.read(offlineMapProvider).value?.archive;
    final west = widget.west;
    final south = widget.south;
    final east = widget.east;
    final north = widget.north;
    if (archive == null ||
        west == null ||
        south == null ||
        east == null ||
        north == null) {
      return;
    }

    final token = [archive, west, south, east, north, widget.zoom].join('|');
    if (token == _measured) return;
    _measured = token;

    final coverage = await offlineMapCoverage(
      archive,
      west: west,
      south: south,
      east: east,
      north: north,
      zoom: widget.zoom,
    );
    // The view may have moved on while the archive was being read, and
    // an answer about where the map used to be is worse than none.
    if (mounted && token == _measured) {
      setState(() => _coverage = coverage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offline = usesOfflineMap(ref);
    final hasArchive = ref.watch(offlineMapProvider).value?.isReady ?? false;

    if (offline) {
      // Reading the archive is asynchronous and this is a build, so the
      // answer arrives one frame later and through setState.
      _measure();

      final coverage = _coverage;
      if (coverage == null || coverage.isComplete) {
        return const SizedBox.shrink();
      }
      return _Notice(
        message: coverage.isMissing
            ? l10n.mapCoverageMissing
            : l10n.mapCoverageIncomplete(coverage.present, coverage.total),
        action: l10n.mapCoverageUseOnline,
        onAction: () => ref
            .read(mapSourceProvider.notifier)
            .use(MapSourcePreference.online),
      );
    }

    if (!onlineTileFailures.recent) return const SizedBox.shrink();
    return _Notice(
      message: l10n.mapTilesUnavailable,
      // Only where there is something to switch to. An offer that does
      // nothing is worse than no offer.
      action: hasArchive ? l10n.mapCoverageUseOffline : null,
      onAction: () {
        onlineTileFailures.clear();
        ref.read(mapSourceProvider.notifier).use(MapSourcePreference.offline);
      },
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.action, this.onAction});

  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.layers_clear_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(message, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
              if (action != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: onAction, child: Text(action!)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

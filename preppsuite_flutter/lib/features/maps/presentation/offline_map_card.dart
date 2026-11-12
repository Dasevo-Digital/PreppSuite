import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../emergency_points/application/offline_nearby_points.dart';
import '../../shelters/application/geo_bounds.dart' show GeoBoundingBox;
import '../application/map_archive_access.dart';
import '../application/offline_map_providers.dart';
import 'map_download_screen.dart';
import '../../../core/error_text.dart';

/// Settings card for the offline map.
///
/// One decision to make — which file — and one thing worth showing back:
/// how far the archive actually zooms, because that is what decides
/// whether it is a street map or a country outline.
class OfflineMapCard extends ConsumerWidget {
  const OfflineMapCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(offlineMapProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.offlineMapIntro, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            switch (async) {
              AsyncLoading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              AsyncError(:final error) => Text(
                describeError(l10n, error),
              ),
              _ => _Body(state: async.requireValue, l10n: l10n),
            },
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state, required this.l10n});

  final OfflineMapState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final archive = state.archive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.isConfigured)
          Text(l10n.offlineMapInactive, style: theme.textTheme.bodyMedium)
        else ...[
          Text(
            l10n.offlineMapActive(state.label!),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          if (archive != null)
            Text(
              l10n.offlineMapZoomRange(
                archive.header.minZoom,
                archive.header.maxZoom,
              ),
              style: theme.textTheme.bodySmall,
            ),
          if (state.problem != null)
            Text(
              _explain(state.problem!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          if (archive != null) ...[
            const SizedBox(height: 8),
            _OfflinePoints(bounds: boundsOfArchive(archive), l10n: l10n),
          ],
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const MapDownloadScreen(),
                ),
              ),
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(l10n.mapDownloadAction),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _choose(context, ref),
              icon: const Icon(Icons.map_outlined),
              label: Text(
                state.isConfigured
                    ? l10n.offlineMapChangeAction
                    : l10n.offlineMapChooseAction,
              ),
            ),
            if (state.isConfigured)
              TextButton(
                onPressed: () => ref.read(offlineMapProvider.notifier).forget(),
                child: Text(l10n.offlineMapForgetAction),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final picked = await pickMapArchive(
      dialogTitle: l10n.settingsOfflineMapTitle,
    );
    if (picked == null) return;

    final problem = await ref
        .read(offlineMapProvider.notifier)
        .useArchive(location: picked.value, label: picked.label);
    if (problem == null || !context.mounted) return;

    // The card shows the same reason, but a file that was just picked and
    // refused deserves an answer at the moment of picking.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_explain(problem))));
  }

  String _explain(OfflineMapProblem problem) => switch (problem) {
    OfflineMapProblem.unreadable => l10n.offlineMapErrorUnreadable,
    OfflineMapProblem.notVectorTiles => l10n.offlineMapErrorNotVector,
    OfflineMapProblem.unknownSchema => l10n.offlineMapErrorSchema,
  };
}

/// What came along with the map for the searches near a place (#366):
/// how many, from when, and a way to ask again.
class _OfflinePoints extends ConsumerWidget {
  const _OfflinePoints({required this.bounds, required this.l10n});

  final GeoBoundingBox bounds;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(offlineNearbyPointsProvider).value;
    if (state == null) return const SizedBox.shrink();
    final kept = state.kept;
    final forThisMap = kept != null && kept.isFor(bounds);

    final text = switch (state.status) {
      OfflinePointsStatus.fetching => l10n.offlineMapPointsFetching,
      OfflinePointsStatus.tooLarge => l10n.offlineMapPointsTooLarge,
      OfflinePointsStatus.failed when !forThisMap =>
        l10n.offlineMapPointsFailed,
      _ when forThisMap => l10n.offlineMapPointsKept(
        kept.defibrillators,
        kept.points,
        DateFormat.yMMMd(l10n.localeName).format(kept.fetchedAt.toLocal()),
      ),
      _ => l10n.offlineMapPointsMissing,
    };
    final failedAgain =
        state.status == OfflinePointsStatus.failed && forThisMap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: theme.textTheme.bodySmall),
        if (failedAgain)
          Text(
            l10n.offlineMapPointsFailed,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        if (state.status == OfflinePointsStatus.fetching)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: LinearProgressIndicator(),
          )
        else if (state.status != OfflinePointsStatus.tooLarge)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => ref
                  .read(offlineNearbyPointsProvider.notifier)
                  .refresh(bounds),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.offlineMapPointsRefresh),
            ),
          ),
      ],
    );
  }
}

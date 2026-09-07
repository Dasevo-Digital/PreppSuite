import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/map_source_preference.dart';
import '../application/offline_map_providers.dart';
import 'base_map_layer.dart';

/// Which map is being drawn, and the switch between them.
class MapSourceBar extends ConsumerWidget {
  const MapSourceBar({super.key, required this.state, required this.l10n});

  final OfflineMapState? state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final archive = state?.archive;
    final preference = ref.watch(mapSourceProvider);
    final offline = usesOfflineMap(ref);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              offline && archive != null
                  ? l10n.mapSourceOfflineDetail(
                      state!.label!,
                      archive.header.minZoom,
                      archive.header.maxZoom,
                    )
                  : archive == null
                  ? l10n.mapSourceNoArchive
                  : l10n.mapSourceOnlineDetail,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<MapSourcePreference>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: MapSourcePreference.offline,
                  icon: const Icon(Icons.sd_storage_outlined, size: 18),
                  label: Text(l10n.mapSourceOffline),
                  // Nothing to switch to without a download; the line
                  // above says so rather than leaving a dead control
                  // that looks like it should work.
                  enabled: archive != null,
                ),
                ButtonSegment(
                  value: MapSourcePreference.online,
                  icon: const Icon(Icons.cloud_outlined, size: 18),
                  label: Text(l10n.mapSourceOnline),
                ),
              ],
              selected: {
                archive == null ? MapSourcePreference.online : preference,
              },
              onSelectionChanged: (selection) =>
                  ref.read(mapSourceProvider.notifier).use(selection.single),
            ),
          ],
        ),
      ),
    );
  }
}

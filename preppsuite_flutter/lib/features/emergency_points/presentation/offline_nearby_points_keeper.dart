import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../maps/application/offline_map_providers.dart';
import '../application/offline_nearby_points.dart';

/// Keeps the points in step with the offline map. Draws nothing; sits in
/// the shell beside the other keepers, so it sees a map taken into use
/// from settings, from a download or from a restored backup alike.
class OfflineNearbyPointsKeeper extends ConsumerStatefulWidget {
  const OfflineNearbyPointsKeeper({super.key});

  @override
  ConsumerState<OfflineNearbyPointsKeeper> createState() =>
      _OfflineNearbyPointsKeeperState();
}

class _OfflineNearbyPointsKeeperState
    extends ConsumerState<OfflineNearbyPointsKeeper> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(offlineMapProvider, (previous, next) {
      final map = next.value;
      if (map == null) return;
      final points = ref.read(offlineNearbyPointsProvider.notifier);
      if (map.archive case final archive?) {
        unawaited(points.ensureFor(boundsOfArchive(archive)));
      } else if (!map.isConfigured) {
        // No map any more: the points belonged to it. A map that is only
        // unreadable for now (a disk not plugged in) keeps them.
        unawaited(points.forget());
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

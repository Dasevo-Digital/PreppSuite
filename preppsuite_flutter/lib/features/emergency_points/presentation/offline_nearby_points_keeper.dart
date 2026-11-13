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
  /// Looks again now and then: a desktop app can stay open for weeks, and
  /// the map itself does not change to say that its points are 60 days
  /// old.
  Timer? _again;

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
    _again = Timer.periodic(const Duration(hours: 12), (_) {
      final archive = ref.read(offlineMapProvider).value?.archive;
      if (archive == null) return;
      unawaited(
        ref
            .read(offlineNearbyPointsProvider.notifier)
            .ensureFor(boundsOfArchive(archive)),
      );
    });
  }

  @override
  void dispose() {
    _again?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'mapSourcePreference';

/// Where the map should draw from when there is a choice.
///
/// There is only a choice when an archive is open; without one everything
/// falls back to the network whatever this says.
enum MapSourcePreference {
  /// The archive on the device, and the network only when there is no
  /// archive at all. The default, because that is what the download was
  /// for.
  offline,

  /// The network, even with an archive open.
  ///
  /// Worth having: an extract covers the region somebody downloaded, and
  /// looking anywhere else means a blank screen until they switch. This
  /// is the switch.
  online,
}

class MapSourceController extends Notifier<MapSourcePreference> {
  @override
  MapSourcePreference build() {
    // Same shape as ThemeModeController: the stored value arrives a frame
    // or two later rather than holding up the first build.
    unawaited(_loadInitial());
    return MapSourcePreference.offline;
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    final name = prefs.getString(_prefsKey);
    if (name != null) {
      state =
          MapSourcePreference.values.asNameMap()[name] ??
          MapSourcePreference.offline;
    }
  }

  Future<void> use(MapSourcePreference preference) async {
    state = preference;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, preference.name);
  }
}

final mapSourceProvider =
    NotifierProvider<MapSourceController, MapSourcePreference>(
      MapSourceController.new,
    );

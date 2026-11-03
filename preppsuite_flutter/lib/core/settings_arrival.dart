import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings that this device did not write itself (#237).
///
/// What another device's snapshot, a handover, a QR join or a backup
/// carries is written straight into the preferences. A screen opened
/// afterwards reads it; a controller that read it once when the app
/// started did not, and held the old value until the next start -- and
/// neither did a screen that was already open (#258, see
/// [RereadOnSettingsArrival]). The expiry lead times were worst: toggling one afterwards
/// computed from the old list and wrote it back, and the next sync took
/// that old list into the household.
///
/// So whatever writes settings from elsewhere announces it, and such
/// controllers read their value again.
final _arrivals = StreamController<void>.broadcast();

/// Called after settings from elsewhere have been written here.
void announceSettingsArrival() => _arrivals.add(null);

/// Counts the arrivals. Read again on a change rather than rebuilding:
/// a controller that falls back to its default while it reloads would
/// show, and act on, the default for a moment.
final settingsArrivalProvider = NotifierProvider<SettingsArrival, int>(
  SettingsArrival.new,
);

class SettingsArrival extends Notifier<int> {
  @override
  int build() {
    final subscription = _arrivals.stream.listen((_) => state++);
    ref.onDispose(subscription.cancel);
    return 0;
  }
}

/// For a screen that reads a setting of the household as it opens and
/// keeps it in its own state (#258).
///
/// Such a screen stays open while the app is in the background and the
/// shared folder delivers another device's change. Without this it showed
/// the old value, and its next edit wrote the old value back over the
/// new one: an energy plan lost the reserve the laptop had added, and a
/// blackout ended on one device ran again because somebody on another
/// changed how full the freezer was. So it reads again when settings
/// arrive -- and edits what is stored, not what it last showed.
///
/// A mixin over the stream rather than [settingsArrivalProvider]: these
/// screens are not all inside Riverpod, and do not need to be.
mixin RereadOnSettingsArrival<T extends StatefulWidget> on State<T> {
  StreamSubscription<void>? _arrival;

  /// Reads this screen's settings again.
  void settingsArrived();

  @override
  void initState() {
    super.initState();
    _arrival = _arrivals.stream.listen((_) {
      if (mounted) settingsArrived();
    });
  }

  @override
  void dispose() {
    _arrival?.cancel();
    super.dispose();
  }
}

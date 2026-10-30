import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings that this device did not write itself (#237).
///
/// What another device's snapshot, a handover, a QR join or a backup
/// carries is written straight into the preferences. The screens that
/// read a setting as they open see it at once; a controller that read it
/// once when the app started did not, and held the old value until the
/// next start. The expiry lead times were worst: toggling one afterwards
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

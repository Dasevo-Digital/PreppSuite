import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import 'settings_arrival.dart';

const _notificationsEnabledPrefsKey = 'notificationsEnabled';

/// Whether this device's system has been asked at all. Not carried with the
/// household: it is the one thing a backup cannot know about another device.
const _permissionAskedHerePrefsKey = 'notificationsPermissionAskedHere';

/// Reads the persisted notification setting without a provider container.
///
/// The background worker runs in its own isolate, where Riverpod does not
/// exist — but it still has to respect the switch, or it would poll and
/// notify for someone who asked not to be told.
class NotificationsEnabledStore {
  const NotificationsEnabledStore();

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledPrefsKey) ?? false;
  }
}

/// Whether the user opted in to local notifications for new warnings.
/// Defaults to `false` (opt-in only, since enabling it triggers an OS
/// permission prompt) — mirrors `locale_provider.dart`'s shape.
class NotificationsEnabledController extends Notifier<bool> {
  Future<void>? _initialLoad;

  /// What asks the system, for a test to replace.
  @visibleForTesting
  static Future<bool> Function() askSystem =
      NotificationService.instance.requestPermission;

  @override
  bool build() {
    // Read again in place, never through a rebuild: a rebuild reports
    // false for a moment, which is what unregistered push (see below).
    ref.listen(settingsArrivalProvider, (_, _) => unawaited(_loadInitial()));
    _initialLoad = _loadInitial();
    unawaited(_initialLoad);
    return false;
  }

  /// Completes once the persisted value has been read.
  ///
  /// [build] has to return synchronously, so for one turn of the event
  /// loop this provider reports `false` regardless of what the user chose.
  /// Anything that acts on the setting rather than merely displaying it
  /// must wait for this first — push registration read the provisional
  /// `false` as "the user turned notifications off" and dutifully
  /// unregistered the device on every launch.
  Future<void> ensureLoaded() => _initialLoad ?? Future.value();

  Future<void> _loadInitial() async {
    final enabled = await const NotificationsEnabledStore().isEnabled();
    // See LocaleOverrideController for why this guard is needed after an
    // async gap.
    if (!ref.mounted) return;
    state = enabled;
    if (enabled) unawaited(_askIfNeverAskedHere());
  }

  /// A switch that arrived on from another device, in a backup or a
  /// handover, was never put to this device's system (#333): it read as
  /// on while nothing could appear. Once per device, and after the load
  /// rather than inside it, so that a dialog left open holds nothing up.
  Future<void> _askIfNeverAskedHere() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permissionAskedHerePrefsKey) ?? false) return;
    await prefs.setBool(_permissionAskedHerePrefsKey, true);
    final bool granted;
    try {
      granted = await askSystem();
    } on Object {
      return;
    }
    await prefs.setBool(_notificationsEnabledPrefsKey, granted);
    if (ref.mounted) state = granted;
  }

  /// Requests OS permission when turning notifications on; only persists
  /// `true` if the OS actually granted it, so the toggle never lies about
  /// whether notifications will really show.
  Future<void> setEnabled(bool enabled) async {
    final actuallyEnabled = enabled ? await askSystem() : false;

    state = actuallyEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledPrefsKey, actuallyEnabled);
    if (enabled) await prefs.setBool(_permissionAskedHerePrefsKey, true);
  }
}

/// Whether the system would show a notification, asked again whenever the
/// app comes back from wherever that may have been changed (#333).
final systemNotificationsAllowedProvider = FutureProvider.autoDispose<bool>((
  ref,
) {
  AppLifecycleListener? lifecycle;
  try {
    lifecycle = AppLifecycleListener(onResume: ref.invalidateSelf);
  } on Object {
    // No binding, as in a plain unit test.
  }
  ref.onDispose(() => lifecycle?.dispose());
  return NotificationService.instance.systemAllowsNotifications();
});

final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledController, bool>(
      NotificationsEnabledController.new,
    );

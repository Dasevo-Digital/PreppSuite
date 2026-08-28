import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

const _notificationsEnabledPrefsKey = 'notificationsEnabled';

/// Whether the user opted in to local notifications for new warnings.
/// Defaults to `false` (opt-in only, since enabling it triggers an OS
/// permission prompt) — mirrors `locale_provider.dart`'s shape.
class NotificationsEnabledController extends Notifier<bool> {
  Future<void>? _initialLoad;

  @override
  bool build() {
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
    final prefs = await SharedPreferences.getInstance();
    // See LocaleOverrideController for why this guard is needed after an
    // async gap.
    if (!ref.mounted) return;
    state = prefs.getBool(_notificationsEnabledPrefsKey) ?? false;
  }

  /// Requests OS permission when turning notifications on; only persists
  /// `true` if the OS actually granted it, so the toggle never lies about
  /// whether notifications will really show.
  Future<void> setEnabled(bool enabled) async {
    final actuallyEnabled = enabled
        ? await NotificationService.instance.requestPermission()
        : false;

    state = actuallyEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledPrefsKey, actuallyEnabled);
  }
}

final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledController, bool>(
      NotificationsEnabledController.new,
    );

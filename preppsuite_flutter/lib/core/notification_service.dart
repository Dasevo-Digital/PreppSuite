import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:preppsuite_client/preppsuite_client.dart' show Warning;

/// Local (on-device) notifications for newly-pulled warnings — not a real
/// push (no FCM/APNs server component), so a notification only fires while
/// the app is actually running and syncing. See
/// `WarningSyncController.syncNow` for the trigger point.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    await _plugin.initialize(
      settings: const InitializationSettings(
        // Permission is requested explicitly when the user enables
        // notifications in Settings (see [requestPermission]), not here —
        // asking at every app start regardless of intent is bad practice
        // and is exactly what these `request*Permission: false` flags
        // avoid (per the plugin's own guidance).
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  /// Requests OS notification permission. Returns whether it was granted —
  /// callers should only flip their "notifications enabled" preference on
  /// if this returns `true`.
  Future<bool> requestPermission() async {
    await _ensureInitialized();

    final macOSGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    if (macOSGranted != null) return macOSGranted;

    final iOSGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    if (iOSGranted != null) return iOSGranted;

    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (androidGranted != null) return androidGranted;

    // No platform-specific implementation resolved (e.g. desktop other
    // than macOS) — assume granted, `show()` will just no-op if not.
    return true;
  }

  Future<void> showWarningNotification(Warning warning) async {
    await _ensureInitialized();
    await _plugin.show(
      // Stable per-warning id so re-notifying the same warning (e.g. after
      // an unrelated field update) replaces rather than stacks.
      id: warning.externalId.hashCode,
      title: warning.headline,
      body: warning.eventType,
      notificationDetails: const NotificationDetails(
        macOS: DarwinNotificationDetails(),
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'warnings',
          'Warnungen',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../local_db/database.dart' show Warning;
import 'package:timezone/timezone.dart' as tz;

import '../features/inventory/application/expiry_reminder_planner.dart';
import 'notification_capabilities.dart';

/// On-device notifications.
///
/// Warnings are announced from two places that have to produce the same
/// notification: `WarningSyncController` while a screen is open, and the
/// Android background worker while the app is closed. Expiry reminders are
/// scheduled ahead of time and need nothing running at all.
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
        // Both desktops refuse to initialise without their own settings,
        // and the failure is an unhandled exception from the timer that
        // schedules expiry reminders — not a missing notification. It
        // took running the app on Linux to see it.
        //
        // The action name is the app's own, which is a proper noun and
        // needs no translation. GNOME and KDE do not display it anyway;
        // it names the action that clicking the notification triggers.
        linux: LinuxInitializationSettings(defaultActionName: 'PreppSuite'),
        windows: WindowsInitializationSettings(
          appName: 'PreppSuite',
          // Company.Product form, and stable: Windows ties delivered
          // notifications to it, so changing it orphans the ones already
          // scheduled.
          appUserModelId: 'Status403.PreppSuite',
          guid: '9E1A6D86-E8D0-4CEB-897C-8D7E50D5BEE7',
        ),
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

  Future<void> showLocalWarning(Warning warning) async {
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

  /// Payload prefix marking a notification as an expiry reminder, so
  /// [scheduleExpiryReminders] can clear exactly its own pending ones and
  /// leave anything else (warnings) alone.
  static const _expiryPayloadPrefix = 'expiry:';

  /// Replaces all pending expiry reminders with [reminders].
  ///
  /// Rescheduling wholesale rather than diffing: the planner already
  /// produces the complete set that should be pending, and an item's
  /// expiration date, name or existence can change between runs. Cancel-
  /// then-schedule is a few more platform calls but cannot leave a
  /// reminder behind for an item that no longer expires then.
  ///
  /// [title] and [body] build the user-facing text, so this stays free of
  /// localization concerns — see `expiry_reminder_controller.dart`.
  Future<void> scheduleExpiryReminders(
    List<ExpiryReminder> reminders, {
    required String Function(ExpiryReminder) title,
    required String Function(ExpiryReminder) body,
  }) async {
    // Nothing to schedule with where the platform cannot hold a
    // notification until a date. Returning quietly rather than throwing:
    // the scheduler runs on a timer behind every tab, so a failure here
    // is an unhandled exception every few minutes and no notification
    // either way.
    if (!supportsScheduledNotifications) return;

    await _ensureInitialized();
    await cancelExpiryReminders();

    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: title(reminder),
        body: body(reminder),
        payload: '$_expiryPayloadPrefix${reminder.itemClientId}',
        // `fireAt` is local wall-clock time; converting it to UTC gives the
        // right absolute instant without needing the timezone database and
        // a platform channel to name the local zone. The only cost is that
        // a reminder scheduled across a DST change fires an hour off its
        // intended hour, which does not matter for a date-based nudge.
        scheduledDate: tz.TZDateTime.from(reminder.fireAt.toUtc(), tz.UTC),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          macOS: DarwinNotificationDetails(),
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'expiry',
            'Ablaufende Vorräte',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    }
  }

  /// Cancels every pending expiry reminder, leaving other notifications
  /// untouched. Identified by payload rather than by recomputing ids, so
  /// it still works for reminders scheduled by an earlier app run.
  Future<void> cancelExpiryReminders() async {
    if (!supportsScheduledNotifications) return;

    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith(_expiryPayloadPrefix) ?? false) {
        await _plugin.cancel(id: request.id);
      }
    }
  }
}

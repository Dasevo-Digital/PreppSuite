import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../local_db/database.dart' show Warning;
import '../model/categories.dart' show WarningSeverity;

import 'package:timezone/timezone.dart' as tz;

import '../features/inventory/application/expiry_reminder_planner.dart';
import '../features/inventory/application/refill_reminder_planner.dart';
import 'notification_capabilities.dart';

/// How insistently a warning may interrupt on iOS (#101).
///
/// Severe and extreme warnings are time-sensitive: they reach the lock
/// screen through a Focus mode and "Do not disturb", which is the whole
/// point of a warning that arrives at night. Everything below stays an
/// ordinary notification -- a minor one is never announced at all (see
/// `WarningPollService.notifySeverityFloor`), and letting a moderate one
/// through every Focus would teach people to switch the channel off.
///
/// Time-sensitive and not critical: a critical alert also overrides the
/// mute switch, and needs Apple's approval case by case.
///
/// **Without effect for now.** Time-sensitive delivery needs the
/// `com.apple.developer.usernotifications.time-sensitive` entitlement, and
/// a personal development team cannot have it: Xcode refuses to create a
/// profile, and with the entitlement in place no device build signs at all
/// (tried 2026-10-04). Without it iOS treats the level as `active`, so this
/// is harmless today and takes effect once the app is signed by a paid
/// developer account -- add the entitlement then (#101). macOS keeps the
/// default: its packages are signed ad hoc, and a restricted entitlement
/// there stops the app from starting at all.
InterruptionLevel warningInterruptionLevel(WarningSeverity severity) =>
    switch (severity) {
      WarningSeverity.severe ||
      WarningSeverity.extreme => InterruptionLevel.timeSensitive,
      WarningSeverity.minor ||
      WarningSeverity.moderate => InterruptionLevel.active,
    };

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
          // scheduled. Changed once, with the identifier (it was
          // `Status403.PreppSuite`); the reminders are scheduled again
          // from the inventory, so what is orphaned is only what was
          // already pending at the update.
          appUserModelId: 'Dasevo.PreppSuite',
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
      notificationDetails: NotificationDetails(
        macOS: const DarwinNotificationDetails(),
        iOS: DarwinNotificationDetails(
          interruptionLevel: warningInterruptionLevel(
            WarningSeverity.fromName(warning.severity),
          ),
        ),
        android: const AndroidNotificationDetails(
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
  static const _refillPayloadPrefix = 'refill:';
  static const _chargeReminderId = 90407;
  static const _warningDayId = 90408;
  static const _backupReminderId = 90409;

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

  /// Replaces all pending prescription reminders with [reminders] (#150).
  /// Wholesale, like [scheduleExpiryReminders], and for the same reason.
  Future<void> scheduleRefillReminders(
    List<RefillReminder> reminders, {
    required String title,
    required String Function(RefillReminder) body,
  }) async {
    if (!supportsScheduledNotifications) return;

    await _ensureInitialized();
    await cancelRefillReminders();

    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: title,
        body: body(reminder),
        payload: '$_refillPayloadPrefix${reminder.itemClientId}',
        // Local wall-clock time to UTC; see [scheduleExpiryReminders].
        scheduledDate: tz.TZDateTime.from(reminder.fireAt.toUtc(), tz.UTC),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: const NotificationDetails(
          macOS: DarwinNotificationDetails(),
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'refill',
            'Rezepte',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
      );
    }
  }

  /// Cancels every pending prescription reminder, by payload.
  Future<void> cancelRefillReminders() async {
    if (!supportsScheduledNotifications) return;

    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.payload?.startsWith(_refillPayloadPrefix) ?? false) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  /// Schedules the next routine check for rechargeable emergency equipment.
  /// Its fixed id means selecting another interval replaces the old check.
  Future<void> scheduleChargeReminder({
    required DateTime fireAt,
    required String title,
    required String body,
  }) async {
    if (!supportsScheduledNotifications) return;
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id: _chargeReminderId,
      title: title,
      body: body,
      payload: 'charge-reminder',
      scheduledDate: tz.TZDateTime.from(fireAt.toUtc(), tz.UTC),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        macOS: DarwinNotificationDetails(),
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'equipment-checks',
          'Akkus und Geräte prüfen',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  Future<void> cancelChargeReminder() async {
    if (!supportsScheduledNotifications) return;
    await _ensureInitialized();
    await _plugin.cancel(id: _chargeReminderId);
  }

  /// Schedules the reminder to write a backup again (#122). One fixed id,
  /// so a new backup or a new interval replaces the pending one.
  Future<void> scheduleBackupReminder({
    required DateTime fireAt,
    required String title,
    required String body,
  }) async {
    if (!supportsScheduledNotifications) return;
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id: _backupReminderId,
      title: title,
      body: body,
      payload: 'backup-reminder',
      scheduledDate: tz.TZDateTime.from(fireAt.toUtc(), tz.UTC),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        macOS: DarwinNotificationDetails(),
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'backup-reminder',
          'Datensicherung',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  Future<void> cancelBackupReminder() async {
    if (!supportsScheduledNotifications) return;
    await _ensureInitialized();
    await _plugin.cancel(id: _backupReminderId);
  }

  /// Schedules the reminder for the nationwide warning day.
  ///
  /// One fixed id, like the charge check: rescheduling replaces rather
  /// than piles up, and the date is worked out from a rule, so every
  /// launch computes the same instant and writes over its own reminder.
  Future<void> scheduleWarningDayReminder({
    required DateTime fireAt,
    required String title,
    required String body,
  }) async {
    if (!supportsScheduledNotifications) return;
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id: _warningDayId,
      title: title,
      body: body,
      payload: 'warning-day',
      scheduledDate: tz.TZDateTime.from(fireAt.toUtc(), tz.UTC),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: const NotificationDetails(
        macOS: DarwinNotificationDetails(),
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'warning-day',
          'Bundesweiter Warntag',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  Future<void> cancelWarningDayReminder() async {
    if (!supportsScheduledNotifications) return;
    await _ensureInitialized();
    await _plugin.cancel(id: _warningDayId);
  }
}

import 'package:flutter/foundation.dart';

/// Whether this platform can hold a notification until a date.
///
/// Every platform can show one *now* — that is how warnings are
/// announced, and it works everywhere. Scheduling one for next Tuesday is
/// another matter: the freedesktop notification specification has no
/// notion of a notification that arrives later, so the Linux plugin
/// implements neither `zonedSchedule` nor `pendingNotificationRequests`
/// and throws when either is called.
///
/// Expiry reminders therefore do not exist on Linux, and the settings
/// screen says so instead of offering a switch that does nothing.
bool get supportsScheduledNotifications =>
    !kIsWeb && supportsScheduledNotificationsOn(defaultTargetPlatform);

/// Split out so the mapping can be tested; the platform itself cannot be.
bool supportsScheduledNotificationsOn(TargetPlatform platform) =>
    switch (platform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.linux || TargetPlatform.fuchsia => false,
    };

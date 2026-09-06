import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/notification_capabilities.dart';

void main() {
  group('scheduling a notification for later', () {
    test('Linux cannot, and that is not a bug to fix', () {
      // The freedesktop specification has no notion of a notification
      // that arrives later, so the plugin implements neither
      // `zonedSchedule` nor `pendingNotificationRequests` and throws when
      // either is called. Running the app on Linux is what found it.
      expect(supportsScheduledNotificationsOn(TargetPlatform.linux), isFalse);
    });

    test('everywhere else can', () {
      for (final platform in [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      ]) {
        expect(
          supportsScheduledNotificationsOn(platform),
          isTrue,
          reason: '$platform',
        );
      }
    });

    test('every platform is decided one way or the other', () {
      // A switch over the whole enum rather than a default, so a platform
      // added to Flutter breaks the build here instead of quietly being
      // told it can schedule.
      for (final platform in TargetPlatform.values) {
        expect(
          () => supportsScheduledNotificationsOn(platform),
          returnsNormally,
        );
      }
    });
  });
}

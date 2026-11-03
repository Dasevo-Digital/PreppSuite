import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/notification_service.dart';
import 'package:preppsuite_flutter/model/categories.dart';

/// Only the warnings worth waking somebody for may pass a Focus (#101).
void main() {
  test('severe and extreme are time-sensitive', () {
    expect(
      warningInterruptionLevel(WarningSeverity.severe),
      InterruptionLevel.timeSensitive,
    );
    expect(
      warningInterruptionLevel(WarningSeverity.extreme),
      InterruptionLevel.timeSensitive,
    );
  });

  test('everything below stays an ordinary notification', () {
    expect(
      warningInterruptionLevel(WarningSeverity.moderate),
      InterruptionLevel.active,
    );
    expect(
      warningInterruptionLevel(WarningSeverity.minor),
      InterruptionLevel.active,
    );
  });

  group('Android: extreme warnings have a channel of their own (#264)', () {
    test('extreme', () {
      final details = warningAndroidDetails(WarningSeverity.extreme);
      expect(details.channelId, extremeWarningChannel.id);
      expect(details.importance, Importance.max);
      expect(details.visibility, NotificationVisibility.public);
    });

    test('everything else keeps the ordinary one', () {
      for (final severity in [
        WarningSeverity.severe,
        WarningSeverity.moderate,
        WarningSeverity.minor,
      ]) {
        final details = warningAndroidDetails(severity);
        expect(details.channelId, 'warnings', reason: severity.name);
        expect(details.channelId, isNot(extremeWarningChannel.id));
      }
    });
  });
}

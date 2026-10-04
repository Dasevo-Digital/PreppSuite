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
}

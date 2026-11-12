import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/notification_service.dart';
import 'package:preppsuite_flutter/features/home/application/notification_target.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';

/// Every payload the app posts leads somewhere (#382); until then a tap
/// only opened the app.
void main() {
  test('each reminder leads to its page', () {
    expect(
      notificationTargetFor(NotificationService.backupReminderPayload),
      const NotificationBackup(),
    );
    expect(
      notificationTargetFor(NotificationService.chargeReminderPayload),
      const NotificationTab(ShellDestination.overview),
    );
    expect(
      notificationTargetFor(NotificationService.warningDayPayload),
      const NotificationTab(ShellDestination.warnings),
    );
    expect(
      notificationTargetFor('${NotificationService.warningPayloadPrefix}mow.1'),
      const NotificationTab(ShellDestination.warnings),
    );
    expect(
      notificationTargetFor('${NotificationService.documentPayloadPrefix}d1'),
      const NotificationDocuments(),
    );
    for (final prefix in [
      NotificationService.expiryPayloadPrefix,
      NotificationService.refillPayloadPrefix,
      NotificationService.deviceChargePayloadPrefix,
    ]) {
      expect(
        notificationTargetFor('${prefix}rice'),
        const NotificationItem('rice'),
        reason: prefix,
      );
    }
  });

  test('a payload this version does not know only opens the app', () {
    expect(notificationTargetFor('something-new'), isNull);
    expect(
      notificationTargetFor(NotificationService.expiryPayloadPrefix),
      isNull,
    );
    expect(notificationTargetFor(''), isNull);
  });
}

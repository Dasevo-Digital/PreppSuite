/// Where a tapped notification leads (#382).
///
/// Every notification the app posts carries a payload, which until #382
/// served only to find its own pending reminders again and cancel them. A
/// tap opened the app and nothing more: "time for a backup" left the
/// person on the overview, looking for where backups are made. The same
/// payloads now say where to go.
library;

import '../../../core/notification_service.dart';
import 'shell_layout.dart';

sealed class NotificationTarget {
  const NotificationTarget();
}

/// A tab of the app: the warnings, the overview.
final class NotificationTab extends NotificationTarget {
  const NotificationTab(this.destination);

  final ShellDestination destination;

  @override
  bool operator ==(Object other) =>
      other is NotificationTab && other.destination == destination;

  @override
  int get hashCode => destination.hashCode;
}

/// One item of the stock: what expires, what needs a new prescription,
/// the device whose battery is due.
final class NotificationItem extends NotificationTarget {
  const NotificationItem(this.clientId);

  final String clientId;

  @override
  bool operator ==(Object other) =>
      other is NotificationItem && other.clientId == clientId;

  @override
  int get hashCode => clientId.hashCode;
}

/// Where the backup is made.
final class NotificationBackup extends NotificationTarget {
  const NotificationBackup();

  @override
  bool operator ==(Object other) => other is NotificationBackup;

  @override
  int get hashCode => 0;
}

/// The personal documents, where a deadline belongs.
final class NotificationDocuments extends NotificationTarget {
  const NotificationDocuments();

  @override
  bool operator ==(Object other) => other is NotificationDocuments;

  @override
  int get hashCode => 1;
}

/// The page [payload] belongs to, or null for one this version does not
/// know -- a reminder scheduled by a later version, say -- which then only
/// opens the app, as before.
NotificationTarget? notificationTargetFor(String payload) {
  String? after(String prefix) {
    if (!payload.startsWith(prefix)) return null;
    final rest = payload.substring(prefix.length);
    return rest.isEmpty ? null : rest;
  }

  if (payload == NotificationService.backupReminderPayload) {
    return const NotificationBackup();
  }
  // The household's check of everything rechargeable: the overview is where
  // it is confirmed.
  if (payload == NotificationService.chargeReminderPayload) {
    return const NotificationTab(ShellDestination.overview);
  }
  if (payload == NotificationService.warningDayPayload ||
      payload.startsWith(NotificationService.warningPayloadPrefix)) {
    return const NotificationTab(ShellDestination.warnings);
  }
  if (payload.startsWith(NotificationService.documentPayloadPrefix)) {
    return const NotificationDocuments();
  }
  for (final prefix in const [
    NotificationService.expiryPayloadPrefix,
    NotificationService.refillPayloadPrefix,
    NotificationService.deviceChargePayloadPrefix,
  ]) {
    if (after(prefix) case final clientId?) return NotificationItem(clientId);
  }
  return null;
}

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notification_service.dart';
import '../../../core/notifications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/backup_reminder.dart';

/// Keeps one reminder to write a backup pending (#122). Draws nothing.
///
/// Counted from the last backup, like the equipment check: a reminder
/// counted from now would restart every time somebody opened the app.
class BackupReminderScheduler extends ConsumerStatefulWidget {
  const BackupReminderScheduler({super.key});

  @override
  ConsumerState<BackupReminderScheduler> createState() =>
      _BackupReminderSchedulerState();
}

class _BackupReminderSchedulerState
    extends ConsumerState<BackupReminderScheduler> {
  Future<void> _schedule() async {
    if (!mounted) return;
    final status = ref.read(backupStatusProvider);
    if (!ref.read(notificationsEnabledProvider)) return;
    final due = status.dueAt();
    if (due == null) {
      await NotificationService.instance.cancelBackupReminder();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    await NotificationService.instance.scheduleBackupReminder(
      // Overdue means tomorrow morning, not never -- a notification for a
      // moment that has passed does not arrive. The same goes for a
      // device that has never written one: it is asked tomorrow, not at
      // the second it starts.
      fireAt: due.isAfter(now)
          ? due
          : DateTime(now.year, now.month, now.day + 1, 10),
      title: l10n.backupReminderTitle,
      body: status.lastBackup == null
          ? l10n.backupReminderBodyNever
          : l10n.backupReminderBody(
              DateFormat.yMMMd(
                l10n.localeName,
              ).format(status.lastBackup!.toLocal()),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(backupStatusProvider, (_, _) => unawaited(_schedule()));
    ref.listen(notificationsEnabledProvider, (previous, next) {
      if (next) {
        unawaited(_schedule());
      } else if (previous == true) {
        unawaited(NotificationService.instance.cancelBackupReminder());
      }
    });
    return const SizedBox.shrink();
  }
}

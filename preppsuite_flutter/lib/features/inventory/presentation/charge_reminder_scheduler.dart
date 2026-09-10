import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notification_service.dart';
import '../../../core/notifications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/charge_reminder_provider.dart';

/// Keeps one periodic check-in for rechargeable emergency equipment pending.
class ChargeReminderScheduler extends ConsumerStatefulWidget {
  const ChargeReminderScheduler({super.key});

  @override
  ConsumerState<ChargeReminderScheduler> createState() =>
      _ChargeReminderSchedulerState();
}

class _ChargeReminderSchedulerState
    extends ConsumerState<ChargeReminderScheduler> {
  Future<void> _schedule() async {
    if (!mounted) return;
    final days = ref.read(chargeReminderDaysProvider);
    if (!ref.read(notificationsEnabledProvider)) return;
    if (days == 0) {
      await NotificationService.instance.cancelChargeReminder();
      return;
    }
    // Counted from the last confirmed check rather than from now.
    // Measured from now, the interval restarted whenever the setting was
    // touched, and the reminder arrived on time whether or not anybody had
    // been near the equipment. Nothing recorded means "start counting
    // today", which is what a fresh install wants.
    final from =
        ref.read(chargeCheckProvider).lastChecked?.toLocal() ?? DateTime.now();
    final fireAt = _atTen(
      DateTime(from.year, from.month, from.day + days),
    );
    final l10n = AppLocalizations.of(context)!;
    await NotificationService.instance.scheduleChargeReminder(
      // A check confirmed long ago puts the due date in the past, and a
      // notification scheduled for a date that has gone by simply never
      // arrives. Overdue means tomorrow morning, not never.
      fireAt: fireAt.isAfter(DateTime.now()) ? fireAt : _tomorrowAtTen(),
      title: l10n.chargeReminderTitle,
      body: l10n.chargeReminderBody,
    );
  }

  static DateTime _atTen(DateTime day) =>
      DateTime(day.year, day.month, day.day, 10);

  static DateTime _tomorrowAtTen() {
    final now = DateTime.now();
    return _atTen(DateTime(now.year, now.month, now.day + 1));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chargeReminderDaysProvider, (_, _) => unawaited(_schedule()));
    // Confirming a check moves the next reminder along with it.
    ref.listen(chargeCheckProvider, (_, _) => unawaited(_schedule()));
    ref.listen(notificationsEnabledProvider, (previous, next) {
      if (next) {
        unawaited(_schedule());
      } else if (previous == true) {
        unawaited(NotificationService.instance.cancelChargeReminder());
      }
    });
    return const SizedBox.shrink();
  }
}

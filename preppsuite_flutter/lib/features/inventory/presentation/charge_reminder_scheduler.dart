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
    final now = DateTime.now();
    final fireAt = DateTime(now.year, now.month, now.day + days, 10);
    final l10n = AppLocalizations.of(context)!;
    await NotificationService.instance.scheduleChargeReminder(
      fireAt: fireAt,
      title: l10n.chargeReminderTitle,
      body: l10n.chargeReminderBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chargeReminderDaysProvider, (_, _) => unawaited(_schedule()));
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

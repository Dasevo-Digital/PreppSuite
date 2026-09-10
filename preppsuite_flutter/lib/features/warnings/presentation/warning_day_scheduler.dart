import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notification_service.dart';
import '../../../core/notifications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/warning_day.dart';

/// Keeps the reminder for the next nationwide warning day pending.
///
/// Unlike the other schedulers here there is nothing to listen to: the
/// date follows a rule and no setting moves it. So this schedules once on
/// mount and then only reacts to notifications being switched on or off.
class WarningDayScheduler extends ConsumerStatefulWidget {
  const WarningDayScheduler({super.key});

  @override
  ConsumerState<WarningDayScheduler> createState() =>
      _WarningDaySchedulerState();
}

class _WarningDaySchedulerState extends ConsumerState<WarningDayScheduler> {
  @override
  void initState() {
    super.initState();
    // After the first frame, because the texts come from the localisations
    // and those need a context that is in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_schedule()));
  }

  Future<void> _schedule() async {
    if (!mounted) return;
    if (!ref.read(notificationsEnabledProvider)) return;

    // Nine in the morning: the test warning goes out at eleven, and a
    // reminder that arrives after it has been and gone is worse than
    // none — it reads as an announcement and is a post-mortem.
    final day = nextFederalWarningDay();
    final fireAt = DateTime(day.year, day.month, day.day, 9);
    if (!fireAt.isAfter(DateTime.now())) {
      // Today, but past nine already. Nothing to schedule: the day is
      // running, and the notice in the warning list is what carries it.
      // Deliberately not pushed to next year here — the next launch
      // works the date out again and will land on it.
      await NotificationService.instance.cancelWarningDayReminder();
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    await NotificationService.instance.scheduleWarningDayReminder(
      fireAt: fireAt,
      title: l10n.warningDayNotificationTitle,
      body: l10n.warningDayNotificationBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationsEnabledProvider, (previous, next) {
      if (next) {
        unawaited(_schedule());
      } else if (previous == true) {
        unawaited(NotificationService.instance.cancelWarningDayReminder());
      }
    });
    return const SizedBox.shrink();
  }
}

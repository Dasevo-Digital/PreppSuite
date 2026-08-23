import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notification_service.dart';
import '../../../core/notifications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/expiry_reminder_planner.dart';
import '../application/expiry_reminder_provider.dart';
import '../application/inventory_providers.dart';

/// Invisible widget that keeps the scheduled expiry reminders in step with
/// the inventory and the user's settings.
///
/// It is a widget rather than a provider because the notification text is
/// localized, and [AppLocalizations] hangs off a [BuildContext]. Sitting in
/// [HomeShell] above the tabs means it stays mounted for the whole session,
/// so a change on any tab reschedules.
class ExpiryReminderScheduler extends ConsumerStatefulWidget {
  const ExpiryReminderScheduler({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<ExpiryReminderScheduler> createState() =>
      _ExpiryReminderSchedulerState();
}

class _ExpiryReminderSchedulerState
    extends ConsumerState<ExpiryReminderScheduler> {
  Timer? _debounce;

  /// Coalesces bursts of writes — a CSV import commits as one batch but
  /// still lands as several stream emissions — into a single reschedule,
  /// which is a platform call per reminder.
  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleReschedule() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _reschedule);
  }

  Future<void> _reschedule() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.read(notificationsEnabledProvider);
    final leadDays = ref.read(expiryLeadDaysProvider);
    final items =
        ref.read(inventoryItemsProvider(widget.householdId)).value ?? const [];

    // Switching notifications off, or clearing every lead time, has to
    // clear what is already pending — otherwise reminders scheduled
    // earlier would keep firing after the user opted out.
    if (!enabled || leadDays.isEmpty) {
      await NotificationService.instance.cancelExpiryReminders();
      return;
    }

    final reminders = planExpiryReminders(
      items: items,
      now: DateTime.now(),
      leadDays: leadDays,
    );

    await NotificationService.instance.scheduleExpiryReminders(
      reminders,
      title: (_) => l10n.expiryReminderTitle,
      body: (reminder) => reminder.leadDays == 1
          ? l10n.expiryReminderBodyTomorrow(reminder.itemName)
          : l10n.expiryReminderBody(reminder.itemName, reminder.leadDays),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(inventoryItemsProvider(widget.householdId), (_, next) {
      // Only once the stream actually has data; the initial loading state
      // would otherwise clear all reminders on every cold start.
      if (next.hasValue) _scheduleReschedule();
    });
    ref.listen(expiryLeadDaysProvider, (_, _) => _scheduleReschedule());
    ref.listen(notificationsEnabledProvider, (_, _) => _scheduleReschedule());

    return const SizedBox.shrink();
  }
}

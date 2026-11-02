import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/notification_service.dart';
import '../../../core/notifications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/expiry_reminder_planner.dart';
import '../application/expiry_reminder_provider.dart';
import '../application/inventory_providers.dart';
import '../application/device_charge.dart';
import '../application/refill_reminder_planner.dart';
import '../../knowledge/application/document_deadline.dart';
import '../../knowledge/application/personal_document_provider.dart';

/// Invisible widget that keeps the scheduled expiry reminders -- and the
/// prescription reminders beside them (#150) -- in step with the
/// inventory and the user's settings.
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
    extends ConsumerState<ExpiryReminderScheduler>
    with WidgetsBindingObserver {
  Timer? _debounce;
  bool _running = false;
  bool _again = false;

  /// What this run last left pending, null when that is not known.
  List<_Pending>? _scheduled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleReschedule();
  }

  /// Coalesces bursts of writes — a CSV import commits as one batch but
  /// still lands as several stream emissions — into a single reschedule,
  /// which is a platform call per reminder.
  static const _debounceDuration = Duration(milliseconds: 500);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleReschedule() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, _reschedule);
  }

  Future<void> _reschedule() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        await _rescheduleOnce();
      } while (_again && mounted);
    } finally {
      _running = false;
    }
  }

  Future<void> _rescheduleOnce() async {
    if (!mounted) return;
    await ref.read(notificationsEnabledProvider.notifier).ensureLoaded();
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.read(notificationsEnabledProvider);
    final leadDays = ref.read(expiryLeadDaysProvider);
    final items =
        ref.read(inventoryItemsProvider(widget.householdId)).value ?? const [];

    // Switching notifications off has to clear what is already pending —
    // otherwise reminders scheduled earlier would keep firing after the
    // user opted out.
    //
    // An empty household list is deliberately **not** shortcut here any
    // more. Since an item may carry its own lead times, "the household
    // picked none" no longer means "nobody gets one", and a shortcut
    // would silently swallow every per-item reminder. Planning with an
    // empty default simply yields nothing for the items that follow it,
    // and scheduling an empty list is itself a full cancel.
    if (!enabled) {
      _scheduled = null;
      await NotificationService.instance.cancelReminders();
      return;
    }

    if (!ref.read(inventoryItemsProvider(widget.householdId)).hasValue ||
        !ref.read(personalDocumentsProvider).hasValue) {
      return;
    }

    final now = DateTime.now();

    // Planned first, and taken out of the expiry reminders' share of the
    // 64 notifications iOS keeps: a household with a few medicines in
    // daily use has a few of these, and each one matters more than the
    // sixtieth jar of jam.
    final refills = planRefillReminders(
      items: items,
      now: now,
    ).take(maxScheduledExpiryReminders).toList();
    String refillBody(RefillReminder reminder) => l10n.refillReminderBody(
      reminder.itemName,
      DateFormat.yMMMd(l10n.localeName).format(reminder.runsOutOn),
    );

    // Then the devices whose battery is due (#179), from the same share
    // and for the same reason: a radio that will not switch on in the
    // dark is worth more than the sixtieth jar of jam.
    final charges = planDeviceChargeReminders(
      items: items,
      now: now,
    ).take(maxScheduledExpiryReminders - refills.length).toList();
    String chargeBody(DeviceChargeReminder reminder) =>
        l10n.deviceChargeReminderBody(reminder.itemName);

    final documents = planDocumentReminders(
      ref.read(personalDocumentsProvider).value ?? const [],
      now: now,
      limit: maxScheduledExpiryReminders - refills.length - charges.length,
    );

    final reminders = planExpiryReminders(
      items: items,
      now: now,
      leadDays: leadDays,
      limit:
          maxScheduledExpiryReminders -
          refills.length -
          charges.length -
          documents.length,
    );
    String expiryBody(ExpiryReminder reminder) => reminder.leadDays == 1
        ? l10n.expiryReminderBodyTomorrow(reminder.itemName)
        : l10n.expiryReminderBody(reminder.itemName, reminder.leadDays);

    // What is pending already, said the same way, schedules nothing
    // (#252). Every change to the inventory -- a count, a note, a sync
    // bringing rows -- and every return to the app used to cancel and
    // schedule all of it again: up to 64 cancellations and 60 schedules,
    // each of which Android's plugin answers by rewriting its whole list.
    final plan = <_Pending>[
      for (final r in refills)
        (
          id: r.id,
          at: r.fireAt,
          title: l10n.refillReminderTitle,
          body: refillBody(r),
        ),
      for (final r in charges)
        (
          id: r.id,
          at: r.fireAt,
          title: l10n.deviceChargeReminderTitle,
          body: chargeBody(r),
        ),
      for (final r in documents)
        (
          id: r.id,
          at: r.fireAt,
          title: l10n.documentReminderTitle,
          body: l10n.documentReminderBody,
        ),
      for (final r in reminders)
        (
          id: r.id,
          at: r.fireAt,
          title: l10n.expiryReminderTitle,
          body: expiryBody(r),
        ),
    ];
    if (listEquals(plan, _scheduled)) return;
    _scheduled = null;

    // Clear the old allocation before adding any category. Otherwise a
    // new refill can briefly exceed iOS's limit while yesterday's 60
    // expiry reminders still occupy their slots and be silently dropped.
    await NotificationService.instance.cancelReminders();
    await NotificationService.instance.scheduleRefillReminders(
      refills,
      title: l10n.refillReminderTitle,
      body: refillBody,
      replace: false,
    );
    await NotificationService.instance.scheduleDeviceChargeReminders(
      charges,
      title: l10n.deviceChargeReminderTitle,
      body: chargeBody,
      replace: false,
    );
    await NotificationService.instance.scheduleDocumentReminders(
      documents,
      title: l10n.documentReminderTitle,
      body: l10n.documentReminderBody,
      replace: false,
    );
    await NotificationService.instance.scheduleExpiryReminders(
      reminders,
      title: (_) => l10n.expiryReminderTitle,
      body: expiryBody,
      replace: false,
    );
    _scheduled = plan;
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
    ref.listen(personalDocumentsProvider, (previous, next) {
      if (!next.hasValue) return;
      if (previous?.value case final before?
          when listEquals(
            documentReminderInputs(before),
            documentReminderInputs(next.requireValue),
          )) {
        return;
      }
      _scheduleReschedule();
    });

    return const SizedBox.shrink();
  }
}

/// One pending reminder as the system holds it: what tells a plan that
/// needs scheduling from one that is already there.
typedef _Pending = ({int id, DateTime at, String title, String body});

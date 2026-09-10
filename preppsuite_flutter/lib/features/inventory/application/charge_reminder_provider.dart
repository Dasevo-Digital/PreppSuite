import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chargeReminderDaysPrefsKey = 'chargeReminderDays';

/// The intervals offered as chips. Zero is a conscious opt-out, not a
/// missing preference.
///
/// Fourteen days is here because a power bank left in a drawer loses
/// charge faster than the older intervals assumed, and somebody who checks
/// their equipment fortnightly should not have to pick "monthly" and
/// remember the difference.
const selectableChargeReminderDays = [0, 14, 30, 60, 90, 180];
const defaultChargeReminderDays = 90;

/// What a freely chosen interval may be.
///
/// The chips are suggestions, not the whole range: whoever wants 21 days
/// or a year should be able to say so. Bounded all the same — zero already
/// means off, and a reminder further out than a year is one nobody is
/// waiting for. This replaced a whitelist, which had the effect that a
/// custom value was accepted for the session and then silently reset to
/// 90 on the next launch, because loading discarded anything not in the
/// list.
const minimumChargeReminderDays = 1;
const maximumChargeReminderDays = 365;

/// Whether [days] is something this setting can hold at all.
bool isChargeReminderDays(int days) =>
    days == 0 ||
    (days >= minimumChargeReminderDays && days <= maximumChargeReminderDays);

class ChargeReminderDaysController extends Notifier<int> {
  @override
  int build() {
    unawaited(_load());
    return defaultChargeReminderDays;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_chargeReminderDaysPrefsKey);
    if (!ref.mounted || stored == null) return;
    state = isChargeReminderDays(stored) ? stored : defaultChargeReminderDays;
  }

  Future<void> setDays(int days) async {
    if (!isChargeReminderDays(days)) return;
    state = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chargeReminderDaysPrefsKey, days);
  }
}

final chargeReminderDaysProvider =
    NotifierProvider<ChargeReminderDaysController, int>(
      ChargeReminderDaysController.new,
    );

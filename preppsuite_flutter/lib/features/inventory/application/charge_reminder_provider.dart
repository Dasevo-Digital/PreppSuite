import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chargeReminderDaysPrefsKey = 'chargeReminderDays';

/// Intervals for checking power banks, rechargeable batteries and the
/// emergency radio. Zero is a conscious opt-out, not a missing preference.
const selectableChargeReminderDays = [0, 30, 60, 90, 180];
const defaultChargeReminderDays = 90;

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
    state = selectableChargeReminderDays.contains(stored)
        ? stored
        : defaultChargeReminderDays;
  }

  Future<void> setDays(int days) async {
    if (!selectableChargeReminderDays.contains(days)) return;
    state = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_chargeReminderDaysPrefsKey, days);
  }
}

final chargeReminderDaysProvider =
    NotifierProvider<ChargeReminderDaysController, int>(
      ChargeReminderDaysController.new,
    );

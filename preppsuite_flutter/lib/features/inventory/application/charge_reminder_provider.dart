import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chargeReminderDaysPrefsKey = 'chargeReminderDays';
const _chargeReminderCheckedPrefsKey = 'chargeReminderLastChecked';

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

/// When the rechargeable equipment was last confirmed as checked, and
/// whether that is overdue.
///
/// The reminder used to be a blind timer: it fired every so many days from
/// whenever the setting was last touched, and nothing recorded whether
/// anybody had actually gone and looked. So there was no such thing as
/// "overdue" — only a notification that arrived and was dismissed, which
/// is the same screen whether the power banks are full or flat.
class ChargeCheck {
  const ChargeCheck({required this.lastChecked, required this.everyDays});

  /// Null when nobody has confirmed a check yet, which is the state a
  /// fresh install is in and is not the same as being overdue.
  final DateTime? lastChecked;

  /// Zero means the reminder is switched off, and then nothing is due.
  final int everyDays;

  bool get isOff => everyDays == 0;

  /// Calendar days, not blocks of 24 hours. `add(Duration(days: 90))`
  /// across the end of summer time lands an hour short -- 23:00 on the
  /// day before -- and [daysUntilDue], which counts from midnight, then
  /// called the check due a day early. Found by the calendar export's
  /// test (#102).
  DateTime? get dueAt {
    if (isOff) return null;
    final from = lastChecked;
    if (from == null) return null;
    // In the zone the check was recorded in: a UTC stamp stays UTC.
    final make = from.isUtc ? DateTime.utc : DateTime.new;
    return make(
      from.year,
      from.month,
      from.day + everyDays,
      from.hour,
      from.minute,
      from.second,
    );
  }

  /// Days until the next check, negative once it has passed.
  int? daysUntilDue({DateTime? now}) {
    final due = dueAt;
    if (due == null) return null;
    final today = _midnight(now ?? DateTime.now());
    return _midnight(due).difference(today).inDays;
  }

  /// True once the interval has elapsed. False while it has not, and false
  /// when nobody ever confirmed a check — an install that has never been
  /// through this is not behind on it.
  bool isDue({DateTime? now}) {
    final days = daysUntilDue(now: now);
    return days != null && days <= 0;
  }

  static DateTime _midnight(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class ChargeCheckController extends Notifier<ChargeCheck> {
  /// Kept beside the state, not read out of it: `build` runs again every
  /// time the interval changes, and reading `state` there would either
  /// throw on the first run or drop the loaded date on every later one.
  DateTime? _lastChecked;

  @override
  ChargeCheck build() {
    // Watched, so changing the interval moves the due date with it rather
    // than leaving one computed against the old interval.
    final days = ref.watch(chargeReminderDaysProvider);
    unawaited(_load());
    return ChargeCheck(lastChecked: _lastChecked, everyDays: days);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_chargeReminderCheckedPrefsKey);
    if (!ref.mounted) return;
    _lastChecked = stored == null ? null : DateTime.tryParse(stored);
    state = ChargeCheck(
      lastChecked: _lastChecked,
      everyDays: state.everyDays,
    );
  }

  /// Records that somebody has just been through the equipment.
  Future<void> markChecked({DateTime? at}) async {
    _lastChecked = (at ?? DateTime.now()).toUtc();
    state = ChargeCheck(
      lastChecked: _lastChecked,
      everyDays: state.everyDays,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chargeReminderCheckedPrefsKey,
      _lastChecked!.toIso8601String(),
    );
  }
}

final chargeCheckProvider =
    NotifierProvider<ChargeCheckController, ChargeCheck>(
      ChargeCheckController.new,
    );

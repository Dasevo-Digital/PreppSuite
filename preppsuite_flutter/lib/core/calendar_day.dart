import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Today, at local midnight, and a new value when the day changes (#262).
///
/// What expires, what is due and how many days a medicine has left are
/// all counted from today, and they were counted when a screen was
/// built. A screen is built again when its rows change, not when the day
/// does: on a desktop left open overnight, or a telephone picked up the
/// next morning, a tin that ran out at midnight stood under "soon" and a
/// pack in daily use kept yesterday's count of days until something was
/// edited. A screen whose figures depend on the date watches this; it
/// changes at midnight and, because a sleeping device fires no timer,
/// is checked again whenever the app comes back to the front.
///
/// Where only the date matters the value is passed on as "now"; where
/// the hour does -- a reminder still to come today -- the screen reads
/// the clock itself and takes this as the moment to do it again.
final calendarDayProvider = NotifierProvider<CalendarDay, DateTime>(
  CalendarDay.new,
);

class CalendarDay extends Notifier<DateTime> {
  /// The clock, for a test to wind on.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  Timer? _midnight;

  @override
  DateTime build() {
    AppLifecycleListener? lifecycle;
    try {
      lifecycle = AppLifecycleListener(onResume: refresh);
    } on Object {
      // No binding, as in a plain unit test: midnight alone then.
    }
    ref.onDispose(() {
      _midnight?.cancel();
      lifecycle?.dispose();
    });
    _schedule();
    return _today();
  }

  /// Looks at the clock again, and moves on if the day has.
  void refresh() {
    final today = _today();
    if (today != state) state = today;
    _schedule();
  }

  DateTime _today() {
    final at = now();
    return DateTime(at.year, at.month, at.day);
  }

  void _schedule() {
    _midnight?.cancel();
    final at = now();
    // Midnight by the calendar, not 24 hours on: across a change of
    // summer time a day has 23 or 25 of them.
    final next = DateTime(at.year, at.month, at.day + 1);
    _midnight = Timer(
      next.difference(at) + const Duration(seconds: 1),
      refresh,
    );
  }
}

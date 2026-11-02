import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';

export '../../../core/app_database_providers.dart';

/// Warnings in force now -- the banner, the badge, the overview, the
/// lamps, the home screen widget.
///
/// The query alone cannot say "now": it binds the moment it was built,
/// and drift runs it again with that moment on every change. The banner
/// keeps this provider for the whole run, so a warning that ended after
/// the app started -- a BBK warning the poll retired, a MeteoAlarm one
/// past its end -- stayed on every one of those screens until the next
/// start (#248). [warningsInForce] measures against the clock instead,
/// and again when the next one ends.
final activeWarningsProvider = StreamProvider.autoDispose<List<Warning>>(
  (ref) =>
      warningsInForce(ref.watch(appDatabaseProvider).watchActiveWarnings()),
);

/// [rows] without what has ended by [clock], again whenever [rows] changes
/// and again the moment the next warning in it ends.
Stream<List<Warning>> warningsInForce(
  Stream<List<Warning>> rows, {
  DateTime Function() clock = DateTime.now,
}) {
  late final StreamController<List<Warning>> out;
  StreamSubscription<List<Warning>>? subscription;
  Timer? nextEnd;
  var latest = const <Warning>[];

  void emit() {
    nextEnd?.cancel();
    final now = clock();
    final inForce = [
      for (final warning in latest)
        if (warning.expires == null || warning.expires!.isAfter(now)) warning,
    ];
    if (!out.isClosed) out.add(inForce);
    DateTime? soonest;
    for (final warning in inForce) {
      final ends = warning.expires;
      if (ends != null && (soonest == null || ends.isBefore(soonest))) {
        soonest = ends;
      }
    }
    if (soonest != null) {
      // A beat past the end, so the clock has passed it when this runs.
      nextEnd = Timer(
        soonest.difference(now) + const Duration(seconds: 1),
        emit,
      );
    }
  }

  out = StreamController<List<Warning>>(
    onListen: () {
      subscription = rows.listen((value) {
        latest = value;
        emit();
      }, onError: out.addError);
    },
    onCancel: () async {
      nextEnd?.cancel();
      await subscription?.cancel();
    },
  );
  return out.stream;
}

/// Full history, including expired warnings — the dedicated warnings screen.
final allWarningsProvider = StreamProvider.autoDispose<List<Warning>>(
  (ref) => ref.watch(appDatabaseProvider).watchAllWarnings(),
);

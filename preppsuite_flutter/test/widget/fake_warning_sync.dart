import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_sync_controller.dart';

/// A warning sync that never touches the network or a database.
///
/// The warnings screen keeps the real controller alive and calls it from
/// its refresh button; a widget test has no network, and the real one
/// would open the database at its default place unless something
/// overrides it. [result] is what a manual fetch reports, null standing
/// for a run that failed with [error].
class FakeWarningSync extends WarningSyncController {
  FakeWarningSync(
    super.profile, {
    this.result = const WarningPollResult(
      fetched: 0,
      newsworthy: [],
      retired: 0,
      complete: true,
    ),
    this.error,
  });

  final WarningPollResult? result;
  final Object? error;
  var calls = 0;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<WarningPollResult?> syncNow() async {
    calls++;
    final failure = error;
    state = result == null && failure != null
        ? AsyncError(failure, StackTrace.empty)
        : const AsyncData(null);
    return result;
  }
}

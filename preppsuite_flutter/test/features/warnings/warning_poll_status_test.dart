import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_status_store.dart';

/// Which feed decides "current", and what counts as one feed lagging (#92).
void main() {
  final attempt = DateTime.utc(2026, 10, 3, 8);
  final older = DateTime.utc(2026, 9, 20, 8);

  test('Germany is current when the BBK is', () {
    final status = WarningPollStatus(
      lastAttempt: attempt,
      lastComplete: older,
      sourceComplete: {'bbk': attempt, 'meteoalarm': older},
    );

    expect(status.currentAt('DE'), attempt);
    expect(status.lagging('DE'), ['meteoalarm']);
  });

  test('elsewhere MeteoAlarm is the feed, and the BBK is never missed', () {
    final status = WarningPollStatus(
      lastAttempt: attempt,
      sourceComplete: {'meteoalarm': attempt},
    );

    expect(status.currentAt('AT'), attempt);
    expect(status.lagging('AT'), isEmpty);
  });

  test('before the first per-feed poll the old total is used', () {
    final status = WarningPollStatus(lastAttempt: attempt, lastComplete: older);

    expect(status.currentAt('DE'), older);
    expect(status.lagging('DE'), isEmpty);
  });

  test('a block is overtaken by a BBK refresh, MeteoAlarm or not', () {
    final status = WarningPollStatus(
      lastAttempt: attempt,
      lastComplete: older,
      lastBlocked: DateTime.utc(2026, 10, 1),
      sourceComplete: {'bbk': attempt},
    );

    expect(status.isBlocked, isFalse);
  });
}

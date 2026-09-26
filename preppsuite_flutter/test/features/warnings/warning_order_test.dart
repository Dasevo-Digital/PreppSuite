import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_order.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// What the warning list puts at the top.
///
/// The case this file exists for came off a telephone: the device had one
/// warning in force, and the first four entries on the screen were all
/// expired ones. Nothing had crashed and nothing overflowed — the sort
/// simply had no opinion about whether a warning was still running, so a
/// severe warning that was over outranked a mild one that was not.
void main() {
  final now = DateTime.utc(2026, 9, 26, 10);
  const home = '03459';
  const elsewhere = '09162';

  final filter = WarningRegionFilter(countryCode: 'DE', ownRegionKey: home);

  Warning warning({
    required String id,
    String severity = 'moderate',
    String? region = home,
    DateTime? expires,
    DateTime? sent,
  }) => Warning(
    source: 'bbk',
    externalId: id,
    countryCode: 'DE',
    regionKey: region,
    severity: severity,
    eventType: 'Warnung',
    headline: id,
    effective: now.subtract(const Duration(days: 1)),
    expires: expires,
    sent: sent ?? now.subtract(const Duration(days: 1)),
    updatedAt: now,
    notified: false,
  );

  List<String> order(List<Warning> warnings) =>
      ([...warnings]..sort(
            (a, b) => compareWarningsForList(a, b, filter: filter, now: now),
          ))
          .map((warning) => warning.externalId)
          .toList();

  final running = warning(id: 'laeuft', severity: 'minor');
  final over = warning(
    id: 'vorbei',
    severity: 'severe',
    expires: now.subtract(const Duration(hours: 2)),
  );

  test('what is running comes before what is over', () {
    // Exactly the pair from the telephone: mild and in force against
    // severe and finished.
    expect(order([over, running]), ['laeuft', 'vorbei']);
  });

  test('even when the expired one is newer', () {
    final freshlyOver = warning(
      id: 'gerade-vorbei',
      severity: 'severe',
      sent: now.subtract(const Duration(minutes: 5)),
      expires: now.subtract(const Duration(minutes: 1)),
    );
    expect(order([freshlyOver, running]), ['laeuft', 'gerade-vorbei']);
  });

  test('a warning without an end has not ended', () {
    // A civil-protection alert that names no end is running, which is
    // the safe reading.
    expect(order([over, warning(id: 'ohne-ende')]), ['ohne-ende', 'vorbei']);
  });

  test('and it comes before the region, not after it', () {
    // This was the other way round, and a telephone showed what that
    // cost: „Amtliche WARNUNG vor STURMBÖEN · Abgelaufen" stood above a
    // warning that was in force, because the expired one named the
    // device's own district. Being nearby does not make something that
    // is over current again.
    final farAway = warning(
      id: 'weit-weg',
      severity: 'minor',
      region: elsewhere,
    );
    expect(order([over, farAway]), ['weit-weg', 'vorbei']);
  });

  test('and the region decides among the ones that are running', () {
    final here = warning(id: 'hier', severity: 'minor');
    final farAway = warning(
      id: 'weit-weg',
      severity: 'severe',
      region: elsewhere,
    );
    expect(order([farAway, here]), ['hier', 'weit-weg']);
  });

  test('and among the ones that are over', () {
    final overElsewhere = warning(
      id: 'vorbei-woanders',
      severity: 'severe',
      region: elsewhere,
      expires: now.subtract(const Duration(hours: 2)),
    );
    expect(order([overElsewhere, over]), ['vorbei', 'vorbei-woanders']);
  });

  test('a warning that names no region outranks a foreign one', () {
    // It concerns everybody, this household included. It used to share a
    // rank with "meant for somebody else" and sorted as if it were.
    final everyone = warning(id: 'alle', severity: 'minor', region: null);
    final farAway = warning(
      id: 'weit-weg',
      severity: 'severe',
      region: elsewhere,
    );
    expect(order([farAway, everyone]), ['alle', 'weit-weg']);
  });

  test('severity and recency still break ties among equals', () {
    final mild = warning(id: 'leicht', severity: 'minor');
    final bad = warning(id: 'schwer', severity: 'severe');
    expect(order([mild, bad]), ['schwer', 'leicht']);

    final older = warning(
      id: 'aelter',
      sent: now.subtract(const Duration(days: 2)),
    );
    final newer = warning(
      id: 'neuer',
      sent: now.subtract(const Duration(hours: 1)),
    );
    expect(order([older, newer]), ['neuer', 'aelter']);
  });

  test('the moment of expiry is not yet expired', () {
    final atTheDot = warning(id: 'punktgenau', expires: now);
    expect(order([warning(id: 'anderes', severity: 'minor'), atTheDot]), [
      'punktgenau',
      'anderes',
    ]);
  });
}

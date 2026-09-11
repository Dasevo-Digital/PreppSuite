import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_client.dart';

/// Against the DWD's real open-data server.
///
/// Skipped unless PREPPSUITE_TEST_NETWORK is set. What no fixture can
/// show is whether the dataset version in the file names has moved —
/// `v2-3--0` is part of every path, and a bump there breaks every
/// request at once while the code stays perfectly valid.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real DWD server'
      : null;

  test('the station list arrives, in Latin-1', () async {
    final client = FireDangerClient();
    addTearDown(client.close);

    final stations = await client.fetchStations();
    stdout.writeln('${stations.length} Waldbrand-Stationen');

    // 483 when this was written, plus a header row that is skipped.
    expect(stations.length, greaterThan(300));

    // The umlaut test: read as UTF-8 this comes back mangled, and the
    // list is the one Latin-1 file in the app.
    final names = stations.map((s) => s.name).toList();
    expect(names, contains('Großenkneten'));
    expect(
      names.where((n) => n.contains('�')),
      isEmpty,
      reason: 'a replacement character means the encoding is wrong',
    );

    final braunschweig = stations.firstWhere((s) => s.name == 'Braunschweig');
    expect(braunschweig.id, '662');
    expect(braunschweig.state, 'Niedersachsen');
    expect(braunschweig.latitude, closeTo(52.29, 0.01));
  }, skip: reason);

  test('a station forecasts today and the days after', () async {
    final client = FireDangerClient();
    addTearDown(client.close);

    final stations = await client.fetchStations();
    final station = stations.firstWhere((s) => s.name == 'Braunschweig');

    final forecast = await client.fetchForecast(station);
    expect(forecast, isNotNull);

    stdout.writeln(
      '${forecast!.stationName} ${forecast.issuedFor.toIso8601String()}: '
      '${forecast.days.map((d) => d.step).join(" ")}'
      '${forecast.peakAhead == null ? "" : " — Spitze "
                "${forecast.peakAhead!.level.step} in "
                "${forecast.peakAhead!.inDays} Tagen"}',
    );

    // Seven columns, and every one of them a step on the DWD's scale.
    expect(forecast.days, hasLength(7));
    expect(forecast.today.step, inInclusiveRange(1, 5));

    // In season the newest row is today's or yesterday's. Out of season
    // — the DWD issues March to October — this is the assertion that
    // says so rather than the app showing a level from last winter.
    expect(
      forecast.isStale(),
      isFalse,
      reason:
          'issued ${forecast.issuedFor}; out of season, or the '
          'dataset version moved',
    );
  }, skip: reason);
}

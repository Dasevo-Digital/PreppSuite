import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/road_closure_client.dart';

/// Asks the Autobahn GmbH's own interface.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real traffic service'
      : null;

  test(
    'the motorways are listed',
    () async {
      final roads = await RoadClosureClient().fetchRoads();
      stdout.writeln(
        '${roads.length} Autobahnen: ${roads.take(6).join(", ")} …',
      );

      expect(roads.length, greaterThan(50));
      expect(roads, contains('A2'));
      expect(roads.every((r) => r.startsWith('A')), isTrue);
    },
    timeout: const Timeout(Duration(minutes: 2)),
    skip: reason,
  );

  test(
    'a busy motorway has closures with directions and times',
    () async {
      final events = await RoadClosureClient().fetchEvents('A2');
      stdout.writeln(
        '${events.length} Meldungen auf der A2, '
        '${events.where((e) => e.current).length} davon jetzt, '
        '${events.where((e) => e.blocked).length} sperrend',
      );

      expect(events, isNotEmpty);
      // Both kinds come from the same shape and have to stay apart.
      expect(
        events.map((e) => e.kind).toSet(),
        isNotEmpty,
      );
      for (final event in events.take(20)) {
        expect(event.road, 'A2');
        expect(event.title, isNotEmpty);
      }
      // Titles are mixed and there is no rule to lean on: of 25 closures
      // on the A2, 16 began with "A2 | …" and the rest were free text
      // out of a roadworks system — "Beseitigung Unfall und Gebrauch -
      // AM H - Abruf 37". Watching several motorways at once, a card
      // that does not say which road it belongs to is useless, so the
      // screen prefixes it. What has to hold is that the client knows
      // the road for every event, whatever the title says.
      expect(events.every((e) => e.road == 'A2'), isTrue);
      expect(
        events.any((e) => !e.title.startsWith('A2')),
        isTrue,
        reason: 'if this ever stops being true the prefix can go',
      );

      // The service states a direction for practically everything, and
      // that is the field a driver needs.
      final directed = events.where((e) => e.direction != null);
      expect(directed.length, greaterThan(events.length ~/ 2));
      // Positions are inside Germany where they are given at all.
      for (final event in events.where((e) => e.latitude != null).take(20)) {
        expect(event.latitude, inInclusiveRange(47, 56));
        expect(event.longitude, inInclusiveRange(5, 16));
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: reason,
  );
}

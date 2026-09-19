import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_polygon_codec.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  final now = DateTime.utc(2026, 9, 16, 12);

  Warning warning(String? polygonsJson) => Warning(
    source: 'bbk',
    externalId: 'warning-1',
    countryCode: 'DE',
    severity: 'severe',
    eventType: 'storm',
    headline: 'Sturmböen',
    polygonsJson: polygonsJson,
    effective: now,
    sent: now,
    updatedAt: now,
    notified: false,
  );

  test('decodes every valid locally cached CAP polygon', () {
    final polygons = warningPolygons(
      warning('["52.1,10.5 52.2,10.6 52.0,10.7"]'),
    );

    expect(polygons, hasLength(1));
    expect(polygons.single, hasLength(3));
    expect(polygons.single.first.latitude, 52.1);
    expect(polygons.single.last.longitude, 10.7);
  });

  test('bad geometry never hides a warning', () {
    expect(warningPolygons(warning(null)), isEmpty);
    expect(warningPolygons(warning('not json')), isEmpty);
    expect(warningPolygons(warning('["52.1,10.5 broken"]')), isEmpty);
  });

  group('which area covers a spot', () {
    // A square from 52.0,10.0 to 53.0,11.0, given clockwise the way the
    // feed writes them.
    final square = [
      const LatLng(52, 10),
      const LatLng(53, 10),
      const LatLng(53, 11),
      const LatLng(52, 11),
    ];

    test('a point inside counts, a point outside does not', () {
      expect(ringContains(square, const LatLng(52.5, 10.5)), isTrue);
      expect(ringContains(square, const LatLng(51.5, 10.5)), isFalse);
      expect(ringContains(square, const LatLng(52.5, 11.5)), isFalse);
    });

    test('a bite out of the area is not inside it', () {
      // An L: the missing quarter is the north-east one.
      final shape = [
        const LatLng(52, 10),
        const LatLng(53, 10),
        const LatLng(53, 10.5),
        const LatLng(52.5, 10.5),
        const LatLng(52.5, 11),
        const LatLng(52, 11),
      ];

      expect(ringContains(shape, const LatLng(52.2, 10.2)), isTrue);
      expect(ringContains(shape, const LatLng(52.8, 10.8)), isFalse);
    });

    test('a line is not an area', () {
      expect(
        ringContains(
          [const LatLng(52, 10), const LatLng(53, 10)],
          const LatLng(52.5, 10),
        ),
        isFalse,
      );
    });

    test('a warning is covered when any one of its areas is', () {
      final far = [
        const LatLng(48, 8),
        const LatLng(49, 8),
        const LatLng(49, 9),
        const LatLng(48, 9),
      ];

      expect(polygonsCover([far, square], const LatLng(52.5, 10.5)), isTrue);
      expect(polygonsCover([far, square], const LatLng(50, 10)), isFalse);
      // A warning without geometry covers no spot, even one that concerns
      // everybody — that question belongs to `isWarningRelevant`.
      expect(polygonsCover(const [], const LatLng(52.5, 10.5)), isFalse);
    });

    test('the decoded geometry of a warning answers the same question', () {
      final polygons = warningPolygons(
        warning('["52.0,10.0 53.0,10.0 53.0,11.0 52.0,11.0"]'),
      );

      expect(polygonsCover(polygons, const LatLng(52.5, 10.5)), isTrue);
      expect(polygonsCover(polygons, const LatLng(54.0, 10.5)), isFalse);
    });
  });

  group('decoding the same warning twice', () {
    Warning at(DateTime updatedAt) => Warning(
      source: 'bbk',
      externalId: 'warning-1',
      countryCode: 'DE',
      severity: 'severe',
      eventType: 'storm',
      headline: 'Sturmböen',
      polygonsJson: '["52.1,10.5 52.2,10.6 52.0,10.7"]',
      effective: now,
      sent: now,
      updatedAt: updatedAt,
      notified: false,
    );

    test('costs nothing the second time', () {
      final cache = WarningPolygonCache();
      final first = cache.of(at(now));

      // Identity, not equality: a second decode would build new lists.
      expect(identical(cache.of(at(now)), first), isTrue);
    });

    test('a warning the feed rewrote is decoded again', () {
      final cache = WarningPolygonCache();
      final first = cache.of(at(now));

      expect(
        identical(cache.of(at(now.add(const Duration(minutes: 1)))), first),
        isFalse,
      );
    });

    test('a warning that has ended is forgotten', () {
      final cache = WarningPolygonCache();
      final first = cache.of(at(now));

      cache.retain(const []);

      expect(identical(cache.of(at(now)), first), isFalse);
    });

    test('a warning still in the feed survives a filter being toggled', () {
      final cache = WarningPolygonCache();
      final live = at(now);
      final first = cache.of(live);

      // What the screen does on every rebuild: hand over everything the
      // feed holds, not what the filter left of it.
      cache.retain([live]);

      expect(identical(cache.of(live), first), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
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
}

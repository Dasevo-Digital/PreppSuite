import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/daylight/application/daylight_store.dart';

void main() {
  test('the ordinary form', () {
    final place = parseCoordinates('52.2689, 10.5268');
    expect(place!.latitude, closeTo(52.2689, 1e-6));
    expect(place.longitude, closeTo(10.5268, 1e-6));
  });

  test('a German keyboard writes decimals with commas', () {
    // "52,2689, 10,5268" — three commas, two of them decimal points. The
    // form somebody actually types on a German layout, and the one that
    // would otherwise parse as nonsense.
    final place = parseCoordinates('52,2689, 10,5268');
    expect(place!.latitude, closeTo(52.2689, 1e-6));
    expect(place.longitude, closeTo(10.5268, 1e-6));
  });

  test('a semicolon settles it outright', () {
    final place = parseCoordinates('52,2689; 10,5268');
    expect(place!.latitude, closeTo(52.2689, 1e-6));
    expect(place.longitude, closeTo(10.5268, 1e-6));
  });

  test('a space is a separator too', () {
    final place = parseCoordinates('52.2689 10.5268');
    expect(place!.latitude, closeTo(52.2689, 1e-6));
  });

  test('degree signs are ignored', () {
    expect(parseCoordinates('52.2689°, 10.5268°'), isNotNull);
  });

  test('the southern and western halves of the world exist', () {
    final place = parseCoordinates('-0.1807, -78.4678');
    expect(place!.latitude, closeTo(-0.1807, 1e-6));
    expect(place.longitude, closeTo(-78.4678, 1e-6));
  });

  test('a place name is not a coordinate', () {
    expect(parseCoordinates('Braunschweig'), isNull);
  });

  test('a half-typed coordinate is not an error, it is just not one yet', () {
    expect(parseCoordinates('52.'), isNull);
    expect(parseCoordinates(''), isNull);
  });

  test('impossible coordinates are refused', () {
    expect(parseCoordinates('95, 10'), isNull);
    expect(parseCoordinates('52, 200'), isNull);
  });

  test('an empty name is stored as no name rather than as an empty one', () {
    expect(parseCoordinates('52, 10', name: '   ')?.name, isNull);
    expect(parseCoordinates('52, 10', name: 'Zuhause')?.name, 'Zuhause');
  });
}

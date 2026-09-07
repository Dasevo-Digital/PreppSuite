import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/continents.dart';

/// Which continent a place counts as being on.
///
/// A table rather than a geocoder, so the answers are worth checking
/// once: a wrong box here means somebody asks for their continent and
/// downloads the wrong half of the world.
void main() {
  test('the obvious ones', () {
    expect(continentFor(52.37, 9.73), Continent.europe); // Hannover
    expect(continentFor(30.04, 31.24), Continent.africa); // Kairo
    expect(continentFor(35.68, 139.69), Continent.asia); // Tokio
    expect(continentFor(40.71, -74.01), Continent.northAmerica); // New York
    expect(
      continentFor(-34.60, -58.38),
      Continent.southAmerica,
    ); // Buenos Aires
    expect(continentFor(-33.87, 151.21), Continent.oceania); // Sydney
  });

  test('the overlaps go to Europe, deliberately', () {
    // Istanbul and Moscow sit inside the Asia box too. Order decides,
    // and for this app's users Europe is the expected answer.
    expect(continentFor(41.01, 28.98), Continent.europe);
    expect(continentFor(55.76, 37.62), Continent.europe);
  });

  test('the open sea belongs to no continent', () {
    expect(continentFor(0, -140), isNull); // mid-Pacific
    expect(continentFor(-70, 0), isNull); // Antarctica
  });

  test('Europe reaches its edges', () {
    expect(continentFor(64.14, -21.94), Continent.europe); // Reykjavik
    expect(continentFor(35.34, 25.13), Continent.europe); // Kreta
    expect(continentFor(71.17, 25.78), Continent.europe); // Nordkap
  });

  test('a continent is a box at a zoom level', () {
    final area = Continent.europe.areaAt(9);
    expect(area.minZoom, 0);
    expect(area.maxZoom, 9);
    expect(area.minLongitude, Continent.europe.minLongitude);
  });
}

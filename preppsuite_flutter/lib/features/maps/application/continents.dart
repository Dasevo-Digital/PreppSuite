import 'map_area_download.dart';

/// The continents, as boxes.
///
/// Written down rather than asked of a geocoder. "Europe" is not a place
/// Nominatim answers usefully — and it does not need to be: a continent's
/// outline does not change, and a download only ever wants a rectangle.
/// Asking the network for a constant would add a request that can fail to
/// a feature whose whole point is working without one.
///
/// The boxes are generous on purpose. A continent ring is the coarsest
/// band of a staggered download, so a degree too far costs a handful of
/// tiles at zoom 5 and buys the map an edge that is not ragged.
enum Continent {
  /// Iceland and the Azores to the Urals, Crete to the North Cape.
  europe(-25, 34, 45, 71.5),

  africa(-19, -35.5, 52, 38),

  /// From the Urals east. Overlaps Europe around Turkey and western
  /// Russia, which [continentFor] settles by order.
  asia(25, -11, 180, 78),

  northAmerica(-169, 7, -52, 72),

  southAmerica(-82, -56, -34, 13),

  oceania(110, -48, 180, 0);

  const Continent(
    this.minLongitude,
    this.minLatitude,
    this.maxLongitude,
    this.maxLatitude,
  );

  final double minLongitude;
  final double minLatitude;
  final double maxLongitude;
  final double maxLatitude;

  bool contains(double latitude, double longitude) =>
      longitude >= minLongitude &&
      longitude <= maxLongitude &&
      latitude >= minLatitude &&
      latitude <= maxLatitude;

  MapArea areaAt(int detail) => MapArea(
    minLongitude: minLongitude,
    minLatitude: minLatitude,
    maxLongitude: maxLongitude,
    maxLatitude: maxLatitude,
    maxZoom: detail,
  );
}

/// The continent a point sits on, or null out at sea.
///
/// The order decides the overlaps, and it is not alphabetical: Europe is
/// tried before Asia, so Istanbul and Moscow come out European. That is a
/// choice, not a fact — but it is the one this app's users would expect,
/// and a continent here is a download boundary rather than a claim about
/// geography.
Continent? continentFor(double latitude, double longitude) {
  for (final continent in const [
    Continent.europe,
    Continent.africa,
    Continent.northAmerica,
    Continent.southAmerica,
    Continent.oceania,
    Continent.asia,
  ]) {
    if (continent.contains(latitude, longitude)) return continent;
  }
  return null;
}

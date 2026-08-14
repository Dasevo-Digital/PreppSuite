import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../features/household/application/german_states.dart';

/// Thrown when the device's location can't be determined at all
/// (permission denied, services disabled) — as opposed to a successful
/// lookup that just couldn't be matched to a known state, which returns
/// `null` from [GeolocationService.determineBundesland] instead.
class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Determines the user's Bundesland from device location — a deliberately
/// coarser fallback than manually entering an ARS. Nominatim (OpenStreetMap's
/// free, key-less geocoder) reports a state name but not an ARS/Kreis, so
/// there is no way to get Kreis-level precision this way; see
/// `docs/warning-feeds.md` and `SettingsScreen` for how this is presented to
/// the user.
class GeolocationService {
  GeolocationService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// Returns the matched [GermanState], or `null` if the position resolved
  /// but Nominatim's state name didn't match any of [germanStates] (e.g.
  /// outside Germany). Throws [LocationUnavailableException] if permission
  /// was denied or the position couldn't be read at all.
  Future<GermanState?> determineBundesland() async {
    final position = await _getPosition();
    final stateName = await _reverseGeocodeState(position);
    if (stateName == null) return null;
    return germanStateByName(stateName);
  }

  /// Raw device coordinates — e.g. to center the Schutzräume map on the
  /// user's current position (`ShelterMapScreen`). Same
  /// permission/error handling as [determineBundesland], without the
  /// reverse-geocoding step.
  Future<LatLng> getCurrentLatLng() async {
    final position = await _getPosition();
    return LatLng(position.latitude, position.longitude);
  }

  /// Forward-geocodes a free-text place/postal code query (e.g. "38100" or
  /// "Braunschweig") to a coordinate, for the Schutzräume map's "PLZ oder
  /// Ort" search. Returns `null` if nothing matched — not an exception,
  /// since "no results" is an expected, non-exceptional outcome of a
  /// search (unlike a denied location permission).
  Future<LatLng?> searchPlace(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': query,
      'countrycodes': 'de',
      'limit': '1',
      'accept-language': 'de',
    });

    final response = await _httpClient.get(
      uri,
      headers: {'User-Agent': 'PreppSuite/1.0'},
    );
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List || decoded.isEmpty) return null;
    final first = decoded.first;
    if (first is! Map) return null;

    final lat = double.tryParse('${first['lat']}');
    final lon = double.tryParse('${first['lon']}');
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  Future<Position> _getPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException(
        'Location services are disabled.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableException('Location permission denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
      ),
    );
  }

  Future<String?> _reverseGeocodeState(Position position) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '${position.latitude}',
      'lon': '${position.longitude}',
      'accept-language': 'de',
    });

    final response = await _httpClient.get(
      uri,
      // Nominatim's usage policy requires an identifying User-Agent for
      // non-browser clients.
      headers: {'User-Agent': 'PreppSuite/1.0'},
    );
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) return null;
    final address = decoded['address'];
    if (address is! Map) return null;
    return address['state'] as String?;
  }
}

import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import '../features/maps/application/readable_position.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../features/household/application/german_states.dart';
import 'http_client.dart';

/// Why the device's location could not be had.
enum LocationRefusal {
  /// Location is switched off for the whole device.
  servicesOff,

  /// Refused for this app, and the system will not ask again — the only
  /// way back is the system settings, which the app has to say.
  deniedForever,

  /// Refused this time.
  denied,

  /// Everything else: no implementation on this platform, a missing
  /// Info.plist key, a location manager that answered nothing.
  unavailable,
}

/// Thrown when the device's location can't be determined at all
/// (permission denied, services disabled) — as opposed to a successful
/// lookup that just couldn't be matched to a known state, which returns
/// `null` from [GeolocationService.determineBundesland] instead.
class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.reason, [this.detail]);

  final LocationRefusal reason;

  /// The platform's own words, for the cases where there is nothing
  /// better to say.
  final String? detail;

  @override
  String toString() => detail ?? reason.name;
}

/// Determines the user's Bundesland from device location — a deliberately
/// coarser fallback than manually entering an ARS. Nominatim (OpenStreetMap's
/// free, key-less geocoder) reports a state name but not an ARS/Kreis, so
/// there is no way to get Kreis-level precision this way; see
/// `docs/warning-feeds.md` and `SettingsScreen` for how this is presented to
/// the user.
class GeolocationService {
  GeolocationService({http.Client? httpClient})
    : _ownsClient = httpClient == null,
      _httpClient = httpClient ?? TimeoutClient();

  final http.Client _httpClient;
  final bool _ownsClient;
  void close() {
    if (_ownsClient) _httpClient.close();
  }

  /// Returns the matched [GermanState], or `null` if the position resolved
  /// but Nominatim's state name didn't match any of [germanStates] (e.g.
  /// outside Germany). Throws [LocationUnavailableException] if permission
  /// was denied or the position couldn't be read at all.
  Future<GermanState?> determineBundesland() async {
    final position = await _getPosition();
    return stateAt(position.latitude, position.longitude);
  }

  /// The [GermanState] a coordinate lies in, by the same coarse lookup as
  /// [determineBundesland]: only two decimals of it leave the device.
  Future<GermanState?> stateAt(double latitude, double longitude) async {
    final stateName = await _reverseGeocodeState(latitude, longitude);
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

  /// The same fix, with the one number that decides whether it is worth
  /// reading out: how far off it may be.
  ///
  /// A position without its accuracy is a claim without a confidence. Ten
  /// metres is a doorway; eight hundred is the wrong end of the village,
  /// and the screen that reads it aloud has to be able to say which.
  Future<ReadablePosition> getCurrentFix() async {
    final position = await _getPosition();
    return ReadablePosition(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMetres: position.accuracy,
      // What a stale fix has and a fresh one does not: an age worth
      // saying. Somebody reading coordinates over a radio has to know
      // whether they are standing in them.
      takenAt: position.timestamp,
    );
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

    final response = await _httpClient
        .get(
          uri,
          headers: {'User-Agent': 'PreppSuite/1.0'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Geocoding failed (${response.statusCode})',
        uri,
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List || decoded.isEmpty) return null;
    final first = decoded.first;
    if (first is! Map) return null;

    final lat = double.tryParse('${first['lat']}');
    final lon = double.tryParse('${first['lon']}');
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  /// Asks for the position, turning every way this can fail into a
  /// [LocationUnavailableException].
  ///
  /// Everything is wrapped, not just the cases this code raises itself: a
  /// missing Info.plist key or a platform without an implementation comes
  /// back as a plain platform error, and an uncaught one of those is a
  /// button that looks like nothing happened when it was pressed.
  Future<Position> _getPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationUnavailableException(LocationRefusal.servicesOff);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      switch (permission) {
        case LocationPermission.deniedForever:
          throw const LocationUnavailableException(
            LocationRefusal.deniedForever,
          );
        case LocationPermission.denied:
          throw const LocationUnavailableException(LocationRefusal.denied);
        case LocationPermission.unableToDetermine:
          throw const LocationUnavailableException(
            LocationRefusal.unavailable,
          );
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break;
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } on Object {
        // A fresh fix is a receiver waking up, and indoors or on a
        // desktop it often does not manage it inside fifteen seconds.
        // The device meanwhile has a perfectly good position from three
        // minutes ago lying about, and telling somebody "your location
        // could not be determined" while holding it is simply wrong --
        // it sends them to check a setting that was never off.
        //
        // Only reached once the permission questions above are settled,
        // so this never papers over a refusal: those throw before here.
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return last;
        rethrow;
      }
    } on LocationUnavailableException {
      rethrow;
    } on Object catch (error) {
      throw LocationUnavailableException(
        LocationRefusal.unavailable,
        error.toString(),
      );
    }
  }

  Future<String?> _reverseGeocodeState(
    double latitude,
    double longitude,
  ) async {
    // Only the state is wanted, so only that much of the position goes
    // out: two decimals, about a kilometre. No `zoom` to go with it —
    // at the state level Berlin, Hamburg and Bremen are answered as
    // cities, and `address.state` would go missing for exactly those.
    // The fix itself names a front door, and Nominatim's logs are not the
    // place for this household's address. A device within a kilometre of
    // a state border may be told the neighbouring one — the setting it
    // fills in can be corrected by hand.
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toStringAsFixed(2),
      'lon': longitude.toStringAsFixed(2),
      'accept-language': 'de',
    });

    final response = await _httpClient
        .get(
          uri,
          // Nominatim's usage policy requires an identifying User-Agent for
          // non-browser clients.
          headers: {'User-Agent': 'PreppSuite/1.0'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) return null;
    final address = decoded['address'];
    if (address is! Map) return null;
    return address['state'] as String?;
  }
}

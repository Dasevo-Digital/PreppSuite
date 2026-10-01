import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:preppsuite_flutter/core/geolocation_service.dart';

/// What the app does when the receiver does not answer in time.
///
/// The case this is about: location is switched on, permission is given,
/// and `getCurrentPosition` still times out — indoors, on a desktop, with
/// a cold receiver. The device meanwhile holds a perfectly usable
/// position from three minutes ago. Telling somebody their location could
/// not be determined while holding it sends them to check a setting that
/// was never off.
class _FakeGeolocator extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  _FakeGeolocator({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.current,
    this.last,
  });

  final bool serviceEnabled;
  final LocationPermission permission;

  /// Null means `getCurrentPosition` throws, which is what a timeout
  /// looks like from here.
  final Position? current;
  final Position? last;

  var askedForLast = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    final position = current;
    if (position == null) {
      return Future.error(
        TimeoutException('time limit reached'),
      );
    }
    return Future.value(position);
  }

  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) {
    askedForLast++;
    return Future.value(last);
  }
}

class TimeoutException implements Exception {
  TimeoutException(this.message);
  final String message;
  @override
  String toString() => message;
}

Position at(double lat, double lon, DateTime when) => Position(
  latitude: lat,
  longitude: lon,
  timestamp: when,
  accuracy: 30,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  final now = DateTime.utc(2026, 9, 22, 12);

  tearDown(() => GeolocatorPlatform.instance = _FakeGeolocator());

  group('when a fresh fix does not come', () {
    test('the last known one is used instead of failing', () async {
      final platform = _FakeGeolocator(
        current: null,
        last: at(52.2689, 10.5268, now.subtract(const Duration(minutes: 3))),
      );
      GeolocatorPlatform.instance = platform;

      final fix = await GeolocationService().getCurrentFix();

      expect(fix.latitude, closeTo(52.2689, 1e-6));
      expect(platform.askedForLast, 1);
    });

    test('and it says how old it is', () async {
      GeolocatorPlatform.instance = _FakeGeolocator(
        current: null,
        last: at(52.0, 10.0, now.subtract(const Duration(minutes: 40))),
      );

      final fix = await GeolocationService().getCurrentFix();

      expect(fix.ageAt(now)!.inMinutes, 40);
      expect(fix.isStaleAt(now), isTrue);
    });

    test('with nothing known either, the failure stands', () async {
      GeolocatorPlatform.instance = _FakeGeolocator(current: null, last: null);

      await expectLater(
        GeolocationService().getCurrentLatLng(),
        throwsA(isA<LocationUnavailableException>()),
      );
    });
  });

  group('what the fallback must never cover up', () {
    test('location switched off is still location switched off', () async {
      // Handing over a stale fix here would answer a question the
      // household did not ask and hide one they need to act on.
      final platform = _FakeGeolocator(
        serviceEnabled: false,
        last: at(52.0, 10.0, now),
      );
      GeolocatorPlatform.instance = platform;

      await expectLater(
        GeolocationService().getCurrentLatLng(),
        throwsA(
          isA<LocationUnavailableException>().having(
            (e) => e.reason,
            'reason',
            LocationRefusal.servicesOff,
          ),
        ),
      );
      expect(platform.askedForLast, 0);
    });

    test('a refusal for good is still a refusal for good', () async {
      final platform = _FakeGeolocator(
        permission: LocationPermission.deniedForever,
        last: at(52.0, 10.0, now),
      );
      GeolocatorPlatform.instance = platform;

      await expectLater(
        GeolocationService().getCurrentLatLng(),
        throwsA(
          isA<LocationUnavailableException>().having(
            (e) => e.reason,
            'reason',
            LocationRefusal.deniedForever,
          ),
        ),
      );
      expect(platform.askedForLast, 0);
    });
  });

  test('a fresh fix is used as it is, and is not stale', () async {
    final platform = _FakeGeolocator(
      current: at(52.5, 13.4, now),
      last: at(48.1, 11.6, now.subtract(const Duration(hours: 5))),
    );
    GeolocatorPlatform.instance = platform;

    final fix = await GeolocationService().getCurrentFix();

    expect(fix.latitude, closeTo(52.5, 1e-6));
    expect(fix.isStaleAt(now), isFalse);
    expect(platform.askedForLast, 0);
  });

  test('the state lookup sends a kilometre, not the front door', () async {
    // Only the state is wanted. A fix to the metre in Nominatim's logs is
    // this household's address.
    GeolocatorPlatform.instance = _FakeGeolocator(
      current: at(52.268874, 10.526770, now),
    );
    Uri? asked;
    final service = GeolocationService(
      httpClient: MockClient((request) async {
        asked = request.url;
        return http.Response(
          jsonEncode({
            'address': {'state': 'Niedersachsen'},
          }),
          200,
        );
      }),
    );

    final state = await service.determineBundesland();

    expect(state, isNotNull);
    expect(asked!.queryParameters['lat'], '52.27');
    expect(asked!.queryParameters['lon'], '10.53');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/core/geolocation_service.dart';

void main() {
  test(
    'an unavailable geocoder reports failure instead of no matching place',
    () async {
      final service = GeolocationService(
        httpClient: MockClient((_) async => http.Response('', 503)),
      );
      await expectLater(
        service.searchPlace('Berlin'),
        throwsA(isA<http.ClientException>()),
      );
    },
  );
  test('a successful empty search still means no matching place', () async {
    final service = GeolocationService(
      httpClient: MockClient((_) async => http.Response('[]', 200)),
    );
    expect(await service.searchPlace('No matching place'), isNull);
  });
}

import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/fire_danger_client.dart';

/// The DWD season file, unpacked within bounds.
///
/// The download was limited to two megabytes compressed, and two
/// megabytes of gzip can unpack to two gigabytes.
void main() {
  test('a forecast that unpacks past the limit is no forecast', () async {
    final bomb = gzip.encode(Uint8List(32 * 1024 * 1024));
    expect(bomb.length, lessThan(2 * 1024 * 1024));

    final client = FireDangerClient(
      httpClient: MockClient(
        (request) async => http.Response.bytes(bomb, 200),
      ),
    );
    addTearDown(client.close);

    expect(
      await client.fetchForecast(
        const FireDangerStation(id: '01001', name: 'Testort'),
      ),
      isNull,
    );
  });
}

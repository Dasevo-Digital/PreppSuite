import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_http.dart';

void main() {
  final uri = Uri.parse('https://warnings.invalid/feed');

  test('returns a complete response inside its limits', () async {
    final client = MockClient((_) async => http.Response('warnung', 200));

    final response = await getWarningResponse(client, uri);

    expect(response.statusCode, 200);
    expect(response.body, 'warnung');
  });

  test('rejects a warning feed above its byte budget', () async {
    final client = MockClient((_) async => http.Response('12345', 200));

    await expectLater(
      getWarningResponse(client, uri, maxResponseBytes: 4),
      throwsA(isA<WarningResponseTooLarge>()),
    );
  });

  test('times out a warning feed that does not answer', () async {
    final client = MockClient(
      (_) => Future<http.Response>.delayed(
        const Duration(milliseconds: 50),
        () => http.Response('late', 200),
      ),
    );

    await expectLater(
      getWarningResponse(
        client,
        uri,
        timeout: const Duration(milliseconds: 1),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });
}

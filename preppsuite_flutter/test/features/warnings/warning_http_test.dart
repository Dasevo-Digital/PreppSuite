import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_http.dart';

void main() {
  test('steady trickle still stops at the total response deadline', () async {
    var cancelled = false;
    late Timer timer;
    final stream = StreamController<List<int>>(
      onCancel: () {
        cancelled = true;
        timer.cancel();
      },
    );
    timer = Timer.periodic(
      const Duration(milliseconds: 10),
      (_) => stream.add([1]),
    );
    final client = MockClient.streaming(
      (_, _) async => http.StreamedResponse(stream.stream, 200),
    );
    await expectLater(
      getWarningResponse(
        client,
        Uri.parse('https://warnings.invalid/feed'),
        timeout: const Duration(milliseconds: 50),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(cancelled, isTrue);
    await stream.close();
    client.close();
  });
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

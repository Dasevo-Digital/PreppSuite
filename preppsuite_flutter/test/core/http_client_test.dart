import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/core/http_client.dart';

/// A network that is up but not working must end in an error, not in a
/// spinner (#139).
void main() {
  const short = Duration(milliseconds: 100);

  test('an answer in time comes through unchanged', () async {
    final client = TimeoutClient(
      inner: MockClient((_) async => http.Response('ok', 200)),
      responseTimeout: short,
      idleTimeout: short,
    );
    final response = await client.get(Uri.parse('https://example.org/'));
    expect(response.statusCode, 200);
    expect(response.body, 'ok');
  });

  test('a server that never answers is a timeout', () async {
    final client = TimeoutClient(
      inner: MockClient((_) => Completer<http.Response>().future),
      responseTimeout: short,
    );
    await expectLater(
      client.get(Uri.parse('https://example.org/')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('a body that stops arriving is a timeout', () async {
    final stalled = StreamController<List<int>>();
    final client = TimeoutClient(
      inner: MockClient.streaming(
        (_, _) async => http.StreamedResponse(stalled.stream, 200),
      ),
      idleTimeout: short,
    );
    stalled.add(utf8.encode('the first part '));
    await expectLater(
      client.get(Uri.parse('https://example.org/archive.zim')),
      throwsA(isA<TimeoutException>()),
    );
    await stalled.close();
  });

  test('a slow but steady body is not cut off', () async {
    final slow = StreamController<List<int>>();
    final client = TimeoutClient(
      inner: MockClient.streaming(
        (_, _) async => http.StreamedResponse(slow.stream, 200),
      ),
      idleTimeout: short,
    );
    final reading = client.get(Uri.parse('https://example.org/archive.zim'));
    // Longer in total than the idle limit, never idle that long.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      slow.add(utf8.encode('$i'));
    }
    await slow.close();
    expect((await reading).body, '01234');
  });
}

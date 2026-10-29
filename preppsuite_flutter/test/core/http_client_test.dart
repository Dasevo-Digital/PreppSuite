import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/core/http_client.dart';

/// A network that is up but not working must end in an error, not in a
/// spinner (#139).
void main() {
  test('response timeout closes only its own live socket', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <Socket>[];
    final disconnected = Completer<void>();
    final listening = server.listen((socket) {
      sockets.add(socket);
      socket.listen(
        (bytes) {
          if (utf8.decode(bytes).contains('/ok ')) {
            socket.write('HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok');
          }
        },
        onDone: () {
          if (!disconnected.isCompleted) disconnected.complete();
        },
      );
    });
    final client = TimeoutClient(
      responseTimeout: const Duration(milliseconds: 100),
    );
    final base = 'http://127.0.0.1:${server.port}';
    try {
      final hanging = expectLater(
        client.get(Uri.parse('$base/hang')),
        throwsA(isA<TimeoutException>()),
      );
      expect((await client.get(Uri.parse('$base/ok'))).body, 'ok');
      await hanging;
      await disconnected.future.timeout(const Duration(seconds: 2));
      expect((await client.get(Uri.parse('$base/ok'))).body, 'ok');
    } finally {
      client.close();
      for (final socket in sockets) {
        socket.destroy();
      }
      await listening.cancel();
      await server.close();
    }
  });

  test('multipart headers still match the finalized request body', () async {
    final client = TimeoutClient(
      inner: MockClient.streaming((request, body) async {
        final text = await body.bytesToString();
        final type = request.headers['content-type']!;
        expect(type, startsWith('multipart/form-data; boundary='));
        expect(text, contains(type.split('boundary=').last));
        expect(text, contains('payload'));
        return http.StreamedResponse(Stream.value([111, 107]), 200);
      }),
    );
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://example.org/'),
    )..fields['field'] = 'payload';
    expect(await (await client.send(request)).stream.bytesToString(), 'ok');
    client.close();
  });
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

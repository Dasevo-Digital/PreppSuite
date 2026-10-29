import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/http_client.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';
import 'package:preppsuite_flutter/features/downloads/application/archive_downloader.dart';

void main() {
  final previousHttp = HttpOverrides.current;
  TestWidgetsFlutterBinding.ensureInitialized();
  // These bounded transport checks need real loopback sockets rather than
  // the widget binding's synthetic HTTP 400 response.
  HttpOverrides.global = previousHttp;
  tearDownAll(() => HttpOverrides.global = previousHttp);
  late Directory directory;
  late ServerSocket server;
  late StreamSubscription<Socket> listener;
  late Completer<void> requested;
  late Completer<void> disconnected;
  final sockets = <Socket>[];

  Future<void> serve(String? response) async {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    listener = server.listen((socket) {
      sockets.add(socket);
      var answered = false;
      var archive = false;
      socket.listen(
        (bytes) {
          if (answered) return;
          answered = true;
          if (!requested.isCompleted) requested.complete();
          archive = !utf8.decode(bytes).contains('/ok ');
          if (!archive) {
            socket.write(
              'HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok',
            );
          } else if (response != null) {
            socket.write(response);
          }
        },
        onDone: () {
          if (archive && !disconnected.isCompleted) disconnected.complete();
        },
        onError: (Object _) {
          if (archive && !disconnected.isCompleted) disconnected.complete();
        },
      );
    });
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('archive-cleanup-');
    requested = Completer<void>();
    disconnected = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeStorageChannel, (_) async => null);
  });
  tearDown(() async {
    for (final socket in sockets) {
      socket.destroy();
    }
    sockets.clear();
    await listener.cancel();
    await server.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeStorageChannel, null);
  });

  test(
    'a rejected status aborts an unending body even with a borrowed client',
    () async {
      await serve(
        'HTTP/1.1 503 Unavailable\r\nContent-Length: 100000\r\n\r\nx',
      );
      final client = TimeoutClient(
        idleTimeout: const Duration(seconds: 5),
      );
      addTearDown(client.close);
      final other = client.get(Uri.parse('http://127.0.0.1:${server.port}/ok'));
      await expectLater(
        ArchiveDownloader(httpClient: client, retryDelays: const [])
            .download(
              url: Uri.parse('http://127.0.0.1:${server.port}/archive'),
              targetPath: '${directory.path}/archive',
            )
            .toList(),
        throwsA(isA<DownloadException>()),
      );
      await disconnected.future.timeout(const Duration(seconds: 2));
      expect((await other).body, 'ok');
      expect(
        (await client.get(Uri.parse('http://127.0.0.1:${server.port}/ok')))
            .body,
        'ok',
      );
    },
  );

  test('the completed 416 shortcut also aborts its response body', () async {
    await serve(
      'HTTP/1.1 416 Range Not Satisfiable\r\nContent-Range: bytes */3\r\nContent-Length: 100000\r\n\r\nx',
    );
    final target = '${directory.path}/archive';
    await File('$target.part').writeAsString('abc');
    await ArchiveDownloader()
        .download(
          url: Uri.parse('http://127.0.0.1:${server.port}/archive'),
          targetPath: target,
        )
        .toList();
    await disconnected.future.timeout(const Duration(seconds: 2));
    expect(await File(target).readAsString(), 'abc');
  });

  test('cancel while waiting for headers terminates promptly', () async {
    await serve(null);
    final subscription = ArchiveDownloader()
        .download(
          url: Uri.parse('http://127.0.0.1:${server.port}/archive'),
          targetPath: '${directory.path}/archive',
        )
        .listen((_) {});
    await requested.future.timeout(const Duration(seconds: 2));
    await subscription.cancel().timeout(const Duration(seconds: 2));
    await disconnected.future.timeout(const Duration(seconds: 2));
    expect(await File('${directory.path}/archive').exists(), isFalse);
  });
}

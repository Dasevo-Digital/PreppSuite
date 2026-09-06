import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_http_server.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart'
    show FileByteRangeSource;

import 'zim_fixture.dart';

/// The article view is a browser engine pointed at this server, so what it
/// answers is what a Wikipedia page turns out to be.
void main() {
  late Directory workspace;
  late ZimArchive archive;
  late ZimHttpServer server;
  late HttpClient client;

  setUp(() async {
    workspace = Directory.systemTemp.createTempSync('preppsuite-zim-server');
    final path = writeZim(
      workspace,
      ZimFixture(
        entries: [
          ZimFixtureEntry(
            namespace: 'C',
            url: 'Trinkwasser',
            title: 'Trinkwasser',
            content: utf8.encode('<h1>Trinkwasser</h1>'),
          ),
          const ZimFixtureEntry(
            namespace: 'C',
            url: 'style/main.css',
            title: 'main.css',
            content: [98, 111, 100, 121], // "body"
            mimeType: 1,
          ),
          const ZimFixtureEntry(
            namespace: 'C',
            url: 'Wasservorrat',
            title: 'Wasservorrat',
            redirectTo: 'C/Trinkwasser',
          ),
          ZimFixtureEntry(
            namespace: 'C',
            url: 'Karte.png',
            title: 'Karte.png',
            // Big enough that it cannot go out in one socket buffer, so a
            // client that walks away is guaranteed to leave the server
            // writing into a closed connection.
            content: List<int>.filled(4 * 1024 * 1024, 0x42),
            mimeType: 1,
          ),
        ],
      ),
    );

    archive = await ZimArchive.open(
      await FileByteRangeSource.open(File(path)),
    );
    server = await ZimHttpServer.start(archive);
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.close();
    await archive.close();
    workspace.deleteSync(recursive: true);
  });

  Future<HttpClientResponse> get(String path) async {
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${server.port}$path'),
    );
    return request.close();
  }

  test('an article is served as utf-8 html', () async {
    final response = await get('/C/Trinkwasser');

    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers.contentType?.mimeType, 'text/html');
    // Without the charset the engine guesses, and German articles come out
    // with mangled umlauts.
    expect(response.headers.contentType?.charset, 'utf-8');
    expect(await utf8.decodeStream(response), '<h1>Trinkwasser</h1>');
  });

  test('a url containing slashes keeps all of them', () async {
    // Stylesheets and images sit in subdirectories; splitting the path on
    // every slash would look for an entry that does not exist and every
    // page would lose its styling.
    final response = await get('/C/style/main.css');

    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers.contentType?.mimeType, 'image/png');
    expect(await utf8.decodeStream(response), 'body');
  });

  test('a redirect is followed rather than reported', () async {
    // The engine would follow a 302 too, but the archive stores redirects
    // as entries rather than as HTTP, so there is nothing to redirect to.
    final response = await get('/C/Wasservorrat');

    expect(response.statusCode, HttpStatus.ok);
    expect(await utf8.decodeStream(response), '<h1>Trinkwasser</h1>');
  });

  test('an entry the archive does not hold is a 404', () async {
    final response = await get('/C/Rechenschieber');

    expect(response.statusCode, HttpStatus.notFound);
    await response.drain<void>();
  });

  test('a path without a namespace is a 404 rather than a crash', () async {
    final response = await get('/favicon.ico');

    expect(response.statusCode, HttpStatus.notFound);
    await response.drain<void>();
  });

  test(
    'every response carries a policy that keeps the archive offline',
    () async {
      // An archive is whatever file the user picked, and a ZIM can carry
      // scripts. Under this server's origin those scripts would otherwise be
      // free to pull code off the internet or post the page back out.
      for (final path in ['/C/Trinkwasser', '/C/style/main.css']) {
        final response = await get(path);
        final policy = response.headers.value('content-security-policy');

        expect(policy, isNotNull, reason: path);
        expect(policy, contains("default-src 'self'"));
        // The one that stops fetch() and XMLHttpRequest reaching outward.
        expect(policy, contains("connect-src 'self'"));
        // Without these two, one tag would undo the rest: <base> re-points
        // every relative URL in the page, a form posts wherever it likes.
        expect(policy, contains("base-uri 'none'"));
        expect(policy, contains("form-action 'none'"));
        await response.drain<void>();
      }
    },
  );

  test('a 404 carries the policy too', () async {
    // Not pedantry: an archive can hand the engine a URL that misses, and
    // the error page is a document like any other.
    final response = await get('/C/Rechenschieber');

    expect(response.headers.value('content-security-policy'), isNotNull);
    await response.drain<void>();
  });

  test(
    'a client that walks away mid-transfer does not end the server',
    () async {
      // The engine does this every time the reader taps a link while images
      // are still loading. Dart happens to swallow the socket error, so this
      // passes against the older shape too — it is not a regression test. It
      // pins the property down: whatever one request does, the next reader
      // still gets a page.
      final socket = await Socket.connect('127.0.0.1', server.port);
      socket.write('GET /C/Karte.png HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n');
      await socket.flush();
      // Wait for delivery to be under way, then leave without reading it.
      await socket.first;
      socket.destroy();

      // The one assertion that matters: the next reader still gets a page.
      final response = await get('/C/Trinkwasser');
      expect(response.statusCode, HttpStatus.ok);
      expect(await utf8.decodeStream(response), '<h1>Trinkwasser</h1>');
    },
  );

  test('the server is reachable only over loopback', () async {
    expect(server.uriFor(await archive.entryAt(0)).host, '127.0.0.1');
  });
}

import 'dart:async';
import 'dart:io';

import 'zim_archive.dart';

/// Serves a ZIM archive to the article view over loopback.
///
/// A browser engine is the only thing that renders a Wikipedia page
/// properly, and a browser engine wants URLs. So the archive is put behind
/// one: `http://127.0.0.1:<port>/C/Trinkwasser`. Every relative link,
/// stylesheet and image inside the page then resolves against the same
/// origin and lands back here — which is why navigating between articles
/// needs no code at all.
///
/// Bound to the loopback address only, so nothing outside the device can
/// reach it. Other apps on the same device can, for as long as an article
/// is open; what they would find is the public encyclopedia the user
/// downloaded.
class ZimHttpServer {
  ZimHttpServer._(this._server, this._archive);

  final HttpServer _server;
  final ZimArchive _archive;

  int get port => _server.port;

  Uri uriFor(ZimEntry entry) =>
      Uri.parse('http://127.0.0.1:$port/${entry.namespace}/${entry.url}');

  static Future<ZimHttpServer> start(ZimArchive archive) async {
    // Port zero: the system picks a free one. A fixed port would collide
    // with whatever else the user is running.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final instance = ZimHttpServer._(server, archive);
    unawaited(instance._serve());
    return instance;
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _serve() async {
    await for (final request in _server) {
      try {
        await _respond(request);
      } on Object {
        // A request that fails must not take the server down with it —
        // the page would then lose its stylesheet and every later image.
        request.response.statusCode = HttpStatus.internalServerError;
      } finally {
        await request.response.close();
      }
    }
  }

  Future<void> _respond(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    if (segments.length < 2) {
      request.response.statusCode = HttpStatus.notFound;
      return;
    }

    // The first segment is the namespace; everything after it is the URL,
    // which may itself contain slashes.
    final namespace = segments.first;
    final url = segments.skip(1).join('/');

    final found = await _archive.findByUrl(namespace, url);
    final entry = found == null ? null : await _archive.resolve(found);
    if (entry == null || entry.isRedirect) {
      request.response.statusCode = HttpStatus.notFound;
      return;
    }

    final bytes = await _archive.readBlob(entry);
    request.response
      ..headers.contentType = _contentTypeOf(_archive.mimeTypeOf(entry))
      ..headers.contentLength = bytes.length
      // Nothing here ever changes while the app is open, and the engine
      // asks for the same stylesheet on every page.
      ..headers.set(HttpHeaders.cacheControlHeader, 'max-age=3600')
      ..add(bytes);
  }

  static ContentType _contentTypeOf(String mimeType) {
    final parts = mimeType.split(';').first.trim().split('/');
    if (parts.length != 2) return ContentType.binary;

    return ContentType(
      parts[0],
      parts[1],
      // The archives are UTF-8 throughout; without saying so the engine
      // guesses, and German articles come out with mangled umlauts.
      charset: parts[0] == 'text' ? 'utf-8' : null,
    );
  }
}

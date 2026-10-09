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
///
/// Every response carries [_contentSecurityPolicy], which is what actually
/// keeps an archive offline — see there.
class ZimHttpServer {
  ZimHttpServer._(this._server, this._archive);

  final HttpServer _server;
  final ZimArchive _archive;

  int get port => _server.port;

  /// The address of [entry] on this server.
  ///
  /// Built from segments rather than pasted into a string: an entry's URL
  /// is the archive's own text and may hold a space, a `?` or a `#`, which
  /// pasted in would end the path early or turn into a query. Each segment
  /// is encoded here and decoded again by [_respond], so the archive gets
  /// back exactly the URL it named.
  Uri uriFor(ZimEntry entry) => Uri(
    scheme: 'http',
    host: '127.0.0.1',
    port: port,
    pathSegments: [entry.namespace, ...entry.url.split('/')],
  );

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
      request.response.headers.set(
        'Content-Security-Policy',
        _contentSecurityPolicy,
      );
      try {
        await _respond(request);
      } on Object {
        try {
          request.response.statusCode = HttpStatus.internalServerError;
        } on Object {
          // The headers are already on the wire; there is nothing left to
          // say about this request. Setting the status now would throw.
        }
      }

      // Closing is deliberately outside the catch above and guarded on its
      // own. It used to sit in a `finally`, from where a throw escapes the
      // loop, ends `_serve` — which nobody awaits — and leaves the server
      // listening while answering nothing.
      //
      // Measured, not assumed: a client walking away mid-transfer, which
      // the engine does on every tapped link, does *not* throw here. Dart's
      // HttpServer swallows that socket error, so the old shape held. The
      // guard is here so that it does not have to keep holding by accident
      // — one write added after the headers go out is enough to turn a
      // single failed request into a reader that never sees another page.
      try {
        await request.response.close();
      } on Object {
        // The client is gone. There was never anyone to deliver to.
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

  /// Keeps an archive from reaching the network.
  ///
  /// An archive is not trusted content. The reader points at whatever file
  /// the user selected, and a ZIM can carry scripts — real Wikipedia ones
  /// do. Served from here, those scripts run under the origin of this
  /// server, which means same-origin access to the whole archive and to
  /// any other port on loopback. Without a policy they could also pull a
  /// script off the internet or post what they read back out.
  ///
  /// `'unsafe-inline'` and `'unsafe-eval'` stay allowed on purpose. The
  /// danger here is not an injected script — the archive is untrusted as a
  /// whole, so there is no boundary inside it to defend — it is the
  /// archive talking to the network. Forbidding inline scripts would break
  /// collapsible sections and maths on real articles and buy nothing;
  /// `default-src 'self'` and `connect-src 'self'` are what close the way
  /// out.
  ///
  /// `base-uri` and `form-action` are listed because `default-src` does
  /// not cover them: a `<base href="https://...">` would re-point every
  /// relative URL in the page outward, and a form would post there.
  ///
  /// Sent on every response rather than only on HTML, because an SVG
  /// delivered as `image/svg+xml` carries scripts of its own.
  static const _contentSecurityPolicy =
      "default-src 'self' data: blob:; "
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob:; "
      "style-src 'self' 'unsafe-inline' data:; "
      "img-src 'self' data: blob:; "
      "media-src 'self' data: blob:; "
      "font-src 'self' data:; "
      "connect-src 'self'; "
      "frame-src 'none'; "
      "object-src 'none'; "
      "base-uri 'none'; "
      "form-action 'none'";

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

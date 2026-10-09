import 'dart:async';

import 'package:http/http.dart' as http;

/// The HTTP client every feature starts from, with a limit on waiting
/// (#139).
///
/// Ten of the app's network calls had none. On a network that is up but
/// not working -- a hotel portal that swallows requests, a mobile cell
/// that is overloaded, a router whose uplink died -- such a call does not
/// fail, it waits, and the screen behind it shows a spinner for as long as
/// it is open. In an emergency that spinner is indistinguishable from an
/// answer about to arrive.
///
/// Two limits, because a download is not a lookup:
///
/// * [responseTimeout] for the server to start answering at all.
/// * [idleTimeout] for the body to stop arriving. A map or an encyclopedia
///   may take an hour and is fine as long as bytes keep coming; one that
///   stalls for a minute has stalled.
///
/// Clients passed in by tests are taken as they are; this is only the
/// default.
class TimeoutClient extends http.BaseClient {
  TimeoutClient({
    http.Client? inner,
    this.responseTimeout = const Duration(seconds: 30),
    this.idleTimeout = const Duration(seconds: 60),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration responseTimeout;
  final Duration idleTimeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner
        .send(request)
        .timeout(
          responseTimeout,
          onTimeout: () => throw TimeoutException(
            'no answer from ${request.url.host}',
            responseTimeout,
          ),
        );
    final body = response.stream.timeout(
      idleTimeout,
      onTimeout: (sink) {
        sink.addError(
          TimeoutException('${request.url.host} stopped sending', idleTimeout),
        );
        sink.close();
      },
    );
    return http.StreamedResponse(
      http.ByteStream(body),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}

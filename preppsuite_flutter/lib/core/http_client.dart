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

  final _active = <Completer<void>>{};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final abort = Completer<void>();
    _active.add(abort);
    void stop() {
      if (!abort.isCompleted) abort.complete();
      _active.remove(abort);
    }

    if (request is http.Abortable) {
      final weak = WeakReference(abort);
      unawaited(
        request.abortTrigger?.then((_) {
          final signal = weak.target;
          if (signal != null && !signal.isCompleted) signal.complete();
        }),
      );
    }
    try {
      final response = await _inner
          .send(_AbortableProxy(request, abort.future))
          .timeout(
            responseTimeout,
            onTimeout: () {
              stop();
              throw TimeoutException('Response deadline', responseTimeout);
            },
          );
      final body = response.stream.timeout(
        idleTimeout,
        onTimeout: (sink) {
          stop();
          sink.addError(
            TimeoutException('Response idle deadline', idleTimeout),
          );
          sink.close();
        },
      );
      return http.StreamedResponse(
        _finishBody(body, stop),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (_) {
      stop();
      rethrow;
    }
  }

  @override
  void close() {
    for (final abort in _active.toList()) {
      if (!abort.isCompleted) abort.complete();
    }
    _active.clear();
    _inner.close();
  }
}

Stream<List<int>> _finishBody(
  Stream<List<int>> body,
  void Function() stop,
) async* {
  try {
    yield* body;
  } finally {
    stop();
  }
}

/// Preserve arbitrary request bodies, including multipart uploads, while
/// giving the transport a request-local abort signal.
class _AbortableProxy extends http.BaseRequest with http.Abortable {
  _AbortableProxy(this.original, this.abortTrigger)
    : super(original.method, original.url) {
    headers.addAll(original.headers);
    contentLength = original.contentLength;
    followRedirects = original.followRedirects;
    maxRedirects = original.maxRedirects;
    persistentConnection = original.persistentConnection;
  }
  final http.BaseRequest original;
  @override
  final Future<void> abortTrigger;
  @override
  http.ByteStream finalize() {
    super.finalize();
    final body = original.finalize();
    // Multipart requests create their boundary during finalize().
    headers
      ..clear()
      ..addAll(original.headers);
    return body;
  }
}

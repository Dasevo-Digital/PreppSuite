import 'dart:async';

import '../../../core/bounded_input.dart';

import 'package:http/http.dart' as http;

const warningRequestTimeout = Duration(seconds: 20);
const warningResponseMaxBytes = 4 * 1024 * 1024;

class WarningResponseTooLarge implements Exception {
  const WarningResponseTooLarge();
}

/// Reads public warning feeds with fixed time and memory budgets. A failed
/// source is handled by the caller as incomplete data, never as no warning.
///
/// [onChunk] sees each piece of the body as it arrives. Throwing from it
/// ends the read: the connection is closed, and what it threw comes out of
/// this call. That is how a feed whose first kilobyte says nothing changed
/// costs that kilobyte and not the rest of it.
Future<http.Response> getWarningResponse(
  http.Client client,
  Uri uri, {
  Duration timeout = warningRequestTimeout,
  int maxResponseBytes = warningResponseMaxBytes,
  void Function(List<int> chunk)? onChunk,
}) async {
  final abort = Completer<void>();
  final clock = Stopwatch()..start();
  void stop() {
    if (!abort.isCompleted) abort.complete();
  }

  try {
    final request = http.AbortableRequest(
      'GET',
      uri,
      abortTrigger: abort.future,
    );
    final streamed = await client
        .send(request)
        .timeout(
          timeout,
          onTimeout: () {
            stop();
            throw TimeoutException('Warning deadline', timeout);
          },
        );
    final remaining = timeout - clock.elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException('Warning deadline', timeout);
    }
    final bytes = await readBoundedBytes(
      onChunk == null
          ? streamed.stream
          : streamed.stream.map((chunk) {
              onChunk(chunk);
              return chunk;
            }),
      maxBytes: maxResponseBytes,
      declaredLength: streamed.contentLength,
      timeout: remaining,
      onAbort: stop,
    );
    return http.Response.bytes(
      bytes,
      streamed.statusCode,
      headers: streamed.headers,
      request: streamed.request,
      reasonPhrase: streamed.reasonPhrase,
    );
  } on InputTooLarge {
    throw const WarningResponseTooLarge();
  } finally {
    stop();
  }
}

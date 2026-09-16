import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

const warningRequestTimeout = Duration(seconds: 20);
const warningResponseMaxBytes = 4 * 1024 * 1024;

class WarningResponseTooLarge implements Exception {
  const WarningResponseTooLarge();
}

/// Reads public warning feeds with fixed time and memory budgets. A failed
/// source is handled by the caller as incomplete data, never as no warning.
Future<http.Response> getWarningResponse(
  http.Client client,
  Uri uri, {
  Duration timeout = warningRequestTimeout,
  int maxResponseBytes = warningResponseMaxBytes,
}) async {
  final streamed = await client.send(http.Request('GET', uri)).timeout(timeout);
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in streamed.stream.timeout(timeout)) {
    if (bytes.length + chunk.length > maxResponseBytes) {
      throw const WarningResponseTooLarge();
    }
    bytes.add(chunk);
  }
  return http.Response.bytes(
    bytes.takeBytes(),
    streamed.statusCode,
    headers: streamed.headers,
    request: streamed.request,
    reasonPhrase: streamed.reasonPhrase,
  );
}

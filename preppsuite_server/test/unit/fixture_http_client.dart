import 'dart:convert';

import 'package:http/http.dart' as http;

/// A fake [http.Client] that serves canned bodies for exact URLs, so client
/// parsing logic can be tested against real captured responses without any
/// live network access.
class FixtureHttpClient extends http.BaseClient {
  FixtureHttpClient(this._responsesByUrl);

  final Map<String, String> _responsesByUrl;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = _responsesByUrl[request.url.toString()];
    if (body == null) {
      return http.StreamedResponse(const Stream.empty(), 404);
    }
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      request: request,
    );
  }
}

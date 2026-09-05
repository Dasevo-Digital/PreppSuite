import 'dart:convert';

import 'package:http/http.dart' as http;

/// A fake [http.Client] serving canned bodies for exact URLs, so the feed
/// parsing can be tested against real captured responses without network
/// access. Moved here from the server together with the clients it feeds.
class FixtureHttpClient extends http.BaseClient {
  FixtureHttpClient(this._responsesByUrl, {this.onRequest});

  final Map<String, String> _responsesByUrl;

  /// Called with every requested URL, so a test can assert *which*
  /// endpoints were polled rather than only what came back.
  final void Function(String url)? onRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    onRequest?.call(request.url.toString());
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

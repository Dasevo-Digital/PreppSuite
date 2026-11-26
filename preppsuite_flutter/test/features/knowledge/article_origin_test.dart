import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/article_viewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// What the article view will follow and what it refuses.
///
/// The archive is not trusted content — it is whatever file the user
/// pointed at — so a link inside it may lead anywhere. Everything that is
/// not this app's own loopback server is somewhere the reader does not go.
void main() {
  final origin = Uri.parse('http://127.0.0.1:52341/C/Trinkwasser');

  test('another article on the same server is followed', () {
    expect(
      isArchiveUrl(Uri.parse('http://127.0.0.1:52341/C/Wasservorrat'), origin),
      isTrue,
    );
  });

  test('the internet is refused', () {
    expect(isArchiveUrl(Uri.parse('https://example.org/'), origin), isFalse);
  });

  test('another port on loopback is refused', () {
    // Whatever else is listening on this device is no more part of the
    // archive than a website is — and probing those ports is exactly what
    // a hostile archive would want to do.
    expect(
      isArchiveUrl(Uri.parse('http://127.0.0.1:8080/admin'), origin),
      isFalse,
    );
  });

  test('a different scheme on the same host and port is refused', () {
    expect(
      isArchiveUrl(Uri.parse('https://127.0.0.1:52341/C/Trinkwasser'), origin),
      isFalse,
    );
  });

  test('localhost is refused, because the server answers as 127.0.0.1', () {
    // Same machine, different origin as far as a browser engine is
    // concerned. Letting it through would widen the rule for nothing.
    expect(
      isArchiveUrl(Uri.parse('http://localhost:52341/C/Trinkwasser'), origin),
      isFalse,
    );
  });

  test('an unparsable link is refused rather than crashing the view', () {
    expect(isArchiveUrl(null, origin), isFalse);
  });

  group('an HTTP error ends the page only when it is the page (#407)', () {
    HttpResponseError android(String url) => HttpResponseError(
      request: WebResourceRequest(uri: Uri.parse(url)),
      response: const WebResourceResponse(uri: null, statusCode: 404),
    );

    test('a picture missing from the archive leaves the article', () {
      // Android reports every resource of a page, with no main-frame flag.
      // One missing picture used to replace the article with an error.
      expect(
        isPageHttpError(
          android('http://127.0.0.1:52341/I/Quelle.jpg'),
          document: origin,
        ),
        isFalse,
      );
    });

    test('the page itself, with or without its fragment, does end it', () {
      expect(
        isPageHttpError(android(origin.toString()), document: origin),
        isTrue,
      );
      expect(
        isPageHttpError(
          android('http://127.0.0.1:52341/C/Trinkwasser'),
          document: Uri.parse(
            'http://127.0.0.1:52341/C/Trinkwasser#Geschichte',
          ),
        ),
        isTrue,
      );
    });

    test('the same page spelled with escapes is the same page', () {
      expect(
        isPageHttpError(
          android('http://127.0.0.1:52341/C/K%C3%A4se'),
          document: Uri.parse('http://127.0.0.1:52341/C/Käse'),
        ),
        isTrue,
      );
    });

    test('WebKit names no request and reports only the page', () {
      expect(
        isPageHttpError(
          const HttpResponseError(
            response: WebResourceResponse(uri: null, statusCode: 500),
          ),
          document: origin,
        ),
        isTrue,
      );
    });
  });
}

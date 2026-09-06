import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/article_viewer.dart';

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
}

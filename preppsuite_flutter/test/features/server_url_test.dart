import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/server_url.dart';

void main() {
  group('normalizeServerUrl', () {
    test('keeps a complete address, adding the trailing slash', () {
      // Serverpod appends endpoint paths to this string; without the slash
      // the request goes to "…example.cominventory".
      expect(
        normalizeServerUrl('https://preppsuite.example.com'),
        'https://preppsuite.example.com/',
      );
      expect(
        normalizeServerUrl('https://preppsuite.example.com/'),
        'https://preppsuite.example.com/',
      );
    });

    test('assumes https for a bare hostname', () {
      // Downgrading a public hostname to plain http silently would be the
      // worse guess.
      expect(
        normalizeServerUrl('preppsuite.example.com'),
        'https://preppsuite.example.com/',
      );
    });

    test('assumes http for an address on the local network', () {
      // A home server reached by IP has no certificate to present.
      expect(
        normalizeServerUrl('192.168.1.5:8080'),
        'http://192.168.1.5:8080/',
      );
      expect(normalizeServerUrl('localhost:8080'), 'http://localhost:8080/');
      expect(normalizeServerUrl('nas.local:8080'), 'http://nas.local:8080/');
    });

    test('an explicit scheme is never overridden', () {
      expect(
        normalizeServerUrl('http://preppsuite.example.com'),
        'http://preppsuite.example.com/',
      );
      expect(
        normalizeServerUrl('https://192.168.1.5:8080'),
        'https://192.168.1.5:8080/',
      );
    });

    test('keeps a port and a path', () {
      expect(
        normalizeServerUrl('https://example.com:8443/preppsuite'),
        'https://example.com:8443/preppsuite/',
      );
    });

    test('tolerates surrounding whitespace, as pasting tends to add', () {
      expect(
        normalizeServerUrl('  https://example.com  '),
        'https://example.com/',
      );
    });

    test('refuses empty and blank input', () {
      expect(normalizeServerUrl(''), isNull);
      expect(normalizeServerUrl('   '), isNull);
    });

    test('refuses input with spaces inside it', () {
      expect(normalizeServerUrl('mein server.de'), isNull);
    });

    test('refuses schemes that are not http(s)', () {
      // A typo like "ftp://" or a pasted "mailto:" should fail visibly
      // rather than produce a client that can never connect.
      expect(normalizeServerUrl('ftp://example.com'), isNull);
      expect(normalizeServerUrl('mailto:someone@example.com'), isNull);
    });

    test('refuses a scheme without a host', () {
      expect(normalizeServerUrl('https://'), isNull);
    });
  });
}

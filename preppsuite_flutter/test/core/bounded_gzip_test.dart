import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:archive/archive.dart' show GZipEncoder;
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/bounded_gzip.dart';

/// Unpacking bytes this app did not write.
///
/// A gzip stream expands by up to a factor of a thousand, so a limit on
/// what comes in says nothing about what comes out.
void main() {
  test('what fits comes back as it went in', () {
    final original = Uint8List.fromList(List.generate(100000, (i) => i % 7));

    expect(gunzipBounded(gzip.encode(original), limit: 100000), original);
  });

  test('the archive package writes what this reads', () {
    // The QR chain packs with `GZipEncoder` and now unpacks through here.
    final original = Uint8List.fromList(List.generate(5000, (i) => i % 13));

    expect(
      gunzipBounded(GZipEncoder().encode(original), limit: 5000),
      original,
    );
  });

  test('a stream that unpacks past the limit stops there', () {
    // Ten megabytes of zeros is about ten kilobytes of gzip.
    final bomb = gzip.encode(Uint8List(10 * 1024 * 1024));
    expect(bomb.length, lessThan(64 * 1024));

    expect(
      () => gunzipBounded(bomb, limit: 1024 * 1024),
      throwsA(isA<DecompressionLimitException>()),
    );
  });

  test('something that is not gzip is a format error', () {
    expect(
      () => gunzipBounded([1, 2, 3, 4, 5], limit: 1024),
      throwsA(isA<FormatException>()),
    );
  });
}

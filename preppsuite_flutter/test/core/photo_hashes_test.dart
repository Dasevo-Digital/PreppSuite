import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/photo_hashes.dart';

/// The names a row gives its pictures (#376), and the rule two devices
/// settle on when they name the same version's pictures differently.
void main() {
  final a = 'a' * 64;
  final b = 'b' * 64;

  test('a picture is named by its SHA-256', () async {
    // The standard test vector for "abc".
    const abc =
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';
    expect(photoContentHashSync(utf8.encode('abc')), abc);
    expect(await photoContentHash(Uint8List.fromList(utf8.encode('abc'))), abc);
  });

  test('only lists of the right length with hashes or nulls are read', () {
    expect(photoHashesFromJson([a, null, b], places: 3), [a, null, b]);
    expect(photoHashesFromJson([null], places: 1), [null]);
    expect(photoHashesFromJson([a, b], places: 3), isNull);
    expect(photoHashesFromJson([a, 'x', null], places: 3), isNull);
    expect(photoHashesFromJson(['A' * 64, null, null], places: 3), isNull);
    expect(photoHashesFromJson(null, places: 3), isNull);
    expect(photoHashesFromJson('[]', places: 3), isNull);
    expect(decodePhotoHashes('not json', places: 3), isNull);
    expect(
      decodePhotoHashes(encodePhotoHashes([a, null, null]), places: 3),
      [a, null, null],
    );
  });

  test('of two lists for one version, the one with more pictures stays', () {
    final one = encodePhotoHashes([a, null, null]);
    final two = encodePhotoHashes([b, a, null]);
    expect(comparePhotoHashes(two, one), greaterThan(0));
    expect(comparePhotoHashes(one, two), lessThan(0));
  });

  test('between equally full lists the text decides, the same everywhere', () {
    final first = encodePhotoHashes([a, null, null]);
    final second = encodePhotoHashes([b, null, null]);
    final order = comparePhotoHashes(first, second);
    expect(order, isNot(0));
    expect(comparePhotoHashes(second, first), -order.sign * order.abs());
  });
}

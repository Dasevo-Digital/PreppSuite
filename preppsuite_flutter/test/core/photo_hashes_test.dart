import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/photo_hashes.dart';

/// The names a row gives its pictures (#376), the two kinds of list, and
/// the rules by which they meet.
void main() {
  final a = 'a' * 64;
  final b = 'b' * 64;
  final c = 'c' * 64;

  PhotoList set(List<String?> places) => PhotoList(places);
  PhotoList seen(List<String?> places) => PhotoList(places, seen: true);

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
    expect(decodePhotoList('not json', places: 3), isNull);
  });

  test('a set and a seen list are stored apart and read back', () {
    final asSet = set([a, null, null]);
    final asSeen = seen([null, b, null]);
    expect(decodePhotoList(encodePhotoList(asSet), places: 3), asSet);
    expect(decodePhotoList(encodePhotoList(asSeen), places: 3), asSeen);
    expect(encodePhotoList(asSeen), startsWith('{'));
    expect(asSet, isNot(seen([a, null, null])));
  });

  test('two lists join place by place, the same in either order', () {
    expect(joinPhotoPlaces([a, null, null], [null, b, null]), [a, b, null]);
    expect(joinPhotoPlaces([a, null, null], [b, null, null]), [b, null, null]);
    expect(joinPhotoPlaces([b, null, null], [a, null, null]), [b, null, null]);
  });

  group('a newer version', () {
    test('with a set list brings it, empty places and all', () {
      expect(
        photoListForNewer(
          stored: set([a, b, null]),
          incoming: set([c, null, null]),
        ),
        set([c, null, null]),
      );
    });

    test('without a list keeps what is stored', () {
      expect(
        photoListForNewer(stored: set([a, null, null])),
        set([a, null, null]),
      );
    });

    test('with a seen list adds to a seen one and leaves a set one', () {
      expect(
        photoListForNewer(
          stored: seen([a, null, null]),
          incoming: seen([null, b, null]),
        ),
        seen([a, b, null]),
      );
      expect(
        photoListForNewer(
          stored: set([a, null, null]),
          incoming: seen([null, b, null]),
        ),
        set([a, null, null]),
        reason: 'an emptied place is not filled again by what a device holds',
      );
    });
  });

  group('the same version', () {
    test('fills an unknown list', () {
      expect(
        photoListForSameVersion(incoming: seen([a, null, null])),
        seen([a, null, null]),
      );
    });

    test('a set list beats a seen one, whichever arrives first', () {
      expect(
        photoListForSameVersion(
          stored: seen([a, b, null]),
          incoming: set([c, null, null]),
        ),
        set([c, null, null]),
      );
      expect(
        photoListForSameVersion(
          stored: set([c, null, null]),
          incoming: seen([a, b, null]),
        ),
        set([c, null, null]),
      );
    });

    test('a seen list that knows nothing never empties a place', () {
      expect(
        photoListForSameVersion(
          stored: seen([a, null, null]),
          incoming: seen([null, null, b]),
        ),
        seen([a, null, b]),
      );
    });
  });
}

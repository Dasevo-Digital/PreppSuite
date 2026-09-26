import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/dark_map_style.dart';
import 'package:preppsuite_flutter/features/maps/application/map_label_language.dart';
import 'package:preppsuite_flutter/features/maps/application/map_style_fingerprint.dart';
// ignore: implementation_imports
import 'package:vector_tile_renderer/src/themes/light_theme.dart'
    show lightThemeData;

/// Why the map has to be told that its style changed.
///
/// `vector_map_tiles` files rendered tiles on disk under the theme's id
/// and version, and both come from the package's style rather than from
/// what this app does to it. The German labels were correct in the
/// style, in the parsed theme and in the archive — and the map still
/// drew „Cologne", because it was handing back pictures rendered weeks
/// before. This is the guard against that happening again.
void main() {
  test('the same style always fingerprints the same', () {
    // A cache key that moved on its own would throw the cache away on
    // every start, which is the opposite mistake.
    expect(
      mapStyleFingerprint(lightThemeData()),
      mapStyleFingerprint(lightThemeData()),
    );
  });

  test('each pass over the style changes it', () {
    final plain = mapStyleFingerprint(lightThemeData());
    final german = mapStyleFingerprint(germanMapLabels(lightThemeData()));
    final dark = mapStyleFingerprint(darkenMapStyle(lightThemeData()));
    final both = mapStyleFingerprint(
      germanMapLabels(darkenMapStyle(lightThemeData())),
    );

    expect({plain, german, dark, both}, hasLength(4));
  });

  test('a single changed colour is enough', () {
    // The case that matters: a small edit somewhere in sixty kilobytes
    // of style must not be able to hide behind an unchanged key.
    final before = {
      'layers': [
        {
          'id': 'a',
          'paint': {'fill-color': '#ffffff'},
        },
      ],
    };
    final after = {
      'layers': [
        {
          'id': 'a',
          'paint': {'fill-color': '#fffffe'},
        },
      ],
    };
    expect(mapStyleFingerprint(before), isNot(mapStyleFingerprint(after)));
  });

  test('it is eight hexadecimal characters', () {
    expect(mapStyleFingerprint(lightThemeData()), matches(r'^[0-9a-f]{8}$'));
  });
}

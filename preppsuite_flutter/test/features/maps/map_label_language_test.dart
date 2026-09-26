import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/map_label_language.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart'
    show ThemeReader;
// ignore: implementation_imports
import 'package:vector_tile_renderer/src/themes/light_theme.dart'
    show lightThemeData;

/// What the offline map calls places.
///
/// The screen showed it plainly: a map of Germany labelled „Germany",
/// „Cologne" and „LOWER SAXONY" in an app that speaks German throughout.
/// The renderer ships the OpenMapTiles demo style, and that style asks
/// the tiles for `{name_en}`.
void main() {
  List<Object?> textFieldsIn(Object? node) => switch (node) {
    List() => [for (final item in node) ...textFieldsIn(item)],
    Map() => [
      for (final entry in node.entries)
        if (entry.key == 'text-field')
          entry.value
        else
          ...textFieldsIn(entry.value),
    ],
    _ => const [],
  };

  test('the built-in style really does ask for English', () {
    // If this ever stops being true, the transformation below has
    // nothing left to do and should go, rather than sit there looking
    // like it works.
    expect(textFieldsIn(lightThemeData()), contains('{name_en}'));
  });

  test('and afterwards it asks for German first', () {
    final fields = textFieldsIn(germanMapLabels(lightThemeData()));

    expect(fields, isNot(contains('{name_en}')));
    expect(fields, isNot(contains('{name}')));
    // `contains` compares with ==, and two lists are never equal that
    // way, so the expected value has to be a matcher of its own.
    expect(
      fields,
      contains(
        equals([
          'coalesce',
          ['get', 'name:de'],
          ['get', 'name'],
          ['get', 'name_de'],
          ['get', 'name_en'],
        ]),
      ),
    );
  });

  test('a road number is not a language', () {
    // `{ref}` is "A 2" in every language, and a coalesce over name
    // fields would blank it out.
    expect(textFieldsIn(germanMapLabels(lightThemeData())), contains('{ref}'));
  });

  test('an expression the style already wrote is left alone', () {
    final style = {
      'layers': [
        {
          'layout': {
            'text-field': [
              'concat',
              ['get', 'name'],
              ' (!)',
            ],
          },
        },
      ],
    };
    expect(germanMapLabels(style), style);
  });

  test('the renderer still reads the style afterwards', () {
    // The point of the whole exercise: a style the parser rejects would
    // leave the map blank, and nothing else here would notice.
    final theme = ThemeReader().read(
      germanMapLabels(lightThemeData()) as Map<String, dynamic>,
    );
    expect(theme.layers, isNotEmpty);
  });
}

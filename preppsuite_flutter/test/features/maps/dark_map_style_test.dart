import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/dark_map_style.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart'
    show ProvidedThemes, ThemeReader;
// ignore: implementation_imports
import 'package:vector_tile_renderer/src/themes/light_theme.dart'
    show lightThemeData;

/// The dark map, made by turning the light one over.
void main() {
  (int, int, int, double) rgba(String value) {
    final match = RegExp(
      r'^rgba\((\d+),(\d+),(\d+),([\d.]+)\)$',
    ).firstMatch(value)!;
    return (
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      double.parse(match.group(4)!),
    );
  }

  group('a colour turned over', () {
    test('white land becomes near-black', () {
      final (r, g, b, _) = rgba(darkenColour('#ffffff')!);
      expect([r, g, b], everyElement(lessThan(40)));
    });

    test('near-black lettering becomes light', () {
      final (r, g, b, _) = rgba(darkenColour('#222')!);
      expect([r, g, b], everyElement(greaterThan(180)));
    });

    test('but neither goes all the way', () {
      // Pure black swallows the hairlines between one surface and the
      // next, and those hairlines are what makes a map readable.
      final white = rgba(darkenColour('#fff')!);
      final black = rgba(darkenColour('#000')!);
      expect(white.$1, greaterThan(0));
      expect(black.$1, lessThan(255));
    });

    test('a park stays green instead of turning magenta', () {
      // What a plain pixel inversion gets wrong, and the reason this
      // works on the style rather than on the rendered image.
      final (r, g, b, _) = rgba(darkenColour('#a8d5a2')!);
      expect(g, greaterThan(r));
      expect(g, greaterThan(b));
    });

    test('transparency is kept', () {
      expect(
        rgba(darkenColour('rgba(255,255,255,0.8)')!).$4,
        closeTo(0.8, 1e-3),
      );
      expect(rgba(darkenColour('#ffffff80')!).$4, closeTo(0.502, 1e-3));
    });

    test('every spelling the shipped style uses is understood', () {
      for (final value in [
        '#fff',
        '#fea',
        '#ffffff',
        '#cfcdca',
        'rgba(255,255,255,0.7)',
        'rgb(255,255,255)',
        'hsl(0, 0%, 100%)',
        'hsla(0, 0%, 100%, 0.5)',
      ]) {
        expect(darkenColour(value), isNotNull, reason: value);
      }
    });

    test('and anything that is not a colour is left alone', () {
      for (final value in ['name:de', 'symbol', '', '#zz', 'rgba(1,2)']) {
        expect(darkenColour(value), isNull, reason: value);
      }
    });
  });

  group('the whole style', () {
    test('every colour in it is turned, wherever it sits', () {
      // Colours live in expressions and stop lists as well as in
      // `paint`, which is why the walk does not know the schema.
      final style = darkenMapStyle(lightThemeData()) as Map<String, dynamic>;
      final text = style.toString();

      expect(text, contains('rgba('));
      expect(RegExp(r'#[0-9a-fA-F]{3}\b').hasMatch(text), isFalse);
    });

    test('and the result is still a style the renderer reads', () {
      // The point of the exercise: it has to come back as a Theme, not
      // just as a plausible-looking map of strings.
      final theme = ThemeReader().read(
        darkenMapStyle(lightThemeData()) as Map<String, dynamic>,
      );

      expect(theme.layers, isNotEmpty);
      expect(theme.layers.length, ProvidedThemes.lightTheme().layers.length);
    });

    test('nothing else about the structure moves', () {
      final light = lightThemeData();
      final dark = darkenMapStyle(light) as Map<String, dynamic>;

      expect(dark.keys, light.keys);
      expect((dark['layers'] as List).length, (light['layers'] as List).length);
    });
  });
}

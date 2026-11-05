import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_theme.dart';

/// WCAG contrast ratio of two opaque colours.
double _contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

/// The roles this file overrides by hand, in both themes.
///
/// `ColorScheme.fromSeed` guarantees its own pairs. Once a role is set by
/// hand nothing does, and a tag in a list row is small print: it has to
/// clear 4.5:1 like any other text.
void main() {
  for (final (name, theme) in [
    ('light', appLightTheme),
    ('dark', appDarkTheme),
  ]) {
    final c = theme.colorScheme;

    group('$name theme', () {
      final pairs = <String, (Color, Color)>{
        'primary': (c.onPrimary, c.primary),
        'primary container': (c.onPrimaryContainer, c.primaryContainer),
        'secondary container': (c.onSecondaryContainer, c.secondaryContainer),
        'tertiary': (c.onTertiary, c.tertiary),
        'tertiary container': (c.onTertiaryContainer, c.tertiaryContainer),
        'error container': (c.onErrorContainer, c.errorContainer),
        'subtitle on a card': (c.onSurfaceVariant, c.surfaceContainerLow),
        'subtitle on the page': (c.onSurfaceVariant, c.surface),
        'section heading': (c.primary, c.surface),
      };

      for (final MapEntry(key: label, value: (text, ground)) in pairs.entries) {
        test('$label is readable', () {
          expect(_contrast(text, ground), greaterThanOrEqualTo(4.5));
        });
      }

      // A bar has no text on it, so the graphics threshold of 3:1 applies,
      // against the track it runs in.
      test('the ochre of a meter stands out from its track', () {
        expect(
          _contrast(c.tertiary, c.surfaceContainerHighest),
          greaterThanOrEqualTo(3),
        );
      });
    });
  }

  test('the palette keeps its identity: green, and ochre for "soon"', () {
    for (final theme in [appLightTheme, appDarkTheme]) {
      final c = theme.colorScheme;
      final green = HSVColor.fromColor(c.primary).hue;
      final ochre = HSVColor.fromColor(c.tertiary).hue;
      expect(green, inInclusiveRange(100, 160));
      expect(ochre, inInclusiveRange(30, 55));
    }
  });
}

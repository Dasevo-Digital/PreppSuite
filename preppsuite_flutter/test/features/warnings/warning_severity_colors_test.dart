import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_theme.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_severity_l10n.dart';
import 'package:preppsuite_flutter/model/categories.dart';

/// The warning colours have to be readable, in both themes.
///
/// This is measured rather than eyeballed because the failure was invisible
/// to reading the code: the background came from a switch that looked
/// perfectly regular, and the foreground came from whatever the surrounding
/// theme happened to supply. Three of the four cases were fine. The fourth
/// was the highest severity there is, at 1.32:1.
void main() {
  /// WCAG relative luminance.
  double luminance(Color color) {
    double channel(double value) => value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// The threshold for body text under WCAG AA.
  const required = 4.5;

  for (final brightness in Brightness.values) {
    group('${brightness.name} theme', () {
      for (final severity in WarningSeverity.values) {
        testWidgets('${severity.name} is legible', (tester) async {
          late WarningSeverityColors colors;

          await tester.pumpWidget(
            MaterialApp(
              // The shipped themes, not a scheme built for the test:
              // the severity ladder is set by hand in `app_theme.dart`
              // and this is what holds it to 4.5:1.
              theme: brightness == Brightness.light
                  ? appLightTheme
                  : appDarkTheme,
              home: Builder(
                builder: (context) {
                  colors = warningSeverityColors(context, severity);
                  return const SizedBox.shrink();
                },
              ),
            ),
          );

          final ratio = contrast(colors.foreground, colors.background);
          expect(
            ratio,
            greaterThanOrEqualTo(required),
            reason:
                '${severity.name} in ${brightness.name}: '
                '${ratio.toStringAsFixed(2)}:1, needs $required:1',
          );
        });
      }
    });
  }
}

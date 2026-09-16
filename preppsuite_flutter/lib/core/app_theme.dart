/// What the app looks like.
///
/// This used to be two lines in `app.dart` -- a seed colour handed to
/// `ThemeData` -- which is Material in its factory setting. It works, and
/// it looks like every other app that does the same.
///
/// Green is the identity and it has to be visible. The first attempt at
/// this file set the warning severities on the scheme's own container
/// roles -- minor on `secondaryContainer`, moderate on
/// `tertiaryContainer` -- which looked reasonable until it was rendered:
/// those roles are also every tonal accent in the app, so a blue
/// "minor" turned every add button in a green app pale blue. Semantic
/// colour and accent colour are two systems and are kept apart. The
/// severity ladder lives in `warning_severity_l10n.dart` as its own
/// palette; this file only sets surfaces, the accent and shapes.
library;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Forest green -- chosen for the prepper and civil-protection subject
/// rather than a generic Material default.
const appSeedColor = Color(0xFF2E7D32);

/// Corner radii, in three sizes and no more.
///
/// Named because they are used in several places and drifting by two
/// pixels between them is exactly the kind of thing nobody notices
/// individually and everybody notices together.
abstract final class AppRadius {
  /// Inputs, chips, buttons.
  static const small = 12.0;

  /// Cards and the blocks a page is built from.
  static const medium = 16.0;

  /// Sheets and dialogs.
  static const large = 28.0;
}

/// Whether this platform expects Apple's conventions.
bool get _isApple =>
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// The ground the app sits on, light.
///
/// Not pure white: a paper-white with a trace of the accent's hue reads
/// as chosen, where #FFFFFF reads as unset.
const _lightSurface = Color(0xFFF1F5EE);
const _darkSurface = Color(0xFF0D1210);

ColorScheme _scheme(Brightness brightness) {
  final base = ColorScheme.fromSeed(
    seedColor: appSeedColor,
    brightness: brightness,
  );

  if (brightness == Brightness.light) {
    // White cards on a tinted ground, rather than two greys a shade
    // apart. The first attempt had card and page within three percent of
    // each other's brightness, and the result read as one flat sheet with
    // hairlines drawn on it.
    return base.copyWith(
      surface: _lightSurface,
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFFFFFFF),
      surfaceContainer: const Color(0xFFF3F6EF),
      surfaceContainerHigh: const Color(0xFFEAEFE5),
      surfaceContainerHighest: const Color(0xFFE2E8DC),
      outlineVariant: const Color(0xFFCBD5C6),
      secondaryContainer: const Color(0xFFCCE9D4),
      onSecondaryContainer: const Color(0xFF10301C),
    );
  }

  return base.copyWith(
    surface: _darkSurface,
    surfaceContainerLowest: const Color(0xFF080C0A),
    surfaceContainerLow: const Color(0xFF18201C),
    surfaceContainer: const Color(0xFF1D2622),
    surfaceContainerHigh: const Color(0xFF263029),
    surfaceContainerHighest: const Color(0xFF303B34),
    outlineVariant: const Color(0xFF34413A),
    primary: const Color(0xFF6FDD97),
    onPrimary: const Color(0xFF00391B),
    primaryContainer: const Color(0xFF1E5334),
    onPrimaryContainer: const Color(0xFFBFF3D0),
    secondaryContainer: const Color(0xFF244A33),
    onSecondaryContainer: const Color(0xFFBEE9CC),
  );
}

/// A type scale with more contrast between a heading and its text than
/// Material's default, which on a dense screen like the overview reads as
/// one long grey block.
TextTheme _textTheme(TextTheme base) => base.copyWith(
  headlineSmall: base.headlineSmall?.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  ),
  titleLarge: base.titleLarge?.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  ),
  titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  // Labels that sit above a group of numbers, in small caps spacing.
  labelSmall: base.labelSmall?.copyWith(letterSpacing: 0.6),
);

ThemeData _theme(Brightness brightness) {
  final scheme = _scheme(brightness);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);

  return base.copyWith(
    textTheme: _textTheme(base.textTheme),
    scaffoldBackgroundColor: scheme.surface,

    // Apple's own apps do not tint the bar when content scrolls under it,
    // and on a page made of cards the tint reads as a rendering glitch.
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: _isApple,
      titleTextStyle: _textTheme(base.textTheme).titleLarge,
    ),

    // Outlined rather than raised. Elevation on a dark ground is a lighter
    // rectangle, which on this palette fights the surface steps; a hairline
    // says "this belongs together" without changing the brightness.
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),

    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      side: BorderSide(color: scheme.outlineVariant),
    ),

    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surface,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    ),

    // The swipe-from-the-edge gesture and the sliding transition, on both
    // Apple platforms. Flutter does this for iOS on its own; macOS gets
    // the zoom transition by default, which is an Android idiom.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}

ThemeData get appLightTheme => _theme(Brightness.light);
ThemeData get appDarkTheme => _theme(Brightness.dark);

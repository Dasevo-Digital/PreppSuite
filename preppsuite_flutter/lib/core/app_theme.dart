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

import 'selectable_everywhere.dart';

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

/// The steps every distance on a page is taken from.
///
/// Named for the same reason as [AppRadius]. Screens grew their own 10s
/// and 14s, and the page reads as untidy without anybody being able to say
/// why.
abstract final class AppSpace {
  /// Between lines that belong to one thing.
  static const xs = 4.0;

  /// Inside a row, between an icon and its text.
  static const sm = 8.0;

  /// Between the blocks of a page.
  static const md = 12.0;

  /// The side margin of a page, and the inside of a card.
  static const lg = 16.0;

  /// Above a new section.
  static const xl = 24.0;
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
      // Sage rather than what the seed produces. The generated container
      // is a bright lime, and a lime button on this muted ground was the
      // loudest thing on every list.
      primaryContainer: const Color(0xFFC5E6CD),
      onPrimaryContainer: const Color(0xFF0E2E1A),
      secondaryContainer: const Color(0xFFCCE9D4),
      onSecondaryContainer: const Color(0xFF10301C),
      // Ochre, for "look at this soon". The seed's tertiary is a cool cyan
      // that belongs to no part of this palette and said nothing: "low
      // stock" came out pale blue, the colour of a harmless note.
      tertiary: const Color(0xFF8A6500),
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFFBE7B8),
      onTertiaryContainer: const Color(0xFF2C1F00),
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
    // A deep red for a filled area, not the saturated one the seed gives.
    // It is the same as the severe rung of the warning ladder, and this is
    // an app somebody opens in the dark.
    errorContainer: const Color(0xFF5C1A10),
    onErrorContainer: const Color(0xFFFFDAD4),
    tertiary: const Color(0xFFE8C26C),
    onTertiary: const Color(0xFF3D2E00),
    tertiaryContainer: const Color(0xFF4B3B12),
    onTertiaryContainer: const Color(0xFFFCE8BA),
  );
}

/// A type scale with more contrast between a heading and its text than
/// Material's default, which on a dense screen like the overview reads as
/// one long grey block.
///
/// Running text is set closer than Material's default as well. Its 0.5 of
/// tracking is meant for a small phone in the 2018 sense; on the labels and
/// sentences this app is made of, it spreads a line until it wraps once
/// more than it has to.
TextTheme _textTheme(TextTheme base) => base.copyWith(
  headlineSmall: base.headlineSmall?.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  ),
  // Twenty rather than Material's twenty-two: this is the page title and
  // the heading of a section at once, and at twenty-two the headings of a
  // page stood taller than anything they were heading.
  titleLarge: base.titleLarge?.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  ),
  titleMedium: base.titleMedium?.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  ),
  titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  bodyLarge: base.bodyLarge?.copyWith(letterSpacing: 0.1),
  bodyMedium: base.bodyMedium?.copyWith(letterSpacing: 0.1),
  bodySmall: base.bodySmall?.copyWith(letterSpacing: 0.15),
  labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  labelMedium: base.labelMedium?.copyWith(letterSpacing: 0.2),
  // Labels that sit above a group of numbers, in small caps spacing.
  labelSmall: base.labelSmall?.copyWith(letterSpacing: 0.6),
);

ThemeData _theme(Brightness brightness) {
  final scheme = _scheme(brightness);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  // With the type scale in it. `base.textTheme` carries colours and no
  // sizes: Flutter merges those in when a screen reads `Theme.of`, which is
  // too late for the styles handed to the component themes below. A style
  // taken from it has no font size at all and falls back to 14, which is
  // how the page titles went unnoticed at 14 and list titles came out
  // smaller than they were meant to.
  final text = _textTheme(Typography.englishLike2021.merge(base.textTheme));

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,

    // Apple's own apps do not tint the bar when content scrolls under it,
    // and on a page made of cards the tint reads as a rendering glitch.
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: _isApple,
      titleTextStyle: text.titleLarge,
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

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
    ),

    // The one thing a list asks you to do, in the colour of the app. On
    // the seed's container it was the brightest object on the page without
    // being the most important one. The elevation is the only shadow left
    // in the app, and it is one rectangle.
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      extendedTextStyle: text.labelLarge,
    ),

    expansionTileTheme: ExpansionTileThemeData(
      shape: const RoundedRectangleBorder(),
      collapsedShape: const RoundedRectangleBorder(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.only(bottom: 8),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.small),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
    ),

    // Title and subtitle told apart by weight as well as by colour: a list
    // of entries that are all the same size reads as one grey block.
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      titleTextStyle: text.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      iconColor: scheme.onSurfaceVariant,
      horizontalTitleGap: AppSpace.md,
    ),

    // The colours by name, not left to the styles. A label style carrying a
    // colour wins over the defaults, and both of these carry `onSurface`,
    // so the chosen tab differed from the others by its weight alone.
    tabBarTheme: TabBarThemeData(
      dividerColor: scheme.outlineVariant,
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    ),

    // Floating and rounded like everything else that lies over a page. It
    // sits above the bar instead of pushing the floating button up.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      elevation: 2,
    ),

    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
      indicatorColor: scheme.secondaryContainer,
      // Where you are is said by the weight of its name too, and not only
      // by the pale shape behind the icon.
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.secondaryContainer,
      labelType: NavigationRailLabelType.all,
      useIndicator: true,
      selectedLabelTextStyle: text.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      unselectedLabelTextStyle: text.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
    ),

    // The swipe-from-the-edge gesture and the sliding transition, on both
    // Apple platforms. Flutter does this for iOS on its own; macOS gets
    // the zoom transition by default, which is an Android idiom. Each one
    // also makes the screen inside it selectable (#39).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: SelectablePageTransitions(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.macOS: SelectablePageTransitions(
          CupertinoPageTransitionsBuilder(),
        ),
        TargetPlatform.android: SelectablePageTransitions(
          ZoomPageTransitionsBuilder(),
        ),
        TargetPlatform.linux: SelectablePageTransitions(
          FadeUpwardsPageTransitionsBuilder(),
        ),
        TargetPlatform.windows: SelectablePageTransitions(
          FadeUpwardsPageTransitionsBuilder(),
        ),
        TargetPlatform.fuchsia: SelectablePageTransitions(
          ZoomPageTransitionsBuilder(),
        ),
      },
    ),
  );
}

ThemeData get appLightTheme => _theme(Brightness.light);
ThemeData get appDarkTheme => _theme(Brightness.dark);

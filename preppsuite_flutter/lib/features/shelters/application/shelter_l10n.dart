import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'shelter_bearing.dart';
import 'shelter_classification.dart';

String localizeCompassPoint(AppLocalizations l10n, CompassPoint point) {
  return switch (point) {
    CompassPoint.north => l10n.shelterDirectionNorth,
    CompassPoint.northEast => l10n.shelterDirectionNorthEast,
    CompassPoint.east => l10n.shelterDirectionEast,
    CompassPoint.southEast => l10n.shelterDirectionSouthEast,
    CompassPoint.south => l10n.shelterDirectionSouth,
    CompassPoint.southWest => l10n.shelterDirectionSouthWest,
    CompassPoint.west => l10n.shelterDirectionWest,
    CompassPoint.northWest => l10n.shelterDirectionNorthWest,
  };
}

/// The confidence in words.
///
/// The legend labels, which are the words the screen already teaches: the
/// three colours are explained once at the top, so naming them the same
/// way in the list means the explanation covers both. It also means the
/// colour is never the only thing carrying the grade — which it was on the
/// markers, where a green and a red shield differ in nothing else.
String localizeShelterConfidence(
  AppLocalizations l10n,
  ShelterConfidence confidence,
) {
  return switch (confidence) {
    ShelterConfidence.green => l10n.shelterLegendGreenLabel,
    ShelterConfidence.yellow => l10n.shelterLegendYellowLabel,
    ShelterConfidence.red => l10n.shelterLegendRedLabel,
  };
}

/// How far and which way, in one phrase.
///
/// Metres below a kilometre and one decimal above: "1200 m" is harder to
/// judge at a glance than "1,2 km", and "0,3 km" is a needlessly precise
/// way of writing 300 m.
String formatShelterDistance(
  AppLocalizations l10n,
  double meters,
  CompassPoint direction,
) {
  final where = localizeCompassPoint(l10n, direction);
  if (meters < 1000) {
    // To the nearest ten: the coordinates are not good to the metre, and a
    // figure like "287 m" claims they are.
    return l10n.shelterDistanceMeters((meters / 10).round() * 10, where);
  }
  // Through `NumberFormat` and not `toStringAsFixed`: that one always
  // writes a point, so a German screen read "1.1 km" while every other
  // number on it read "1,1".
  return l10n.shelterDistanceKilometers(
    NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 1,
    ).format(meters / 1000),
    where,
  );
}

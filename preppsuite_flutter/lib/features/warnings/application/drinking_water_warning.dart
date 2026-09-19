/// Whether a warning is about the drinking water.
///
/// There is no CAP code for this. The BBK feed carries KATWARN messages
/// whose titles are machine-built as `<Absender> meldet: <Warnung>` —
/// `warning_ingest.dart` documents one confirmed on the live feed,
/// "Vogelsbergkreis meldet: Warnung Trinkwasserunfall" — and the event
/// type is free text from whoever sent it. So this matches words, which
/// is a guess, and it is built to fail in the harmless direction.
///
/// **It adds, it never hides.** A match puts one extra card in front of
/// somebody: how long their own stored water lasts, and where the map
/// knows drinking water nearby. A false positive costs a card beside a
/// warning that is shown in full either way; a miss costs only that card.
/// Nothing is filtered out and no warning is reworded.
///
/// What it deliberately does not do is say what to do with the water.
/// Boiling times were researched and rejected for this app: the CDC, the
/// WHO and the UBA give different ones, and shipping a number none of
/// them agrees on would be the invented scale this app refuses. The
/// authority's own instruction is printed instead.
library;

import '../../../local_db/database.dart';

/// Lower-case fragments that mean the drinking water, in the wording the
/// German and English feeds actually use.
const _markers = {
  'trinkwasser',
  'abkochgebot',
  'abkochanordnung',
  'abkochanweisung',
  'wasserverunreinigung',
  'wasserversorgung',
  'boil water',
  'drinking water',
  'water supply',
};

bool isDrinkingWaterWarning(Warning warning) {
  final haystack = [
    warning.eventType,
    warning.headline,
  ].join(' ').toLowerCase();
  return _markers.any(haystack.contains);
}

/// The drinking-water warnings among [warnings], in the order given.
List<Warning> drinkingWaterWarnings(Iterable<Warning> warnings) => [
  for (final warning in warnings)
    if (isDrinkingWaterWarning(warning)) warning,
];

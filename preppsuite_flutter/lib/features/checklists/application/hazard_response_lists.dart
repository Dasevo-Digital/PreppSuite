import '../../search/application/app_search.dart' show foldForSearch;

/// Which list of steps answers which warning.
///
/// A warning names its event — "Hochwasser", "Orkanartige Böen",
/// "Hitzewarnung" — and the app holds, offline, a list of what to do in
/// exactly that situation. Until this existed the two never met: the only
/// thing a warning offered was the official page in a browser, on the one
/// screen somebody opens because something is happening.
///
/// Matching is by keyword against the folded event text rather than by an
/// exact table, because the wording is the issuing service's and changes
/// with it: the DWD alone says "Sturmböen", "Schwere Sturmböen",
/// "Orkanartige Böen" and "Orkanböen" for one family of weather.
///
/// The keywords are written the way [foldForSearch] leaves them: it turns
/// an umlaut into its bare vowel, so "Böen" arrives as `boen` and not as
/// `boeen`. A keyword spelled the German way would match nothing at all,
/// silently.
const _matches = <String, List<String>>{
  // Hochwasser: wenn es soweit ist
  '00000000-0000-4000-8000-000000000020': [
    'hochwasser',
    'uberschwemmung',
    'starkregen',
    'sturzflut',
    'dauerregen',
    // Before the storm list, and on purpose: "Sturmflut" begins with
    // "Sturm" and would otherwise be answered with "Fenster schliessen,
    // innen liegender Raum". What comes in a storm surge is water.
    'sturmflut',
  ],
  // Sturm und Unwetter: wenn es soweit ist
  '00000000-0000-4000-8000-000000000021': [
    'sturm',
    'orkan',
    'boen',
    'gewitter',
    'hagel',
    'unwetter',
    'tornado',
  ],
  // Hitze und Dürre
  '00000000-0000-4000-8000-000000000012': ['hitze', 'durre'],
};

/// The list that answers [eventType], or null.
///
/// Null is the ordinary answer for most warnings and not a gap to be
/// filled with the nearest list. A warning about black ice, a power cut
/// or a chemical release is better served by no suggestion than by
/// "Sturm und Unwetter" — an offer that does not fit is worse than none
/// on a screen somebody is reading in a hurry.
String? responseListFor(String eventType) {
  final folded = foldForSearch(eventType);
  if (folded.isEmpty) return null;
  for (final entry in _matches.entries) {
    for (final keyword in entry.value) {
      if (folded.contains(keyword)) return entry.key;
    }
  }
  return null;
}

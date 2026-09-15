import 'first_aid_guide.dart';
import 'first_aid_guides_de.dart';
import 'first_aid_guides_en.dart';

export 'first_aid_guide.dart';

/// The guides in the language being read.
///
/// German is the fallback rather than English: this is a German app for a
/// German emergency system, and a locale nobody has translated is far
/// likelier to be a German speaker's regional variant than an English
/// reader.
List<FirstAidGuide> firstAidGuides(String localeName) {
  return localeName.toLowerCase().startsWith('en')
      ? firstAidGuidesEn
      : firstAidGuidesDe;
}

/// One guide by its id, in the language being read.
///
/// Null rather than an exception: the id can come from a downloaded video
/// pack, and a pack naming a guide this version does not have is a thing
/// to ignore, not to crash on.
FirstAidGuide? firstAidGuide(String localeName, String id) {
  for (final guide in firstAidGuides(localeName)) {
    if (guide.id == id) return guide;
  }
  return null;
}

/// The guides of one group, in list order.
List<FirstAidGuide> firstAidGuidesIn(String localeName, FirstAidGroup group) {
  return [
    for (final guide in firstAidGuides(localeName))
      if (guide.group == group) guide,
  ];
}

/// Every id the app knows, which is what a video pack is checked against.
Set<String> get firstAidGuideIds => {
  for (final guide in firstAidGuidesDe) guide.id,
};

/// Guides whose title or opening line matches [query].
///
/// Searches the "when" line as well as the title on purpose: somebody
/// looking for what to do about a wasp sting types "Stich", and the guide
/// they need is called "Allergischer Schock".
List<FirstAidGuide> searchFirstAidGuides(String localeName, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return firstAidGuides(localeName);
  return [
    for (final guide in firstAidGuides(localeName))
      if (guide.title.toLowerCase().contains(needle) ||
          guide.when.toLowerCase().contains(needle))
        guide,
  ];
}

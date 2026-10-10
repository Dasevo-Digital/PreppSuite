import '../../../l10n/generated/app_localizations.dart';

/// Archives worth starting with, in the order they are offered.
///
/// The Kiwix library holds thousands of files with names like
/// `wikiversity_de_all_maxi_2026-01`, and the search box is no help to
/// somebody who does not already know what to type. This is the answer to
/// "what should I download first", written down.
///
/// Each one is a search rather than a URL. Kiwix dates its filenames and
/// rebuilds them every few months, so a hard-coded link would be a dead
/// link within the year; a query keeps finding the current build.
///
/// What helps in a crisis comes first (#38): medicine, repair, and the
/// three English collections made for exactly this -- water treatment,
/// what to do after a disaster, appropriate technology. Wikipedia answers
/// most questions and is the largest download, and it was the first thing
/// anybody reached for; it is further down on purpose, so that the
/// smaller archive that answers the urgent question is found first.
///
/// Schooling is the reason much of the rest exists. If public life stops
/// for a season, the thing a household misses first after food and heat is
/// somewhere for the children to keep learning — and Khan Academy, the
/// obvious answer, has no German archive at all. What German does have is
/// Wikibooks, Klexikon, PhET and Wikiversity, so those come first.
enum RecommendedArchive {
  /// A focused, German medical encyclopedia. It is deliberately offered
  /// instead of making a person hunt through the general encyclopedia.
  medicine(name: 'WikiMed', query: 'wikimed', language: 'deu'),

  /// Repair instructions for household appliances and electronics, with
  /// pictures, in German.
  ifixit(name: 'iFixit', query: 'ifixit', language: 'deu'),

  /// Water collection and purification, from the openZIM "zimgit"
  /// collections. English only, and there is no German equivalent.
  waterTreatment(
    name: 'Water Treatment Library',
    query: 'water treatment',
    language: 'eng',
  ),

  /// Shelter, sanitation, health and food after a disaster -- the
  /// companion collection to the one above. English only.
  postDisaster(
    name: 'Post Disaster Resource Library',
    query: 'post disaster',
    language: 'eng',
  ),

  /// Appropriate technology: water, sanitation, energy and building with
  /// what is at hand. English only.
  appropedia(name: 'Appropedia', query: 'appropedia', language: 'eng'),

  /// German school lessons: Wikibooks carries "Mathe für Nicht-Freaks",
  /// which is a full secondary and undergraduate maths course.
  wikibooks(name: 'Wikibooks', query: 'wikibooks', language: 'deu'),

  /// The German children's encyclopedia — written for primary school and
  /// readable by them without help.
  klexikon(name: 'Klexikon', query: 'klexikon', language: 'deu'),

  /// Interactive physics, chemistry and maths simulations, in German.
  /// They run inside the archive, which is unusual and worth having.
  phet(name: 'PhET', query: 'phet', language: 'deu'),

  /// Course and teaching material, German.
  wikiversity(name: 'Wikiversity', query: 'wikiversity', language: 'deu'),

  /// The one that answers most questions, and the largest download.
  wikipedia(name: 'Wikipedia', query: 'wikipedia', language: 'deu'),

  /// Only in English, Spanish and French — but it is the school
  /// curriculum end to end, so it is here for anyone who reads English.
  khanAcademy(name: 'Khan Academy', query: 'khan academy', language: 'eng');

  const RecommendedArchive({
    required this.name,
    required this.query,
    required this.language,
  });

  /// What the archive is called. Not translated — these are proper names.
  final String name;

  /// What to put in the library's search box.
  final String query;

  /// ISO 639-3, which is what the catalogue speaks.
  final String language;

  /// Catalogue names are versioned, but retain the family name. Comparing
  /// that small stable part tells APOLLO which of its suggestions already
  /// exists locally without depending on a dated filename.
  bool isInstalled(Iterable<String> labels) {
    final needle = switch (this) {
      RecommendedArchive.medicine => 'wikimed',
      RecommendedArchive.khanAcademy => 'khan academy',
      _ => name.toLowerCase(),
    };
    return labels.any((label) => label.toLowerCase().contains(needle));
  }
}

String recommendedArchiveDescription(
  AppLocalizations l10n,
  RecommendedArchive archive,
) {
  return switch (archive) {
    RecommendedArchive.wikibooks => l10n.knowledgeSuggestionWikibooks,
    RecommendedArchive.klexikon => l10n.knowledgeSuggestionKlexikon,
    RecommendedArchive.phet => l10n.knowledgeSuggestionPhet,
    RecommendedArchive.wikiversity => l10n.knowledgeSuggestionWikiversity,
    RecommendedArchive.wikipedia => l10n.knowledgeSuggestionWikipedia,
    RecommendedArchive.medicine => l10n.knowledgeSuggestionMedicine,
    RecommendedArchive.ifixit => l10n.knowledgeSuggestionIfixit,
    RecommendedArchive.waterTreatment => l10n.knowledgeSuggestionWater,
    RecommendedArchive.postDisaster => l10n.knowledgeSuggestionPostDisaster,
    RecommendedArchive.appropedia => l10n.knowledgeSuggestionAppropedia,
    RecommendedArchive.khanAcademy => l10n.knowledgeSuggestionKhan,
  };
}

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
/// Schooling is the reason half of this list exists. If public life stops
/// for a season, the thing a household misses first after food and heat is
/// somewhere for the children to keep learning — and Khan Academy, the
/// obvious answer, has no German archive at all. What German does have is
/// Wikibooks, Klexikon, PhET and Wikiversity, so those come first.
enum RecommendedArchive {
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

  /// Wikipedia's medical articles alone — a fraction of the size, and the
  /// part that matters when no practice is open.
  medicine(name: 'Wikipedia Medizin', query: 'medizin', language: 'deu'),

  /// Repair instructions for household appliances and electronics, with
  /// pictures, in German.
  ifixit(name: 'iFixit', query: 'ifixit', language: 'deu'),

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
    RecommendedArchive.khanAcademy => l10n.knowledgeSuggestionKhan,
  };
}

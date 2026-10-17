/// A phrasebook for an emergency, offline from the first start (#181).
///
/// Short sentences somebody needs when there is no common language and no
/// network: calling for help, saying where it hurts, asking for water or
/// the shelter, looking for a child -- and answers the other person can
/// point at. Fixed sentences rather than a machine translation: they can
/// be read through once and are the same every time, and a free
/// translator (#182) is a project of its own.
///
/// **The translations have not been checked by native speakers.** They
/// are kept short and plain on purpose, and the screen says so. A
/// language whose sentences somebody has checked is marked in
/// [reviewedPhraseLanguages], and only then does the note go away for it.
library;

part 'phrasebook_phrases.dart';

/// The languages a phrase is given in. German, English and Spanish are
/// the app's own; the rest are the ones most often needed in Germany
/// beside them.
enum PhraseLanguage {
  de('Deutsch'),
  en('English'),
  es('Español'),
  fr('Français'),
  pl('Polski'),
  tr('Türkçe'),
  ru('Русский'),
  uk('Українська'),
  ar('العربية'),
  fa('فارسی');

  const PhraseLanguage(this.endonym);

  /// The language's name in itself, which is what somebody looking for
  /// it recognises whatever language the app is in.
  final String endonym;

  /// Written right to left.
  bool get isRtl => this == PhraseLanguage.ar || this == PhraseLanguage.fa;

  /// The phrase language for an app locale, German for any other.
  static PhraseLanguage forLocale(String languageCode) =>
      PhraseLanguage.values.asNameMap()[languageCode] ?? PhraseLanguage.de;
}

/// Languages whose sentences a native speaker has read through. None yet.
const reviewedPhraseLanguages = <PhraseLanguage>{};

enum PhraseGroup { basics, emergency, health, shelter, people, answers }

class Phrase {
  const Phrase(this.id, this.group, this.text);

  /// Stable, never shown.
  final String id;
  final PhraseGroup group;
  final Map<PhraseLanguage, String> text;

  String operator [](PhraseLanguage language) => text[language]!;
}

/// The phrases of [group], in their order.
List<Phrase> phrasesIn(PhraseGroup group) => [
  for (final phrase in phrasebookPhrases)
    if (phrase.group == group) phrase,
];

/// The phrases whose [from] or [to] text contains every word of [query],
/// ignoring case. Empty query, every phrase.
List<Phrase> searchPhrases(
  String query, {
  required PhraseLanguage from,
  required PhraseLanguage to,
}) {
  final words = query.toLowerCase().trim().split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return phrasebookPhrases;
  return [
    for (final phrase in phrasebookPhrases)
      if (words.every(
        (w) =>
            phrase[from].toLowerCase().contains(w) ||
            phrase[to].toLowerCase().contains(w),
      ))
        phrase,
  ];
}

/// The official translations that come with a BBK warning (#357).
///
/// The BBK sends every MoWaS and DWD warning with `info` blocks in German,
/// in Leichte Sprache (MoWaS only), English, Arabic, Spanish, French,
/// Polish, Russian and Turkish. The app took the German one and threw the
/// rest away, so somebody using it in Spanish read "Trinken Sie kein
/// Leitungswasser" in German while the Spanish words had come in the same
/// answer.
///
/// German stays the version the app reasons with: relevance, drinking
/// water and the response lists all match German words, and the
/// acknowledgement compares the German row. The translations are only
/// shown.
library;

import 'dart:convert';

import '../../../local_db/database.dart';

/// The languages the BBK translates into, in the order offered.
const warningTranslationLanguages = [
  'de-ls',
  'en',
  'es',
  'fr',
  'pl',
  'ru',
  'tr',
  'ar',
];

/// Each language named in itself, as a picker shows it; Leichte Sprache is
/// named by the app's own text, because it is not a language of its own.
const warningLanguageEndonyms = {
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'pl': 'Polski',
  'ru': 'Русский',
  'tr': 'Türkçe',
  'ar': 'العربية',
};

/// One version of a warning's words.
class WarningText {
  const WarningText({
    required this.event,
    required this.headline,
    this.description,
    this.instruction,
  });

  final String event;
  final String headline;
  final String? description;
  final String? instruction;

  Map<String, String> toJson() => {
    'event': event,
    'headline': headline,
    'description': ?description,
    'instruction': ?instruction,
  };

  static WarningText? fromJson(Object? json) {
    if (json is! Map) return null;
    final headline = json['headline'];
    if (headline is! String || headline.trim().isEmpty) return null;
    final event = json['event'];
    final description = json['description'];
    final instruction = json['instruction'];
    return WarningText(
      event: event is String && event.isNotEmpty ? event : headline,
      headline: headline,
      description: description is String ? description : null,
      instruction: instruction is String ? instruction : null,
    );
  }
}

/// A CAP language tag as this app keys it: lower case, German's regional
/// form folded onto `de`.
String normalizeCapLanguage(String raw) {
  final tag = raw.trim().toLowerCase().replaceAll('_', '-');
  return tag == 'de-de' ? 'de' : tag;
}

/// What is stored, with the keys in order so that the same translations
/// always make the same text and an unchanged warning stays unchanged.
String encodeWarningTranslations(Map<String, WarningText> translations) =>
    jsonEncode({
      for (final language in translations.keys.toList()..sort())
        language: translations[language]!.toJson(),
    });

Map<String, WarningText> decodeWarningTranslations(String? stored) {
  if (stored == null || stored.isEmpty) return const {};
  try {
    final json = jsonDecode(stored);
    if (json is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in json.entries)
        '$key': ?WarningText.fromJson(value),
    };
  } on FormatException {
    return const {};
  }
}

/// Whether [language] is written right to left.
bool isRightToLeft(String language) => language == 'ar';

extension WarningLanguages on Warning {
  /// The German words, as stored.
  WarningText get germanText => WarningText(
    event: eventType,
    headline: headline,
    description: description,
    instruction: instruction,
  );

  /// The official translation into [language], or null.
  WarningText? translationIn(String language) =>
      decodeWarningTranslations(translationsJson)[normalizeCapLanguage(
        language,
      )];

  /// What to show in an app set to [appLanguage]: its translation where
  /// the BBK sent one, the German otherwise.
  WarningText textIn(String appLanguage) {
    final language = normalizeCapLanguage(appLanguage).split('-').first;
    if (language == 'de') return germanText;
    return translationIn(language) ?? germanText;
  }

  /// Whether [textIn] gives something other than the German.
  bool isTranslatedFor(String appLanguage) {
    final language = normalizeCapLanguage(appLanguage).split('-').first;
    return language != 'de' && translationIn(language) != null;
  }
}

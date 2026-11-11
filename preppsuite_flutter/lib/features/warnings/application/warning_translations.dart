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
///
/// **What MoWaS translates is not a headline.** Its blocks carry the
/// event's name in the `headline` field ("Power outage") and the German
/// description unchanged; only what to do is translated in full. The
/// German headline is the one that says "Entwarnung", "1. AKTUALISIERUNG"
/// and where. Shown instead of it, the name made an all-clear look like a
/// danger in force, and two warnings for different towns read the same.
/// So a MoWaS translation's headline is kept as the event's name, and the
/// title puts it in front of the German headline. DWD translates
/// everything, its headline included.
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

/// One complete version of a warning's words, as shown.
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
}

/// What one language says differently from the German, and nothing else.
///
/// Stored this way because MoWaS repeats the German description in every
/// block: kept whole, a warning's translations came to eight times its
/// German text, and every list and every poll loaded them.
class WarningTranslation {
  const WarningTranslation({
    this.event,
    this.headline,
    this.description,
    this.instruction,
  });

  /// The event's name, where the language has one of its own.
  final String? event;

  /// A translation of the whole headline; null where only the event's name
  /// was translated (MoWaS).
  final String? headline;
  final String? description;
  final String? instruction;

  bool get isEmpty =>
      event == null &&
      headline == null &&
      description == null &&
      instruction == null;

  /// The heading a section in this language starts with.
  String? get heading => headline ?? event;

  Map<String, String> toJson() => {
    'event': ?event,
    'headline': ?headline,
    'description': ?description,
    'instruction': ?instruction,
  };

  static WarningTranslation? fromJson(Object? json) {
    if (json is! Map) return null;
    String? field(String key) => switch (json[key]) {
      final String value when value.trim().isNotEmpty => value,
      _ => null,
    };
    final translation = WarningTranslation(
      event: field('event'),
      headline: field('headline'),
      description: field('description'),
      instruction: field('instruction'),
    );
    return translation.isEmpty ? null : translation;
  }
}

/// Whether a source's translated `headline` translates the headline. Only
/// DWD's does; MoWaS names the event there, and for the others it is not
/// known, so the German headline stays.
bool bbkTranslatesHeadline(String externalId) => externalId.startsWith('dwd.');

/// [translated] reduced to what differs from [german]. Null when nothing
/// does.
///
/// [translatesHeadline] says whether [translated]'s headline is one (see
/// [bbkTranslatesHeadline]); where not, it is kept as the event's name.
WarningTranslation? compactWarningTranslation({
  required WarningText german,
  required WarningText translated,
  required bool translatesHeadline,
}) {
  String? differing(String? value, String? original) =>
      value == null || value.trim().isEmpty || value == original ? null : value;

  final translation = WarningTranslation(
    event: translatesHeadline
        ? differing(translated.event, german.event)
        : differing(translated.headline, german.headline),
    headline: translatesHeadline
        ? differing(translated.headline, german.headline)
        : null,
    description: differing(translated.description, german.description),
    instruction: differing(translated.instruction, german.instruction),
  );
  return translation.isEmpty ? null : translation;
}

/// A CAP language tag as this app keys it: lower case, German's regional
/// form folded onto `de`.
String normalizeCapLanguage(String raw) {
  final tag = raw.trim().toLowerCase().replaceAll('_', '-');
  return tag == 'de-de' ? 'de' : tag;
}

/// What is stored, with the keys in order so that the same translations
/// always make the same text and an unchanged warning stays unchanged.
String encodeWarningTranslations(
  Map<String, WarningTranslation> translations,
) => jsonEncode({
  for (final language in translations.keys.toList()..sort())
    language: translations[language]!.toJson(),
});

Map<String, WarningTranslation> decodeWarningTranslations(String? stored) {
  if (stored == null || stored.isEmpty) return const {};
  try {
    final json = jsonDecode(stored);
    if (json is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in json.entries)
        '$key': ?WarningTranslation.fromJson(value),
    };
  } on FormatException {
    return const {};
  }
}

/// Whether [language] is written right to left.
bool isRightToLeft(String language) => language == 'ar';

/// "Entwarnung:" at the start of a German headline, as MoWaS writes an
/// all-clear, with a colon or a dash.
final _leadingAllClear = RegExp(
  r'^\s*entwarnung\s*[:\-–]\s*',
  caseSensitive: false,
);

/// The two-letter language [appLanguage] stands for.
String _baseLanguage(String appLanguage) =>
    normalizeCapLanguage(appLanguage).split('-').first;

extension WarningLanguages on Warning {
  /// The German words, as stored.
  WarningText get germanText => WarningText(
    event: eventType,
    headline: headline,
    description: description,
    instruction: instruction,
  );

  /// Whether the publisher marked this version as the end of the warning.
  bool get isAllClear => messageType == 'Cancel';

  /// What the BBK translated into [language], or null.
  WarningTranslation? translationIn(String language) =>
      decodeWarningTranslations(translationsJson)[normalizeCapLanguage(
        language,
      )];

  /// What to show in an app set to [appLanguage]: its translation where
  /// the BBK sent one, the German wherever it did not.
  WarningText textIn(String appLanguage) =>
      _textIn(appLanguage, germanHeadline: headline);

  WarningText _textIn(String appLanguage, {required String germanHeadline}) {
    final language = _baseLanguage(appLanguage);
    final german = germanText;
    if (language == 'de') return german;
    final translation = translationIn(language);
    if (translation == null) {
      return WarningText(
        event: german.event,
        headline: germanHeadline,
        description: german.description,
        instruction: german.instruction,
      );
    }
    return WarningText(
      event: translation.event ?? german.event,
      headline:
          translation.headline ??
          switch (translation.event) {
            final event? => '$event – $germanHeadline',
            null => germanHeadline,
          },
      description: translation.description ?? german.description,
      instruction: translation.instruction ?? german.instruction,
    );
  }

  /// What a list, a banner or a notification calls this warning in
  /// [appLanguage]. [allClear] puts the app's word for an all-clear in
  /// front where the version ends its warning. German needs none: its
  /// headline says "Entwarnung" itself.
  ///
  /// Where the word stands in front, the German "Entwarnung:" after it is
  /// left off (#367). It said the same twice, and on a two-line banner the
  /// twelve characters were the ones that pushed the place out of sight.
  String titleIn(String appLanguage, {String Function(String)? allClear}) {
    if (!isAllClear || allClear == null || _baseLanguage(appLanguage) == 'de') {
      return textIn(appLanguage).headline;
    }
    final rest = headline.replaceFirst(_leadingAllClear, '');
    return allClear(
      _textIn(
        appLanguage,
        germanHeadline: rest.trim().isEmpty ? headline : rest,
      ).headline,
    );
  }

  /// Whether [textIn] gives anything other than the German.
  bool isTranslatedFor(String appLanguage) {
    final language = _baseLanguage(appLanguage);
    return language != 'de' && translationIn(language) != null;
  }

  /// Whether every part of the text is in [appLanguage]: one voice can
  /// read it then. A MoWaS translation leaves the description German.
  bool isWhollyTranslatedFor(String appLanguage) {
    final language = _baseLanguage(appLanguage);
    if (language == 'de') return false;
    final translation = translationIn(language);
    return translation != null &&
        translation.headline != null &&
        (description == null || translation.description != null) &&
        (instruction == null || translation.instruction != null);
  }

  /// Every word of every version, for a search.
  Iterable<String> get searchableTexts sync* {
    yield headline;
    if (description case final text?) yield text;
    yield eventType;
    for (final translation in decodeWarningTranslations(
      translationsJson,
    ).values) {
      if (translation.event case final text?) yield text;
      if (translation.headline case final text?) yield text;
      if (translation.description case final text?) yield text;
      if (translation.instruction case final text?) yield text;
    }
  }
}

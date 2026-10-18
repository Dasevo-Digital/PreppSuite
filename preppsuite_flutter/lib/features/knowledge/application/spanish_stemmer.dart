/// The Snowball Spanish stemmer, in Dart (#194).
///
/// A transcription of `spanish.sbl` as Snowball 2 has it, checked against
/// Snowball's own expected output for its test vocabulary, 28 390 words:
/// see `spanish_stemmer_test.dart` and `tool/snowball_stems.sh`.
///
/// Expects one lowercased word.
library;

/// The stem of [word], which must already be lowercase.
String spanishStem(String word) {
  final (pV, p1, p2) = _markRegions(word);

  var s = _attachedPronoun(word, pV);
  s =
      _standardSuffix(s, p1, p2) ??
      _yVerbSuffix(s, pV) ??
      _verbSuffix(s, pV) ??
      s;
  s = _residualSuffix(s, pV);
  return _postlude(s);
}

const _vowels = 'aeiouáéíóúü';

bool _isVowel(String character) => _vowels.contains(character);

int? _firstVowelFrom(String word, int from) {
  for (var i = from; i < word.length; i++) {
    if (_isVowel(word[i])) return i;
  }
  return null;
}

int? _firstConsonantFrom(String word, int from) {
  for (var i = from; i < word.length; i++) {
    if (!_isVowel(word[i])) return i;
  }
  return null;
}

/// RV, R1 and R2.
///
/// RV: with a vowel first, after the next vowel when the second letter is
/// a consonant, or after the next consonant when it is a vowel; with a
/// consonant first, after the next vowel when the second letter is a
/// consonant too, or after the third letter when it is a vowel. The end
/// of the word when none of these exists.
(int, int, int) _markRegions(String word) {
  final n = word.length;
  var pV = n;
  if (n >= 2) {
    if (_isVowel(word[0])) {
      if (!_isVowel(word[1])) {
        final vowel = _firstVowelFrom(word, 2);
        if (vowel != null) pV = vowel + 1;
      } else {
        final consonant = _firstConsonantFrom(word, 2);
        if (consonant != null) pV = consonant + 1;
      }
    } else {
      if (!_isVowel(word[1])) {
        final vowel = _firstVowelFrom(word, 2);
        if (vowel != null) pV = vowel + 1;
      } else if (n >= 3) {
        pV = 3;
      }
    }
  }

  final p1 = _pastVowelConsonant(word, 0);
  if (p1 == null) return (pV, n, n);
  return (pV, p1, _pastVowelConsonant(word, p1) ?? n);
}

int? _pastVowelConsonant(String word, int from) {
  final vowel = _firstVowelFrom(word, from);
  if (vowel == null) return null;
  final consonant = _firstConsonantFrom(word, vowel + 1);
  if (consonant == null) return null;
  return consonant + 1;
}

String? _longest(String word, Iterable<String> candidates, {int from = 0}) {
  String? best;
  for (final candidate in candidates) {
    if (word.length - candidate.length < from) continue;
    if (word.endsWith(candidate) &&
        (best == null || candidate.length > best.length)) {
      best = candidate;
    }
  }
  return best;
}

String _cut(String word, String suffix) =>
    word.substring(0, word.length - suffix.length);

/// A pronoun hung onto an infinitive or gerund: "dámelo", "haciéndola".
/// Dropped, and the accent it forced onto the verb with it.
String _attachedPronoun(String word, int pV) {
  final pronoun = _longest(word, const [
    'me',
    'se',
    'sela',
    'selo',
    'selas',
    'selos',
    'la',
    'le',
    'lo',
    'las',
    'les',
    'los',
    'nos',
  ]);
  if (pronoun == null) return word;
  final before = _cut(word, pronoun);
  final verb = _longest(before, const [
    'iéndo',
    'ándo',
    'ár',
    'ér',
    'ír',
    'ando',
    'iendo',
    'ar',
    'er',
    'ir',
    'yendo',
  ]);
  if (verb == null) return word;
  final verbStart = before.length - verb.length;
  if (verbStart < pV) return word;

  final stem = before.substring(0, verbStart);
  switch (verb) {
    case 'iéndo':
      return '${stem}iendo';
    case 'ándo':
      return '${stem}ando';
    case 'ár':
      return '${stem}ar';
    case 'ér':
      return '${stem}er';
    case 'ír':
      return '${stem}ir';
    case 'yendo':
      return verbStart >= 1 && before[verbStart - 1] == 'u' ? before : word;
  }
  return before;
}

const _plainR2 = [
  'anza',
  'anzas',
  'ico',
  'ica',
  'icos',
  'icas',
  'ismo',
  'ismos',
  'able',
  'ables',
  'ible',
  'ibles',
  'ista',
  'istas',
  'oso',
  'osa',
  'osos',
  'osas',
  'amiento',
  'amientos',
  'imiento',
  'imientos',
];
const _withIc = [
  'adora',
  'ador',
  'ación',
  'adoras',
  'adores',
  'aciones',
  'ante',
  'antes',
  'ancia',
  'ancias',
];

/// The derivational endings. Null when none applies, so that the verb
/// endings get their turn.
String? _standardSuffix(String word, int p1, int p2) {
  final suffix = _longest(word, const [
    ..._plainR2,
    ..._withIc,
    'logía',
    'logías',
    'ución',
    'uciones',
    'encia',
    'encias',
    'amente',
    'mente',
    'idad',
    'idades',
    'iva',
    'ivo',
    'ivas',
    'ivos',
  ]);
  if (suffix == null) return null;
  final start = word.length - suffix.length;
  final stem = _cut(word, suffix);

  bool inR2(int at) => at >= p2;
  String dropIfR2(String s, String tail) =>
      s.endsWith(tail) && inR2(s.length - tail.length) ? _cut(s, tail) : s;

  if (_plainR2.contains(suffix)) return inR2(start) ? stem : null;
  if (_withIc.contains(suffix)) {
    if (!inR2(start)) return null;
    return dropIfR2(stem, 'ic');
  }
  switch (suffix) {
    case 'logía' || 'logías':
      return inR2(start) ? '${stem}log' : null;
    case 'ución' || 'uciones':
      return inR2(start) ? '${stem}u' : null;
    case 'encia' || 'encias':
      return inR2(start) ? '${stem}ente' : null;
    case 'amente':
      if (start < p1) return null;
      final next = _longest(stem, const ['iv', 'os', 'ic', 'ad']);
      if (next == null || !inR2(stem.length - next.length)) return stem;
      final shorter = _cut(stem, next);
      return next == 'iv' ? dropIfR2(shorter, 'at') : shorter;
    case 'mente':
      if (!inR2(start)) return null;
      final next = _longest(stem, const ['ante', 'able', 'ible']);
      if (next == null || !inR2(stem.length - next.length)) return stem;
      return _cut(stem, next);
    case 'idad' || 'idades':
      if (!inR2(start)) return null;
      final next = _longest(stem, const ['abil', 'ic', 'iv']);
      if (next == null || !inR2(stem.length - next.length)) return stem;
      return _cut(stem, next);
    case 'iva' || 'ivo' || 'ivas' || 'ivos':
      if (!inR2(start)) return null;
      return dropIfR2(stem, 'at');
  }
  return null;
}

/// Verb forms built on a 'y' after 'u': "huyó", "construyendo".
String? _yVerbSuffix(String word, int pV) {
  final suffix = _longest(word, const [
    'ya',
    'ye',
    'yan',
    'yen',
    'yeron',
    'yendo',
    'yo',
    'yó',
    'yas',
    'yes',
    'yais',
    'yamos',
  ], from: pV);
  if (suffix == null) return null;
  final start = word.length - suffix.length;
  if (start >= 1 && word[start - 1] == 'u') return _cut(word, suffix);
  return null;
}

const _verbEndingsAfterGu = ['en', 'es', 'éis', 'emos'];

const _verbEndings = [
  'arían',
  'arías',
  'arán',
  'arás',
  'aríais',
  'aría',
  'aréis',
  'aríamos',
  'aremos',
  'ará',
  'aré',
  'erían',
  'erías',
  'erán',
  'erás',
  'eríais',
  'ería',
  'eréis',
  'eríamos',
  'eremos',
  'erá',
  'eré',
  'irían',
  'irías',
  'irán',
  'irás',
  'iríais',
  'iría',
  'iréis',
  'iríamos',
  'iremos',
  'irá',
  'iré',
  'aba',
  'ada',
  'ida',
  'ía',
  'ara',
  'iera',
  'ad',
  'ed',
  'id',
  'ase',
  'iese',
  'aste',
  'iste',
  'an',
  'aban',
  'ían',
  'aran',
  'ieran',
  'asen',
  'iesen',
  'aron',
  'ieron',
  'ado',
  'ido',
  'ando',
  'iendo',
  'ió',
  'ar',
  'er',
  'ir',
  'as',
  'abas',
  'adas',
  'idas',
  'ías',
  'aras',
  'ieras',
  'ases',
  'ieses',
  'ís',
  'áis',
  'abais',
  'íais',
  'arais',
  'ierais',
  'aseis',
  'ieseis',
  'asteis',
  'isteis',
  'ados',
  'idos',
  'amos',
  'ábamos',
  'íamos',
  'imos',
  'áramos',
  'iéramos',
  'iésemos',
  'ásemos',
];

/// The verb endings, inside RV.
String? _verbSuffix(String word, int pV) {
  final suffix = _longest(word, const [
    ..._verbEndingsAfterGu,
    ..._verbEndings,
  ], from: pV);
  if (suffix == null) return null;
  final stem = _cut(word, suffix);
  if (_verbEndingsAfterGu.contains(suffix)) {
    // "-guen": the 'u' only kept the 'g' hard before the 'e', and goes
    // with the ending.
    final n = stem.length;
    if (n >= 2 && stem[n - 1] == 'u' && stem[n - 2] == 'g') {
      return stem.substring(0, n - 1);
    }
  }
  return stem;
}

String _residualSuffix(String word, int pV) {
  final suffix = _longest(word, const [
    'os',
    'a',
    'o',
    'á',
    'í',
    'ó',
    'e',
    'é',
  ]);
  if (suffix == null) return word;
  final start = word.length - suffix.length;
  if (start < pV) return word;
  final stem = _cut(word, suffix);
  if (suffix == 'e' || suffix == 'é') {
    final n = stem.length;
    if (n >= 2 && stem[n - 1] == 'u' && stem[n - 2] == 'g' && n - 1 >= pV) {
      return stem.substring(0, n - 1);
    }
  }
  return stem;
}

String _postlude(String word) => word
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');

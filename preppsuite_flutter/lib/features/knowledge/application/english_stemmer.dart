/// The Snowball English stemmer ("Porter2"), in Dart (#194).
///
/// A transcription of `english.sbl` as Snowball 2 has it -- the version
/// the German stemmer beside it follows too -- not an approximation. It is
/// checked against Snowball's own expected output for its test vocabulary,
/// 29 417 words: see `english_stemmer_test.dart` and
/// `tool/snowball_stems.sh`.
///
/// Expects one lowercased word.
library;

/// The stem of [word], which must already be lowercase.
String englishStem(String word) {
  final special = _exception1[word];
  if (special != null) return special;
  if (_invariant.contains(word)) return word;
  if (word.length < 3) return word;

  var (s, yFound) = _prelude(word);
  final (p1, p2) = _markRegions(s);

  s = _step1a(s);
  if (!_exception2.contains(s)) {
    s = _step1b(s, p1);
    s = _step1c(s);
    s = _step2(s, p1);
    s = _step3(s, p1, p2);
    s = _step4(s, p2);
    s = _step5(s, p1, p2);
  }

  return yFound ? s.replaceAll('Y', 'y') : s;
}

/// Words with a stem of their own, matched whole.
const _exception1 = {
  'skis': 'ski',
  'skies': 'sky',
  'dying': 'die',
  'lying': 'lie',
  'tying': 'tie',
  'idly': 'idl',
  'gently': 'gentl',
  'ugly': 'ugli',
  'early': 'earli',
  'only': 'onli',
  'singly': 'singl',
};

/// Words that are their own stem.
const _invariant = {'sky', 'news', 'howe', 'atlas', 'cosmos', 'bias', 'andes'};

/// Words left alone once step 1a has run.
const _exception2 = {
  'inning',
  'outing',
  'canning',
  'herring',
  'earring',
  'proceed',
  'exceed',
  'succeed',
};

/// Vowels as the algorithm counts them: lowercase 'y' included, the
/// capital 'Y' the prelude writes not.
const _vowels = 'aeiouy';

/// The letters an 'li' may be dropped after.
const _validLi = 'cdeghkmnrt';

bool _isVowel(String character) => _vowels.contains(character);

/// Drops a leading apostrophe and marks every 'y' that acts as a
/// consonant -- at the start, or after a vowel -- by writing it 'Y'.
(String, bool) _prelude(String word) {
  final characters = word.split('');
  var yFound = false;
  if (characters.isNotEmpty && characters.first == "'") {
    characters.removeAt(0);
  }
  if (characters.isNotEmpty && characters.first == 'y') {
    characters[0] = 'Y';
    yFound = true;
  }
  // Left to right, and on from just past each 'y' marked: a 'y' right
  // after a marked one is not after a vowel any more.
  var at = 0;
  while (true) {
    var found = -1;
    for (var p = at; p + 1 < characters.length; p++) {
      if (_isVowel(characters[p]) && characters[p + 1] == 'y') {
        found = p;
        break;
      }
    }
    if (found < 0) break;
    characters[found + 1] = 'Y';
    yFound = true;
    at = found + 2;
  }
  return (characters.join(), yFound);
}

/// Where R1 and R2 begin. Three prefixes have R1 fixed after them, so
/// that "general" and "generous" are not taken for the same word.
(int, int) _markRegions(String word) {
  final length = word.length;
  int? p1;
  for (final prefix in const ['gener', 'commun', 'arsen']) {
    if (word.startsWith(prefix)) p1 = prefix.length;
  }
  p1 ??= _pastVowelConsonant(word, 0);
  if (p1 == null) return (length, length);
  return (p1, _pastVowelConsonant(word, p1) ?? length);
}

/// The position just past the first non-vowel that follows a vowel,
/// starting at [from], or null when there is none.
int? _pastVowelConsonant(String word, int from) {
  var at = from;
  while (at < word.length && !_isVowel(word[at])) {
    at++;
  }
  if (at >= word.length) return null;
  at++;
  while (at < word.length && _isVowel(word[at])) {
    at++;
  }
  if (at >= word.length) return null;
  return at + 1;
}

/// Whether [word] ends in a short syllable: a vowel between two
/// non-vowels, the last of them not 'w', 'x' or 'Y' -- or, for a word of
/// two letters, a vowel and a non-vowel.
bool _endsShort(String word) {
  final n = word.length;
  if (n >= 3 &&
      !_isVowel(word[n - 1]) &&
      !'wxY'.contains(word[n - 1]) &&
      _isVowel(word[n - 2]) &&
      !_isVowel(word[n - 3])) {
    return true;
  }
  return n == 2 && _isVowel(word[0]) && !_isVowel(word[1]);
}

/// The longest of [candidates] that [word] ends with, or null -- what
/// Snowball's `among` picks.
String? _longest(String word, Iterable<String> candidates) {
  String? best;
  for (final candidate in candidates) {
    if (word.endsWith(candidate) &&
        (best == null || candidate.length > best.length)) {
      best = candidate;
    }
  }
  return best;
}

String _cut(String word, String suffix) =>
    word.substring(0, word.length - suffix.length);

bool _hasVowel(String word, int end) {
  for (var i = 0; i < end; i++) {
    if (_isVowel(word[i])) return true;
  }
  return false;
}

/// Possessive apostrophes, then the plural.
String _step1a(String word) {
  var s = word;
  final apostrophe = _longest(s, const ["'s'", "'s", "'"]);
  if (apostrophe != null) s = _cut(s, apostrophe);

  final suffix = _longest(s, const ['sses', 'ied', 'ies', 's', 'us', 'ss']);
  if (suffix == null) return s;
  final start = s.length - suffix.length;
  switch (suffix) {
    case 'sses':
      return '${_cut(s, suffix)}ss';
    case 'ied' || 'ies':
      // "ties" keeps its 'e', "cries" does not: one letter in front is
      // too little to lose it.
      return '${_cut(s, suffix)}${start >= 2 ? 'i' : 'ie'}';
    case 's':
      // Dropped only with a vowel somewhere before the letter in front of
      // it, so "gas" and "this" stay what they are.
      if (start >= 1 && _hasVowel(s, start - 1)) return _cut(s, suffix);
      return s;
  }
  return s;
}

String _step1b(String word, int p1) {
  final suffix = _longest(word, const [
    'eed',
    'eedly',
    'ed',
    'edly',
    'ing',
    'ingly',
  ]);
  if (suffix == null) return word;
  final start = word.length - suffix.length;

  if (suffix == 'eed' || suffix == 'eedly') {
    return start >= p1 ? '${_cut(word, suffix)}ee' : word;
  }

  if (!_hasVowel(word, start)) return word;
  final s = _cut(word, suffix);
  if (s.endsWith('at') || s.endsWith('bl') || s.endsWith('iz')) return '${s}e';
  for (final pair in const [
    'bb',
    'dd',
    'ff',
    'gg',
    'mm',
    'nn',
    'pp',
    'rr',
    'tt',
  ]) {
    if (s.endsWith(pair)) return s.substring(0, s.length - 1);
  }
  if (s.length == p1 && _endsShort(s)) return '${s}e';
  return s;
}

/// A final 'y' after a non-vowel that is not the first letter becomes
/// 'i': "cry", but not "by" or "say".
String _step1c(String word) {
  final n = word.length;
  if (n < 3) return word;
  final last = word[n - 1];
  if ((last == 'y' || last == 'Y') && !_isVowel(word[n - 2])) {
    return '${word.substring(0, n - 1)}i';
  }
  return word;
}

const _step2Map = {
  'tional': 'tion',
  'enci': 'ence',
  'anci': 'ance',
  'abli': 'able',
  'entli': 'ent',
  'izer': 'ize',
  'ization': 'ize',
  'ational': 'ate',
  'ation': 'ate',
  'ator': 'ate',
  'alism': 'al',
  'aliti': 'al',
  'alli': 'al',
  'fulness': 'ful',
  'ousli': 'ous',
  'ousness': 'ous',
  'iveness': 'ive',
  'iviti': 'ive',
  'biliti': 'ble',
  'bli': 'ble',
  'ogi': 'og',
  'fulli': 'ful',
  'lessli': 'less',
  'li': '',
};

String _step2(String word, int p1) {
  final suffix = _longest(word, _step2Map.keys);
  if (suffix == null) return word;
  final start = word.length - suffix.length;
  if (start < p1) return word;
  if (suffix == 'ogi' && !(start >= 1 && word[start - 1] == 'l')) return word;
  if (suffix == 'li' && !(start >= 1 && _validLi.contains(word[start - 1]))) {
    return word;
  }
  return '${_cut(word, suffix)}${_step2Map[suffix]}';
}

const _step3Map = {
  'tional': 'tion',
  'ational': 'ate',
  'alize': 'al',
  'icate': 'ic',
  'iciti': 'ic',
  'ical': 'ic',
  'ful': '',
  'ness': '',
  'ative': '',
};

String _step3(String word, int p1, int p2) {
  final suffix = _longest(word, _step3Map.keys);
  if (suffix == null) return word;
  final start = word.length - suffix.length;
  if (start < p1) return word;
  if (suffix == 'ative' && start < p2) return word;
  return '${_cut(word, suffix)}${_step3Map[suffix]}';
}

const _step4Suffixes = [
  'al',
  'ance',
  'ence',
  'er',
  'ic',
  'able',
  'ible',
  'ant',
  'ement',
  'ment',
  'ent',
  'ism',
  'ate',
  'iti',
  'ous',
  'ive',
  'ize',
  'ion',
];

String _step4(String word, int p2) {
  final suffix = _longest(word, _step4Suffixes);
  if (suffix == null) return word;
  final start = word.length - suffix.length;
  if (start < p2) return word;
  if (suffix == 'ion' && !(start >= 1 && 'st'.contains(word[start - 1]))) {
    return word;
  }
  return _cut(word, suffix);
}

String _step5(String word, int p1, int p2) {
  final n = word.length;
  if (n == 0) return word;
  final start = n - 1;
  final rest = word.substring(0, start);
  if (word[start] == 'e') {
    if (start >= p2 || (start >= p1 && !_endsShort(rest))) return rest;
  } else if (word[start] == 'l') {
    if (start >= p2 && start >= 1 && word[start - 1] == 'l') return rest;
  }
  return word;
}

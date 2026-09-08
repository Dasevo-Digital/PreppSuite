/// The Snowball German stemmer, in Dart.
///
/// Why a second one when the app already has Xapian's: because Xapian is
/// a C++ library that has to be built and shipped per platform, and on
/// Android it is not there. The index the app builds itself matches by
/// prefix, so "Notvorraete" never finds "Notvorrat". Stemming both the
/// indexed words and the query closes that gap without a byte of native
/// code.
///
/// This is not an approximation of the algorithm but a transcription of
/// it — `german.sbl`, the same source Xapian generates its own from. It
/// is checked against Xapian's output over a whole German dictionary,
/// 356 006 words: see `german_stemmer_test.dart` and
/// `tool/german_stems.sh`.
///
/// Expects one lowercased word.
library;

/// The stem of [word], which must already be lowercase.
String germanStem(String word) {
  if (word.isEmpty) return word;

  final prepared = _prelude(word);
  final (p1, p2) = _markRegions(prepared);
  return _postlude(_standardSuffix(prepared, p1, p2));
}

/// Vowels, as the algorithm counts them — 'y' included.
///
/// The capital U and Y the prelude writes are deliberately not in here:
/// turning them into consonants for the length of the run is the whole
/// point of marking them.
const _vowels = 'aeiouyäöü';

/// The consonants an 's' may be dropped after.
const _sEnding = 'bdfghklmnrt';

/// The same set without 'r', for 'st'.
const _stEnding = 'bdfghklmnt';

bool _isVowel(String character) => _vowels.contains(character);

/// Folds 'ss' out of 'ß' and marks the u and y that sit between vowels.
///
/// A 'u' between two vowels belongs to a diphthong rather than to any
/// suffix, so it is put beyond the reach of everything that follows by
/// being written in capitals — and written back in the postlude.
String _prelude(String word) {
  final characters = word.replaceAll('ß', 'ss').split('');

  var at = 0;
  while (at + 2 < characters.length) {
    final middle = characters[at + 1];
    if (_isVowel(characters[at]) &&
        (middle == 'u' || middle == 'y') &&
        _isVowel(characters[at + 2])) {
      characters[at + 1] = middle == 'u' ? 'U' : 'Y';
      at += 3;
    } else {
      at += 1;
    }
  }

  return characters.join();
}

/// Where R1 and R2 begin: after the first and second vowel-consonant
/// pair, with R1 never earlier than the third character.
(int, int) _markRegions(String word) {
  final length = word.length;
  final atLeastThree = length >= 3 ? 3 : 0;
  var at = 0;

  bool pastVowel() {
    while (at < length && !_isVowel(word[at])) {
      at++;
    }
    if (at >= length) return false;
    at++;
    return true;
  }

  bool pastConsonant() {
    while (at < length && _isVowel(word[at])) {
      at++;
    }
    if (at >= length) return false;
    at++;
    return true;
  }

  if (!pastVowel() || !pastConsonant()) return (length, length);
  final p1 = at < atLeastThree ? atLeastThree : at;

  if (!pastVowel() || !pastConsonant()) return (p1, length);
  return (p1, at);
}

/// Writes the marked letters back and folds the umlauts.
String _postlude(String word) => word
    .replaceAll('Y', 'y')
    .replaceAll('U', 'u')
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u');

/// The three suffix passes, each looking at what the last left behind.
String _standardSuffix(String word, int p1, int p2) {
  var s = word;

  // Inflection: the case and plural endings.
  final first = _longestSuffix(s, const [
    'ern',
    'em',
    'er',
    'en',
    'es',
    'e',
    's',
  ]);
  if (first != null && p1 <= s.length - first.length) {
    final start = s.length - first.length;
    switch (first) {
      case 'em' || 'ern' || 'er':
        s = s.substring(0, start);
      case 'e' || 'en' || 'es':
        s = s.substring(0, start);
        // "Verstaendnisse" has lost its 'e' and now ends in a doubled s
        // that was never part of the word.
        if (s.endsWith('niss')) s = s.substring(0, s.length - 1);
      case 's':
        if (start > 0 && _sEnding.contains(s[start - 1])) {
          s = s.substring(0, start);
        }
    }
  }

  // What the first pass uncovered, plus the superlative.
  final second = _longestSuffix(s, const ['est', 'en', 'er', 'st']);
  if (second != null && p1 <= s.length - second.length) {
    final start = s.length - second.length;
    if (second == 'st') {
      // Three letters have to survive in front of it, or "Angst" would
      // lose an ending it never had.
      if (start >= 4 && _stEnding.contains(s[start - 1])) {
        s = s.substring(0, start);
      }
    } else {
      s = s.substring(0, start);
    }
  }

  // Derivation: the endings that make one word out of another.
  final third = _longestSuffix(s, const [
    'isch',
    'lich',
    'heit',
    'keit',
    'end',
    'ung',
    'ig',
    'ik',
  ]);
  if (third == null || p2 > s.length - third.length) return s;

  final start = s.length - third.length;
  switch (third) {
    case 'end' || 'ung':
      s = s.substring(0, start);
      if (s.endsWith('ig') &&
          !(s.length >= 3 && s[s.length - 3] == 'e') &&
          p2 <= s.length - 2) {
        s = s.substring(0, s.length - 2);
      }
    case 'ig' || 'ik' || 'isch':
      if (!(start >= 1 && s[start - 1] == 'e')) s = s.substring(0, start);
    case 'lich' || 'heit':
      s = s.substring(0, start);
      for (final tail in const ['er', 'en']) {
        if (s.endsWith(tail) && p1 <= s.length - 2) {
          s = s.substring(0, s.length - 2);
          break;
        }
      }
    case 'keit':
      s = s.substring(0, start);
      for (final tail in const ['lich', 'ig']) {
        if (s.endsWith(tail) && p2 <= s.length - tail.length) {
          s = s.substring(0, s.length - tail.length);
          break;
        }
      }
  }

  return s;
}

/// The longest of [candidates] that [word] ends with, or null.
///
/// Longest rather than first: Snowball's `among` takes the longest match,
/// and a word ending in both 'e' and 'ste' has to be read as the latter.
String? _longestSuffix(String word, List<String> candidates) {
  String? best;
  for (final candidate in candidates) {
    if (!word.endsWith(candidate)) continue;
    if (best == null || candidate.length > best.length) best = candidate;
  }
  return best;
}

/// Which stemmer an archive in [language] is indexed with.
///
/// The tag is what a ZIM archive records in its `Language` metadata:
/// Kiwix writes ISO 639-3 ("deu"), older archives the two-letter code.
/// Anything else gets `none`, because a German stemmer let loose on
/// English would take "running" apart along rules that do not apply to
/// it.
String stemmerNameFor(String? language) {
  final tag = (language ?? '').trim().toLowerCase();
  if (tag.startsWith('deu') || tag.startsWith('ger') || tag == 'de') {
    return 'german';
  }
  return 'none';
}

/// The stemmer that [name] stands for, or null for none.
///
/// Named rather than passed around as a function so that the choice can
/// be written into the index itself: an index and the queries against it
/// have to agree, and the only way to be sure is for the index to say.
String Function(String)? stemmerNamed(String? name) =>
    name == 'german' ? germanStem : null;

/// [text], reduced to the stems that go into the index.
///
/// Tokenized here rather than left to FTS5 because the stemmer has to see
/// whole words. The split is the same one FTS5's `unicode61` makes, so
/// what it stores is what it would have stored anyway — only stemmed.
String stemText(String text, String Function(String) stem) {
  final words = text.toLowerCase().split(_notAWord);
  final stems = <String>[];
  for (final word in words) {
    if (word.isEmpty) continue;
    stems.add(stem(word));
  }
  return stems.join(' ');
}

final _notAWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

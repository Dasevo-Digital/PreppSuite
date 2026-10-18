/// Choosing a stemmer for an archive, and stemming text with it (#194).
///
/// German since 0.15.0; English, Spanish and French since 2.5.8, when the
/// archive's own Xapian index stopped being read (#186) and the app's own
/// index had to do the stemming everywhere.
library;

import 'english_stemmer.dart';
import 'french_stemmer.dart';
import 'german_stemmer.dart';
import 'spanish_stemmer.dart';

/// Which stemmer an archive in [language] is indexed with.
///
/// The tag is what a ZIM archive records in its `Language` metadata:
/// Kiwix writes ISO 639-3 ("deu"), older archives the two-letter code, and
/// an archive in several languages a list ("eng,fra") whose first entry
/// decides. Anything else gets `none`, because a stemmer let loose on a
/// language it was not written for takes words apart along rules that do
/// not apply to them.
String stemmerNameFor(String? language) {
  final tag = (language ?? '').trim().toLowerCase();
  if (tag.startsWith('deu') || tag.startsWith('ger') || tag == 'de') {
    return 'german';
  }
  if (tag.startsWith('eng') || tag == 'en') return 'english';
  if (tag.startsWith('spa') || tag == 'es') return 'spanish';
  if (tag.startsWith('fra') || tag.startsWith('fre') || tag == 'fr') {
    return 'french';
  }
  return 'none';
}

/// The stemmer that [name] stands for, or null for none.
///
/// Named rather than passed around as a function so that the choice can
/// be written into the index itself: an index and the queries against it
/// have to agree, and the only way to be sure is for the index to say.
String Function(String)? stemmerNamed(String? name) => switch (name) {
  'german' => germanStem,
  'english' => englishStem,
  'spanish' => spanishStem,
  'french' => frenchStem,
  _ => null,
};

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

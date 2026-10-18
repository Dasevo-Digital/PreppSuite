import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/german_stemmer.dart';
import 'package:preppsuite_flutter/features/knowledge/application/stemmers.dart';

/// The Dart stemmer against the standard it transcribes.
///
/// Two fixtures. `german_stems.csv` is every 89th pair of a whole German
/// dictionary -- 356 006 words from Debian's wngerman -- run through
/// Xapian 1.4's German stemmer in 0.15.0, when the archive's own Xapian
/// index still did the stemming wherever it could; the two agreed on all
/// 356 006. Xapian is gone from the app since 2.5.8 (#186), but the pairs
/// are still Snowball 2's German. `german_snowball_stems.csv` is Snowball's
/// own test vocabulary and expected output, written by
/// `tool/snowball_stems.sh` (see `snowball_stemmers_test.dart`).
///
/// Why it has to be exact rather than close: an index and the queries
/// against it are stemmed by the same function, but an index built by an
/// older version of the app is queried by a newer one.
void main() {
  group('the German stemmer', () {
    test('agrees with the dictionary fixture on every pair', () {
      final file = File('test/features/knowledge/german_stems.csv');
      expect(file.existsSync(), isTrue);

      var checked = 0;
      final wrong = <String>[];
      for (final line in file.readAsLinesSync()) {
        if (line.isEmpty || line.startsWith('#')) continue;
        final parts = line.split(';');
        if (parts.length != 2) continue;

        checked++;
        final got = germanStem(parts[0]);
        if (got != parts[1] && wrong.length < 20) {
          wrong.add('${parts[0]}: erwartet ${parts[1]}, bekommen $got');
        }
      }

      expect(checked, greaterThan(3000));
      expect(wrong, isEmpty);
    });

    test('finds the singular behind a plural', () {
      // The whole reason this exists: the FTS5 index matches by prefix, so
      // without stemming a plural finds its singular only by accident of
      // spelling.
      expect(germanStem('notvorräte'), germanStem('notvorrat'));
      expect(germanStem('häuser'), germanStem('haus'));
      expect(germanStem('elemente'), germanStem('element'));
    });

    test('keeps the doubled s out of words built on -nis', () {
      // "Verstaendnisse" loses its 'e' and would otherwise keep an 's'
      // that was never part of the word.
      expect(germanStem('verständnisse'), germanStem('verständnis'));
      expect(germanStem('verständnisse'), 'verstandnis');
    });

    test('leaves a short word alone', () {
      // R1 never starts before the third character, so there is nothing
      // in range to remove.
      for (final word in const ['ist', 'und', 'des', 'am', 'e', '']) {
        expect(germanStem(word), word, reason: word);
      }
    });

    test('does not take -st off a word that never had it', () {
      // Three letters have to survive in front of it.
      expect(germanStem('angst'), 'angst');
    });

    test('folds the sharp s and the umlauts', () {
      expect(germanStem('straße'), 'strass');
      expect(germanStem('bäume'), 'baum');
    });

    test('reads a u between vowels as part of the sound, not a syllable', () {
      // The prelude marks it as a consonant for the length of the run.
      // Without that, the regions the suffix rules are allowed to work in
      // would start in the wrong place and an inflected form would stop
      // meeting its own stem.
      expect(germanStem('neue'), germanStem('neu'));
      expect(germanStem('bauen'), germanStem('bau'));
    });
  });

  group('choosing a stemmer', () {
    test('German, English, Spanish and French archives get one', () {
      expect(stemmerNameFor('deu'), 'german');
      expect(stemmerNameFor('ger'), 'german');
      expect(stemmerNameFor('de'), 'german');
      expect(stemmerNameFor('DEU'), 'german');
      expect(stemmerNameFor('eng'), 'english');
      expect(stemmerNameFor('en'), 'english');
      expect(stemmerNameFor('spa'), 'spanish');
      expect(stemmerNameFor('es'), 'spanish');
      expect(stemmerNameFor('fra'), 'french');
      expect(stemmerNameFor('fre'), 'french');
      expect(stemmerNameFor('fr'), 'french');
      // A list: the first language decides.
      expect(stemmerNameFor('eng,fra'), 'english');
    });

    test('other languages do not', () {
      expect(stemmerNameFor('ara'), 'none');
      expect(stemmerNameFor('ukr'), 'none');
      expect(stemmerNameFor('mul'), 'none');
      expect(stemmerNameFor(null), 'none');
      expect(stemmerNameFor(''), 'none');
    });

    test('an index that names no stemmer is searched unstemmed', () {
      // What every index built before 0.15.0 says about itself. It keeps
      // working exactly as it did rather than being silently rebuilt.
      expect(stemmerNamed(null), isNull);
      expect(stemmerNamed('none'), isNull);
      for (final name in ['german', 'english', 'spanish', 'french']) {
        expect(stemmerNamed(name), isNotNull, reason: name);
      }
    });

    test('text becomes the stems that go into the index', () {
      expect(
        stemText('Die Notvorräte im Keller.', germanStem),
        'die notvorrat im kell',
      );
    });
  });
}

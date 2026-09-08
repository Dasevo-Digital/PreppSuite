import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/german_stemmer.dart';

/// The Dart stemmer against Xapian's.
///
/// Not a handful of examples but the real thing: `tool/german_stems.sh`
/// runs a whole German dictionary — 356 006 words — through Xapian's own
/// German stemmer and writes every 89th pair here. Over the full run the
/// two agree on all 356 006; the fixture is what fits in a repository.
///
/// Why it has to be exact rather than close: where an archive carries its
/// own index, Xapian does the stemming, and where it does not, this does.
/// Two stemmers that disagree would make the same search find different
/// articles depending on which platform someone is holding.
void main() {
  group('the German stemmer', () {
    test('agrees with Xapian on every pair in the fixture', () {
      final file = File('test/features/knowledge/german_stems.csv');
      expect(file.existsSync(), isTrue, reason: 'run tool/german_stems.sh');

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
    test('German archives get one, others do not', () {
      expect(stemmerNameFor('deu'), 'german');
      expect(stemmerNameFor('ger'), 'german');
      expect(stemmerNameFor('de'), 'german');
      expect(stemmerNameFor('DEU'), 'german');
      expect(stemmerNameFor('eng'), 'none');
      expect(stemmerNameFor('mul'), 'none');
      expect(stemmerNameFor(null), 'none');
      expect(stemmerNameFor(''), 'none');
    });

    test('an index that names no stemmer is searched unstemmed', () {
      // What every index built before 0.15.0 says about itself. It keeps
      // working exactly as it did rather than being silently rebuilt.
      expect(stemmerNamed(null), isNull);
      expect(stemmerNamed('none'), isNull);
      expect(stemmerNamed('german'), isNotNull);
    });

    test('text becomes the stems that go into the index', () {
      expect(
        stemText('Die Notvorräte im Keller.', germanStem),
        'die notvorrat im kell',
      );
    });
  });
}

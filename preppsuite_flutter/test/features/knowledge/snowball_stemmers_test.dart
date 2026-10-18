import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/english_stemmer.dart';
import 'package:preppsuite_flutter/features/knowledge/application/french_stemmer.dart';
import 'package:preppsuite_flutter/features/knowledge/application/german_stemmer.dart';
import 'package:preppsuite_flutter/features/knowledge/application/spanish_stemmer.dart';
import 'package:preppsuite_flutter/features/knowledge/application/stemmers.dart';

/// The Dart stemmers against Snowball's own expected output (#194).
///
/// Each fixture is a sample of Snowball 2's test vocabulary for the
/// language and the stem its reference implementation gives for every
/// word, written by `tool/snowball_stems.sh` from pinned files. Over the
/// full lists -- 29 417 English, 28 390 Spanish, 20 805 French and
/// 35 033 German words -- the Dart stemmers agree on every one.
void main() {
  void agrees(String fixture, String Function(String) stem) {
    final file = File('test/fixtures/stems/$fixture');
    expect(file.existsSync(), isTrue, reason: 'run tool/snowball_stems.sh');

    var checked = 0;
    final wrong = <String>[];
    for (final line in file.readAsLinesSync()) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final parts = line.split(';');
      if (parts.length != 2) continue;
      checked++;
      final got = stem(parts[0]);
      if (got != parts[1] && wrong.length < 20) {
        wrong.add('${parts[0]}: expected ${parts[1]}, got $got');
      }
    }
    expect(checked, greaterThan(3000));
    expect(wrong, isEmpty);
  }

  test('English agrees with Snowball', () {
    agrees('english_stems.csv', englishStem);
  });

  test('Spanish agrees with Snowball', () {
    agrees('spanish_stems.csv', spanishStem);
  });

  test('French agrees with Snowball', () {
    agrees('french_stems.csv', frenchStem);
  });

  test('German agrees with Snowball', () {
    agrees('german_snowball_stems.csv', germanStem);
  });

  group('what the stemming is for', () {
    // The point of all this, in the words somebody would search with.
    test('English plurals and verb forms meet', () {
      expect(englishStem('repairs'), englishStem('repair'));
      expect(englishStem('purifying'), englishStem('purified'));
      expect(englishStem('bandages'), englishStem('bandage'));
    });

    test('Spanish plurals and verb forms meet', () {
      expect(spanishStem('medicamentos'), spanishStem('medicamento'));
      expect(spanishStem('hervir'), spanishStem('hervido'));
    });

    test('French plurals and verb forms meet', () {
      expect(frenchStem('pansements'), frenchStem('pansement'));
      expect(frenchStem('purifier'), frenchStem('purifiée'));
    });

    test('stemText stems every word of an English sentence', () {
      expect(
        stemText('Boiling the water kills germs.', englishStem),
        'boil the water kill germ',
      );
    });
  });
}

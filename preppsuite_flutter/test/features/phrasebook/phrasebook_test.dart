import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';

void main() {
  test('every phrase is there in every language', () {
    for (final phrase in phrasebookPhrases) {
      for (final language in PhraseLanguage.values) {
        final text = phrase.text[language];
        expect(text, isNotNull, reason: '${phrase.id} lacks $language');
        expect(text!.trim(), text, reason: '${phrase.id} $language');
        expect(text, isNotEmpty);
      }
    }
  });

  test('ids are unique and every group has phrases', () {
    final ids = [for (final p in phrasebookPhrases) p.id];
    expect(ids.toSet(), hasLength(ids.length));
    for (final group in PhraseGroup.values) {
      expect(phrasesIn(group), isNotEmpty, reason: '$group');
    }
  });

  test('every sentence ends as a sentence', () {
    for (final phrase in phrasebookPhrases) {
      for (final language in PhraseLanguage.values) {
        expect(
          phrase[language],
          matches(RegExp(r'[.!?؟]$')),
          reason: '${phrase.id} $language',
        );
      }
    }
  });

  group('each language in its own script', () {
    // The likeliest slip in a table of ten languages is a line pasted into
    // the wrong column, or a Persian word typed with Arabic letters.
    final latin = RegExp(r'[A-Za-z]');
    final arabicYehKaf = RegExp('[يك]');
    final persianYehKeheh = RegExp('[یک]');
    final ukrainianOnly = RegExp('[іїєґІЇЄҐ]');
    final russianOnly = RegExp('[ыэъёЫЭЪЁ]');

    test('Arabic and Persian carry no Latin word', () {
      for (final phrase in phrasebookPhrases) {
        expect(phrase[PhraseLanguage.ar], isNot(contains(latin)));
        expect(phrase[PhraseLanguage.fa], isNot(contains(latin)));
      }
    });

    test(
      'Persian is written with Persian yeh and kaf, Arabic with its own',
      () {
        for (final phrase in phrasebookPhrases) {
          expect(
            phrase[PhraseLanguage.fa],
            isNot(contains(arabicYehKaf)),
            reason: phrase.id,
          );
          expect(
            phrase[PhraseLanguage.ar],
            isNot(contains(persianYehKeheh)),
            reason: phrase.id,
          );
        }
      },
    );

    test('Russian and Ukrainian are not each other', () {
      for (final phrase in phrasebookPhrases) {
        expect(
          phrase[PhraseLanguage.ru],
          isNot(contains(ukrainianOnly)),
          reason: phrase.id,
        );
        expect(
          phrase[PhraseLanguage.uk],
          isNot(contains(russianOnly)),
          reason: phrase.id,
        );
      }
    });
  });

  test('the emergency number is 112 in every language', () {
    final phrase = phrasebookPhrases.firstWhere(
      (p) => p.id == 'emergencyNumber',
    );
    for (final language in PhraseLanguage.values) {
      expect(phrase[language], contains('112'), reason: '$language');
    }
  });

  test('search looks in both languages', () {
    final found = searchPhrases(
      'krankenwagen',
      from: PhraseLanguage.de,
      to: PhraseLanguage.en,
    );
    expect([for (final p in found) p.id], ['callAmbulance']);
    expect(
      searchPhrases(
        'ambulance',
        from: PhraseLanguage.de,
        to: PhraseLanguage.en,
      ).map((p) => p.id),
      ['callAmbulance'],
    );
    expect(
      searchPhrases('', from: PhraseLanguage.de, to: PhraseLanguage.en),
      phrasebookPhrases,
    );
  });

  test('right to left where the script is', () {
    expect(
      [
        for (final l in PhraseLanguage.values)
          if (l.isRtl) l,
      ],
      [PhraseLanguage.ar, PhraseLanguage.fa],
    );
    expect(PhraseLanguage.forLocale('es'), PhraseLanguage.es);
    expect(PhraseLanguage.forLocale('xx'), PhraseLanguage.de);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides_de.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides_en.dart';

/// The guides are prose in two files, and a compiler cannot check prose.
/// What it can be held to is that the two files still describe the same
/// instructions — a translation that quietly loses a step loses a step of
/// a resuscitation.
void main() {
  test('every id is unique', () {
    final ids = firstAidGuidesDe.map((g) => g.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('both languages carry the same guides in the same order', () {
    expect(
      firstAidGuidesEn.map((g) => g.id).toList(),
      firstAidGuidesDe.map((g) => g.id).toList(),
    );
  });

  test('both languages carry the same number of steps', () {
    for (var i = 0; i < firstAidGuidesDe.length; i++) {
      final de = firstAidGuidesDe[i];
      final en = firstAidGuidesEn[i];
      expect(
        en.steps.length,
        de.steps.length,
        reason: 'step count differs for ${de.id}',
      );
      expect(
        en.cautions.length,
        de.cautions.length,
        reason: 'caution count differs for ${de.id}',
      );
      expect(
        en.facts.length,
        de.facts.length,
        reason: 'fact count differs for ${de.id}',
      );
    }
  });

  test('the flags that drive the interface agree between languages', () {
    for (var i = 0; i < firstAidGuidesDe.length; i++) {
      final de = firstAidGuidesDe[i];
      final en = firstAidGuidesEn[i];
      expect(en.group, de.group, reason: de.id);
      expect(en.callFirst, de.callFirst, reason: de.id);
      expect(en.hasPacer, de.hasPacer, reason: de.id);
      expect(en.drawing, de.drawing, reason: de.id);
    }
  });

  test('nothing is empty and everything names a source', () {
    for (final guides in [firstAidGuidesDe, firstAidGuidesEn]) {
      for (final guide in guides) {
        expect(guide.title.trim(), isNotEmpty, reason: guide.id);
        expect(guide.when.trim(), isNotEmpty, reason: guide.id);
        expect(guide.steps, isNotEmpty, reason: guide.id);
        // The rule the whole app follows: no medical advice of this
        // app's own, and where it repeats somebody else's it says whose.
        expect(guide.source.trim(), isNotEmpty, reason: guide.id);
        for (final step in guide.steps) {
          expect(step.text.trim(), isNotEmpty, reason: guide.id);
        }
      }
    }
  });

  test('the resuscitation guides are the ones that offer the pacer', () {
    final withPacer = [
      for (final guide in firstAidGuidesDe)
        if (guide.hasPacer) guide.id,
    ];
    expect(withPacer, ['cpr-adult', 'cpr-child']);
  });

  test('every group has at least one guide in it', () {
    for (final group in FirstAidGroup.values) {
      expect(firstAidGuidesIn('de', group), isNotEmpty, reason: '$group');
    }
  });

  group('choosing a language', () {
    test('English for an English locale, in any of its spellings', () {
      expect(firstAidGuides('en'), same(firstAidGuidesEn));
      expect(firstAidGuides('en_GB'), same(firstAidGuidesEn));
      expect(firstAidGuides('EN'), same(firstAidGuidesEn));
    });

    test('German for everything else, including a locale nobody has '
        'translated', () {
      expect(firstAidGuides('de'), same(firstAidGuidesDe));
      expect(firstAidGuides('de_AT'), same(firstAidGuidesDe));
      expect(firstAidGuides('fr'), same(firstAidGuidesDe));
    });
  });

  group('looking one up', () {
    test('by id', () {
      expect(firstAidGuide('de', 'cpr-adult')?.hasPacer, isTrue);
    });

    test('an id this version does not have reads as nothing, not as a '
        'crash', () {
      // Ids arrive from downloaded video packs, which are written
      // elsewhere and may name a guide added after this build.
      expect(firstAidGuide('de', 'teleportation-injury'), isNull);
    });
  });

  group('searching', () {
    test('an empty query is the whole list', () {
      expect(searchFirstAidGuides('de', '   ').length, firstAidGuidesDe.length);
    });

    test('matches the title', () {
      final found = searchFirstAidGuides('de', 'seitenlage');
      expect(found.map((g) => g.id), contains('recovery-position'));
    });

    test('matches the opening line, which is how a symptom is found', () {
      // Somebody looking up a wasp sting types "Stich"; the guide they
      // need is called "Allergischer Schock" and says "Stich" only in
      // its opening line.
      final found = searchFirstAidGuides('de', 'Stich');
      expect(found.map((g) => g.id), contains('anaphylaxis'));
    });

    test('is case-insensitive', () {
      expect(
        searchFirstAidGuides('de', 'VERGIFTUNG').map((g) => g.id),
        contains('poisoning'),
      );
    });
  });

  test('the ids a video pack is checked against are the German ones', () {
    expect(firstAidGuideIds, firstAidGuidesDe.map((g) => g.id).toSet());
  });
}

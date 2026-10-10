import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/kids_comic/application/kids_comic.dart';
import 'package:preppsuite_flutter/features/kids_comic/application/kids_comic_de.dart';
import 'package:preppsuite_flutter/features/kids_comic/application/kids_comic_en.dart';
import 'package:preppsuite_flutter/features/kids_comic/application/kids_comic_es.dart';

/// The comic is prose in three files and pictures in a fourth place, and a
/// compiler checks none of it against the rest.
///
/// What it is held to here: every language tells the same story, panel by
/// panel and speaker by speaker — a translation that drops "never go back
/// into the house" drops the one line that matters most — and every
/// picture the text names is a file the app actually carries.
void main() {
  List<ComicPanel> panels(KidsComic comic) => [
    for (final chapter in comic.chapters) ...chapter.panels,
  ];

  /// The translations, each held against the German original.
  const translations = {'en': kidsComicEn, 'es': kidsComicEs};

  for (final MapEntry(key: language, value: comic) in translations.entries) {
    group('$language against German', () {
      test('the same chapters in the same order', () {
        expect(
          comic.chapters.map((c) => c.id).toList(),
          kidsComicDe.chapters.map((c) => c.id).toList(),
        );
      });

      test('the same pictures, the same width', () {
        expect(
          panels(comic).map((p) => (p.image, p.wide)).toList(),
          panels(kidsComicDe).map((p) => (p.image, p.wide)).toList(),
        );
      });

      test('every panel has the same speakers in order', () {
        final de = panels(kidsComicDe);
        final other = panels(comic);
        for (var i = 0; i < de.length; i++) {
          expect(
            other[i].lines.map((l) => l.speaker).toList(),
            de[i].lines.map((l) => l.speaker).toList(),
            reason: 'speakers differ in ${de[i].image}',
          );
        }
      });

      test('the same number of rules per chapter, the same numbers', () {
        for (var i = 0; i < kidsComicDe.chapters.length; i++) {
          expect(
            comic.chapters[i].rules.length,
            kidsComicDe.chapters[i].rules.length,
            reason: kidsComicDe.chapters[i].id,
          );
        }
        expect(comic.parentsTips.length, kidsComicDe.parentsTips.length);
        expect(comic.numbers.map((n) => n.number).toList(), ['112', '110']);
      });
    });
  }

  test('German carries the numbers too', () {
    expect(kidsComicDe.numbers.map((n) => n.number).toList(), ['112', '110']);
  });

  test('every speaker has a name in every language', () {
    for (final comic in [kidsComicDe, ...translations.values]) {
      expect(comic.speakers.keys.toSet(), ComicSpeaker.values.toSet());
    }
  });

  test('no line is empty, and every picture is described', () {
    for (final comic in [kidsComicDe, ...translations.values]) {
      for (final panel in panels(comic)) {
        expect(panel.description.trim(), isNotEmpty, reason: panel.image);
        expect(panel.lines, isNotEmpty, reason: panel.image);
        for (final line in panel.lines) {
          expect(
            (line.lead ?? '') + line.text,
            isNot(isEmpty),
            reason: panel.image,
          );
        }
      }
    }
  });

  test('every picture is carried, and nothing else is', () {
    // `flutter test` runs from the package root, where the assets live.
    final carried = {
      for (final file in Directory('assets/comic').listSync())
        if (file.path.endsWith('.png'))
          file.uri.pathSegments.last.replaceAll('.png', ''),
    };
    final named = {
      kidsComicCover,
      for (final panel in panels(kidsComicDe)) panel.image,
    };
    expect(named.length, panels(kidsComicDe).length + 1, reason: 'unique ids');
    expect(carried, named);
  });

  test('every picture is drawn in the source the assets come from', () {
    final source = File('../tool/comic/mila_und_nuss.html').readAsStringSync();
    for (final panel in panels(kidsComicDe)) {
      expect(source, contains('data-panel="${panel.image}"'));
    }
  });

  test('German is the fallback, English and Spanish are chosen', () {
    expect(kidsComic('de').title, kidsComicDe.title);
    expect(kidsComic('fr').title, kidsComicDe.title);
    expect(kidsComic('en_GB').title, kidsComicEn.title);
    expect(kidsComic('es').title, kidsComicEs.title);
    expect(kidsComic('es_MX').title, kidsComicEs.title);
  });
}

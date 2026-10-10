import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides_de.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides_en.dart';

import '../../../tool/first_aid/first_aid_markdown.dart';

/// The Markdown is the text, the Dart is what the app compiles in (#146).
///
/// These hold the two to each other field by field, so a guide changed in
/// `content/first_aid/` without running `tool/first_aid/generate.dart` --
/// or the other way round -- fails here instead of shipping a screen that
/// says something the reviewed text does not.
void main() {
  for (final (language, compiled) in [
    ('de', firstAidGuidesDe),
    ('en', firstAidGuidesEn),
  ]) {
    test('$language: the app compiles in exactly the Markdown', () {
      final parsed = parseFirstAidMarkdown(
        File('content/first_aid/$language.md').readAsStringSync(),
      ).map((p) => p.guide).toList();

      expect(
        parsed.map((g) => g.id),
        compiled.map((g) => g.id),
        reason: 'ids and order',
      );
      for (var i = 0; i < compiled.length; i++) {
        final want = compiled[i];
        final got = parsed[i];
        final where = '$language/${want.id}';
        expect(got.group, want.group, reason: where);
        expect(got.title, want.title, reason: where);
        expect(got.when, want.when, reason: where);
        expect(got.callFirst, want.callFirst, reason: where);
        expect(got.drawing, want.drawing, reason: where);
        expect(got.hasPacer, want.hasPacer, reason: where);
        expect(got.source, want.source, reason: where);
        expect(got.cautions, want.cautions, reason: where);
        expect(
          [for (final s in got.steps) (s.text, s.detail)],
          [for (final s in want.steps) (s.text, s.detail)],
          reason: where,
        );
        expect(
          [for (final f in got.facts) (f.label, f.value)],
          [for (final f in want.facts) (f.label, f.value)],
          reason: where,
        );
      }
    });
  }

  group('the reader refuses what it cannot be sure of', () {
    const guide = '''
## burn
- group: injury
- title: Burn
- when: Skin is burnt.
- source: IFRC

### steps
1. Cool it.
''';

    test('a well-formed guide reads', () {
      final parsed = parseFirstAidMarkdown(guide).single.guide;

      expect(parsed.id, 'burn');
      expect(parsed.steps.single.text, 'Cool it.');
      expect(parsed.steps.single.detail, isNull);
    });

    test('an unknown key', () {
      expect(
        () => parseFirstAidMarkdown(guide.replaceFirst('- when', '- whne')),
        throwsA(isA<FirstAidMarkdownError>()),
      );
    });

    test('a step out of order', () {
      expect(
        () => parseFirstAidMarkdown(guide.replaceFirst('1. Cool', '2. Cool')),
        throwsA(isA<FirstAidMarkdownError>()),
      );
    });

    test('a line that is none of the above', () {
      expect(
        () => parseFirstAidMarkdown('$guide\nCool it some more.\n'),
        throwsA(isA<FirstAidMarkdownError>()),
      );
    });

    test('a guide without its source', () {
      expect(
        () => parseFirstAidMarkdown(guide.replaceFirst('- source: IFRC\n', '')),
        throwsA(isA<FirstAidMarkdownError>()),
      );
    });
  });

  test('every language the app speaks has every guide', () {
    // German is the reference; a language that drops a guide or a step
    // drops a step of a resuscitation.
    final reference = parseFirstAidMarkdown(
      File('content/first_aid/de.md').readAsStringSync(),
    );
    for (final file in Directory('content/first_aid').listSync()) {
      if (file is! File || !file.path.endsWith('.md')) continue;
      if (file.path.endsWith('README.md')) continue;
      final other = parseFirstAidMarkdown(file.readAsStringSync());
      expect(
        other.map((p) => p.guide.id),
        reference.map((p) => p.guide.id),
        reason: file.path,
      );
      for (var i = 0; i < reference.length; i++) {
        expect(
          other[i].guide.steps.length,
          reference[i].guide.steps.length,
          reason: '${file.path}: ${reference[i].guide.id}',
        );
      }
    }
    expect(firstAidGuideIds, {for (final p in reference) p.guide.id});
  });
}

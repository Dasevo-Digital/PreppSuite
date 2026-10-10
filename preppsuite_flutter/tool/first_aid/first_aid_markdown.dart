// Reads the first aid guides out of their Markdown files (#146).
//
// The guides are medical text, and medical text has to be readable by
// somebody who checks it against a guideline or translates it -- without
// reading Dart. So the text lives in `content/first_aid/<language>.md`,
// and `generate.dart` turns it into the constants the app compiles in.
// The app never parses anything at run time: first aid is the one screen
// that has to open when nothing else does, and a parser that could fail
// there would be a new way for it not to.
//
// The format is described in `content/first_aid/README.md`. It is strict
// on purpose. A line this reader does not recognise is an error with its
// line number, never something quietly skipped: a skipped caution is a
// caution nobody sees.

import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guide.dart';
import 'package:preppsuite_flutter/features/first_aid/application/poison_centres.dart';

/// The placeholder a facts list uses for the poison centres, which are
/// kept in `poison_centres.dart` once for every language.
const poisonCentresPlaceholder = '{poisonCentres}';

class FirstAidMarkdownError implements Exception {
  const FirstAidMarkdownError(this.line, this.message);

  final int line;
  final String message;

  @override
  String toString() => 'line $line: $message';
}

/// A parsed guide, and whether its facts are the poison centres -- which
/// the generator writes as a reference rather than as copies.
class ParsedGuide {
  const ParsedGuide(this.guide, {this.factsArePoisonCentres = false});

  final FirstAidGuide guide;
  final bool factsArePoisonCentres;
}

List<ParsedGuide> parseFirstAidMarkdown(String text) {
  final lines = text.split('\n');
  final guides = <ParsedGuide>[];
  var index = 0;

  Never fail(String message) => throw FirstAidMarkdownError(index + 1, message);

  bool blank(String line) => line.trim().isEmpty;

  while (index < lines.length) {
    final line = lines[index];
    if (blank(line)) {
      index++;
      continue;
    }
    if (line.startsWith('<!--')) {
      while (!lines[index].contains('-->')) {
        index++;
        if (index >= lines.length) fail('a comment is never closed');
      }
      index++;
      continue;
    }
    if (!line.startsWith('## ')) fail('expected "## <id>", found "$line"');

    final id = line.substring(3).trim();
    if (!RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(id)) {
      fail('"$id" is not an id: lower case, digits and dashes');
    }
    index++;

    // The header: one "- key: value" per line, until the first section.
    final fields = <String, String>{};
    while (index < lines.length && lines[index].startsWith('- ')) {
      final entry = lines[index].substring(2);
      final colon = entry.indexOf(': ');
      if (colon < 0) fail('expected "- key: value"');
      final key = entry.substring(0, colon);
      if (!_keys.contains(key)) fail('unknown key "$key"');
      if (fields.containsKey(key)) fail('"$key" twice');
      fields[key] = entry.substring(colon + 2);
      index++;
    }

    final steps = <FirstAidStep>[];
    final cautions = <String>[];
    final facts = <FirstAidFact>[];
    var poison = false;
    final seen = <String>{};

    while (index < lines.length && !lines[index].startsWith('## ')) {
      final current = lines[index];
      if (blank(current)) {
        index++;
        continue;
      }
      if (current.startsWith('<!--')) break;
      if (!current.startsWith('### ')) {
        fail('expected "### steps", "### cautions" or "### facts"');
      }
      final section = current.substring(4).trim();
      if (!const {'steps', 'cautions', 'facts'}.contains(section)) {
        fail('unknown section "$section"');
      }
      if (!seen.add(section)) fail('"$section" twice in one guide');
      index++;

      while (index < lines.length &&
          !lines[index].startsWith('#') &&
          !lines[index].startsWith('<!--')) {
        final item = lines[index];
        if (blank(item)) {
          index++;
          continue;
        }
        switch (section) {
          case 'steps':
            final number = RegExp(r'^(\d+)\. (.+)$').firstMatch(item);
            if (number == null) fail('expected "<n>. <step>"');
            if (int.parse(number[1]!) != steps.length + 1) {
              fail('step ${number[1]} where ${steps.length + 1} belongs');
            }
            String? detail;
            if (index + 1 < lines.length &&
                lines[index + 1].startsWith('   ') &&
                !blank(lines[index + 1])) {
              detail = lines[index + 1].substring(3);
              index++;
            }
            steps.add(FirstAidStep(number[2]!, detail: detail));
          case 'cautions':
            if (!item.startsWith('- ')) fail('expected "- <caution>"');
            cautions.add(item.substring(2));
          case 'facts':
            if (!item.startsWith('- ')) fail('expected "- <label>: <value>"');
            final entry = item.substring(2);
            if (entry == poisonCentresPlaceholder) {
              if (facts.isNotEmpty || poison) {
                fail('$poisonCentresPlaceholder stands alone in a list');
              }
              poison = true;
            } else {
              if (poison) {
                fail('$poisonCentresPlaceholder stands alone in a list');
              }
              final colon = entry.indexOf(': ');
              if (colon < 0) fail('expected "- <label>: <value>"');
              facts.add(
                FirstAidFact(
                  entry.substring(0, colon),
                  entry.substring(colon + 2),
                ),
              );
            }
        }
        index++;
      }
    }

    String need(String key) =>
        fields[key] ?? (throw FirstAidMarkdownError(index, '$id has no $key'));
    bool flag(String key) => switch (fields[key]) {
      null => false,
      'true' => true,
      final other => throw FirstAidMarkdownError(
        index,
        '$id: $key is "true" or absent, not "$other"',
      ),
    };

    final group = FirstAidGroup.values.asNameMap()[need('group')];
    if (group == null) {
      throw FirstAidMarkdownError(index, '$id: unknown group');
    }
    final drawingName = fields['drawing'];
    final drawing = drawingName == null
        ? null
        : FirstAidDrawing.values.asNameMap()[drawingName] ??
              (throw FirstAidMarkdownError(index, '$id: unknown drawing'));
    if (steps.isEmpty) throw FirstAidMarkdownError(index, '$id has no steps');

    guides.add(
      ParsedGuide(
        FirstAidGuide(
          id: id,
          group: group,
          title: need('title'),
          when: need('when'),
          callFirst: flag('callFirst'),
          steps: steps,
          cautions: cautions,
          facts: poison ? poisonCentres : facts,
          drawing: drawing,
          hasPacer: flag('pacer'),
          source: need('source'),
        ),
        factsArePoisonCentres: poison,
      ),
    );
  }

  final ids = <String>{};
  for (final parsed in guides) {
    if (!ids.add(parsed.guide.id)) {
      throw FirstAidMarkdownError(0, '${parsed.guide.id} twice');
    }
  }
  return guides;
}

const _keys = {
  'group',
  'title',
  'when',
  'callFirst',
  'drawing',
  'pacer',
  'source',
};

/// The Dart file the app compiles in, from [guides].
///
/// Unformatted; `generate.dart` runs `dart format` over it.
String generateFirstAidDart({
  required List<ParsedGuide> guides,
  required String variable,
  required String language,
}) {
  String quote(String text) =>
      "'${text.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

  final out = StringBuffer()
    ..writeln('// GENERATED by tool/first_aid/generate.dart from')
    ..writeln('// content/first_aid/$language.md. Do not edit: change the')
    ..writeln('// Markdown and run the generator again. The reasons behind the')
    ..writeln('// text are written down there, beside it.')
    ..writeln()
    ..writeln("import 'first_aid_guide.dart';");
  if (guides.any((parsed) => parsed.factsArePoisonCentres)) {
    out.writeln("import 'poison_centres.dart';");
  }
  out
    ..writeln()
    ..writeln('const $variable = <FirstAidGuide>[');
  for (final parsed in guides) {
    final guide = parsed.guide;
    out
      ..writeln('FirstAidGuide(')
      ..writeln('id: ${quote(guide.id)},')
      ..writeln('group: FirstAidGroup.${guide.group.name},')
      ..writeln('title: ${quote(guide.title)},')
      ..writeln('when: ${quote(guide.when)},');
    if (guide.callFirst) out.writeln('callFirst: true,');
    out.writeln('steps: [');
    for (final step in guide.steps) {
      out.write('FirstAidStep(${quote(step.text)}');
      if (step.detail != null) out.write(', detail: ${quote(step.detail!)}');
      out.writeln('),');
    }
    out.writeln('],');
    if (guide.cautions.isNotEmpty) {
      out.writeln('cautions: [');
      for (final caution in guide.cautions) {
        out.writeln('${quote(caution)},');
      }
      out.writeln('],');
    }
    if (parsed.factsArePoisonCentres) {
      out.writeln('facts: poisonCentres,');
    } else if (guide.facts.isNotEmpty) {
      out.writeln('facts: [');
      for (final fact in guide.facts) {
        out.writeln(
          'FirstAidFact(${quote(fact.label)}, ${quote(fact.value)}),',
        );
      }
      out.writeln('],');
    }
    if (guide.drawing != null) {
      out.writeln('drawing: FirstAidDrawing.${guide.drawing!.name},');
    }
    if (guide.hasPacer) out.writeln('hasPacer: true,');
    out
      ..writeln('source: ${quote(guide.source)},')
      ..writeln('),');
  }
  out.writeln('];');
  return out.toString();
}

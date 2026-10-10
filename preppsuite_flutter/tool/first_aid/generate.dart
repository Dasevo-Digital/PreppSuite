// Turns content/first_aid/<language>.md into the Dart the app compiles in
// (#146). Run from preppsuite_flutter/:
//
//   dart run tool/first_aid/generate.dart
//
// test/features/first_aid/first_aid_content_test.dart fails while the two
// disagree, so forgetting this is caught before it ships.
import 'dart:io';

import 'first_aid_markdown.dart';

/// Every language with guides, and the constant its file defines. A new
/// language is a new Markdown file, a line here, and a line in
/// `first_aid_guides.dart` that picks it.
const _languages = {'de': 'firstAidGuidesDe', 'en': 'firstAidGuidesEn'};

void main() {
  for (final MapEntry(key: language, value: variable) in _languages.entries) {
    final source = File('content/first_aid/$language.md');
    final List<ParsedGuide> guides;
    try {
      guides = parseFirstAidMarkdown(source.readAsStringSync());
    } on FirstAidMarkdownError catch (error) {
      stderr.writeln('${source.path}, $error');
      exitCode = 1;
      return;
    }
    final target =
        'lib/features/first_aid/application/first_aid_guides_$language.dart';
    File(target).writeAsStringSync(
      generateFirstAidDart(
        guides: guides,
        variable: variable,
        language: language,
      ),
    );
    final format = Process.runSync('dart', ['format', target]);
    if (format.exitCode != 0) {
      stderr.write(format.stderr);
      exitCode = 1;
      return;
    }
    stdout.writeln('$target: ${guides.length} guides');
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/tesseract_data.dart';
import 'package:preppsuite_flutter/features/knowledge/application/text_recognition.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';

/// Linux reads with the system's Tesseract and its language packages
/// (#205). A stand-in program answers `--list-langs` with what it is told
/// and otherwise prints the arguments it got, which is what is checked.
void main() {
  late Directory folder;
  setUp(() => folder = Directory.systemTemp.createTempSync('tesseract'));
  tearDown(() => folder.deleteSync(recursive: true));

  String standIn(List<String> languages) {
    final script = File('${folder.path}/tesseract')
      ..writeAsStringSync(
        '#!/bin/sh\n'
        'if [ "\$1" = "--list-langs" ]; then\n'
        '  echo \'List of available languages in "/usr/share/tessdata/":\'\n'
        '${[for (final l in languages) "  echo $l\n"].join()}'
        '  exit 0\n'
        'fi\n'
        'echo "\$@"\n',
      );
    Process.runSync('chmod', ['+x', script.path]);
    return script.path;
  }

  final page = PageImage(
    bgra: Uint8List.fromList([0, 0, 0, 255]),
    width: 1,
    height: 1,
  );

  test('a language package is found by its Tesseract name', () async {
    final data = SystemTesseractData(executable: standIn(['eng', 'rus']));

    expect(await data.has(tesseractLanguages[PhraseLanguage.ru]!), isTrue);
    expect(await data.has(tesseractLanguages[PhraseLanguage.ar]!), isFalse);
  });

  test('without the program nothing is there', () async {
    const data = SystemTesseractData(executable: '/nonexistent/tesseract');

    expect(await data.has(tesseractLanguages[PhraseLanguage.ru]!), isFalse);
  });

  test(
    'a photo in Russian is read with the Russian package and English',
    () async {
      final recognizer = TesseractRecognizer(
        executable: standIn(['deu', 'eng', 'rus']),
      );
      const languages = ['ru-RU', 'en-US'];

      expect(
        await recognizer.support(languages: languages),
        TextRecognitionSupport.available,
      );
      expect(
        await recognizer.recognize(page, languages: languages),
        contains('-l rus+eng'),
      );
    },
  );

  test(
    'a scan is still read with what there is of German and English',
    () async {
      final recognizer = TesseractRecognizer(executable: standIn(['eng']));

      expect(await recognizer.recognize(page), contains('-l eng'));
    },
  );

  test('with neither, Tesseract is asked for', () async {
    final recognizer = TesseractRecognizer(executable: standIn(['osd']));

    expect(await recognizer.support(), TextRecognitionSupport.needsTesseract);
  });
}

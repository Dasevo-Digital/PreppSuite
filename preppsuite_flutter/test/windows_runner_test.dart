import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

/// The Windows runner, read as source (#409).
///
/// None of it can be built or run off Windows, and what these guard only
/// shows on a Windows machine with the wrong language pack, an umlaut in
/// the account name or a window closed at the wrong moment. The build
/// machine compiles it; this keeps the decisions from going back.
void main() {
  final recognition = File(
    'windows/runner/text_recognition.cpp',
  ).readAsStringSync();

  test('narrow paths are UTF-8 in the whole process', () {
    // The translator's engine opens its models with fopen. In the ANSI
    // code page a path through "C:\Users\Jürgen" names another file, and
    // the model "could not be opened".
    final manifest = XmlDocument.parse(
      File('windows/runner/runner.exe.manifest').readAsStringSync(),
    );
    final settings = manifest
        .findAllElements(
          'windowsSettings',
          namespaceUri: 'urn:schemas-microsoft-com:asm.v3',
        )
        .single;
    final codePage = settings.childElements
        .where((element) => element.localName == 'activeCodePage')
        .single;
    expect(
      codePage.namespaceUri,
      'http://schemas.microsoft.com/SMI/2019/WindowsSettings',
    );
    expect(codePage.innerText, 'UTF-8');
  });

  group('photo text on Windows', () {
    test('another script is not read with the profile languages', () {
      // Asked for Russian without its language pack, Windows used to fall
      // back to the user's German and read the sign as a jumble of Latin
      // letters; the translator's "install the language pack" never came.
      final engineFor = _body(recognition, 'OcrEngine EngineFor(');
      final fallback = engineFor.indexOf('TryCreateFromUserProfileLanguages');
      expect(fallback, isNonNegative);
      expect(
        engineFor.indexOf('if (!latin) return OcrEngine{nullptr};'),
        allOf(isNonNegative, lessThan(fallback)),
      );
      expect(
        engineFor,
        contains('WrittenInLatin(engine.RecognizerLanguage())'),
        reason:
            'nor is Latin text read with a profile engine for another '
            'script',
      );
      expect(_body(recognition, 'bool WrittenInLatin('), contains('"Latn"'));
    });

    test('a reading that outlasts the window touches nothing of it', () {
      // The threads are detached. Closing the window during a recognition
      // destroyed the object they pointed at, and the finished thread
      // then locked its mutex and filled its list.
      final threads = RegExp(
        r'std::thread\(\[([^\]]*)\]',
      ).allMatches(recognition).map((match) => match.group(1)!).toList();
      expect(threads, hasLength(2));
      for (final captures in threads) {
        expect(captures, isNot(contains('this')));
        expect(captures, contains('state = state_'));
      }
      expect(
        _body(recognition, 'TextRecognition::~TextRecognition()'),
        contains('state_->window = nullptr;'),
      );
      expect(
        _body(recognition, 'void TextRecognition::Post('),
        contains('if (!state->window) return;'),
      );
    });
  });
}

/// The body of the function whose definition starts with [signature].
String _body(String source, String signature) {
  final start = source.indexOf(signature);
  expect(start, isNonNegative, reason: '$signature is not in the source');
  final open = source.indexOf('{', start);
  var depth = 0;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}' && --depth == 0) return source.substring(open, i + 1);
  }
  fail('$signature has no end');
}

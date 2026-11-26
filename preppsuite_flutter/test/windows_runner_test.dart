import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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

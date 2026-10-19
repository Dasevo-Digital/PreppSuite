import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../knowledge/application/text_recognition.dart';
import '../../phrasebook/application/phrasebook.dart' show PhraseLanguage;

/// Text from a photograph, for the translator (#203).
///
/// A sign, a notice on a door, the leaflet handed out at a shelter: the
/// words are in front of somebody and typing them in a script they cannot
/// read is not possible. The photo goes to the text recognition the app
/// already has for scanned documents -- Vision on Apple systems,
/// `Windows.Media.Ocr`, Tesseract on Android and Linux -- on the device,
/// and what it reads lands in the translator's field, to be checked
/// before it is translated.
///
/// Tesseract reads with the German and English data the app ships, so on
/// Android and Linux it reads Latin letters and nothing else. Cyrillic,
/// Arabic and Persian need data of their own; until that can be fetched
/// the screen says so instead of producing a page of wrong letters.

/// The languages written in Latin letters, which every engine here reads.
const _latin = {
  PhraseLanguage.de,
  PhraseLanguage.en,
  PhraseLanguage.es,
  PhraseLanguage.fr,
  PhraseLanguage.pl,
  PhraseLanguage.tr,
};

String _tag(PhraseLanguage language) => switch (language) {
  PhraseLanguage.de => 'de-DE',
  PhraseLanguage.en => 'en-US',
  PhraseLanguage.es => 'es-ES',
  PhraseLanguage.fr => 'fr-FR',
  PhraseLanguage.pl => 'pl-PL',
  PhraseLanguage.tr => 'tr-TR',
  PhraseLanguage.ru => 'ru-RU',
  PhraseLanguage.uk => 'uk-UA',
  PhraseLanguage.ar => 'ar-SA',
  PhraseLanguage.fa => 'fa-IR',
};

/// What to ask the engine for, for text in [language].
///
/// A Latin-script language falls back to German and English: an engine
/// without Polish still reads the letters, and only an ł may come out as
/// an l. Another script has no fallback, because English would read it
/// as nonsense rather than not at all.
List<String> recognitionLanguagesFor(PhraseLanguage language) => {
  _tag(language),
  if (_latin.contains(language)) ...['de-DE', 'en-US'],
}.toList();

bool isLatinScript(PhraseLanguage language) => _latin.contains(language);

/// Whether the engine on [platform] can read [language]'s script at all,
/// before it is asked. Only Tesseract's limit is known in advance; Vision
/// and Windows answer for themselves through `support`.
bool readsScriptOn(TargetPlatform platform, PhraseLanguage language) =>
    switch (platform) {
      TargetPlatform.android || TargetPlatform.linux => isLatinScript(language),
      _ => true,
    };

/// The longest side a photo is read at: the same limit as a scanned page,
/// enough for a sign across a room and well inside what the engines take.
const _longestSide = 4000;

/// [bytes] of a photo, upright and in BGRA, or null when it is no image
/// the app can decode.
@visibleForTesting
PageImage? photoPage(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } on Object {
    // Some decoders throw on bytes that are not theirs rather than
    // declining them; a file that is no picture is simply not one.
    return null;
  }
  if (decoded == null) return null;
  // A phone stores which way up it was held instead of turning the
  // pixels; an engine reading sideways text finds nothing.
  var image = img.bakeOrientation(decoded);
  final longest = math.max(image.width, image.height);
  if (longest > _longestSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: _longestSide)
        : img.copyResize(image, height: _longestSide);
  }
  if (image.numChannels != 4 || image.format != img.Format.uint8) {
    image = image.convert(format: img.Format.uint8, numChannels: 4, alpha: 255);
  }
  return PageImage(
    bgra: image.getBytes(order: img.ChannelOrder.bgra),
    width: image.width,
    height: image.height,
  );
}

/// The photo's text in [languages], read off the main isolate: decoding a
/// twelve-megapixel photo takes long enough to stop the screen.
final photoTextReaderProvider =
    Provider<Future<String> Function(Uint8List bytes, List<String> languages)>(
      (ref) {
        final recognizer = ref.watch(textRecognizerProvider);
        return (bytes, languages) async {
          final page = await Isolate.run(() => photoPage(bytes));
          if (page == null) return '';
          return recognizer.recognize(page, languages: languages);
        };
      },
    );

/// A photo from the camera or the library, as bytes, or null when the
/// person changed their mind.
final translatorPhotoPickerProvider =
    Provider<Future<Uint8List?> Function(ImageSource source)>(
      (ref) => (source) async {
        final picked = await ImagePicker().pickImage(
          source: source,
          maxWidth: _longestSide.toDouble(),
          maxHeight: _longestSide.toDouble(),
        );
        return picked?.readAsBytes();
      },
    );

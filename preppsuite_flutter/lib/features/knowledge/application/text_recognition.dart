/// Reading the text in a scanned page, on the device (#66).
///
/// A scanned PDF has no text layer, so the index saw an empty document and
/// said so. What it takes to read one instead was measured before any of
/// this was built -- see `docs/texterkennung-messung.md` -- and the answer
/// was that each system has a good engine of its own, or none:
///
/// * **macOS and iOS**: Apple's Vision, part of the system.
/// * **Android**: Tesseract, shipped in the APK with German and English
///   data. ML Kit was measured first and reads a little better, but sends
///   usage figures to Google by its own terms; Tesseract talks to nobody.
/// * **Windows**: `Windows.Media.Ocr`, part of the system -- for the
///   languages whose language pack is installed.
/// * **Linux**: Tesseract, which no Linux system has by default and which
///   this app does not bundle. Where it is installed it is used; where it
///   is not, the screen says how to install it.
///
/// Nothing leaves the device on any of them. The engines get a page as
/// pixels and hand back its text; the pixels come from the PDF renderer
/// the app already carries, so every platform reads the same image.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One rendered page: BGRA, eight bits a channel, [width] by [height].
class PageImage {
  const PageImage({
    required this.bgra,
    required this.width,
    required this.height,
  });

  final Uint8List bgra;
  final int width;
  final int height;
}

/// Whether this device can read a scanned page, and if not, what is
/// missing.
enum TextRecognitionSupport {
  available,

  /// Windows: the engine is there, but for no language of this app.
  needsLanguagePack,

  /// Linux: Tesseract, or its German data, is not installed.
  needsTesseract,

  /// No engine at all.
  unsupported,
}

abstract interface class TextRecognizer {
  Future<TextRecognitionSupport> support();

  /// The text on [page], lines separated by line breaks and blocks by a
  /// blank line, as the engine found them.
  Future<String> recognize(PageImage page);
}

/// The engine behind the app's platform channel: Vision on Apple systems,
/// Tesseract inside the Android app, `Windows.Media.Ocr` on Windows.
class PlatformTextRecognizer implements TextRecognizer {
  const PlatformTextRecognizer();

  static const _channel = MethodChannel(
    'de.dasevo.preppsuite/text_recognition',
  );

  /// German first, then English: the order the engines try them in where
  /// they take a list.
  static const languages = ['de-DE', 'en-US'];

  @override
  Future<TextRecognitionSupport> support() async {
    try {
      final answer = await _channel.invokeMethod<String>('support', {
        'languages': languages,
      });
      return TextRecognitionSupport.values.asNameMap()[answer] ??
          TextRecognitionSupport.unsupported;
    } on MissingPluginException {
      return TextRecognitionSupport.unsupported;
    } on PlatformException {
      return TextRecognitionSupport.unsupported;
    }
  }

  @override
  Future<String> recognize(PageImage page) async {
    final text = await _channel.invokeMethod<String>('recognize', {
      'bgra': page.bgra,
      'width': page.width,
      'height': page.height,
      'languages': languages,
    });
    return text ?? '';
  }
}

/// Tesseract on Linux, through its command line.
///
/// A program the household installs, not a library this app ships: its
/// German data alone is some fifteen megabytes, and every distribution
/// packages it (`tesseract-ocr`, `tesseract-ocr-deu`).
class TesseractRecognizer implements TextRecognizer {
  const TesseractRecognizer({this.executable = 'tesseract'});

  final String executable;

  /// German and English, as far as they are installed: `deu+eng`, or one
  /// of them, or null when neither is. English alone still reads a German
  /// page's letters, if not every umlaut; the screen asks for the German
  /// data only when there is nothing at all.
  Future<String?> _languages() async {
    try {
      final result = await Process.run(executable, ['--list-langs']);
      if (result.exitCode != 0) return null;
      final installed = '${result.stdout}\n${result.stderr}'
          .split('\n')
          .map((line) => line.trim())
          .toSet();
      final usable = [
        for (final language in const ['deu', 'eng'])
          if (installed.contains(language)) language,
      ];
      return usable.isEmpty ? null : usable.join('+');
    } on ProcessException {
      return null;
    }
  }

  @override
  Future<TextRecognitionSupport> support() async => await _languages() == null
      ? TextRecognitionSupport.needsTesseract
      : TextRecognitionSupport.available;

  @override
  Future<String> recognize(PageImage page) async {
    final languages = await _languages();
    if (languages == null) {
      throw ProcessException(executable, const [], 'no tessdata for deu/eng');
    }
    final directory = await Directory.systemTemp.createTemp('preppsuite-ocr');
    try {
      // PGM: grey, eight bits, a header of three lines. The simplest image
      // Tesseract reads, and enough -- colour carries nothing for text.
      final image = File('${directory.path}/page.pgm');
      await image.writeAsBytes(greyPgm(page), flush: true);
      final result = await Process.run(executable, [
        image.path,
        'stdout',
        '-l',
        languages,
      ]);
      if (result.exitCode != 0) {
        throw ProcessException(executable, const [], '${result.stderr}');
      }
      return '${result.stdout}';
    } finally {
      await directory.delete(recursive: true);
    }
  }
}

/// [page] as a binary PGM, grey from the usual luminance weights.
@visibleForTesting
Uint8List greyPgm(PageImage page) {
  final header = 'P5\n${page.width} ${page.height}\n255\n';
  final out = BytesBuilder(copy: false)..add(header.codeUnits);
  final grey = Uint8List(page.width * page.height);
  final pixels = page.bgra;
  for (var i = 0, j = 0; i < grey.length; i++, j += 4) {
    final blue = pixels[j];
    final green = pixels[j + 1];
    final red = pixels[j + 2];
    grey[i] = (red * 299 + green * 587 + blue * 114) ~/ 1000;
  }
  out.add(grey);
  return out.takeBytes();
}

final textRecognizerProvider = Provider<TextRecognizer>(
  (ref) => !kIsWeb && Platform.isLinux
      ? const TesseractRecognizer()
      : const PlatformTextRecognizer(),
);

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:preppsuite_flutter/features/knowledge/application/document_text_recognition.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/knowledge/application/tesseract_data.dart';
import 'package:preppsuite_flutter/features/knowledge/application/text_recognition.dart';
import 'package:preppsuite_flutter/features/phrasebook/application/phrasebook.dart';

/// The text recognition of each system, actually asked (#66).
///
/// The unit tests stand a fake engine in for the real one, which proves
/// everything around it and nothing about whether Vision, Tesseract or
/// Windows answer at all -- or answer with the text. Here a known sentence
/// is drawn as a picture, put into a PDF with no text layer, the way a
/// scanner makes one, and read back.
///
/// Run against a device or simulator:
///
/// ```bash
/// flutter test integration_test/native_text_recognition_test.dart -d <device>
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const sentence = 'Notvorrat fuer zehn Tage';

  TextRecognizer recognizer() => Platform.isLinux
      ? const TesseractRecognizer()
      : const PlatformTextRecognizer();

  /// [sentence] in black on white, as PNG bytes.
  ///
  /// Drawn in Dart with the `image` package rather than through the
  /// engine's rasteriser: a Windows test run over a remote session has no
  /// display to rasterise on, and `Picture.toImage` fails there.
  Uint8List drawn() {
    final image = img.Image(width: 1400, height: 200)
      ..clear(img.ColorRgb8(255, 255, 255));
    img.drawString(
      image,
      sentence,
      font: img.arial48,
      x: 40,
      y: 70,
      color: img.ColorRgb8(0, 0, 0),
    );
    return img.encodePng(image);
  }

  testWidgets('the engine is there', (tester) async {
    final support = await tester.runAsync(() => recognizer().support());

    expect(
      support,
      TextRecognitionSupport.available,
      reason:
          'Vision and Windows.Media.Ocr come with the system, Tesseract '
          'with the Android app; on Linux it has to be installed',
    );
  });

  testWidgets('a scanned page is read back', (tester) async {
    final text = await tester.runAsync(() async {
      final picture = drawn();
      final pdf = pw.Document()
        ..addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(picture))),
          ),
        );
      final directory = await Directory.systemTemp.createTemp('scan');
      try {
        final file = File('${directory.path}/scan.pdf');
        await file.writeAsBytes(await pdf.save(), flush: true);
        final source = await PdfPageSource.open(
          PersonalDocument(
            id: 'scan',
            location: file.path,
            label: 'scan.pdf',
            addedAt: DateTime.utc(2026),
          ),
        );
        try {
          return (await recognizeDocument(
            source: source,
            recognizer: recognizer(),
          )).searchText;
        } finally {
          await source.close();
        }
      } finally {
        await directory.delete(recursive: true);
      }
    });

    expect(text?.toLowerCase(), contains('notvorrat'));
    expect(text?.toLowerCase(), contains('zehn'));
  });

  /// [text] drawn by the engine's own text renderer, in the system font,
  /// as BGRA: the `image` package's bitmap font has no Cyrillic.
  Future<PageImage> rendered(String text) async {
    const width = 1400;
    const height = 300;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)
      ..drawRect(
        const ui.Rect.fromLTWH(0, 0, 1400, 300),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF),
      );
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 96))
      ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF000000)))
      ..addText(text);
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 1320));
    canvas.drawParagraph(paragraph, const ui.Offset(40, 80));
    final image = await recorder.endRecording().toImage(width, height);
    final rgba = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    final bgra = Uint8List(rgba.length);
    for (var i = 0; i < rgba.length; i += 4) {
      bgra[i] = rgba[i + 2];
      bgra[i + 1] = rgba[i + 1];
      bgra[i + 2] = rgba[i];
      bgra[i + 3] = rgba[i + 3];
    }
    return PageImage(bgra: bgra, width: width, height: height);
  }

  // Android fetches the Russian data the way "Text aus Foto" does (#205)
  // and reads with it; Vision on Apple systems reads Cyrillic as it is.
  // Windows depends on an installed language pack and Linux on a system
  // package, so neither is asked here.
  testWidgets(
    'a sign in Cyrillic is read',
    (tester) async {
      final text = await tester.runAsync(() async {
        const languages = ['ru-RU', 'en-US'];
        if (Platform.isAndroid) {
          final data = DownloadedTesseractData();
          await data
              .install(tesseractLanguages[PhraseLanguage.ru]!)
              .drain<void>();
          expect(
            await data.has(tesseractLanguages[PhraseLanguage.ru]!),
            isTrue,
          );
        }
        const recognizer = PlatformTextRecognizer();
        expect(
          await recognizer.support(languages: languages),
          TextRecognitionSupport.available,
        );
        return recognizer.recognize(
          await rendered('ВЫХОД ЗДЕСЬ'),
          languages: languages,
        );
      });

      expect(text?.toLowerCase(), contains('выход'));
    },
    skip: !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS),
  );
}

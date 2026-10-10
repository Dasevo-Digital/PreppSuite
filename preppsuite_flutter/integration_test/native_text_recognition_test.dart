import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:preppsuite_flutter/features/knowledge/application/document_text_recognition.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';
import 'package:preppsuite_flutter/features/knowledge/application/text_recognition.dart';

/// The text recognition of each system, actually asked (#66).
///
/// The unit tests stand a fake engine in for the real one, which proves
/// everything around it and nothing about whether Vision, ML Kit or
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

  // Android has no engine yet: ML Kit, the one that was measured, sends
  // usage figures to Google, which this app does not do (#66).
  final skip = Platform.isAndroid;

  testWidgets('the engine is there', skip: skip, (tester) async {
    final support = await tester.runAsync(() => recognizer().support());

    expect(
      support,
      TextRecognitionSupport.available,
      reason:
          'Vision, ML Kit and Windows.Media.Ocr ship with the app or the '
          'system; Tesseract has to be installed on the Linux machine',
    );
  });

  testWidgets('a scanned page is read back', skip: skip, (tester) async {
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
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr/qr.dart';

/// The barcode reader, actually asked (#158).
///
/// On Android the scanner reads with zxing-cpp since ML Kit was taken out
/// of it (`third_party/mobile_scanner`). No unit test reaches the native
/// side. Here a known QR code and a known EAN-13 are drawn as pictures and
/// read back through the scanner's path for a photo, which uses the same
/// decoder the camera feeds.
///
/// On iOS the scanner reads with Apple's Vision, which this patch leaves
/// alone -- and which the plugin does not offer for a photo in the
/// simulator. There the tests say so and are skipped; on a phone they
/// run.
///
/// Run against a device or simulator:
///
/// ```bash
/// flutter test integration_test/native_barcode_test.dart -d <device>
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// An offer to the neighbours, umlaut and dash included: the QR code's
  /// bytes are UTF-8 with no declaration, and a reader that guessed Latin-1
  /// would hand back "fÃ¼r".
  const offer =
      'Wasser: 20 l Trinkwasser für Nachbarn – Haus 4\n'
      'PreppSuite-Angebot/1 water 2026-10-11';

  /// A real EAN-13 with a valid check digit.
  const ean = '4006381333931';

  Future<String> write(img.Image image) async {
    final directory = await Directory.systemTemp.createTemp('barcode');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/code.png');
    await file.writeAsBytes(img.encodePng(image), flush: true);
    return file.path;
  }

  img.Image qrPicture(String text) {
    const module = 8;
    const quiet = 4;
    final code = QrImage(
      QrCode.fromData(data: text, errorCorrectLevel: QrErrorCorrectLevel.M),
    );
    final side = (code.moduleCount + 2 * quiet) * module;
    final image = img.Image(width: side, height: side)
      ..clear(img.ColorRgb8(255, 255, 255));
    for (var y = 0; y < code.moduleCount; y++) {
      for (var x = 0; x < code.moduleCount; x++) {
        if (!code.isDark(y, x)) continue;
        img.fillRect(
          image,
          x1: (x + quiet) * module,
          y1: (y + quiet) * module,
          x2: (x + quiet + 1) * module - 1,
          y2: (y + quiet + 1) * module - 1,
          color: img.ColorRgb8(0, 0, 0),
        );
      }
    }
    return image;
  }

  img.Image eanPicture(String digits) {
    const left = [
      '0001101',
      '0011001',
      '0010011',
      '0111101',
      '0100011',
      '0110001',
      '0101111',
      '0111011',
      '0110111',
      '0001011',
    ];
    const even = [
      '0100111',
      '0110011',
      '0011011',
      '0100001',
      '0011101',
      '0111001',
      '0000101',
      '0010001',
      '0001001',
      '0010111',
    ];
    const parity = [
      'LLLLLL',
      'LLGLGG',
      'LLGGLG',
      'LLGGGL',
      'LGLLGG',
      'LGGLLG',
      'LGGGLL',
      'LGLGLG',
      'LGLGGL',
      'LGGLGL',
    ];
    String right(int digit) =>
        left[digit].split('').map((bit) => bit == '0' ? '1' : '0').join();

    final numbers = digits.split('').map(int.parse).toList();
    final pattern = StringBuffer('101');
    for (var i = 1; i <= 6; i++) {
      final table = parity[numbers.first][i - 1] == 'L' ? left : even;
      pattern.write(table[numbers[i]]);
    }
    pattern.write('01010');
    for (var i = 7; i <= 12; i++) {
      pattern.write(right(numbers[i]));
    }
    pattern.write('101');

    const module = 4;
    const quiet = 11;
    final bits = pattern.toString();
    final image = img.Image(
      width: (bits.length + 2 * quiet) * module,
      height: 240,
    )..clear(img.ColorRgb8(255, 255, 255));
    for (var i = 0; i < bits.length; i++) {
      if (bits[i] != '1') continue;
      img.fillRect(
        image,
        x1: (i + quiet) * module,
        y1: 20,
        x2: (i + quiet + 1) * module - 1,
        y2: 219,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
    return image;
  }

  /// What the scanner reads off [picture], or null where it cannot read
  /// a photo at all -- the iOS simulator, see above.
  Future<({BarcodeCapture? capture, bool unsupported})> analyze(
    WidgetTester tester,
    img.Image picture, {
    List<BarcodeFormat> formats = const [],
  }) async {
    final result = await tester.runAsync(() async {
      final path = await write(picture);
      try {
        final capture = await MobileScannerController().analyzeImage(
          path,
          formats: formats,
        );
        return (capture: capture, unsupported: false);
      } on UnsupportedError {
        return (capture: null, unsupported: true);
      }
    });
    return result!;
  }

  const simulator = 'reading a photo is not offered in the iOS simulator';

  testWidgets('a QR code is read back, umlauts and all', (tester) async {
    final read = await analyze(
      tester,
      qrPicture(offer),
      formats: const [BarcodeFormat.qrCode],
    );
    if (read.unsupported) return markTestSkipped(simulator);

    final barcode = read.capture?.barcodes.single;
    expect(barcode?.rawValue, offer);
    expect(barcode?.format, BarcodeFormat.qrCode);
  });

  testWidgets('an EAN-13 is read back as one', (tester) async {
    final read = await analyze(tester, eanPicture(ean));
    if (read.unsupported) return markTestSkipped(simulator);

    final barcode = read.capture?.barcodes.single;
    expect(barcode?.rawValue, ean);
    expect(barcode?.format, BarcodeFormat.ean13);
  });
}

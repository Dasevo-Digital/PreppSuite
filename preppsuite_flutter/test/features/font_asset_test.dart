import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// The bundled font is a static cut, and has to stay one.
///
/// It exists for two PDF reports, both of which build their theme with
/// the same face for base and bold — so no weight is ever interpolated.
/// The variable original carried 1.25 MB of glyph variation data for
/// that, on every platform, unused: 2,049,096 bytes against 646,160
/// after instancing, and 1.19 MB against 293 KB once gzipped, which is
/// what a download costs.
///
/// This guards the asset rather than the code, because the way to lose
/// it is to drop a fresh NotoSans from Google Fonts over the top — those
/// are variable. `tool/font_instance.py` is the way to update it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List font;

  setUpAll(() async {
    font = (await rootBundle.load(
      'assets/fonts/NotoSans-Regular.ttf',
    )).buffer.asUint8List();
  });

  /// The four-character tags of every table in a TrueType file.
  Set<String> tablesOf(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    final count = view.getUint16(4);
    return {
      for (var i = 0; i < count; i++)
        String.fromCharCodes(bytes.sublist(12 + i * 16, 12 + i * 16 + 4)),
    };
  }

  test('it carries no variable-font tables', () {
    // `fvar` is the one that makes a font variable at all; the others are
    // the payload that comes with it. `gvar` alone was 61 % of the file.
    expect(
      tablesOf(font),
      isNot(
        anyOf(
          contains('fvar'),
          contains('gvar'),
          contains('avar'),
          contains('HVAR'),
          contains('MVAR'),
        ),
      ),
    );
  });

  test('it still carries what the PDFs read', () {
    // Character map, outlines and advance widths. Without these the
    // reports fall back to a base-14 font, which mangles umlauts
    // silently — see missing_equipment_report_test.
    expect(tablesOf(font), containsAll(<String>['cmap', 'glyf', 'hmtx']));
  });

  test('instancing did not cost the glyphs', () {
    // 4515 glyphs in the original and in the instance. The number is
    // here so that a subsetted font — which would be a different and
    // much riskier change, since the PDFs carry whatever a person typed
    // — cannot arrive unnoticed.
    final view = ByteData.sublistView(font);
    final tables = tablesOf(font);
    expect(tables, contains('maxp'));

    final count = view.getUint16(4);
    var offset = 0;
    for (var i = 0; i < count; i++) {
      final tag = String.fromCharCodes(
        font.sublist(12 + i * 16, 12 + i * 16 + 4),
      );
      if (tag == 'maxp') offset = view.getUint32(12 + i * 16 + 8);
    }
    expect(view.getUint16(offset + 4), 4515);
  });

  test('and it is the size that says the instancing happened', () {
    // A plain lower bound and upper bound rather than an exact figure:
    // a newer NotoSans may legitimately differ by a few kilobytes, but
    // not by a megabyte.
    expect(font.lengthInBytes, lessThan(1000000));
    expect(font.lengthInBytes, greaterThan(300000));
  });
}

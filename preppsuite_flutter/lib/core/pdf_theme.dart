import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// The page theme every PDF of the app is set in: NotoSans for regular
/// and bold alike.
///
/// The default of the `pdf` package is Helvetica, a base-14 font that
/// covers U+0000 to U+00FF and nothing else. The incident log and the
/// briefing were set in it (#290): the dash in their own title
/// "PreppSuite – …" did not print, in any language, and neither did
/// the quotation marks a German keyboard types, a euro sign or a name in
/// another script. One face for both weights, as in the other reports --
/// see `missing_equipment_report.dart` for why the bundled cut is static.
Future<pw.ThemeData> unicodePdfTheme() async {
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  return pw.ThemeData.withFont(base: font, bold: font);
}

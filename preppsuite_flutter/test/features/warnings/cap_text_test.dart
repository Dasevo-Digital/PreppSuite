import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/cap_text.dart';

void main() {
  test('the all-clear from Braunschweig reads as text', () {
    // The opening of the live detail, 2026-10-17, as the feed sent it.
    const sent =
        'Dies ist die Entwarnung zur Warnung &quot;Entschärfung einer '
        'Weltkriegsbombe - Braunschweig Leiferde/Stöckheim&quot; vom '
        '16.10.2026 09:49:32 gesendet durch Feuerwehr Braunschweig. Die '
        'Warnung ist aufgehoben.<br/><br/>Die Weltkriegsbombe ist entschärft.';

    expect(
      capPlainText(sent),
      'Dies ist die Entwarnung zur Warnung "Entschärfung einer '
      'Weltkriegsbombe - Braunschweig Leiferde/Stöckheim" vom '
      '16.10.2026 09:49:32 gesendet durch Feuerwehr Braunschweig. Die '
      'Warnung ist aufgehoben.\n\nDie Weltkriegsbombe ist entschärft.',
    );
  });

  test('each instruction keeps its own line', () {
    expect(
      capPlainText(
        'Meiden Sie das betroffene Gebiet.<br/>Informieren Sie sich.<BR>'
        'Achten Sie auf Durchsagen.<br />',
      ),
      'Meiden Sie das betroffene Gebiet.\nInformieren Sie sich.\n'
      'Achten Sie auf Durchsagen.',
    );
  });

  test('more than one blank line is one', () {
    expect(capPlainText('a<br/><br/><br/><br/>b'), 'a\n\nb');
  });

  test('a list becomes lines with bullets', () {
    expect(
      capPlainText('<ul><li>Fenster schließen</li><li>Radio an</li></ul>'),
      '• Fenster schließen\n• Radio an',
    );
  });

  test('entities are decoded once, and unknown ones are kept', () {
    expect(capPlainText('Gr&ouml;&szlig;e &amp;lt; 3'), 'Größe &lt; 3');
    expect(capPlainText('&#8222;so&#x201C; &bogus;'), '„so“ &bogus;');
  });

  test('a bare angle bracket is a word, not a tag', () {
    expect(capPlainText('Pegel < 3 m, > 2 m'), 'Pegel < 3 m, > 2 m');
  });

  test('plain text from DWD passes unchanged', () {
    const dwd =
        'Es tritt Dauerregen auf. Dabei werden Niederschlagsmengen '
        'zwischen 40 l/m² und 60 l/m² erwartet.';
    expect(capPlainText(dwd), dwd);
  });

  test('nothing readable is null', () {
    expect(capPlainText(null), isNull);
    expect(capPlainText(42), isNull);
    expect(capPlainText('  <br/> &nbsp; '), isNull);
  });
}

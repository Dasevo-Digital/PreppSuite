import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/morse/application/morse_code.dart';

void main() {
  group('the table', () {
    final all = [
      ...morseLetters,
      ...morseDigits,
      ...morsePunctuation,
      ...morseExtensions,
    ];

    test('no two characters share a signal', () {
      // A decoder could not tell them apart; the multiplication sign is
      // left out of the punctuation for exactly this reason.
      final codes = [for (final s in all) s.code];
      expect(codes.toSet(), hasLength(codes.length));
    });

    test('nothing but dots and dashes', () {
      for (final symbol in all) {
        expect(
          symbol.code,
          matches(RegExp(r'^[.-]+$')),
          reason: symbol.character,
        );
      }
      for (final prosign in MorseProsign.values) {
        expect(prosign.code, matches(RegExp(r'^[.-]+$')));
      }
    });

    test('a few signals checked against ITU-R M.1677-1', () {
      String code(String c) => all.firstWhere((s) => s.character == c).code;
      expect(code('A'), '.-');
      expect(code('Q'), '--.-');
      expect(code('É'), '..-..');
      expect(code('0'), '-----');
      expect(code('?'), '..--..');
      expect(code('@'), '.--.-.');
      expect(MorseProsign.sos.code, '...---...');
      expect(MorseProsign.error.code, '........');
    });

    test('the alphabet is all there', () {
      expect(
        [for (final s in morseLetters) s.character].where((c) => c != 'É'),
        [for (var c = 65; c <= 90; c++) String.fromCharCode(c)],
      );
    });
  });

  group('encoding', () {
    test('letters by a space, words by a slash', () {
      expect(
        encodeMorse('SOS hilfe').format(dot: '.', dash: '-'),
        '... --- ... / .... .. .-.. ..-. .',
      );
    });

    test('lower case, umlauts and an accent', () {
      expect(
        encodeMorse('Grüße').format(dot: '.', dash: '-'),
        '--. .-. ..-- ...--.. .',
      );
      expect(
        encodeMorse('café').format(dot: '.', dash: '-'),
        '-.-. .- ..-. ..-..',
      );
      expect(
        encodeMorse('niño').format(dot: '.', dash: '-'),
        '-. .. --.-- ---',
      );
    });

    test('an accent the table lacks is sent as its letter', () {
      expect(encodeMorse('à').format(dot: '.', dash: '-'), '.-');
    });

    test('what cannot be sent is named, not dropped silently', () {
      final message = encodeMorse('Notruf € 112 #');
      expect(message.unknown, ['€', '#']);
      expect(
        message.format(dot: '.', dash: '-'),
        '-. --- - .-. ..- ..-. / .---- .---- ..---',
      );
    });

    test('nothing in, nothing out', () {
      expect(encodeMorse('   ').isEmpty, isTrue);
    });
  });

  group('decoding', () {
    test('back to text', () {
      expect(
        decodeMorse('... --- ... / .... .. .-.. ..-. .').text,
        'SOS HILFE',
      );
    });

    test('whatever dots and dashes a hand types', () {
      expect(decodeMorse('·−   −···  •- ').text, 'A B A');
      expect(decodeMorse('...|---\n...').text, 'S O S');
      expect(decodeMorse('_._.').text, 'C');
    });

    test('the signals that are more than a letter', () {
      expect(decodeMorse('...---...').text, 'SOS');
      expect(decodeMorse('----').text, 'CH');
      expect(decodeMorse('..........').text, '…');
    });

    test('an unknown code is marked and listed', () {
      final decoded = decodeMorse('.- ......- -...');
      expect(decoded.text, 'A${MorseDecoding.unknownMark}B');
      expect(decoded.unknown, ['......-']);
    });

    test('a round trip keeps the message', () {
      const text = 'TREFFPUNKT 18 UHR AM RATHAUS, BITTE BESTAETIGEN?';
      expect(decodeMorse(encodeMorse(text).format()).text, text);
    });
  });

  group('the lamp', () {
    const unit = Duration(milliseconds: 100);

    test('keeps the Recommendation\'s proportions', () {
      // E T: dot, letter gap, dash, then the end-of-message pause.
      final rhythm = MorseRhythm(encodeMorse('ET'), unit: unit);
      expect(rhythm.spans, [
        (lit: true, length: unit),
        (lit: false, length: unit * 3),
        (lit: true, length: unit * 3),
        (lit: false, length: unit * 14),
      ]);
      expect(rhythm.period, unit * 21);
    });

    test('seven units between words', () {
      final rhythm = MorseRhythm(encodeMorse('E E'), unit: unit);
      expect(rhythm.spans[1], (lit: false, length: unit * 7));
    });

    test('says which character is being sent', () {
      final rhythm = MorseRhythm(encodeMorse('ST'), unit: unit);
      // S is three dots with one-unit gaps: 0–500 ms, then three dark.
      expect(rhythm.characterAt(const Duration(milliseconds: 50)), 0);
      expect(rhythm.characterAt(const Duration(milliseconds: 150)), 0);
      expect(rhythm.characterAt(const Duration(milliseconds: 600)), isNull);
      expect(rhythm.characterAt(const Duration(milliseconds: 850)), 1);
      expect(rhythm.isLitAt(const Duration(milliseconds: 850)), isTrue);
      // And it repeats.
      expect(
        rhythm.characterAt(rhythm.period + const Duration(milliseconds: 50)),
        0,
      );
    });

    test('an empty message is dark', () {
      final rhythm = MorseRhythm(encodeMorse(''), unit: unit);
      expect(rhythm.isLitAt(Duration.zero), isFalse);
      expect(rhythm.characterAt(Duration.zero), isNull);
    });
  });
}

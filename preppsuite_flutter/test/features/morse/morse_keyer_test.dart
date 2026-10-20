import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/morse/application/morse_code.dart';
import 'package:preppsuite_flutter/features/morse/application/morse_keyer.dart';

/// Keys [elements] ('.', '-', ' ' for a letter gap, '/' for a word gap)
/// at [unit] a dot, with [wobble] added to every other press and pause,
/// as a hand does, and returns what the keyer reads.
String key(
  MorseKeyer keyer,
  String elements, {
  required int unit,
  int wobble = 0,
}) {
  var clock = 0;
  var gap = 0;
  var i = 0;
  for (final element in elements.split('')) {
    if (element == ' ') {
      gap = 3 * unit;
      continue;
    }
    if (element == '/') {
      gap = 7 * unit;
      continue;
    }
    final jitter = i.isEven ? wobble : -wobble;
    i++;
    clock += (gap == 0 ? unit : gap) + jitter;
    gap = 0;
    keyer.down(Duration(milliseconds: clock));
    clock += (element == '-' ? 3 * unit : unit) + jitter;
    keyer.up(Duration(milliseconds: clock));
  }
  return keyer.code;
}

/// Keys [elements] as a finger or a mouse does: a tap is far shorter than
/// the pause after it, and the pause after a long press longer than the
/// one after a short press, because the key has to come up and go down
/// again. All in milliseconds.
String keyByHand(
  MorseKeyer keyer,
  String elements, {
  int dot = 100,
  int dash = 350,
  int afterDot = 150,
  int afterDash = 260,
  int letterGap = 600,
  int wordGap = 1500,
}) {
  var clock = 0;
  int? pause;
  for (final element in elements.split('')) {
    if (element == ' ') {
      pause = letterGap;
      continue;
    }
    if (element == '/') {
      pause = wordGap;
      continue;
    }
    if (pause != null) clock += pause;
    keyer.down(Duration(milliseconds: clock));
    clock += element == '-' ? dash : dot;
    keyer.up(Duration(milliseconds: clock));
    pause = element == '-' ? afterDash : afterDot;
  }
  return keyer.code;
}

void main() {
  test('a hand on a key or a screen is read as it presses (#191)', () {
    // What came back from the first test by hand: the pause between two
    // long presses is well over two short taps, and an O fell apart into
    // T and M.
    expect(keyByHand(MorseKeyer(), '... --- ...'), '... --- ...');
    expect(keyByHand(MorseKeyer(), '--.'), '--.');
    expect(
      decodeMorse(keyByHand(MorseKeyer(), '.... . .-.. .--.')).text,
      'HELP',
    );
  });

  test('every hand in a plausible range is read alike', () {
    // Taps of 60 to 220 ms, dashes two and a half to four taps long, a
    // pause after a dash up to 1.8 times the one after a tap, and letters
    // paused on purpose: three to five times the pause after a dash. The
    // first keyer read 2100 of 2700 such hands wrong.
    final misread = <String>[];
    for (final dot in [60, 120, 220]) {
      for (final dash in [2.5, 4.0]) {
        for (final afterDot in [1.0, 2.5]) {
          for (final afterDash in [1.0, 1.8]) {
            for (final letter in [3.0, 5.0]) {
              final pauseAfterDot = (dot * afterDot).round();
              final pauseAfterDash = (pauseAfterDot * afterDash).round();
              for (final message in [
                '... --- ...',
                '.... . .-.. .--.',
                '-.-. --.-',
                '.-- .- ... ... . .-.',
              ]) {
                final read = keyByHand(
                  MorseKeyer(),
                  message,
                  dot: dot,
                  dash: (dot * dash).round(),
                  afterDot: pauseAfterDot,
                  afterDash: pauseAfterDash,
                  letterGap: (pauseAfterDash * letter).round(),
                );
                if (read != message) {
                  misread.add(
                    '$dot ms, $dash/$afterDot/$afterDash/$letter: '
                    '$message -> $read',
                  );
                }
              }
            }
          }
        }
      }
    }
    expect(misread, isEmpty);
  });

  test('a long pause to think is a word gap, and the letters stay', () {
    expect(
      keyByHand(MorseKeyer(), '... --- .../... --- ...', wordGap: 4000),
      '... --- ... / ... --- ...',
    );
  });

  test('a short letter pause is still one, a slow one no word', () {
    expect(
      keyByHand(MorseKeyer(), '... --- ...', letterGap: 400),
      '... --- ...',
    );
    expect(
      keyByHand(MorseKeyer(), '... --- ...', letterGap: 900),
      '... --- ...',
    );
  });

  test('presses become dots and dashes, pauses letters and words', () {
    final keyed = key(MorseKeyer(), '... --- .../.-', unit: 200);
    expect(keyed, '... --- ... / .-');
    expect(decodeMorse(keyed).text, 'SOS A');
  });

  test('a slower hand is followed without being told the speed', () {
    final keyer = MorseKeyer();
    final keyed = key(keyer, '.... . .-.. .--.', unit: 450);
    expect(decodeMorse(keyed).text, 'HELP');
    expect(keyer.dot.inMilliseconds, greaterThan(300));
  });

  test('so is a faster one, once a dot has shown the difference', () {
    // At 90 ms a dot, the dashes of the first letter are shorter than the
    // fixed first line and read as dots -- until the first dot arrives
    // and the whole message is read again.
    final keyer = MorseKeyer();
    expect(key(keyer, '--', unit: 90), '..');
    keyer.reset();
    final keyed = key(keyer, '.-- .- ... ... . .-.', unit: 90);
    expect(decodeMorse(keyed).text, 'WASSER');
  });

  test("the app's own slowest lamp is read from the first press", () {
    expect(decodeMorse(key(MorseKeyer(), '--', unit: 500)).text, 'M');
    expect(decodeMorse(key(MorseKeyer(), '....', unit: 500)).text, 'H');
  });

  test('a hand that wobbles by a fifth is still read', () {
    final keyed = key(MorseKeyer(), '... --- ...', unit: 200, wobble: 40);
    expect(decodeMorse(keyed).text, 'SOS');
  });

  test('an up without a down adds nothing', () {
    final keyer = MorseKeyer();
    keyer.up(const Duration(seconds: 1));
    expect(keyer.isEmpty, isTrue);
    expect(keyer.code, '');
  });

  test('after a reset the next press starts afresh', () {
    final keyer = MorseKeyer();
    key(keyer, '...', unit: 200);
    keyer.reset();
    expect(keyer.isEmpty, isTrue);
    expect(key(keyer, '-', unit: 500), '-');
  });
}

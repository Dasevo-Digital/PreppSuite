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

void main() {
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

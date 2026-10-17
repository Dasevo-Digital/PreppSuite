import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/distress_signal.dart';
import 'package:preppsuite_flutter/features/home/application/signal_tone.dart';

/// The tone has to be the light's rhythm exactly: a dot as long as a dot,
/// silence where the lamp is dark.
void main() {
  const rate = 16000;
  final rhythm = SignalRhythm([
    (lit: true, length: const Duration(milliseconds: 100)),
    (lit: false, length: const Duration(milliseconds: 300)),
    (lit: true, length: const Duration(milliseconds: 50)),
    (lit: false, length: const Duration(milliseconds: 50)),
  ]);
  final wav = signalToneWav(rhythm, hertz: 800, sampleRate: rate);
  final header = ByteData.sublistView(wav, 0, 44);

  String ascii(int at, int length) =>
      String.fromCharCodes(wav.sublist(at, at + length));

  test('is a mono 8-bit PCM WAV as long as one turn', () {
    expect(ascii(0, 4), 'RIFF');
    expect(ascii(8, 4), 'WAVE');
    expect(header.getUint16(20, Endian.little), 1);
    expect(header.getUint16(22, Endian.little), 1);
    expect(header.getUint32(24, Endian.little), rate);
    expect(header.getUint16(34, Endian.little), 8);
    // 500 ms at 16 kHz.
    expect(header.getUint32(40, Endian.little), 8000);
    expect(wav.length, 44 + 8000);
  });

  bool soundsAt(int milliseconds) {
    final from = 44 + milliseconds * rate ~/ 1000;
    final window = wav.sublist(from, from + 40);
    return window.any((sample) => (sample - 128).abs() > 20);
  }

  test('sounds while lit and is silent while dark', () {
    expect(soundsAt(50), isTrue);
    expect(soundsAt(200), isFalse);
    expect(soundsAt(420), isTrue);
    expect(soundsAt(470), isFalse);
  });

  test('fades in, so the edge does not click', () {
    expect(wav[44], 128);
    expect((wav[45] - 128).abs(), lessThan(10));
  });

  test('the two-minute alpine turn stays under 2 MB', () {
    final alpine = signalToneWav(
      DistressSignalPattern(DistressSignal.alpine),
      hertz: distressToneHertz,
    );
    expect(alpine.length, lessThan(2 * 1024 * 1024));
  });
}

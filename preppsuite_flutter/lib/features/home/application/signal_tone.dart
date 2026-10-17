/// A rhythm of light and dark as a rhythm of tone and silence (#188).
///
/// Sound reaches where light does not: through rubble, round a corner,
/// in fog, up a stairwell. The alpine distress signal is defined as six
/// signals a minute, seen *or heard*, and Morse began as a sound. So the
/// distress signal and the Morse lamp can sound what they flash.
///
/// One turn of the rhythm is rendered into a WAV file ahead of time and
/// started again at the top of every turn, rather than a short beep
/// being triggered at each flash. A beep per flash would start a little
/// late every time, by however long the platform takes to open its audio
/// path, and at the fast Morse speed a dot is 120 ms; inside one file the
/// tone and the silence keep their lengths exactly, and restarting it each
/// turn keeps it in step with the light however long it runs.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'distress_signal.dart';

/// Where small phone speakers are loudest, and where a whistle sits:
/// for the distress signal, which has to carry.
const distressToneHertz = 2000.0;

/// The usual listening tone for Morse, lower and easier to follow for
/// a long message.
const morseToneHertz = 800.0;

/// One turn of [rhythm] as an 8-bit mono PCM WAV file.
///
/// 8 bits at 16 kHz because this is a beep, not music: the two-minute
/// turn of the alpine signal comes to under 2 MB. Each tone fades in and
/// out over a few milliseconds, which is what keeps a square edge from
/// clicking.
Uint8List signalToneWav(
  SignalRhythm rhythm, {
  required double hertz,
  int sampleRate = 16000,
}) {
  assert(hertz > 0 && hertz < sampleRate / 2);
  final spans = rhythm.spans;
  final total = spans.fold<int>(
    0,
    (sum, span) => sum + _samples(span.length, sampleRate),
  );
  final data = Uint8List(44 + total);
  final header = ByteData.sublistView(data, 0, 44);
  void ascii(int at, String text) {
    for (var i = 0; i < text.length; i++) {
      header.setUint8(at + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + total, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate, Endian.little); // bytes per second
  header.setUint16(32, 1, Endian.little); // bytes per frame
  header.setUint16(34, 8, Endian.little); // bits per sample
  ascii(36, 'data');
  header.setUint32(40, total, Endian.little);

  // 8-bit PCM is unsigned: 128 is silence.
  data.fillRange(44, data.length, 128);
  final fade = sampleRate * 5 ~/ 1000;
  final step = 2 * math.pi * hertz / sampleRate;
  var at = 44;
  for (final span in spans) {
    final length = _samples(span.length, sampleRate);
    if (span.lit) {
      for (var i = 0; i < length; i++) {
        final edge = math.min(i, length - 1 - i);
        final gain = edge >= fade ? 1.0 : edge / fade;
        data[at + i] = (128 + 110 * gain * math.sin(step * i)).round();
      }
    }
    at += length;
  }
  return data;
}

int _samples(Duration length, int sampleRate) =>
    length.inMicroseconds * sampleRate ~/ Duration.microsecondsPerSecond;

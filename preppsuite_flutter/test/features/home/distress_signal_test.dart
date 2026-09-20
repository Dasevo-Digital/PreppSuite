import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/distress_signal.dart';

/// The two rhythms that mean "here, and I need help".
///
/// Both are conventions somebody else wrote down, so the test is whether
/// this reproduces them — not whether it looks about right. A rhythm that
/// is nearly the alpine signal is a torch waving about.
void main() {
  group('SOS', () {
    final sos = DistressSignalPattern(
      DistressSignal.sos,
      unit: const Duration(milliseconds: 100),
    );

    test('nine flashes: three short, three long, three short', () {
      expect(sos.flashesPerPeriod, 9);

      final lengths = [
        for (final span in sos.spans)
          if (span.lit) span.length.inMilliseconds,
      ];
      expect(lengths, [100, 100, 100, 300, 300, 300, 100, 100, 100]);
    });

    test('it is one character, not three letters', () {
      // Three letters would put a three-unit gap between S, O and S. The
      // distress signal is a prosign: one unit throughout.
      final gaps = [
        for (final span in sos.spans)
          if (!span.lit) span.length.inMilliseconds,
      ];
      // Eight single gaps inside, then the word gap that ends it.
      expect(gaps, [100, 100, 100, 100, 100, 100, 100, 100, 700]);
    });

    test('the turn is thirty units long', () {
      // 15 units lit, 8 between the elements, 7 to close.
      expect(sos.period, const Duration(milliseconds: 3000));
    });

    test('it repeats exactly, however late the question comes', () {
      // The whole reason this is a function of elapsed time: a counter
      // that ticks late drifts, and a drifted rhythm is not a signal.
      for (final offset in [0, 250, 700, 1450, 2999]) {
        final early = Duration(milliseconds: offset);
        final late = early + sos.period * 97;
        expect(sos.isLitAt(late), sos.isLitAt(early), reason: '$offset ms');
      }
    });

    test('the lamp is on at the first dot and off in the closing gap', () {
      expect(sos.isLitAt(const Duration(milliseconds: 50)), isTrue);
      expect(sos.isLitAt(const Duration(milliseconds: 150)), isFalse);
      // The last 700 ms of the turn are the word gap.
      expect(sos.isLitAt(const Duration(milliseconds: 2500)), isFalse);
    });

    test('the default unit is slow enough to read by eye', () {
      // Morse fixes the ratios and not the speed; this is the app's own
      // choice, so it is pinned rather than left to drift.
      expect(DistressSignalPattern.defaultUnit.inMilliseconds, 500);
      expect(
        DistressSignalPattern(DistressSignal.sos).period,
        const Duration(seconds: 15),
      );
    });
  });

  group('the alpine distress signal', () {
    final alpine = DistressSignalPattern(DistressSignal.alpine);

    test('six inside one minute, then a minute of nothing', () {
      expect(alpine.flashesPerPeriod, 6);
      expect(alpine.period, const Duration(minutes: 2));

      // The sixth flash has to start before the minute is out, or it is
      // not six within a minute.
      expect(alpine.flashNumberAt(const Duration(seconds: 50)), 6);
      expect(alpine.flashNumberAt(const Duration(seconds: 59)), 0);
    });

    test('the pause is a full minute, because the answer goes in it', () {
      for (final second in [61, 75, 90, 110, 119]) {
        expect(
          alpine.isLitAt(Duration(seconds: second)),
          isFalse,
          reason: '$second s',
        );
      }
    });

    test('one every ten seconds', () {
      for (var flash = 0; flash < 6; flash++) {
        final at = Duration(seconds: flash * 10);
        expect(alpine.isLitAt(at), isTrue, reason: '${at.inSeconds} s');
        expect(alpine.flashNumberAt(at), flash + 1);
        // A second lit, nine dark.
        expect(alpine.isLitAt(at + const Duration(seconds: 2)), isFalse);
      }
    });

    test('the answer is three, and falls in the other one’s pause', () {
      final answer = DistressSignalPattern(DistressSignal.alpineAnswer);

      expect(answer.flashesPerPeriod, 3);
      expect(answer.period, const Duration(minutes: 2));
      expect(answer.isLitAt(const Duration(seconds: 20)), isTrue);
      expect(answer.isLitAt(const Duration(seconds: 40)), isTrue);
    });
  });

  test('a flash number is zero while nothing is lit', () {
    final alpine = DistressSignalPattern(DistressSignal.alpine);
    expect(alpine.flashNumberAt(const Duration(seconds: 5)), 0);
    expect(alpine.flashNumberAt(const Duration(seconds: 90)), 0);
  });
}

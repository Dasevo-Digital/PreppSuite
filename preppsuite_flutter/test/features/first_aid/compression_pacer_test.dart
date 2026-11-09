import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/compression_pacer.dart';

/// What is worth testing here is not "is 110 a minute 110 a minute" but
/// the two things that would be wrong in a way nobody notices: the count
/// of thirty drifting over the minutes, and the counter running backwards
/// when a clock is corrected.
void main() {
  const pacer = CompressionPacer();

  test('the default rate is inside the guideline and not at its floor', () {
    expect(
      CompressionPacer.defaultBeatsPerMinute,
      greaterThan(CompressionPacer.minimumBeatsPerMinute),
    );
    expect(
      CompressionPacer.defaultBeatsPerMinute,
      lessThan(CompressionPacer.maximumBeatsPerMinute),
    );
  });

  test('a rate outside the guideline is pulled back into it', () {
    // The dial only offers three values, but nothing stops a caller —
    // or a later screen — passing something else.
    const slow = CompressionPacer(beatsPerMinute: 40);
    const fast = CompressionPacer(beatsPerMinute: 400);
    expect(
      slow.beatInterval,
      const CompressionPacer(beatsPerMinute: 100).beatInterval,
    );
    expect(
      fast.beatInterval,
      const CompressionPacer(beatsPerMinute: 120).beatInterval,
    );
  });

  group('the beat', () {
    test('starts at zero and lands on the first count', () {
      final tick = pacer.at(Duration.zero);
      expect(tick.beat, 0);
      expect(tick.compression, 1);
      expect(tick.cycle, 1);
    });

    test('has not advanced a microsecond before it is due', () {
      final interval = pacer.beatInterval;
      expect(
        pacer.at(interval - const Duration(microseconds: 1)).beat,
        0,
      );
      expect(pacer.at(interval).beat, 1);
    });

    test('does not drift over ten minutes', () {
      // The point of computing from elapsed time rather than counting:
      // 110 a minute is 545,454.54... microseconds, and a pacer that
      // added a rounded interval per beat would be several beats out by
      // here -- which means the count of thirty would be wrong, which
      // means the breaths come at the wrong moment.
      const only = CompressionPacer(compressionsPerCycle: 0);
      const tenMinutes = Duration(minutes: 10);
      expect(only.at(tenMinutes).beat, 1100);
    });

    test('at 100 a minute an exact minute is exactly a hundred beats', () {
      const hundred = CompressionPacer(
        beatsPerMinute: 100,
        compressionsPerCycle: 0,
      );
      expect(hundred.at(const Duration(minutes: 1)).beat, 100);
    });
  });

  group('counting to thirty', () {
    test('runs one to thirty and then starts again', () {
      final interval = pacer.beatInterval;
      expect(pacer.at(interval * 29).compression, 30);
      expect(pacer.at(interval * 29).cycle, 1);
      expect(pacer.at(pacer.onsetOf(30)).compression, 1);
      expect(pacer.at(pacer.onsetOf(30)).cycle, 2);
    });

    test('the thirtieth beat is the one that calls for breaths', () {
      final interval = pacer.beatInterval;
      expect(pacer.at(interval * 28).isLastOfCycle, isFalse);
      expect(pacer.at(interval * 29).isLastOfCycle, isTrue);
      expect(pacer.at(pacer.onsetOf(30)).isLastOfCycle, isFalse);
    });

    test('a child counts to fifteen', () {
      const child = CompressionPacer(compressionsPerCycle: 15);
      final interval = child.beatInterval;
      expect(child.at(interval * 14).compression, 15);
      expect(child.at(interval * 14).isLastOfCycle, isTrue);
      expect(child.at(child.onsetOf(15)).compression, 1);
      expect(child.at(child.onsetOf(15)).cycle, 2);
    });

    test('compression-only never asks for breaths and keeps counting up', () {
      const only = CompressionPacer(compressionsPerCycle: 0);
      final interval = only.beatInterval;
      expect(only.at(interval * 40).compression, 41);
      expect(only.at(interval * 40).isLastOfCycle, isFalse);
      expect(only.at(interval * 40).cycle, 1);
    });
  });

  group('the breaths (#337)', () {
    final pressing = pacer.beatInterval * 30;

    test('the beat waits for them after the last compression', () {
      final tick = pacer.at(pressing);
      expect(tick.isBreathing, isTrue);
      expect(tick.breathLeft, CompressionPacer.breathPause);
      expect(tick.compression, 30);
    });

    test('no beat falls inside the pause', () {
      // A change of `beat` is a click. Clicking through the breaths is
      // what sent people back in at the wrong count.
      expect(pacer.at(pressing).beat, 29);
      expect(pacer.at(pressing + const Duration(seconds: 4)).beat, 29);
      expect(pacer.at(pressing + CompressionPacer.breathPause).beat, 30);
    });

    test('every round is thirty compressions, however long it runs', () {
      for (final round in [0, 1, 7, 40]) {
        final first = pacer.at(pacer.onsetOf(round * 30));
        final last = pacer.at(pacer.onsetOf(round * 30 + 29));
        expect(first.compression, 1, reason: 'round $round');
        expect(first.cycle, round + 1);
        expect(last.compression, 30, reason: 'round $round');
        expect(last.cycle, round + 1);
      }
    });

    test('a tap starts the next round and leaves the clock alone', () {
      final elapsed = pressing + const Duration(seconds: 2);
      final waiting = pacer.at(elapsed);
      final after = pacer.at(elapsed, skipped: waiting.breathLeft);
      expect(after.isBreathing, isFalse);
      expect(after.compression, 1);
      expect(after.cycle, 2);
      expect(after.elapsed, elapsed, reason: 'two minutes stay two minutes');
    });

    test('a beat is placed behind the pauses before it', () {
      expect(pacer.onsetOf(30), pressing + CompressionPacer.breathPause);
      expect(
        pacer.onsetOf(61),
        pacer.beatInterval * 61 + CompressionPacer.breathPause * 2,
      );
    });

    test('compression-only never waits', () {
      const only = CompressionPacer(compressionsPerCycle: 0);
      for (var seconds = 0; seconds < 300; seconds += 7) {
        expect(only.at(Duration(seconds: seconds)).isBreathing, isFalse);
      }
    });
  });

  group('a clock that goes backwards', () {
    test('reads as not started rather than as a negative count', () {
      // Only a clock correction can produce this, and a counter running
      // backwards mid-resuscitation would be worse than one that waits.
      final tick = pacer.at(const Duration(seconds: -5));
      expect(tick.beat, 0);
      expect(tick.compression, 1);
      expect(tick.elapsed, Duration.zero);
    });
  });

  group('changing over', () {
    test('nothing is due in the first two minutes', () {
      expect(pacer.at(const Duration(seconds: 119)).swapsDue, 0);
    });

    test('one at two minutes, two at four', () {
      expect(pacer.at(const Duration(minutes: 2)).swapsDue, 1);
      expect(pacer.at(const Duration(minutes: 4)).swapsDue, 2);
    });
  });

  test('a beat can be placed in time without adding intervals up', () {
    const only = CompressionPacer(compressionsPerCycle: 0);
    expect(only.onsetOf(0), Duration.zero);
    expect(only.onsetOf(110), closeTo60Seconds);
  });
}

/// 110 beats at 110 a minute is a minute, give or take the microsecond
/// that the interval was truncated by.
final closeTo60Seconds = predicate<Duration>(
  (d) =>
      (d - const Duration(minutes: 1)).abs() < const Duration(milliseconds: 1),
  'within a millisecond of a minute',
);

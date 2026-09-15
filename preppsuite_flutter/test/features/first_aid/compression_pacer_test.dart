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
      const tenMinutes = Duration(minutes: 10);
      expect(pacer.at(tenMinutes).beat, 1100);
    });

    test('at 100 a minute an exact minute is exactly a hundred beats', () {
      const hundred = CompressionPacer(beatsPerMinute: 100);
      expect(hundred.at(const Duration(minutes: 1)).beat, 100);
    });
  });

  group('counting to thirty', () {
    test('runs one to thirty and then starts again', () {
      final interval = pacer.beatInterval;
      expect(pacer.at(interval * 29).compression, 30);
      expect(pacer.at(interval * 29).cycle, 1);
      expect(pacer.at(interval * 30).compression, 1);
      expect(pacer.at(interval * 30).cycle, 2);
    });

    test('the thirtieth beat is the one that calls for breaths', () {
      final interval = pacer.beatInterval;
      expect(pacer.at(interval * 28).isLastOfCycle, isFalse);
      expect(pacer.at(interval * 29).isLastOfCycle, isTrue);
      expect(pacer.at(interval * 30).isLastOfCycle, isFalse);
    });

    test('a child counts to fifteen', () {
      const child = CompressionPacer(compressionsPerCycle: 15);
      final interval = child.beatInterval;
      expect(child.at(interval * 14).compression, 15);
      expect(child.at(interval * 14).isLastOfCycle, isTrue);
      expect(child.at(interval * 15).compression, 1);
      expect(child.at(interval * 15).cycle, 2);
    });

    test('compression-only never asks for breaths and keeps counting up', () {
      const only = CompressionPacer(compressionsPerCycle: 0);
      final interval = only.beatInterval;
      expect(only.at(interval * 40).compression, 41);
      expect(only.at(interval * 40).isLastOfCycle, isFalse);
      expect(only.at(interval * 40).cycle, 1);
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
    expect(pacer.onsetOf(0), Duration.zero);
    expect(pacer.onsetOf(110), closeTo60Seconds);
  });
}

/// 110 beats at 110 a minute is a minute, give or take the microsecond
/// that the interval was truncated by.
final closeTo60Seconds = predicate<Duration>(
  (d) =>
      (d - const Duration(minutes: 1)).abs() < const Duration(milliseconds: 1),
  'within a millisecond of a minute',
);

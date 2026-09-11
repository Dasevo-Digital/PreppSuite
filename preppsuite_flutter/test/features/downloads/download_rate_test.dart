import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/download_rate.dart';

/// How fast a download is going and how much longer it has.
///
/// The banner used to show only "1,2 GB von 52 GB", which answers how far
/// along in arithmetic and says nothing about when the archive will be
/// usable — which for a file this size is the only question.
void main() {
  group('the speed', () {
    test('nothing is said for the first two seconds', () {
      // A quarter of a second of a connection warming up reads as either
      // nothing or ten times the real speed, and a figure that swings by
      // a factor of ten is worse than no figure.
      expect(
        downloadRate(
          received: 5000000,
          total: 100000000,
          startedFrom: 0,
          elapsed: const Duration(milliseconds: 500),
        ),
        isNull,
      );
    });

    test('bytes since this run started, over the time since', () {
      final rate = downloadRate(
        received: 20000000,
        total: 100000000,
        startedFrom: 0,
        elapsed: const Duration(seconds: 10),
      );

      expect(rate!.bytesPerSecond, closeTo(2000000, 1));
    });

    test('a resumed download is measured from where it resumed', () {
      // The case this exists for: a 52 GB archive that stopped at 40 GB
      // is not going at 40 GB in ten seconds. Measuring from zero would
      // report a speed this connection has never managed, and a
      // remaining time to match.
      final rate = downloadRate(
        received: 41000000000,
        total: 52000000000,
        startedFrom: 40000000000,
        elapsed: const Duration(seconds: 100),
      );

      expect(rate!.bytesPerSecond, closeTo(10000000, 1));
    });

    test('a run that has moved nothing yet says nothing', () {
      expect(
        downloadRate(
          received: 40000000000,
          total: 52000000000,
          startedFrom: 40000000000,
          elapsed: const Duration(seconds: 30),
        ),
        isNull,
      );
    });

    test('it is formatted in the units a mirror states', () {
      final rate = downloadRate(
        received: 24000000,
        total: 100000000,
        startedFrom: 0,
        elapsed: const Duration(seconds: 10),
      );

      expect(rate!.formatted, '2.4 MB/s');
    });
  });

  group('the remaining time', () {
    Duration? remainingFor({
      required int received,
      required int? total,
      required int seconds,
    }) => downloadRate(
      received: received,
      total: total,
      startedFrom: 0,
      elapsed: Duration(seconds: seconds),
    )?.remaining;

    test('what is left, at the speed so far', () {
      // 20 MB in 10 s is 2 MB/s; 80 MB left is 40 s.
      expect(
        remainingFor(received: 20000000, total: 100000000, seconds: 10),
        const Duration(seconds: 40),
      );
    });

    test('without a stated total there is nothing to say', () {
      // Not a guess: a mirror behind a redirect sometimes gives no
      // length at all.
      expect(
        remainingFor(received: 20000000, total: null, seconds: 10),
        isNull,
      );
    });

    test('a finished download has nothing left', () {
      expect(
        remainingFor(received: 100000000, total: 100000000, seconds: 10),
        isNull,
      );
    });

    test('days are reported as days, not smoothed away', () {
      // A 52 GB archive on a bad line really is measured in days, and
      // rounding that down to something comfortable would be a lie about
      // when it can be used.
      // 10 MB in 100 s is 100 kB/s; the remaining 52 GB is six days.
      final remaining = remainingFor(
        received: 10000000,
        total: 52000000000,
        seconds: 100,
      );

      expect(remaining!.inDays, 6);
    });
  });

  group('putting it in words', () {
    test('under a minute is seconds', () {
      final parts = splitRemaining(const Duration(seconds: 42));
      expect(parts.seconds, 42);
      expect(parts.minutes, isNull);
      expect(parts.hours, isNull);
    });

    test('under an hour is minutes', () {
      // Nobody waiting on a 52 GB archive needs seconds.
      final parts = splitRemaining(const Duration(minutes: 7, seconds: 30));
      expect(parts.minutes, 7);
      expect(parts.seconds, isNull);
    });

    test('above that, hours and the minutes inside the hour', () {
      final parts = splitRemaining(const Duration(hours: 3, minutes: 25));
      expect(parts.hours, 3);
      expect(parts.minutes, 25);
      expect(parts.seconds, isNull);
    });

    test('an exact hour keeps its zero minutes rather than vanishing', () {
      final parts = splitRemaining(const Duration(hours: 2));
      expect(parts.hours, 2);
      expect(parts.minutes, 0);
    });
  });
}

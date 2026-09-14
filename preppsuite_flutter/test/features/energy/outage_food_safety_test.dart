import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/application/outage_food_safety.dart';

/// The figures themselves are FEMA's and the USDA's, so what is worth
/// testing is not "is four hours four hours" but the edges a household
/// actually meets: the moment a window closes, the two hours after it,
/// a freezer that is half empty, and a clock that was corrected.
void main() {
  final wentDark = DateTime.utc(2026, 9, 14, 20);

  List<ColdStoreStatus> at(
    Duration since, {
    FreezerFill fill = FreezerFill.full,
  }) => coldStoreStatuses(
    startedAt: wentDark,
    now: wentDark.add(since),
    freezerFill: fill,
  );

  ColdStoreStatus fridge(List<ColdStoreStatus> all) =>
      all.firstWhere((s) => s.store == ColdStore.refrigerator);
  ColdStoreStatus freezer(List<ColdStoreStatus> all) =>
      all.firstWhere((s) => s.store == ColdStore.freezer);

  test('the two stores are answered separately', () {
    final statuses = at(const Duration(hours: 1));
    expect(statuses.map((s) => s.store), [
      ColdStore.refrigerator,
      ColdStore.freezer,
    ]);
  });

  group('the refrigerator', () {
    test('has three hours left after one', () {
      expect(
        fridge(at(const Duration(hours: 1))).remaining,
        const Duration(hours: 3),
      );
      expect(fridge(at(const Duration(hours: 1))).isOver, isFalse);
    });

    test('is over exactly at four hours, not a minute before', () {
      expect(
        fridge(at(const Duration(hours: 3, minutes: 59))).isOver,
        isFalse,
      );
      expect(fridge(at(const Duration(hours: 4))).isOver, isTrue);
    });

    test('never counts backwards past zero', () {
      final late = fridge(at(const Duration(days: 3)));
      expect(late.remaining, Duration.zero);
      expect(late.fraction, 1.0);
    });
  });

  group('the two-hour rule', () {
    test('has not started while the window is still open', () {
      expect(
        fridge(at(const Duration(hours: 2))).graceRemaining,
        perishableGrace,
      );
      expect(fridge(at(const Duration(hours: 2))).isSpoilt, isFalse);
    });

    test('runs down over the two hours after the window', () {
      expect(
        fridge(at(const Duration(hours: 5))).graceRemaining,
        const Duration(hours: 1),
      );
    });

    test('is what decides that food is thrown out', () {
      expect(
        fridge(at(const Duration(hours: 5, minutes: 59))).isSpoilt,
        isFalse,
      );
      expect(fridge(at(const Duration(hours: 6))).isSpoilt, isTrue);
    });
  });

  group('how full the freezer is', () {
    test('doubles the answer', () {
      final full = freezer(at(Duration.zero, fill: FreezerFill.full));
      final half = freezer(at(Duration.zero, fill: FreezerFill.half));
      expect(full.window, const Duration(hours: 48));
      expect(half.window, const Duration(hours: 24));
    });

    test('decides whether a day-old blackout has spoilt it', () {
      const aDayAndAHalf = Duration(hours: 36);
      expect(freezer(at(aDayAndAHalf, fill: FreezerFill.full)).isOver, isFalse);
      expect(freezer(at(aDayAndAHalf, fill: FreezerFill.half)).isOver, isTrue);
    });

    test('does not change the refrigerator', () {
      for (final fill in FreezerFill.values) {
        expect(
          fridge(at(const Duration(hours: 1), fill: fill)).window,
          refrigeratorWindow,
        );
      }
    });
  });

  group('a clock that is wrong', () {
    test('a start in the future reads as just now, never as negative', () {
      // Clocks get corrected, and a countdown running backwards would be
      // worse than one that restarts.
      final statuses = coldStoreStatuses(
        startedAt: wentDark,
        now: wentDark.subtract(const Duration(hours: 2)),
        freezerFill: FreezerFill.full,
      );
      expect(fridge(statuses).elapsed, Duration.zero);
      expect(fridge(statuses).remaining, refrigeratorWindow);
    });
  });

  test('the end is an instant somebody can write on a note', () {
    final status = fridge(at(const Duration(minutes: 30)));
    expect(
      windowEndsAt(wentDark, status),
      DateTime.utc(2026, 9, 15, 0),
    );
  });

  test('the bar fills rather than empties', () {
    expect(fridge(at(Duration.zero)).fraction, 0.0);
    expect(fridge(at(const Duration(hours: 2))).fraction, 0.5);
    expect(fridge(at(const Duration(hours: 4))).fraction, 1.0);
  });
}

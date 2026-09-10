import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/charge_reminder_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How often the app asks somebody to check their power banks.
///
/// The chips are suggestions; the setting takes any interval up to a year.
/// That distinction is the whole point of these tests: the accepted range
/// used to be the chip list itself, so a freely chosen value was taken for
/// the session and then quietly reset to ninety days on the next launch,
/// because loading discarded anything the list did not contain. A reminder
/// that changes its own interval behind the user's back is worse than one
/// they cannot set at all.
void main() {
  Future<ProviderContainer> container() async {
    final ref = ProviderContainer();
    addTearDown(ref.dispose);
    // The first read starts the load from preferences; without waiting for
    // it the controller still holds its default.
    ref.read(chargeReminderDaysProvider);
    await Future<void>.delayed(Duration.zero);
    return ref;
  }

  group('what the setting accepts', () {
    test('a fortnight is on offer, which it was not', () {
      expect(selectableChargeReminderDays, contains(14));
    });

    test('off is always allowed', () {
      expect(isChargeReminderDays(0), isTrue);
    });

    test('anything from a day to a year is allowed', () {
      expect(isChargeReminderDays(1), isTrue);
      expect(isChargeReminderDays(21), isTrue);
      expect(isChargeReminderDays(365), isTrue);
    });

    test('beyond a year and below a day is not', () {
      expect(isChargeReminderDays(366), isFalse);
      expect(isChargeReminderDays(-1), isFalse);
    });

    test('a value no chip offers is still a valid setting', () {
      // The reason this is not just the chip list: 21 is a perfectly
      // sensible answer and no chip proposes it.
      expect(selectableChargeReminderDays, isNot(contains(21)));
      expect(isChargeReminderDays(21), isTrue);
    });
  });

  group('remembering it', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('an interval from the chips is kept', () async {
      final ref = await container();
      await ref.read(chargeReminderDaysProvider.notifier).setDays(14);

      expect(ref.read(chargeReminderDaysProvider), 14);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('chargeReminderDays'), 14);
    });

    test('a freely chosen interval survives a restart', () async {
      final first = await container();
      await first.read(chargeReminderDaysProvider.notifier).setDays(21);

      // A second container reads the same preferences a relaunch would.
      final second = await container();
      expect(second.read(chargeReminderDaysProvider), 21);
    });

    test('an interval out of range is refused, not stored', () async {
      final ref = await container();
      await ref.read(chargeReminderDaysProvider.notifier).setDays(90);
      await ref.read(chargeReminderDaysProvider.notifier).setDays(4000);

      expect(ref.read(chargeReminderDaysProvider), 90);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('chargeReminderDays'), 90);
    });

    test('switching it off is kept as off, not as missing', () async {
      final ref = await container();
      await ref.read(chargeReminderDaysProvider.notifier).setDays(0);

      final second = await container();
      expect(second.read(chargeReminderDaysProvider), 0);
    });

    test(
      'a stored value from a broken write falls back to the default',
      () async {
        SharedPreferences.setMockInitialValues({'chargeReminderDays': -5});

        final ref = await container();
        expect(ref.read(chargeReminderDaysProvider), defaultChargeReminderDays);
      },
    );

    test('nothing stored means the default', () async {
      final ref = await container();
      expect(ref.read(chargeReminderDaysProvider), defaultChargeReminderDays);
    });
  });

  group('when the next check is due', () {
    // A blind interval fires whether or not anybody went and looked. These
    // are the cases that separate "not yet", "today", "behind" and "nobody
    // has ever confirmed one" — the last of which is not a failure to keep
    // up with anything.
    ChargeCheck at(DateTime? checked, int every) =>
        ChargeCheck(lastChecked: checked, everyDays: every);

    final monday = DateTime.utc(2026, 9, 7, 8);

    test('switched off, nothing is ever due', () {
      final check = at(monday, 0);

      expect(check.isOff, isTrue);
      expect(check.dueAt, isNull);
      expect(check.isDue(now: monday.add(const Duration(days: 400))), isFalse);
    });

    test('never confirmed is not the same as overdue', () {
      final check = at(null, 14);

      expect(check.daysUntilDue(now: monday), isNull);
      expect(check.isDue(now: monday), isFalse);
    });

    test('the interval is counted from the last check', () {
      final check = at(monday, 14);

      expect(check.dueAt, DateTime.utc(2026, 9, 21, 8));
      expect(check.daysUntilDue(now: monday), 14);
    });

    test('the day before is not yet due', () {
      final check = at(monday, 14);

      expect(check.daysUntilDue(now: DateTime.utc(2026, 9, 20, 23)), 1);
      expect(check.isDue(now: DateTime.utc(2026, 9, 20, 23)), isFalse);
    });

    test('the day itself is due, whatever the time of day', () {
      final check = at(monday, 14);

      // Compared by calendar day, not by the hour: a check confirmed at
      // eight in the morning is not "due at eight" two weeks later.
      expect(check.isDue(now: DateTime.utc(2026, 9, 21, 0, 5)), isTrue);
      expect(check.isDue(now: DateTime.utc(2026, 9, 21, 23, 55)), isTrue);
      expect(check.daysUntilDue(now: DateTime.utc(2026, 9, 21, 23)), 0);
    });

    test('afterwards it counts how far behind', () {
      final check = at(monday, 14);

      expect(check.daysUntilDue(now: DateTime.utc(2026, 9, 24)), -3);
      expect(check.isDue(now: DateTime.utc(2026, 9, 24)), isTrue);
    });
  });

  group('confirming a check', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is remembered across a restart', () async {
      final first = ProviderContainer();
      addTearDown(first.dispose);
      first.read(chargeCheckProvider);
      await Future<void>.delayed(Duration.zero);
      await first
          .read(chargeCheckProvider.notifier)
          .markChecked(at: DateTime.utc(2026, 9, 7));

      final second = ProviderContainer();
      addTearDown(second.dispose);
      second.read(chargeCheckProvider);
      await Future<void>.delayed(Duration.zero);

      expect(
        second.read(chargeCheckProvider).lastChecked,
        DateTime.utc(2026, 9, 7),
      );
    });

    test('changing the interval moves the due date, not the check', () async {
      final ref = ProviderContainer();
      addTearDown(ref.dispose);
      ref.read(chargeCheckProvider);
      await Future<void>.delayed(Duration.zero);
      await ref
          .read(chargeCheckProvider.notifier)
          .markChecked(at: DateTime.utc(2026, 9, 7));

      await ref.read(chargeReminderDaysProvider.notifier).setDays(14);
      await Future<void>.delayed(Duration.zero);

      final check = ref.read(chargeCheckProvider);
      expect(check.everyDays, 14);
      expect(check.lastChecked, DateTime.utc(2026, 9, 7));
      expect(check.dueAt, DateTime.utc(2026, 9, 21));
    });
  });
}

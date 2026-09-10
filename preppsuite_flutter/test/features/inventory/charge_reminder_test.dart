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
}

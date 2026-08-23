import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_planner.dart';
import 'package:preppsuite_flutter/features/inventory/application/expiry_reminder_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to the planner defaults', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(expiryLeadDaysProvider), defaultExpiryLeadDays);
  });

  test('setLeadDays sorts descending, dedupes and persists', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(expiryLeadDaysProvider.notifier).setLeadDays([
      7,
      30,
      7,
    ]);

    expect(container.read(expiryLeadDaysProvider), [30, 7]);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('expiryLeadDays'), '30,7');
  });

  test('values outside the selectable list are rejected', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(expiryLeadDaysProvider.notifier).setLeadDays([
      30,
      5,
      -1,
      1000,
    ]);

    expect(container.read(expiryLeadDaysProvider), [30]);
  });

  test('toggle adds a missing lead time and removes a present one', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(expiryLeadDaysProvider.notifier);

    await notifier.setLeadDays([30]);
    await notifier.toggle(7);
    expect(container.read(expiryLeadDaysProvider), [30, 7]);

    await notifier.toggle(30);
    expect(container.read(expiryLeadDaysProvider), [7]);
  });

  test('a persisted selection is restored on next launch', () async {
    SharedPreferences.setMockInitialValues({'expiryLeadDays': '14,3'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Same as the other preference controllers: the synchronous initial
    // value is the default until the async prefs load lands.
    expect(container.read(expiryLeadDaysProvider), defaultExpiryLeadDays);
    await pumpEventQueue();

    expect(container.read(expiryLeadDaysProvider), [14, 3]);
  });

  test(
    'an empty stored value means "no reminders", not the defaults',
    () async {
      SharedPreferences.setMockInitialValues({'expiryLeadDays': ''});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // The read is what builds the provider and starts the prefs load, so
      // it has to happen before pumping, not after.
      expect(container.read(expiryLeadDaysProvider), defaultExpiryLeadDays);
      await pumpEventQueue();

      expect(container.read(expiryLeadDaysProvider), isEmpty);
    },
  );

  test('clearing every lead time persists as empty', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(expiryLeadDaysProvider.notifier).setLeadDays([]);

    expect(container.read(expiryLeadDaysProvider), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('expiryLeadDays'), '');
  });
}

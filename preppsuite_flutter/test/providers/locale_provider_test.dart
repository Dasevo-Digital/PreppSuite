import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to null (follow system locale)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(localeOverrideProvider), isNull);
  });

  test('setLocale updates state immediately and persists it', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(localeOverrideProvider.notifier)
        .setLocale(const Locale('de'));

    expect(container.read(localeOverrideProvider), const Locale('de'));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('localeOverride'), 'de');
  });

  test('a persisted preference is restored on next launch', () async {
    SharedPreferences.setMockInitialValues({'localeOverride': 'en'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Reading triggers `build()`, which kicks off the async prefs load in
    // the background — the initial value is synchronously null (see the
    // controller's doc comment on why) until that completes.
    expect(container.read(localeOverrideProvider), isNull);
    await pumpEventQueue();

    expect(container.read(localeOverrideProvider), const Locale('en'));
  });

  test('setLocale(null) reverts to following the system locale and clears '
      'the stored preference', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(localeOverrideProvider.notifier);

    await notifier.setLocale(const Locale('de'));
    await notifier.setLocale(null);

    expect(container.read(localeOverrideProvider), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('localeOverride'), isFalse);
  });
}

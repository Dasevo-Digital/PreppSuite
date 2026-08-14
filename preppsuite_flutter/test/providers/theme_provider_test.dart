import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to ThemeMode.system', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('setThemeMode updates state immediately and persists it', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.dark);

    expect(container.read(themeModeProvider), ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeModeOverride'), 'dark');
  });

  test('a persisted preference is restored on next launch', () async {
    SharedPreferences.setMockInitialValues({'themeModeOverride': 'light'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Reading triggers `build()`, which kicks off the async prefs load in
    // the background — the initial value is synchronously "system" (see
    // the controller's doc comment on why) until that completes.
    expect(container.read(themeModeProvider), ThemeMode.system);
    await pumpEventQueue();

    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}

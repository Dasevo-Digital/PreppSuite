import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/server_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ServerUrlController.compiledDefault = 'http://localhost:8080/';
  });

  test('falls back to what the app was built with', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(serverUrlProvider), 'http://localhost:8080/');
  });

  test('a stored address wins over the compiled one', () async {
    SharedPreferences.setMockInitialValues({
      serverUrlPrefsKey: 'https://preppsuite.example.com/',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // The read builds the provider and starts the prefs load.
    expect(container.read(serverUrlProvider), 'http://localhost:8080/');
    await pumpEventQueue();

    expect(
      container.read(serverUrlProvider),
      'https://preppsuite.example.com/',
    );
  });

  test('setServerUrl normalizes before storing', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final accepted = await container
        .read(serverUrlProvider.notifier)
        .setServerUrl('  preppsuite.example.com  ');

    expect(accepted, isTrue);
    expect(
      container.read(serverUrlProvider),
      'https://preppsuite.example.com/',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(serverUrlPrefsKey),
      'https://preppsuite.example.com/',
      reason: 'the normalized form is what gets stored, not the raw input',
    );
  });

  test('an unusable address is rejected and nothing is stored', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final accepted = await container
        .read(serverUrlProvider.notifier)
        .setServerUrl('ftp://example.com');

    expect(accepted, isFalse);
    expect(
      container.read(serverUrlProvider),
      'http://localhost:8080/',
      reason: 'a rejected address must not replace a working one',
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(serverUrlPrefsKey), isNull);
  });

  test('a stored address survives the next launch', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(serverUrlProvider.notifier)
        .setServerUrl('192.168.1.5:8080');

    // A second container stands in for the next app start.
    final next = ProviderContainer();
    addTearDown(next.dispose);
    next.read(serverUrlProvider);
    await pumpEventQueue();

    expect(next.read(serverUrlProvider), 'http://192.168.1.5:8080/');
  });
}

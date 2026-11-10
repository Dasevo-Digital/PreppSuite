import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/notifications_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A switch that arrived on from another device was never put to this
/// device's system (#333).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final original = NotificationsEnabledController.askSystem;
  final originalFolder = NotificationsEnabledController.markerFolder;
  late Directory cache;
  setUp(() async {
    cache = await Directory.systemTemp.createTemp('preppsuite-cache');
    NotificationsEnabledController.markerFolder = () async => cache;
  });
  tearDown(() async {
    NotificationsEnabledController.askSystem = original;
    NotificationsEnabledController.markerFolder = originalFolder;
    await cache.delete(recursive: true);
  });

  var asked = 0;
  void systemAnswers(bool answer) {
    asked = 0;
    NotificationsEnabledController.askSystem = () async {
      asked++;
      return answer;
    };
  }

  Future<(ProviderContainer, bool)> load() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(notificationsEnabledProvider.notifier);
    await notifier.ensureLoaded();
    // The question goes out after the load, on purpose, and reads a real
    // file: waiting for the event queue alone was not always enough.
    await notifier.askedForTesting;
    return (container, container.read(notificationsEnabledProvider));
  }

  test('a switch that arrived on is put to the system once', () async {
    SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
    systemAnswers(true);

    final (_, enabled) = await load();
    expect(asked, 1);
    expect(enabled, isTrue);

    await load();
    expect(asked, 1, reason: 'once per device, not once per start');
  });

  test('what the system refuses is what gets stored', () async {
    SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
    systemAnswers(false);

    final (_, enabled) = await load();

    expect(enabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notificationsEnabled'), isFalse);
  });

  test('a switch that is off asks nothing', () async {
    SharedPreferences.setMockInitialValues({'notificationsEnabled': false});
    systemAnswers(true);

    await load();

    expect(asked, 0);
  });

  test('a preference that came with a transferred phone is not "asked" '
      '(#333)', () async {
    // Android's device-to-device transfer carries the preferences, and
    // 2.9.5 kept the marker there. The cache folder stays behind.
    SharedPreferences.setMockInitialValues({
      'notificationsEnabled': true,
      'notificationsPermissionAskedHere': true,
    });
    systemAnswers(true);

    await load();

    expect(asked, 1);
  });

  test(
    'without a cache folder it never asks rather than every start',
    () async {
      SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
      NotificationsEnabledController.markerFolder = () async =>
          throw const FileSystemException('none');
      systemAnswers(true);

      await load();
      await load();

      expect(asked, 0);
    },
  );

  test('turning it on here counts as having asked', () async {
    SharedPreferences.setMockInitialValues({});
    systemAnswers(true);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(notificationsEnabledProvider.notifier);
    await notifier.ensureLoaded();

    await notifier.setEnabled(true);
    expect(asked, 1);

    await load();
    expect(asked, 1);
  });
}

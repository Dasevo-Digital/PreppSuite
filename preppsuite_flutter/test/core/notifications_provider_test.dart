import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/notifications_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A switch that arrived on from another device was never put to this
/// device's system (#333).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final original = NotificationsEnabledController.askSystem;
  tearDown(() => NotificationsEnabledController.askSystem = original);

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
    // The question goes out after the load, on purpose.
    await pumpEventQueue();
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

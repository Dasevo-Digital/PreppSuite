import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_flutter/core/crisis_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('starts disabled and persists an explicit crisis-mode choice', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(crisisModeProvider), isFalse);
    await container.read(crisisModeProvider.notifier).setEnabled(true);

    expect(container.read(crisisModeProvider), isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool('crisisModeGlobal'),
      isTrue,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/memory_pressure_listener.dart';

void main() {
  testWidgets(
    'memory pressure reaches active listeners and disposal unregisters them',
    (tester) async {
      var calls = 0;
      final listener = MemoryPressureListener(() => calls++);
      tester.binding.handleMemoryPressure();
      expect(calls, 1);
      listener.dispose();
      tester.binding.handleMemoryPressure();
      expect(calls, 1);
    },
  );
}

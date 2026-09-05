import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';

void main() {
  group('choosing the shell navigation', () {
    test('a phone keeps the bar along the bottom', () {
      // Every current phone upright, and the narrow half of an iPad in
      // Split View.
      expect(shellNavigationFor(320), ShellNavigation.bar);
      expect(shellNavigationFor(430), ShellNavigation.bar);
      expect(shellNavigationFor(599), ShellNavigation.bar);
    });

    test('a tablet gets a rail', () {
      expect(shellNavigationFor(600), ShellNavigation.rail);
      // iPad Pro 13" upright.
      expect(shellNavigationFor(1024), ShellNavigation.rail);
    });

    test('a wide window spells the labels out', () {
      // iPad Pro 13" on its side, and any desktop window worth the name.
      expect(shellNavigationFor(1200), ShellNavigation.extendedRail);
      expect(shellNavigationFor(1366), ShellNavigation.extendedRail);
    });

    test('a window narrowed to nothing still decides', () {
      // Desktop windows get dragged, and a zero width is passed through
      // on the way rather than being a special case.
      expect(shellNavigationFor(0), ShellNavigation.bar);
    });
  });
}

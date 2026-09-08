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

  group('fitting the destinations into a bar', () {
    ShellSlots slots(
      ShellNavigation navigation,
      ShellDestination selected, [
      List<ShellDestination>? destinations,
    ]) => shellSlotsFor(
      navigation: navigation,
      selected: selected,
      destinations: destinations ?? ShellDestination.values,
    );

    test('a rail shows every destination', () {
      // It scrolls, and a window wide enough for a rail is tall enough
      // for the list.
      for (final navigation in [
        ShellNavigation.rail,
        ShellNavigation.extendedRail,
      ]) {
        final result = slots(navigation, ShellDestination.settings);
        expect(result.visible, ShellDestination.values);
        expect(result.overflow, isEmpty);
        expect(result.hasOverflow, isFalse);
      }
    });

    test('a bar keeps the first few and hides the rest', () {
      final result = slots(ShellNavigation.bar, ShellDestination.overview);

      expect(result.visible, [
        ShellDestination.overview,
        ShellDestination.emergency,
        ShellDestination.inventory,
        ShellDestination.checklists,
      ]);
      expect(result.visible, hasLength(barSlotLimit - 1));
      expect(result.hasOverflow, isTrue);
      expect(result.overflow.first, ShellDestination.warnings);
      expect(
        {...result.visible, ...result.overflow},
        ShellDestination.values.toSet(),
        reason: 'a destination must not fall out of the app entirely',
      );
    });

    test('a bar with few enough destinations hides nothing', () {
      final result = slots(ShellNavigation.bar, ShellDestination.inventory, [
        ShellDestination.overview,
        ShellDestination.inventory,
        ShellDestination.checklists,
      ]);

      expect(result.visible, hasLength(3));
      expect(result.hasOverflow, isFalse);
    });

    test('exactly as many destinations as slots still fit', () {
      final five = ShellDestination.values.take(barSlotLimit).toList();
      final result = slots(ShellNavigation.bar, five.last, five);

      expect(result.visible, five);
      expect(result.hasOverflow, isFalse);
    });

    test('the open destination is always on the bar', () {
      // Otherwise the bar shows nothing selected while that screen is on
      // display, which reads as "you are nowhere".
      for (final destination in ShellDestination.values) {
        final result = slots(ShellNavigation.bar, destination);
        expect(
          result.visible,
          contains(destination),
          reason: '$destination was open but not on the bar',
        );
        expect(result.overflow, isNot(contains(destination)));
      }
    });

    test('a hidden destination takes the last slot, not an extra one', () {
      final result = slots(ShellNavigation.bar, ShellDestination.settings);

      expect(result.visible, hasLength(barSlotLimit - 1));
      expect(result.visible.last, ShellDestination.settings);
      // The ones before it stay where a thumb last found them.
      expect(result.visible.take(3), [
        ShellDestination.overview,
        ShellDestination.emergency,
        ShellDestination.inventory,
      ]);
    });

    test('the overflow keeps the declared order', () {
      final result = slots(ShellNavigation.bar, ShellDestination.knowledge);
      final order = ShellDestination.values;

      expect(
        result.overflow,
        orderedEquals(
          order.where(result.overflow.contains).toList(),
        ),
      );
    });
  });
}

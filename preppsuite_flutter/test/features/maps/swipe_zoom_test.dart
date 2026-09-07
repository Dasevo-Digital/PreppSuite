import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/presentation/swipe_zoom.dart';

/// Zooming a map with a device that has no wheel.
///
/// The widget itself needs a map under it and a gesture on top, neither
/// of which a widget test provides. The arithmetic it turns on does not,
/// and getting the sign wrong there means every swipe zooms the wrong
/// way — which nobody would call a rounding error.
void main() {
  test('swiping up zooms in, down zooms out', () {
    // Flutter's y grows downwards, so a swipe up is negative.
    expect(zoomForSwipe(startZoom: 8, swipeY: -100), 9);
    expect(zoomForSwipe(startZoom: 8, swipeY: 100), 7);
  });

  test('a hundred pixels is one level', () {
    expect(zoomForSwipe(startZoom: 5, swipeY: -50), 5.5);
    expect(zoomForSwipe(startZoom: 5, swipeY: -200), 7);
  });

  test('the limits hold', () {
    expect(zoomForSwipe(startZoom: 3, swipeY: 1000, lowest: 2), 2);
    expect(zoomForSwipe(startZoom: 17, swipeY: -1000, highest: 18), 18);
  });

  test('a pinch is left to the map', () {
    // A real trackpad sends the same event kind for a pinch, with a
    // scale. flutter_map already handles that, and doing it here as well
    // would zoom twice.
    expect(isSwipe(1.0), isTrue);
    expect(isSwipe(1.005), isTrue);
    expect(isSwipe(0.995), isTrue);
    expect(isSwipe(1.2), isFalse);
    expect(isSwipe(0.8), isFalse);
  });
}

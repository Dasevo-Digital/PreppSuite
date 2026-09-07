import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// How much zoom a swipe of one logical pixel is worth.
///
/// 0.01 means a hundred pixels of swipe is one zoom level. A comfortable
/// swipe on a trackpad covers one to two hundred, so one to two levels —
/// which is what maps everywhere else feel like.
const double swipeZoomFactor = 0.01;

/// How far the scale may stray from 1 and still count as a swipe.
///
/// A real trackpad sends the same kind of event for a two-finger pinch as
/// for a swipe, only with a scale value. flutter_map already handles the
/// pinch, and must not be interfered with there.
const double swipePinchThreshold = 0.01;

/// The zoom a swipe arrives at.
///
/// Up zooms in, down zooms out — the way Apple Maps and Google Maps behave
/// on a trackpad. Flutter's y grows downwards, so a swipe up gives a
/// negative [swipeY].
double zoomForSwipe({
  required double startZoom,
  required double swipeY,
  double? lowest,
  double? highest,
}) {
  final next = startZoom - swipeY * swipeZoomFactor;
  return next.clamp(lowest ?? 0.0, highest ?? double.infinity);
}

/// Whether this gesture is a swipe rather than a pinch.
bool isSwipe(double scale) => (scale - 1).abs() <= swipePinchThreshold;

/// Lays swipe-to-zoom over a map.
///
/// **Why this is needed, and why it is not one line.** A Magic Mouse has
/// no wheel but a touch surface, and macOS reports a swipe on it not as
/// wheel notches but as a continuous gesture — technically a trackpad.
/// flutter_map builds its own gesture handling and leaves
/// `trackpadScrollCausesScale` at its default of `false`, so such input
/// *pans* instead of zooming. The library offers no way to change that
/// from outside.
///
/// **The ordering is the trick here, and it runs the opposite way round
/// from what one expects.** A [Listener] gets its event before the
/// gesture recognisers work on it: Flutter delivers the event down the
/// hit-tested widget chain first and runs the recognisers last. Setting
/// centre and zoom straight away means the map writes its pan over the
/// top immediately afterwards.
///
/// So the correction is scheduled as a microtask. That runs once event
/// delivery has finished — after the map, and still inside the same
/// frame. Only the result is ever visible.
///
/// The obvious alternative, a gesture recogniser of our own competing
/// with the map for the pointer, would hang on which of the two wins the
/// arena first. This does not.
class SwipeZoom extends StatefulWidget {
  const SwipeZoom({
    super.key,
    required this.controller,
    required this.child,
    this.lowestZoom,
    this.highestZoom,
  });

  final MapController controller;
  final Widget child;
  final double? lowestZoom;
  final double? highestZoom;

  @override
  State<SwipeZoom> createState() => _SwipeZoomState();
}

class _SwipeZoomState extends State<SwipeZoom> {
  /// Where the gesture started. The zoom is carried forward from this
  /// rather than from the last value: `pan` is the whole distance since
  /// the gesture began, not the distance since the last event.
  double? _startZoom;
  LatLng? _startCentre;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerPanZoomStart: (_) {
      final camera = widget.controller.camera;
      _startZoom = camera.zoom;
      _startCentre = camera.center;
    },
    onPointerPanZoomUpdate: (event) {
      final startZoom = _startZoom;
      final startCentre = _startCentre;
      if (startZoom == null || startCentre == null) return;
      if (!isSwipe(event.scale)) return;

      final next = zoomForSwipe(
        startZoom: startZoom,
        swipeY: event.pan.dy,
        lowest: widget.lowestZoom,
        highest: widget.highestZoom,
      );
      // The centre is set deliberately as well: it takes back what the
      // map made of the same gesture as a pan. And it does so *after*
      // the map — see the explanation above.
      scheduleMicrotask(() {
        if (!mounted || _startZoom == null) return;
        widget.controller.move(startCentre, next);
      });
    },
    onPointerPanZoomEnd: (_) {
      _startZoom = null;
      _startCentre = null;
    },
    child: widget.child,
  );
}

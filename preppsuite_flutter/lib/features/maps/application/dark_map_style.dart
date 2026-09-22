/// A dark map, made from the light one.
///
/// The renderer ships exactly one style and it is light. In a dark app
/// that made the offline map a white rectangle — the single brightest
/// thing on the screen, on the feature somebody opens at night in a
/// power cut.
///
/// **Turned rather than replaced.** A second hand-written style would be
/// a second thing to keep in step with the first, for a map whose whole
/// job is to show the same roads. So the style data is walked and every
/// colour in it is turned over: the hue stays, the lightness flips, the
/// saturation is damped. Land that was white becomes near-black, the
/// lettering that was near-black becomes light, and a green park stays
/// recognisably a park instead of turning magenta the way a plain pixel
/// inversion would.
///
/// It walks *every* string in the structure rather than the colour keys
/// it knows about. A Mapbox style puts colours inside expressions and
/// stop lists as well as in `paint`, and a walk that knew the schema
/// would miss exactly the ones that are hardest to spot.
library;

import 'dart:math' as math;

/// The style, with every colour in it turned over.
Object? darkenMapStyle(Object? node) {
  if (node is String) return darkenColour(node) ?? node;
  if (node is List) return [for (final item in node) darkenMapStyle(item)];
  if (node is Map) {
    return <String, dynamic>{
      for (final entry in node.entries)
        '${entry.key}': darkenMapStyle(entry.value),
    };
  }
  return node;
}

/// The same colour on a dark ground, or null where [value] is not one.
///
/// Returns `rgba(...)`, which is one of the forms the style already uses
/// and therefore one the renderer's own parser reads.
String? darkenColour(String value) {
  final rgba = _parse(value.trim());
  if (rgba == null) return null;
  final (r, g, b, a) = rgba;

  final (h, s, l) = _toHsl(r, g, b);
  final (nr, ng, nb) = _toRgb(
    h,
    // Damped, or every wood and every lake glows on a dark ground.
    s * 0.62,
    // Flipped, then held off both ends: pure white would go to pure
    // black, which swallows the hairlines between one surface and the
    // next — and those hairlines are what makes a map readable.
    (1 - l).clamp(0.06, 0.90),
  );
  final alpha = a == 1 ? '1' : a.toStringAsFixed(3);
  return 'rgba($nr,$ng,$nb,$alpha)';
}

/// `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`, `rgb()`, `rgba()`, `hsl()`,
/// `hsla()` — the four spellings the shipped style actually uses, plus
/// the two short forms of each.
(int, int, int, double)? _parse(String value) {
  if (value.startsWith('#')) {
    final hex = value.substring(1);
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) return null;
    int at(int index, int width) {
      final digits = hex.substring(index * width, (index + 1) * width);
      final n = int.parse(width == 1 ? '$digits$digits' : digits, radix: 16);
      return n;
    }

    return switch (hex.length) {
      3 => (at(0, 1), at(1, 1), at(2, 1), 1.0),
      4 => (at(0, 1), at(1, 1), at(2, 1), at(3, 1) / 255),
      6 => (at(0, 2), at(1, 2), at(2, 2), 1.0),
      8 => (at(0, 2), at(1, 2), at(2, 2), at(3, 2) / 255),
      _ => null,
    };
  }

  final call = RegExp(r'^(rgba?|hsla?)\(([^)]*)\)$').firstMatch(value);
  if (call == null) return null;
  final parts = call.group(2)!.split(',').map((p) => p.trim()).toList();
  if (parts.length < 3) return null;

  double? number(String raw) => double.tryParse(raw.replaceAll('%', ''));
  final one = number(parts[0]);
  final two = number(parts[1]);
  final three = number(parts[2]);
  if (one == null || two == null || three == null) return null;
  final alpha = parts.length > 3 ? (number(parts[3]) ?? 1) : 1.0;

  if (call.group(1)!.startsWith('hsl')) {
    final (r, g, b) = _toRgb(one / 360, two / 100, three / 100);
    return (r, g, b, alpha);
  }
  return (one.round(), two.round(), three.round(), alpha);
}

(double h, double s, double l) _toHsl(int r, int g, int b) {
  final rd = r / 255, gd = g / 255, bd = b / 255;
  final max = math.max(rd, math.max(gd, bd));
  final min = math.min(rd, math.min(gd, bd));
  final l = (max + min) / 2;
  if (max == min) return (0, 0, l);

  final d = max - min;
  final s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
  final h = switch (max) {
    _ when max == rd => ((gd - bd) / d + (gd < bd ? 6 : 0)) / 6,
    _ when max == gd => ((bd - rd) / d + 2) / 6,
    _ => ((rd - gd) / d + 4) / 6,
  };
  return (h, s, l);
}

(int r, int g, int b) _toRgb(double h, double s, double l) {
  if (s <= 0) {
    final v = (l * 255).round().clamp(0, 255);
    return (v, v, v);
  }
  final q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  final p = 2 * l - q;
  int channel(double t) {
    var x = t;
    if (x < 0) x += 1;
    if (x > 1) x -= 1;
    final v = switch (x) {
      _ when x < 1 / 6 => p + (q - p) * 6 * x,
      _ when x < 1 / 2 => q,
      _ when x < 2 / 3 => p + (q - p) * (2 / 3 - x) * 6,
      _ => p,
    };
    return (v * 255).round().clamp(0, 255);
  }

  return (channel(h + 1 / 3), channel(h), channel(h - 1 / 3));
}

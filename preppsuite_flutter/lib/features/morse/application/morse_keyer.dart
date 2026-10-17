/// Morse keyed by hand (#191): press along with a light you can see, and
/// the presses become dots and dashes.
///
/// Somebody reading a lamp across a valley cannot write dots and dashes
/// fast enough with a keyboard, and does not know the code by heart -- but
/// they can press in time with what they see. Morse fixes the ratios and
/// not the speed: a dash is three dots, the gap inside a letter one, the
/// gap between letters three, between words seven. So the keyer does not
/// ask for a speed. It keeps every press of the message and reads the
/// whole of it again after each one:
///
///  * Once there is a short press and one at least twice as long, the line
///    between dot and dash is the geometric middle of the two -- for the
///    ratio of one to three, 1.7 dots.
///  * Until then every press looks alike, and the line is a fixed 0.8 s:
///    a dot of the app's own slowest lamp is 0.5 s, its dash 1.5 s. A fast
///    sender's first dashes read as dots until the first real dot arrives,
///    and are then corrected, because the message is read again.
///  * A pause longer than two dots ends a letter, one longer than five
///    ends a word.
library;

import 'dart:math' as math;

class MorseKeyer {
  /// How many recent presses set the line, so somebody who speeds up is
  /// followed rather than held to how they began.
  static const window = 12;

  /// The line between dot and dash before there is anything to compare.
  static const firstLine = Duration(milliseconds: 800);

  final _presses = <int>[];
  final _gaps = <int>[];
  Duration? _downAt;
  Duration? _upAt;
  var _gap = 0;

  /// The key goes down [at] some point on a monotonic clock.
  void down(Duration at) {
    _downAt = at;
    final upAt = _upAt;
    _gap = upAt == null ? 0 : (at - upAt).inMicroseconds;
  }

  /// The key comes up [at].
  void up(Duration at) {
    final downAt = _downAt;
    _downAt = null;
    if (downAt == null) return;
    _upAt = at;
    _presses.add((at - downAt).inMicroseconds);
    _gaps.add(_gap);
  }

  /// Whether anything has been keyed since the last [reset].
  bool get isEmpty => _presses.isEmpty;

  /// The line between a dot and a dash, as things stand.
  Duration get line {
    if (_presses.isEmpty) return firstLine;
    final recent = _presses.sublist(math.max(0, _presses.length - window));
    final shortest = recent.reduce(math.min);
    final longest = recent.reduce(math.max);
    if (longest < 2 * shortest) return firstLine;
    return Duration(microseconds: math.sqrt(shortest * longest).round());
  }

  /// One dot, as things stand: the average short press, or a third of the
  /// average long one while there has been no short press yet.
  Duration get dot {
    final split = line.inMicroseconds;
    final dots = _presses.where((p) => p <= split).toList();
    if (dots.isNotEmpty) {
      return Duration(
        microseconds: dots.reduce((a, b) => a + b) ~/ dots.length,
      );
    }
    if (_presses.isEmpty) return firstLine ~/ 2;
    return Duration(
      microseconds: _presses.reduce((a, b) => a + b) ~/ _presses.length ~/ 3,
    );
  }

  /// Everything keyed since the last [reset], in the decoder's spelling:
  /// `.` and `-`, a space between letters, ` / ` between words.
  String get code {
    final split = line.inMicroseconds;
    final unit = dot.inMicroseconds;
    final out = StringBuffer();
    for (var i = 0; i < _presses.length; i++) {
      if (i > 0) {
        final gap = _gaps[i];
        if (gap > 5 * unit) {
          out.write(' / ');
        } else if (gap > 2 * unit) {
          out.write(' ');
        }
      }
      out.write(_presses[i] > split ? '-' : '.');
    }
    return out.toString();
  }

  /// Starts a new message.
  void reset() {
    _presses.clear();
    _gaps.clear();
    _downAt = null;
    _upAt = null;
    _gap = 0;
  }
}

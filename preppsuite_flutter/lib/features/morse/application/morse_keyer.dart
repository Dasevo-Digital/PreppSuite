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
///  * Pauses are read against the pauses, not against the presses. A
///    finger or a mouse taps a dot in a tenth of a second, but the pause
///    after it is longer, and the one after a dash longer still, because
///    the key has to come up and go down again. Measured in taps, a pause
///    inside a letter was easily more than two -- and an O fell apart into
///    T and M. What tells the pauses apart is that between letters a hand
///    waits on purpose: sorted, the pauses step up at least twofold where
///    the letters begin. The first such step ends a letter, a second one
///    above it a word.
///  * Until there is such a step -- while the first letter is keyed -- a
///    pause ends a letter only if it is longer than a dash and than two
///    dots. A word needs at least five pauses inside a letter.
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
    final pauses = _pauseLines(split);
    final out = StringBuffer();
    for (var i = 0; i < _presses.length; i++) {
      if (i > 0) {
        final gap = _gaps[i];
        final letter = _presses[i - 1] > split
            ? pauses.afterDash
            : pauses.afterDot;
        if (gap > letter) out.write(gap > pauses.word ? ' / ' : ' ');
      }
      out.write(_presses[i] > split ? '-' : '.');
    }
    return out.toString();
  }

  /// Where a pause stops being inside a letter -- after a dot, and after a
  /// dash -- and where it starts being between words, in microseconds.
  ///
  /// The pauses after dots and after dashes are told apart separately. A
  /// hand that lets go of a long press takes longer to come down again,
  /// and when that is twice the pause after a tap, the first step in all
  /// pauses together would be that one, not the step to the next letter.
  ({int afterDot, int afterDash, int word}) _pauseLines(int split) {
    final unit = dot.inMicroseconds;
    final dashes = _presses.where((p) => p > split).toList();
    final dash = dashes.isEmpty
        ? 3 * unit
        : dashes.reduce((a, b) => a + b) ~/ dashes.length;
    final afterDots = <int>[];
    final afterDashes = <int>[];
    // The first press has no pause before it.
    for (
      var i = math.max(1, _presses.length - window);
      i < _presses.length;
      i++
    ) {
      (_presses[i - 1] > split ? afterDashes : afterDots).add(_gaps[i]);
    }
    afterDots.sort();
    afterDashes.sort();

    // Where one kind has no step -- every pause after a dash is inside a
    // letter, say -- it takes the other kind's, but no less than a dash
    // and two dots. Where neither has one, the step can still lie between
    // them (".- .-": inside a letter after the dot, between letters after
    // the dash), and only then, before the first letter is through, a
    // pause ends a letter once it is longer than one and a half dashes.
    final dotStep = _firstStep(afterDots, above: unit);
    final dashStep = _firstStep(afterDashes, above: unit);
    final floor = math.max(2 * unit, dash);
    final fallback =
        _firstStep([...afterDots, ...afterDashes]..sort(), above: unit) ??
        math.max(floor, dash * 3 ~/ 2);
    final afterDot =
        dotStep ?? (dashStep == null ? fallback : math.max(dashStep, floor));
    final afterDash =
        dashStep ?? (dotStep == null ? fallback : math.max(dotStep, floor));

    final inside = [
      for (final gap in afterDots)
        if (gap <= afterDot) gap,
      for (final gap in afterDashes)
        if (gap <= afterDash) gap,
    ]..sort();
    final between = [
      for (final gap in afterDots)
        if (gap > afterDot) gap,
      for (final gap in afterDashes)
        if (gap > afterDash) gap,
    ]..sort();
    final usual = inside.isEmpty ? unit : inside[inside.length ~/ 2];
    // Without a second step, every pause between letters so far is one
    // kind. Read against the shortest of them, as Morse has it (seven to
    // three): a hand that waits between letters waits far longer than
    // Morse asks, and against the pauses inside a letter a slow letter
    // would be a word.
    final word = math.max(
      5 * usual,
      _firstStep(between, above: math.max(afterDot, afterDash)) ??
          (between.isEmpty ? 0 : between.first * 7 ~/ 3),
    );
    return (afterDot: afterDot, afterDash: afterDash, word: word);
  }

  /// The geometric middle of the first place in [sorted] where a pause is
  /// at least twice the one before it and the middle lies above [above].
  ///
  /// The first, not the largest: one long pause to think is a far bigger
  /// step than the one between letters, and taking it would make every
  /// letter before it part of one.
  static int? _firstStep(List<int> sorted, {required int above}) {
    for (var i = 1; i < sorted.length; i++) {
      final shorter = sorted[i - 1];
      final longer = sorted[i];
      if (shorter <= 0 || longer < 2 * shorter) continue;
      final middle = math.sqrt(shorter * longer).round();
      if (middle >= above) return middle;
    }
    return null;
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

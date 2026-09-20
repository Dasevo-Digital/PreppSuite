/// The two rhythms that mean "here, and I need help".
///
/// A lamp held up is not a signal; a lamp held up *in a rhythm somebody
/// recognises* is. Both rhythms here are conventions with a long paper
/// trail, and neither is invented:
///
///  * **SOS** in Morse — three short, three long, three short, sent as one
///    character rather than three letters, which is what makes it a
///    prosign rather than a word.
///  * **The alpine distress signal** — six signals inside one minute, then
///    a minute of nothing, then again. The answer is three per minute,
///    given during the pause, so that whoever is signalling knows they
///    have been seen.
///
/// What is *not* handed down is how fast to flash. Morse fixes the ratios
/// between dot, dash and gap and says nothing about the speed; the ITU
/// timing is written for a receiving operator, not for an eye picking a
/// light out of a dark hillside. So the unit is deliberately slow — half a
/// second — and that is a choice this file makes and admits to, not a rule
/// it is quoting.
///
/// A pure function of elapsed time, the same way the compression pacer is,
/// and for the same reason: a timer that fires every 500 ms fires late,
/// and the lateness accumulates. After ten minutes of counting, a flash
/// meant for the top of the minute lands somewhere else entirely — and the
/// alpine signal is only readable because the six fall inside one minute.
library;

enum DistressSignal {
  /// Three short, three long, three short.
  sos,

  /// Six inside a minute, then a minute of nothing.
  alpine,

  /// Three inside a minute: "I have seen you."
  alpineAnswer,
}

/// One span of the rhythm: lit or dark, and for how long.
typedef SignalSpan = ({bool lit, Duration length});

/// A rhythm, as something that can be asked "are you lit right now".
class DistressSignalPattern {
  DistressSignalPattern(this.signal, {this.unit = defaultUnit})
    : assert(unit > Duration.zero),
      spans = _spansFor(signal, unit);

  /// Half a second a unit. Slow for Morse and deliberately so: this is
  /// read by an eye across a valley, not by an operator with headphones.
  static const defaultUnit = Duration(milliseconds: 500);

  final DistressSignal signal;

  /// The length of a Morse dot. Ignored by the alpine rhythms, whose
  /// timing is given in whole seconds by the convention itself.
  final Duration unit;

  final List<SignalSpan> spans;

  /// One full turn of the rhythm, after which it repeats exactly.
  Duration get period =>
      spans.fold(Duration.zero, (sum, span) => sum + span.length);

  /// How many times the lamp comes on in one turn. What the screen counts
  /// out, so somebody can check they are sending six and not five.
  int get flashesPerPeriod => spans.where((span) => span.lit).length;

  /// Whether the lamp is on [elapsed] after the start.
  ///
  /// Takes the elapsed time rather than keeping one, so that however late
  /// the caller asks, the answer is the one the rhythm demands.
  bool isLitAt(Duration elapsed) {
    final total = period.inMicroseconds;
    if (total == 0) return false;
    var into = elapsed.inMicroseconds % total;
    if (into < 0) into += total;

    var boundary = 0;
    for (final span in spans) {
      boundary += span.length.inMicroseconds;
      if (into < boundary) return span.lit;
    }
    return false;
  }

  /// Which flash of the turn is happening, counted from one.
  ///
  /// Zero during the pause. The alpine signal is six *inside one minute*,
  /// and somebody sending it by hand needs to see where they are.
  int flashNumberAt(Duration elapsed) {
    final total = period.inMicroseconds;
    if (total == 0) return 0;
    var into = elapsed.inMicroseconds % total;
    if (into < 0) into += total;

    var boundary = 0;
    var seen = 0;
    for (final span in spans) {
      if (span.lit) seen++;
      boundary += span.length.inMicroseconds;
      if (into < boundary) return span.lit ? seen : 0;
    }
    return 0;
  }

  static List<SignalSpan> _spansFor(DistressSignal signal, Duration unit) {
    switch (signal) {
      case DistressSignal.sos:
        // Sent as one character: the elements are separated by a single
        // unit throughout, with no letter gaps. Three letters would be
        // S-O-S; one character is the distress prosign.
        const elements = [1, 1, 1, 3, 3, 3, 1, 1, 1];
        return [
          for (var i = 0; i < elements.length; i++) ...[
            (lit: true, length: unit * elements[i]),
            // A single unit between elements, and the seven-unit word gap
            // after the last one, so a listener hears where it ends.
            (lit: false, length: unit * (i == elements.length - 1 ? 7 : 1)),
          ],
        ];

      case DistressSignal.alpine:
        return _perMinute(6);
      case DistressSignal.alpineAnswer:
        return _perMinute(3);
    }
  }

  /// [count] evenly spaced signals inside a minute, then a minute of
  /// nothing. The pause is the half that carries the meaning: it is what
  /// tells the rhythm apart from somebody walking about with a torch, and
  /// it is when an answer is given.
  static List<SignalSpan> _perMinute(int count) {
    const minute = Duration(seconds: 60);
    const flash = Duration(seconds: 1);
    final gap = minute ~/ count - flash;
    return [
      for (var i = 0; i < count; i++) ...[
        (lit: true, length: flash),
        (lit: false, length: gap),
      ],
      (lit: false, length: minute),
    ];
  }
}

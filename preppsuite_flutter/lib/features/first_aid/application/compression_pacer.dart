/// The beat for chest compressions.
///
/// This is the one thing an app can do during a resuscitation that a
/// printed card cannot, and it is the reason the first aid section is not
/// simply a document. A rescuer cannot count to a hundred and ten while
/// also counting to thirty, watching a chest and talking to a dispatcher;
/// left to themselves, most people drift well under the guideline rate.
///
/// Deliberately a pure function of elapsed time rather than a counter that
/// a timer increments. A timer that fires every 545 ms fires late, and the
/// lateness accumulates: after two minutes a counting pacer is several
/// beats adrift, and the count of thirty is wrong. Asking "how many beats
/// fit into the time since the start" cannot drift, however late the
/// caller is.
library;

/// How fast to beat and how the beats are grouped.
class CompressionPacer {
  const CompressionPacer({
    this.beatsPerMinute = defaultBeatsPerMinute,
    this.compressionsPerCycle = 30,
  });

  /// The middle of the guideline's 100 to 120.
  ///
  /// The middle and not the bottom: the rate that is actually delivered
  /// drops under fatigue, so starting at the floor means spending most of
  /// the attempt below it.
  static const defaultBeatsPerMinute = 110;

  /// What the guideline allows, and therefore what the dial allows.
  static const minimumBeatsPerMinute = 100;
  static const maximumBeatsPerMinute = 120;

  /// How often two rescuers should change over.
  ///
  /// Not a rule of the pacer but of the guideline: compressions get
  /// shallower with fatigue long before the person doing them notices.
  static const swapInterval = Duration(minutes: 2);

  final int beatsPerMinute;

  /// 30 for an adult, 15 for a child. Zero means "do not group them" —
  /// compression-only resuscitation has no cycle.
  final int compressionsPerCycle;

  /// The gap between two beats, to microsecond resolution.
  ///
  /// 110 a minute is 545,454.54… µs. Rounding that to milliseconds would
  /// be a beat out after roughly three minutes, which is inside the span
  /// this is used for.
  Duration get beatInterval => Duration(microseconds: (60 * 1000000) ~/ _rate);

  int get _rate =>
      beatsPerMinute.clamp(minimumBeatsPerMinute, maximumBeatsPerMinute);

  /// Where the pacer is [elapsed] after it started.
  PacerTick at(Duration elapsed) {
    // A negative elapsed can only come from a clock correction. Reading it
    // as "not started yet" keeps the count at zero instead of running the
    // counter backwards.
    final micros = elapsed.inMicroseconds;
    final beat = micros <= 0 ? 0 : micros ~/ beatInterval.inMicroseconds;

    final grouped = compressionsPerCycle > 0;
    return PacerTick(
      beat: beat,
      compression: grouped ? (beat % compressionsPerCycle) + 1 : beat + 1,
      compressionsPerCycle: compressionsPerCycle,
      cycle: grouped ? (beat ~/ compressionsPerCycle) + 1 : 1,
      elapsed: micros <= 0 ? Duration.zero : elapsed,
    );
  }

  /// When beat number [beat] falls, counting the first beat as zero.
  ///
  /// The UI schedules against this rather than adding intervals together,
  /// for the same reason [at] exists.
  Duration onsetOf(int beat) =>
      Duration(microseconds: beat * beatInterval.inMicroseconds);
}

/// One moment of a running pacer.
class PacerTick {
  const PacerTick({
    required this.beat,
    required this.compression,
    required this.compressionsPerCycle,
    required this.cycle,
    required this.elapsed,
  });

  /// Beats since the start, the first being zero. This is what the sound
  /// is keyed to: a change here is a click.
  final int beat;

  /// Where in the cycle this beat is, counting from one — what a rescuer
  /// would be saying out loud.
  final int compression;

  final int compressionsPerCycle;

  /// Which round of thirty this is, counting from one.
  final int cycle;

  final Duration elapsed;

  /// Whether this beat completes a cycle, and breaths come next.
  bool get isLastOfCycle =>
      compressionsPerCycle > 0 && compression == compressionsPerCycle;

  /// How many two-minute changeovers have come due.
  ///
  /// Zero for the first two minutes. The screen says so once per
  /// changeover rather than continuously, so this is compared against the
  /// previous tick's value rather than read as a flag.
  int get swapsDue =>
      elapsed.inMicroseconds ~/ CompressionPacer.swapInterval.inMicroseconds;
}

/// What a gauge reading means, worked out without any network.
///
/// A bare number off a gauge is unreadable to anybody who does not know
/// their own river: 66 cm is a drought on the Rhine at Cologne and a flood
/// on a small canal. What makes it readable are the long-term reference
/// values the same service publishes -- the mean level, the mean of flood
/// levels, the highest ever recorded -- so every number here is stated
/// against them or not stated at all.
///
/// Deliberately not a warning. Warning levels (Meldestufen) are the
/// Laender's and are not in this data; the app already receives their
/// flood warnings through the BBK feed. This is the number and its
/// context, which is what somebody deciding whether to clear a cellar
/// actually watches.
library;

/// A long-term reference level published for a gauge, in centimetres.
enum PegelReference {
  /// Mittel der Tageswasserstände — the everyday level.
  mean('MW'),

  /// Mittel der Hochwasserstände — what a flood here usually looks like.
  meanFlood('MHW'),

  /// Höchster Hochwasserstand — the highest ever recorded.
  highest('HHW'),

  /// Mittel der Niedrigwasserstände — what low water usually looks like.
  meanLow('MNW'),

  /// Niedrigster Niedrigwasserstand — the lowest ever recorded.
  lowest('NNW');

  const PegelReference(this.code);

  /// The `shortname` PEGELONLINE uses for it.
  final String code;

  static PegelReference? fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Where a reading sits relative to what is normal for its gauge.
enum PegelBand {
  /// At or below the lowest level ever recorded here.
  recordLow,

  /// Below the mean of low-water levels.
  low,

  /// Between low water and the everyday mean, or thereabouts.
  ordinary,

  /// Above the everyday mean but short of what a flood looks like here.
  elevated,

  /// At or above the mean of flood levels.
  flood,

  /// At or above the highest level ever recorded here.
  recordHigh,

  /// No reference values published for this gauge, so nothing can be said.
  unknown,
}

/// Which way the water is going, over the window the trend was taken.
enum PegelTrend { rising, falling, steady, unknown }

/// One gauge's current state.
class PegelReading {
  const PegelReading({
    required this.stationName,
    required this.water,
    required this.centimetres,
    required this.measuredAt,
    this.references = const {},
    this.changeOverDay,
  });

  final String stationName;
  final String water;
  final double centimetres;
  final DateTime measuredAt;

  /// The published long-term levels, in centimetres. Often incomplete and
  /// sometimes absent: roughly a quarter of the gauges publish none.
  final Map<PegelReference, double> references;

  /// Centimetres gained or lost over the preceding day, where enough of
  /// the series was available to say.
  final double? changeOverDay;

  double? reference(PegelReference which) => references[which];

  PegelTrend get trend {
    final change = changeOverDay;
    if (change == null) return PegelTrend.unknown;
    // Five centimetres over a day: below that a river is not doing
    // anything a household should act on, and wind and shipping alone
    // move a gauge by a centimetre or two.
    if (change >= 5) return PegelTrend.rising;
    if (change <= -5) return PegelTrend.falling;
    return PegelTrend.steady;
  }

  PegelBand get band {
    final lowest = reference(PegelReference.lowest);
    final meanLow = reference(PegelReference.meanLow);
    final mean = reference(PegelReference.mean);
    final meanFlood = reference(PegelReference.meanFlood);
    final highest = reference(PegelReference.highest);

    // Checked from the outside in, so the most consequential band a
    // gauge has the numbers for is the one that wins. A gauge that
    // publishes only MHW can still say "flood".
    if (highest != null && centimetres >= highest) return PegelBand.recordHigh;
    if (meanFlood != null && centimetres >= meanFlood) return PegelBand.flood;
    if (lowest != null && centimetres <= lowest) return PegelBand.recordLow;
    if (meanLow != null && centimetres <= meanLow) return PegelBand.low;
    if (mean != null) {
      return centimetres > mean ? PegelBand.elevated : PegelBand.ordinary;
    }
    // Nothing to compare against in either direction.
    if (meanLow == null && meanFlood == null) return PegelBand.unknown;
    return PegelBand.ordinary;
  }

  /// Whether the reading is old enough that it should be shown as such.
  ///
  /// Inland gauges report every fifteen minutes, so an hour behind means
  /// the app has not reached the service rather than the river standing
  /// still.
  bool isStale({DateTime? now}) =>
      (now ?? DateTime.now()).difference(measuredAt) > const Duration(hours: 1);
}

/// The change over the day preceding the newest sample in [series].
///
/// Returns null unless the series actually reaches back about that far: a
/// gap in the data would otherwise turn into an invented trend, and "the
/// river rose 40 cm" is not a claim to make from the six hours that
/// happened to arrive.
double? changeOverDay(List<({DateTime at, double value})> series) {
  if (series.length < 2) return null;
  final sorted = [...series]..sort((a, b) => a.at.compareTo(b.at));
  final newest = sorted.last;
  final wanted = newest.at.subtract(const Duration(hours: 24));

  // The sample nearest to a day back, in either direction. Picking the
  // oldest one instead would read a two-week-old sample as "yesterday".
  ({DateTime at, double value})? best;
  Duration? closest;
  for (final sample in sorted) {
    final gap = sample.at.difference(wanted).abs();
    if (closest == null || gap < closest) {
      best = sample;
      closest = gap;
    }
  }
  if (best == null || closest! > const Duration(hours: 4)) return null;
  return newest.value - best.value;
}

/// What a gamma dose-rate reading means, worked out without any network.
///
/// The bands here are the BfS's own and not this app's. That distinction
/// matters more here than anywhere else in the app: a number with
/// "Strahlung" next to it frightens people, and a threshold somebody
/// invented would frighten them at the wrong moment. What the BfS
/// publishes alongside the data is:
///
///  - the natural dose rate in Germany runs **0.05 to 0.2 µSv/h**,
///    depending on local geology — 0.05 at some stations in
///    Schleswig-Holstein and Lower Saxony, up to 0.2 in parts of
///    Thuringia, Baden-Württemberg and Bavaria, averaging about 0.08;
///  - **rain raises it by up to a factor of 3** for a few hours, because
///    it washes radon decay products out of the air. This is the normal
///    case after a shower and is harmless; the products have a half-life
///    of about 30 minutes and the reading falls back on its own. Fresh
///    snow does the same; lying snow shields the ground and the reading
///    *drops*;
///  - a radiological event is only in question when a clearly raised
///    reading **persists for a day or longer**, or when it goes **beyond
///    that factor of 3** without a technical fault.
///
/// So this classifies against the station's own long-run baseline rather
/// than against one national number, and it says "wet weather" where the
/// BfS says wet weather. There is no band called "danger": if something
/// were actually happening, the warning would come through the BBK feed,
/// which this app already reads. This screen is the number and its
/// context.
///
/// Source: odlinfo.bfs.de, "Messwertinterpretation".
library;

/// The top of the natural range the BfS states for Germany, in µSv/h.
///
/// Used only where a station has no baseline of its own to compare
/// against — a station read for the first time, offline.
const naturalCeiling = 0.2;

/// The bottom of that range.
const naturalFloor = 0.05;

/// What the BfS calls the ordinary weather effect: rain can lift a
/// reading by up to this multiple of its baseline, for hours, harmlessly.
const weatherFactor = 3.0;

/// Where a reading sits against what is normal for its own station.
enum RadiationBand {
  /// Within the station's usual range, or within the natural range where
  /// the station has no history here yet.
  ordinary,

  /// Above the station's usual range but inside the factor the BfS
  /// attributes to rain and snowmelt. The ordinary reading of this is
  /// weather, not an event.
  weather,

  /// Beyond the factor the BfS attributes to weather. Per the BfS this is
  /// where a technical fault or an actual event comes into question —
  /// which is a reason to look at the warnings, not a warning itself.
  unusual,

  /// The station reports, but nothing is known about its usual range and
  /// the value is outside the national natural range.
  unknown,
}

/// One station's current reading.
class RadiationReading {
  const RadiationReading({
    required this.stationName,
    required this.microsievertsPerHour,
    required this.measuredAt,
    this.terrestrial,
    this.cosmic,
    this.baseline,
    this.validated = true,
  });

  final String stationName;

  /// Gamma dose rate, µSv/h. The gross value, which is what the BfS
  /// shows.
  final double microsievertsPerHour;

  final DateTime measuredAt;

  /// The two parts the service splits the gross value into. Worth
  /// showing: the cosmic part is a constant of the altitude and the
  /// terrestrial part is the ground, so a reader can see that a high
  /// station is high because it is high up.
  final double? terrestrial;
  final double? cosmic;

  /// What this station usually reads, from its own recent series.
  ///
  /// Null on a first look or offline. Then the national natural range
  /// stands in, which is coarser: a station in the Black Forest sits near
  /// 0.16 µSv/h in perfectly ordinary weather.
  final double? baseline;

  /// Whether the service has checked the value. Hourly readings are
  /// published as raw data and the BfS says so; an unchecked one is shown
  /// as unchecked rather than withheld.
  final bool validated;

  /// The reference this reading is judged against.
  double get reference => baseline ?? naturalCeiling;

  /// How many times the reference the reading is.
  double get factor => microsievertsPerHour / reference;

  RadiationBand get band {
    final own = baseline;

    if (own == null) {
      // No history: the only honest comparison is the national range,
      // and inside it there is nothing to say.
      if (microsievertsPerHour <= naturalCeiling) {
        return RadiationBand.ordinary;
      }
      if (microsievertsPerHour <= naturalCeiling * weatherFactor) {
        return RadiationBand.weather;
      }
      return RadiationBand.unknown;
    }

    // A tenth above its own baseline is not a rise: the stations
    // themselves wander a little with ground moisture and temperature,
    // and a band that flipped on every drizzle would train the reader to
    // ignore it.
    if (microsievertsPerHour <= own * 1.1) return RadiationBand.ordinary;
    if (microsievertsPerHour <= own * weatherFactor) {
      return RadiationBand.weather;
    }
    return RadiationBand.unusual;
  }

  /// Whether the reading is old enough that it should be shown as such.
  ///
  /// The network publishes hourly, so two hours behind means the app has
  /// not reached the service rather than the value standing still.
  bool isStale({DateTime? now}) =>
      (now ?? DateTime.now()).difference(measuredAt) > const Duration(hours: 2);
}

/// What a station usually reads, from a series of its own values.
///
/// The median rather than the mean, and that is the whole point: every
/// rainfall in the series is a spike of up to three times the baseline,
/// and an average would fold those spikes into the thing they are
/// supposed to be measured against. Twelve samples is the minimum — a
/// handful of hours could all be the same shower.
double? baselineFrom(List<double> values) {
  final usable = [
    for (final value in values)
      if (value > 0) value,
  ]..sort();
  if (usable.length < 12) return null;

  final middle = usable.length ~/ 2;
  return usable.length.isOdd
      ? usable[middle]
      : (usable[middle - 1] + usable[middle]) / 2;
}

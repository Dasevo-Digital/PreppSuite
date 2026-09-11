/// The five classes of the federal air quality index.
///
/// The names are the Umweltbundesamt's own. So is the classification: the
/// app never computes one. The UBA's interface returns an index per hour
/// per station, and the thresholds behind it are published as data — see
/// [AirQualityClient.thresholds] — so nothing here is a judgement of this
/// app's making.
///
/// One thing the app deliberately does *not* ship is the UBA's per-class
/// behaviour advice. The UBA publishes it only as images on its website,
/// and paraphrasing somebody else's health advice is exactly what the
/// rule against invented scales exists to prevent. The screen names the
/// class and the pollutant behind it and leaves the advice where it is.
enum AirQualityClass {
  veryGood,
  good,
  moderate,
  poor,
  veryPoor,

  /// The hour carries no index — a station that was not reporting.
  unknown;

  /// The index as the UBA's interface states it: 0 to 4, worst first at
  /// the top end. Anything else is [unknown] rather than a guess.
  static AirQualityClass fromIndex(int? index) => switch (index) {
    0 => AirQualityClass.veryGood,
    1 => AirQualityClass.good,
    2 => AirQualityClass.moderate,
    3 => AirQualityClass.poor,
    4 => AirQualityClass.veryPoor,
    _ => AirQualityClass.unknown,
  };

  /// Where the class sits on the scale, for a bar or a colour. Null for
  /// [unknown], because a missing reading is not a position.
  int? get step => this == AirQualityClass.unknown ? null : index;

  bool get isKnown => this != AirQualityClass.unknown;
}

/// One pollutant's own reading and its own class.
///
/// Worth keeping beside the overall figure: the index is the worst of the
/// components, and "the air is moderate" means something different when
/// it is ozone on a summer afternoon than when it is particulates.
class AirQualityComponent {
  const AirQualityComponent({
    required this.id,
    required this.code,
    required this.unit,
    required this.value,
    required this.level,
  });

  /// The UBA's component id — 1 is PM₁₀, 3 ozone, 5 nitrogen dioxide.
  final int id;

  /// The short name the UBA uses: `PM10`, `O3`, `NO2`, `SO2`, `PM2`.
  final String code;

  final String unit;

  /// The measured concentration, in [unit].
  final double value;

  final AirQualityClass level;
}

/// One station's air quality for one hour.
class AirQualityReading {
  const AirQualityReading({
    required this.stationId,
    required this.measuredAt,
    required this.level,
    required this.components,
    required this.incomplete,
  });

  final String stationId;

  /// The end of the hour the reading covers, which is what the interface
  /// states as the measurement's own time.
  final DateTime measuredAt;

  final AirQualityClass level;

  final List<AirQualityComponent> components;

  /// The UBA's own flag for "not every pollutant this station measures
  /// reported this hour". The index is still the worst of what did
  /// arrive, so it is shown — but said to be partial rather than passed
  /// off as the whole picture.
  final bool incomplete;

  /// The pollutant the class comes from: the worst one, and among equals
  /// the one with the highest share of its own class ceiling.
  AirQualityComponent? get leading {
    if (components.isEmpty) return null;
    var worst = components.first;
    for (final component in components) {
      final a = component.level.step ?? -1;
      final b = worst.level.step ?? -1;
      if (a > b) worst = component;
    }
    return worst.level.isKnown ? worst : null;
  }

  /// Hourly data, so anything older than three hours means the station
  /// has stopped reporting rather than that the air has not changed.
  ///
  /// Three and not one: the interface publishes an hour once it is
  /// complete, so the newest value is routinely an hour or more old even
  /// when everything is working.
  bool isStaleAt(DateTime now) =>
      now.difference(measuredAt) > const Duration(hours: 3);
}

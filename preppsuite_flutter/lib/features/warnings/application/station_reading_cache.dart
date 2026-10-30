/// Whether a kept reading belongs to the station now chosen (#239).
///
/// Each station screen keeps its last reading for when there is no
/// network, and the stores dropped it whenever the station was changed on
/// this device. The station is a household setting, though, and also
/// arrives from another device, a handover or a backup. Those write the
/// setting directly, and the reading of the old station stayed: offline,
/// the screen showed the new station's name over the old station's
/// water level. So the reading names the station it was taken at, and
/// is only shown for that one.
bool isReadingOf(
  Map<String, Object?> kept, {
  required String stationId,
  required String stationName,
}) {
  final id = kept['stationId'];
  if (id is String) return id == stationId;
  // Kept before 2.8.0, which noted the name alone.
  return kept['stationName'] == stationName;
}

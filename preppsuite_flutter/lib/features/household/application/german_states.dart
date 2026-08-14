/// The 16 German states (Bundesländer) — mirrors the server's
/// `german_states.dart` (`preppsuite_server/lib/src/warnings/services/`)
/// by hand, same cross-package precedent as `warningFeedCountries` /
/// `meteoAlarmCountrySlugs`. Used for the "add a Bundesland subscription"
/// picker, deriving a Bundesland from device location, and ranking
/// warnings by relevance (`warning_relevance.dart`).
class GermanState {
  const GermanState({
    required this.arsPrefix,
    required this.bbkCode,
    required this.nameDe,
  });

  /// First 2 digits of the ARS/Kreisschlüssel — what a precisely-polled
  /// warning's `regionKey` starts with.
  final String arsPrefix;

  /// The 2-letter code BBK/this app's own server use to identify a state
  /// (e.g. "BY" for Bayern) — what gets stored as a
  /// `WarningRegionSubscription.value` for `kind: bundesland`, and what a
  /// nationwide-polled warning's `regionKey` equals.
  final String bbkCode;
  final String nameDe;
}

const germanStates = <GermanState>[
  GermanState(arsPrefix: '01', bbkCode: 'SH', nameDe: 'Schleswig-Holstein'),
  GermanState(arsPrefix: '02', bbkCode: 'HH', nameDe: 'Hamburg'),
  GermanState(arsPrefix: '03', bbkCode: 'NI', nameDe: 'Niedersachsen'),
  GermanState(arsPrefix: '04', bbkCode: 'HB', nameDe: 'Bremen'),
  GermanState(arsPrefix: '05', bbkCode: 'NW', nameDe: 'Nordrhein-Westfalen'),
  GermanState(arsPrefix: '06', bbkCode: 'HE', nameDe: 'Hessen'),
  GermanState(arsPrefix: '07', bbkCode: 'RP', nameDe: 'Rheinland-Pfalz'),
  GermanState(arsPrefix: '08', bbkCode: 'BW', nameDe: 'Baden-Württemberg'),
  GermanState(arsPrefix: '09', bbkCode: 'BY', nameDe: 'Bayern'),
  GermanState(arsPrefix: '10', bbkCode: 'SL', nameDe: 'Saarland'),
  GermanState(arsPrefix: '11', bbkCode: 'BE', nameDe: 'Berlin'),
  GermanState(arsPrefix: '12', bbkCode: 'BB', nameDe: 'Brandenburg'),
  GermanState(
    arsPrefix: '13',
    bbkCode: 'MV',
    nameDe: 'Mecklenburg-Vorpommern',
  ),
  GermanState(arsPrefix: '14', bbkCode: 'SN', nameDe: 'Sachsen'),
  GermanState(arsPrefix: '15', bbkCode: 'ST', nameDe: 'Sachsen-Anhalt'),
  GermanState(arsPrefix: '16', bbkCode: 'TH', nameDe: 'Thüringen'),
];

/// Best-effort match of a Nominatim reverse-geocoding `address.state`
/// value (e.g. "Bayern", sometimes "Free State of Bavaria" for English
/// locales) against [germanStates]. Only handles the German name — device
/// location is always reverse-geocoded with `accept-language=de` (see
/// `geolocation_service.dart`), so this covers the only shape we produce.
GermanState? germanStateByName(String name) {
  for (final state in germanStates) {
    if (state.nameDe.toLowerCase() == name.toLowerCase()) return state;
  }
  return null;
}

GermanState? germanStateByBbkCode(String code) {
  for (final state in germanStates) {
    if (state.bbkCode == code) return state;
  }
  return null;
}

/// [kreisSchluessel] is expected to be the 5-digit form (e.g. "09162").
GermanState? germanStateForKreisSchluessel(String kreisSchluessel) {
  if (kreisSchluessel.length < 2) return null;
  final prefix = kreisSchluessel.substring(0, 2);
  for (final state in germanStates) {
    if (state.arsPrefix == prefix) return state;
  }
  return null;
}

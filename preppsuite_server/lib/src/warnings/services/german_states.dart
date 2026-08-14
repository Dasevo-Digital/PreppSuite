/// The 16 German states (Bundesländer), each identified two different ways
/// depending on which BBK data gave us a `Warning.regionKey`:
///
/// - [arsPrefix]: the first 2 digits of the ARS/Kreisschlüssel — what a
///   precisely-polled (`BbkClient.fetchDashboard`) warning's `regionKey`
///   starts with (see [GermanState.matchesKreisSchluessel]).
/// - [bbkCode]: the 2-letter state abbreviation BBK embeds in nationwide
///   `mapData.json` warning ids (`mow.DE-HE-...` → `HE`), parsed by
///   `WarningNormalizer._bbkRegionFromId`.
///
/// Both forms are needed to match a `bundesland`-kind
/// [WarningRegionSubscription] against warnings from either polling path.
/// Hand-maintained, fixed set (German states don't change) — same
/// hand-sync-across-files precedent as `meteoAlarmCountrySlugs` /
/// `warningFeedCountries`.
class GermanState {
  const GermanState({
    required this.arsPrefix,
    required this.bbkCode,
    required this.nameDe,
  });

  final String arsPrefix;
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

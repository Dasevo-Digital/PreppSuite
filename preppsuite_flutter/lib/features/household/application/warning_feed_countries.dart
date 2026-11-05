/// Countries covered by planned warning-feed sources (German BBK plus the
/// wider MeteoAlarm/EUMETNET membership, which includes several non-EU
/// European countries). Selecting one here sets [Household.countryCode] and
/// scopes which warning feeds apply once Milestone 6 wires them up.
class WarningFeedCountry {
  const WarningFeedCountry(this.code, this.nameDe, this.nameEn, this.nameEs);

  final String code;
  final String nameDe;
  final String nameEn;

  /// A Spanish reader got the English names (#294).
  final String nameEs;

  /// The name in the app's language, English for any other.
  String nameIn(String languageCode) => switch (languageCode) {
    'de' => nameDe,
    'es' => nameEs,
    _ => nameEn,
  };
}

const warningFeedCountries = <WarningFeedCountry>[
  WarningFeedCountry('DE', 'Deutschland', 'Germany', 'Alemania'),
  WarningFeedCountry('AT', 'Österreich', 'Austria', 'Austria'),
  WarningFeedCountry('CH', 'Schweiz', 'Switzerland', 'Suiza'),
  WarningFeedCountry('FR', 'Frankreich', 'France', 'Francia'),
  WarningFeedCountry('IT', 'Italien', 'Italy', 'Italia'),
  WarningFeedCountry('ES', 'Spanien', 'Spain', 'España'),
  WarningFeedCountry('PT', 'Portugal', 'Portugal', 'Portugal'),
  WarningFeedCountry('NL', 'Niederlande', 'Netherlands', 'Países Bajos'),
  WarningFeedCountry('BE', 'Belgien', 'Belgium', 'Bélgica'),
  WarningFeedCountry('LU', 'Luxemburg', 'Luxembourg', 'Luxemburgo'),
  WarningFeedCountry('PL', 'Polen', 'Poland', 'Polonia'),
  WarningFeedCountry('CZ', 'Tschechien', 'Czechia', 'Chequia'),
  WarningFeedCountry('DK', 'Dänemark', 'Denmark', 'Dinamarca'),
  WarningFeedCountry('SE', 'Schweden', 'Sweden', 'Suecia'),
  WarningFeedCountry('NO', 'Norwegen', 'Norway', 'Noruega'),
  WarningFeedCountry('FI', 'Finnland', 'Finland', 'Finlandia'),
  WarningFeedCountry('IE', 'Irland', 'Ireland', 'Irlanda'),
  WarningFeedCountry(
    'GB',
    'Vereinigtes Königreich',
    'United Kingdom',
    'Reino Unido',
  ),
];

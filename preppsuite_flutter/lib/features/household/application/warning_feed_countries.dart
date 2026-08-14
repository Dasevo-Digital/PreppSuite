/// Countries covered by planned warning-feed sources (German BBK plus the
/// wider MeteoAlarm/EUMETNET membership, which includes several non-EU
/// European countries). Selecting one here sets [Household.countryCode] and
/// scopes which warning feeds apply once Milestone 6 wires them up.
class WarningFeedCountry {
  const WarningFeedCountry(this.code, this.nameDe, this.nameEn);

  final String code;
  final String nameDe;
  final String nameEn;
}

const warningFeedCountries = <WarningFeedCountry>[
  WarningFeedCountry('DE', 'Deutschland', 'Germany'),
  WarningFeedCountry('AT', 'Österreich', 'Austria'),
  WarningFeedCountry('CH', 'Schweiz', 'Switzerland'),
  WarningFeedCountry('FR', 'Frankreich', 'France'),
  WarningFeedCountry('IT', 'Italien', 'Italy'),
  WarningFeedCountry('ES', 'Spanien', 'Spain'),
  WarningFeedCountry('PT', 'Portugal', 'Portugal'),
  WarningFeedCountry('NL', 'Niederlande', 'Netherlands'),
  WarningFeedCountry('BE', 'Belgien', 'Belgium'),
  WarningFeedCountry('LU', 'Luxemburg', 'Luxembourg'),
  WarningFeedCountry('PL', 'Polen', 'Poland'),
  WarningFeedCountry('CZ', 'Tschechien', 'Czechia'),
  WarningFeedCountry('DK', 'Dänemark', 'Denmark'),
  WarningFeedCountry('SE', 'Schweden', 'Sweden'),
  WarningFeedCountry('NO', 'Norwegen', 'Norway'),
  WarningFeedCountry('FI', 'Finnland', 'Finland'),
  WarningFeedCountry('IE', 'Irland', 'Ireland'),
  WarningFeedCountry('GB', 'Vereinigtes Königreich', 'United Kingdom'),
];

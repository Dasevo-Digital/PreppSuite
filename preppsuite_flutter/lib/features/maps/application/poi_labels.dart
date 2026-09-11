import '../../../l10n/generated/app_localizations.dart';
import 'offline_poi_search.dart';

/// The six groups in words.
String localizePoiKind(AppLocalizations l10n, PoiKind kind) => switch (kind) {
  PoiKind.water => l10n.nearbyKindWater,
  PoiKind.health => l10n.nearbyKindHealth,
  PoiKind.food => l10n.nearbyKindFood,
  PoiKind.fuel => l10n.nearbyKindFuel,
  PoiKind.hardware => l10n.nearbyKindHardware,
  PoiKind.help => l10n.nearbyKindHelp,
};

/// What a single point is, in words.
///
/// A switch rather than a map so that adding a subclass to
/// [poiSubclasses] without naming it here does not compile — a point the
/// list can show but cannot label would appear as nothing at all, which
/// is the one outcome worse than not finding it.
String localizePoiSubclass(AppLocalizations l10n, String subclass) =>
    switch (subclass) {
      'drinking_water' => l10n.poiDrinkingWater,
      'pharmacy' => l10n.poiPharmacy,
      'hospital' => l10n.poiHospital,
      'clinic' => l10n.poiClinic,
      'doctors' => l10n.poiDoctors,
      'supermarket' => l10n.poiSupermarket,
      'convenience' => l10n.poiConvenience,
      'bakery' => l10n.poiBakery,
      'butcher' => l10n.poiButcher,
      'greengrocer' => l10n.poiGreengrocer,
      'marketplace' => l10n.poiMarketplace,
      'deli' => l10n.poiDeli,
      'fuel' => l10n.poiFuel,
      'charging_station' => l10n.poiChargingStation,
      'doityourself' => l10n.poiDoityourself,
      'hardware' => l10n.poiHardware,
      'fire_station' => l10n.poiFireStation,
      'police' => l10n.poiPolice,
      'townhall' => l10n.poiTownhall,
      'community_centre' => l10n.poiCommunityCentre,
      // Unreachable while the two lists agree, and the test that walks
      // every subclass in [poiSubclasses] is what keeps them agreeing.
      _ => subclass,
    };

/// Every screen somebody can ask for by name.
///
/// The app grew to sixty-two screens and ten tabs, and the only way to
/// one of them was to know where it lived. Somebody looking for the
/// blackout clock had to remember it sits under Notfall, not under
/// Energie; the flood gauge is under Warnungen, not under Karte. A list
/// that long is not navigated, it is searched — and a search needs
/// somewhere to look.
///
/// **This file is that somewhere, and nothing else is.** It is the only
/// place in the app that states what the app can do, as data rather than
/// as widgets nested inside other widgets. The hub screens still draw
/// their own tiles; they read the same `l10n` getters this does, so a
/// renamed screen is renamed in both at once. What can drift is the
/// *set*: a screen added to a hub and not added here is a screen the
/// search cannot find. `app_destinations_test.dart` is what notices.
library;

import 'package:flutter/material.dart';

import '../features/daylight/presentation/daylight_screen.dart';
import '../features/energy/presentation/energy_screen.dart';
import '../features/energy/presentation/outage_screen.dart';
import '../features/first_aid/presentation/compression_pacer_screen.dart';
import '../features/first_aid/presentation/first_aid_screen.dart';
import '../features/first_aid/presentation/first_aid_videos_screen.dart';
import '../features/first_aid/presentation/knowledge_check_screen.dart';
import '../features/home/application/shell_layout.dart';
import '../features/home/presentation/burglary_screen.dart';
import '../features/home/presentation/distress_signal_screen.dart';
import '../features/home/presentation/emergency_information_screen.dart';
import '../features/home/presentation/preparedness_tools_screen.dart';
import '../features/home/presentation/radio_emergency_screen.dart';
import '../features/home/presentation/readiness_screen.dart';
import '../features/household/presentation/emergency_cards_screen.dart';
import '../features/household/presentation/household_plan_screen.dart';
import '../features/inventory/presentation/medication_range_screen.dart';
import '../features/inventory/presentation/prepper_recipes_screen.dart';
import '../features/inventory/presentation/rotation_screen.dart';
import '../features/inventory/presentation/supply_groups_screen.dart';
import '../features/inventory/presentation/shopping_list_screen.dart';
import '../features/inventory/presentation/storage_tips_screen.dart';
import '../features/inventory/presentation/water_treatment_screen.dart';
import '../features/knowledge/presentation/apollo_library_screen.dart';
import '../features/knowledge/presentation/kiwix_library_screen.dart';
import '../features/knowledge/presentation/personal_documents_screen.dart';
import '../features/maps/presentation/map_download_screen.dart';
import '../features/maps/presentation/my_position_screen.dart';
import '../features/maps/presentation/nearby_screen.dart';
import '../features/possessions/presentation/possessions_screen.dart';
import '../features/preparedness/presentation/preparedness_hub_screen.dart';
import '../features/settings/presentation/followed_places_screen.dart';
import '../features/transfer/presentation/local_devices_screen.dart';
import '../features/transfer/presentation/qr_receive_screen.dart';
import '../features/transfer/presentation/qr_send_screen.dart';
import '../features/warnings/presentation/air_quality_screen.dart';
import '../features/warnings/presentation/fire_danger_screen.dart';
import '../features/warnings/presentation/heavy_rain_screen.dart';
import '../features/home/presentation/check_in_screen.dart';
import '../features/warnings/presentation/pegel_screen.dart';
import '../features/warnings/presentation/hazard_release_screen.dart';
import '../features/warnings/presentation/iodine_tablets_screen.dart';
import '../features/warnings/presentation/radiation_screen.dart';
import '../features/warnings/presentation/road_closure_screen.dart';
import '../features/warnings/presentation/warning_situation_map_screen.dart';
import '../features/kids_comic/application/kids_comic.dart';
import '../features/kids_comic/presentation/kids_comic_screen.dart';
import '../l10n/generated/app_localizations.dart';
import '../model/household_profile.dart';

/// One place the app can go.
class AppDestination {
  const AppDestination({
    required this.id,
    required this.title,
    required this.icon,
    required this.area,
    this.open,
    this.aliases = const [],
  });

  /// Stable, never shown, and never translated. Tests name destinations
  /// by this, so renaming one is a deliberate act rather than something
  /// a copy change does by accident.
  final String id;

  final String Function(AppLocalizations l10n) title;
  final IconData icon;

  /// Which tab it lives under, which is what a result says underneath
  /// its name. Knowing a screen exists is half of finding it; the other
  /// half is knowing where to look next time.
  final ShellDestination area;

  /// Builds the screen to push, or null where this destination **is** a
  /// tab and the shell should simply switch to it.
  final Widget Function(HouseholdProfile profile)? open;

  /// Words somebody might type that are not in the title.
  ///
  /// Deliberately **not** translated, and deliberately both languages at
  /// once. This is a match index, not copy: nobody reads it, and a
  /// German household that types "radio" or an English one that types
  /// "Funk" should both arrive. Keeping two lists in step for words that
  /// are never displayed would be work with no reader.
  final List<String> aliases;

  /// Whether the shell switches tab instead of pushing a route.
  bool get isTab => open == null;
}

/// Everything reachable, in the order the tabs come in.
///
/// Screens that need a record to exist are left out on purpose: an
/// article needs an archive open, a photo editor needs a photo, a form
/// needs the row it edits. Those are reached from the thing they are
/// about, which is the only place they mean anything.
List<AppDestination> appDestinations() => [
  // --- the tabs themselves ------------------------------------------
  AppDestination(
    id: 'overview',
    title: (l) => l.navOverview,
    icon: Icons.dashboard_outlined,
    area: ShellDestination.overview,
  ),
  AppDestination(
    id: 'emergency',
    title: (l) => l.emergencyTitle,
    icon: Icons.emergency_outlined,
    area: ShellDestination.emergency,
    aliases: ['notfall', 'emergency', 'sos'],
  ),
  AppDestination(
    id: 'inventory',
    title: (l) => l.inventoryTitle,
    icon: Icons.inventory_2_outlined,
    area: ShellDestination.inventory,
    aliases: ['vorrat', 'lager', 'stock', 'pantry'],
  ),
  AppDestination(
    id: 'checklists',
    title: (l) => l.checklistsTitle,
    icon: Icons.checklist_outlined,
    area: ShellDestination.checklists,
  ),
  AppDestination(
    id: 'warnings',
    title: (l) => l.warningsTitle,
    icon: Icons.warning_amber_outlined,
    area: ShellDestination.warnings,
    aliases: ['nina', 'bbk', 'meteoalarm', 'unwetter'],
  ),
  AppDestination(
    id: 'shelters',
    title: (l) => l.shelterMapTitle,
    icon: Icons.shield_outlined,
    area: ShellDestination.shelters,
    aliases: ['bunker', 'schutzraum', 'shelter'],
  ),
  AppDestination(
    id: 'map',
    title: (l) => l.navMap,
    icon: Icons.map_outlined,
    area: ShellDestination.map,
  ),
  AppDestination(
    id: 'knowledge',
    title: (l) => l.knowledgeTitle,
    icon: Icons.menu_book_outlined,
    area: ShellDestination.knowledge,
    aliases: ['wikipedia', 'wissen', 'zim'],
  ),
  AppDestination(
    id: 'household',
    title: (l) => l.navHousehold,
    icon: Icons.home_outlined,
    area: ShellDestination.household,
  ),
  AppDestination(
    id: 'settings',
    title: (l) => l.navSettings,
    icon: Icons.settings_outlined,
    area: ShellDestination.settings,
  ),

  // --- under Notfall -------------------------------------------------
  AppDestination(
    id: 'first-aid',
    title: (l) => l.firstAidTitle,
    icon: Icons.medical_services_outlined,
    area: ShellDestination.emergency,
    open: (_) => const FirstAidScreen(),
    aliases: [
      'erste hilfe',
      'first aid',
      'reanimation',
      // Die Seiten zur seelischen Not heissen anders als das, was
      // jemand eintippt, der sie sucht.
      'panik',
      'panikattacke',
      'trauer',
      'suizid',
      'psychische erste hilfe',
    ],
  ),
  AppDestination(
    id: 'compression-pacer',
    title: (l) => l.pacerTitle,
    icon: Icons.favorite_outline,
    area: ShellDestination.emergency,
    open: (_) => const CompressionPacerScreen(),
    aliases: ['herzdruckmassage', 'cpr', 'takt', 'drucktakt'],
  ),
  AppDestination(
    id: 'first-aid-videos',
    title: (l) => l.firstAidVideoPackTitle,
    icon: Icons.play_circle_outline,
    area: ShellDestination.emergency,
    open: (_) => const FirstAidVideosScreen(),
    aliases: ['video', 'filme'],
  ),
  AppDestination(
    id: 'knowledge-check',
    title: (l) => l.knowledgeCheckTitle,
    icon: Icons.quiz_outlined,
    area: ShellDestination.emergency,
    open: (_) => const KnowledgeCheckScreen(),
    aliases: ['quiz', 'ueben', 'uben', 'test'],
  ),
  AppDestination(
    id: 'emergency-directory',
    title: (l) => l.emergencyDirectoryTitle,
    icon: Icons.contact_phone_outlined,
    area: ShellDestination.emergency,
    open: (_) => const EmergencyInformationScreen(),
    aliases: ['112', '110', 'giftnotruf', 'nummern'],
  ),
  AppDestination(
    id: 'burglary',
    title: (l) => l.burglaryTitle,
    icon: Icons.lock_outline,
    area: ShellDestination.emergency,
    open: (p) => BurglaryScreen(householdId: p.id),
    aliases: [
      'einbruch',
      'einbruchschutz',
      'eingebrochen',
      'aufgebrochen',
      'polizei',
      '110',
      'sperrnotruf',
    ],
  ),
  AppDestination(
    id: 'radio-emergency',
    title: (l) => l.radioEmergencyTitle,
    icon: Icons.radio_outlined,
    area: ShellDestination.emergency,
    open: (_) => const RadioEmergencyScreen(),
    aliases: ['notfunk', 'pmr446', 'freenet', 'funk', 'radio'],
  ),
  AppDestination(
    id: 'distress-signal',
    title: (l) => l.distressTitle,
    icon: Icons.sos_outlined,
    area: ShellDestination.emergency,
    open: (_) => const DistressSignalScreen(),
    aliases: ['sos', 'morse', 'signal', 'pfeife'],
  ),
  AppDestination(
    id: 'outage',
    title: (l) => l.outageTitle,
    icon: Icons.kitchen_outlined,
    area: ShellDestination.emergency,
    open: (_) => const OutageScreen(),
    aliases: ['stromausfall', 'blackout', 'kuehlschrank', 'gefrierschrank'],
  ),
  AppDestination(
    id: 'energy',
    title: (l) => l.energyTitle,
    icon: Icons.bolt_outlined,
    area: ShellDestination.emergency,
    open: (_) => const EnergyScreen(),
    aliases: ['strom', 'kraftstoff', 'benzin', 'reichweite', 'fuel'],
  ),
  AppDestination(
    id: 'daylight',
    title: (l) => l.daylightTitle,
    icon: Icons.wb_twilight_outlined,
    area: ShellDestination.emergency,
    open: (_) => const DaylightScreen(),
    aliases: ['sonne', 'mond', 'daemmerung', 'sunrise', 'moon'],
  ),

  // --- under Vorrat ---------------------------------------------------
  AppDestination(
    id: 'supply-groups',
    title: (l) => l.supplyGroupsTitle,
    icon: Icons.donut_small_outlined,
    area: ShellDestination.inventory,
    open: (p) => SupplyGroupsScreen(householdId: p.id),
    aliases: [
      'gruppen',
      'lebensmittelgruppen',
      'abdeckung',
      'ble',
      'einseitig',
      'ausgewogen',
    ],
  ),
  AppDestination(
    id: 'shopping-list',
    title: (l) => l.shoppingListTitle,
    icon: Icons.shopping_cart_outlined,
    area: ShellDestination.inventory,
    open: (p) => ShoppingListScreen(householdId: p.id),
    aliases: ['einkauf', 'einkaufen', 'shopping'],
  ),
  AppDestination(
    id: 'rotation',
    title: (l) => l.rotationTitle,
    icon: Icons.autorenew_outlined,
    area: ShellDestination.inventory,
    open: (p) => RotationScreen(householdId: p.id),
    aliases: ['ablauf', 'mhd', 'haltbarkeit', 'expiry'],
  ),
  AppDestination(
    id: 'medication-range',
    title: (l) => l.medicationTitle,
    icon: Icons.medication_outlined,
    area: ShellDestination.inventory,
    open: (p) => MedicationRangeScreen(householdId: p.id),
    aliases: ['medikamente', 'tabletten', 'reichweite'],
  ),
  AppDestination(
    id: 'storage-tips',
    title: (l) => l.storageTipsTitle,
    icon: Icons.thermostat_outlined,
    area: ShellDestination.inventory,
    open: (p) => StorageTipsScreen(householdId: p.id),
    aliases: ['lagerung', 'lagern', 'storage'],
  ),
  AppDestination(
    id: 'water-treatment',
    title: (l) => l.waterTreatmentTitle,
    icon: Icons.water_drop_outlined,
    area: ShellDestination.inventory,
    open: (p) => const WaterTreatmentScreen(),
    aliases: [
      'wasser',
      'abkochen',
      'trinkwasser',
      'filter',
      'entkeimen',
      'chlor',
      'boil',
      'water',
    ],
  ),
  AppDestination(
    id: 'recipes',
    title: (l) => l.prepperRecipesTitle,
    icon: Icons.restaurant_outlined,
    area: ShellDestination.inventory,
    open: (p) => PrepperRecipesScreen(householdId: p.id),
    aliases: ['rezepte', 'kochen', 'recipes'],
  ),

  // --- under Warnungen ------------------------------------------------
  AppDestination(
    id: 'warning-map',
    title: (l) => l.warningSituationMapTitle,
    icon: Icons.public_outlined,
    area: ShellDestination.warnings,
    open: (p) => WarningSituationMapScreen(profile: p),
    aliases: ['lage', 'lagekarte'],
  ),
  AppDestination(
    id: 'pegel',
    title: (l) => l.pegelTitle,
    icon: Icons.water_outlined,
    area: ShellDestination.warnings,
    open: (_) => const PegelScreen(),
    aliases: ['hochwasser', 'fluss', 'wasserstand', 'flood'],
  ),
  AppDestination(
    id: 'fire-danger',
    title: (l) => l.fireDangerTitle,
    icon: Icons.local_fire_department_outlined,
    area: ShellDestination.warnings,
    open: (_) => const FireDangerScreen(),
    aliases: ['waldbrand', 'wbi', 'duerre', 'wildfire'],
  ),
  AppDestination(
    id: 'check-in',
    title: (l) => l.checkInTitle,
    icon: Icons.sms_outlined,
    area: ShellDestination.emergency,
    open: (p) => CheckInScreen(householdId: p.id),
    aliases: ['lebenszeichen', 'sms', 'mir geht es gut', 'familie', 'safe'],
  ),
  AppDestination(
    id: 'heavy-rain',
    title: (l) => l.heavyRainTitle,
    icon: Icons.thunderstorm_outlined,
    area: ShellDestination.warnings,
    open: (_) => const HeavyRainScreen(),
    aliases: ['starkregen', 'sturzflut', 'ueberflutung', 'keller', 'flood'],
  ),
  AppDestination(
    id: 'hazard-release',
    title: (l) => l.hazardReleaseTitle,
    icon: Icons.masks_outlined,
    area: ShellDestination.warnings,
    open: (_) => const HazardReleaseScreen(),
    aliases: [
      'gefahrstoff',
      'chemieunfall',
      'giftwolke',
      'fenster schliessen',
      'austritt',
      'cbrn',
      'entwarnung',
    ],
  ),
  AppDestination(
    id: 'iodine-tablets',
    title: (l) => l.iodineTitle,
    icon: Icons.medication_outlined,
    area: ShellDestination.warnings,
    open: (_) => const IodineTabletsScreen(),
    aliases: [
      'jod',
      'jodtabletten',
      'kaliumiodid',
      'jodblockade',
      'schilddruese',
    ],
  ),
  AppDestination(
    id: 'radiation',
    title: (l) => l.radiationTitle,
    icon: Icons.radar_outlined,
    area: ShellDestination.warnings,
    open: (_) => const RadiationScreen(),
    aliases: ['strahlung', 'gamma', 'odl', 'bfs', 'radioaktiv'],
  ),
  AppDestination(
    id: 'air-quality',
    title: (l) => l.airQualityTitle,
    icon: Icons.air_outlined,
    area: ShellDestination.warnings,
    open: (_) => const AirQualityScreen(),
    aliases: ['luft', 'feinstaub', 'ozon', 'uba'],
  ),
  AppDestination(
    id: 'road-closures',
    title: (l) => l.roadClosureTitle,
    icon: Icons.traffic_outlined,
    area: ShellDestination.warnings,
    open: (_) => const RoadClosureScreen(),
    aliases: ['autobahn', 'sperrung', 'stau', 'verkehr'],
  ),

  // --- under Karte ----------------------------------------------------
  AppDestination(
    id: 'nearby',
    title: (l) => l.nearbyTitle,
    icon: Icons.near_me_outlined,
    area: ShellDestination.map,
    open: (_) => const NearbyScreen(),
    aliases: ['umgebung', 'apotheke', 'tankstelle', 'nearby'],
  ),
  AppDestination(
    id: 'my-position',
    title: (l) => l.myPositionTitle,
    icon: Icons.share_location_outlined,
    area: ShellDestination.map,
    open: (_) => const MyPositionScreen(),
    aliases: ['standort', 'koordinaten', 'position', 'plus code'],
  ),
  AppDestination(
    id: 'map-download',
    title: (l) => l.mapDownloadTitle,
    icon: Icons.download_outlined,
    area: ShellDestination.map,
    open: (_) => const MapDownloadScreen(),
    aliases: ['offlinekarte', 'herunterladen', 'pmtiles'],
  ),

  // --- under Wissen ---------------------------------------------------
  AppDestination(
    id: 'kiwix-library',
    title: (l) => l.kiwixTitle,
    icon: Icons.library_books_outlined,
    area: ShellDestination.knowledge,
    open: (_) => const KiwixLibraryScreen(),
    aliases: ['kiwix', 'zim', 'archiv', 'wikipedia'],
  ),
  AppDestination(
    id: 'apollo-library',
    title: (l) => l.knowledgeApolloTitle,
    icon: Icons.rocket_launch_outlined,
    area: ShellDestination.knowledge,
    open: (_) => const ApolloLibraryScreen(),
  ),
  AppDestination(
    id: 'personal-documents',
    title: (l) => l.knowledgeDocumentIndexTitle,
    icon: Icons.folder_open_outlined,
    area: ShellDestination.knowledge,
    open: (_) => const PersonalDocumentsScreen(),
    aliases: ['dokumente', 'pdf', 'unterlagen', 'documents'],
  ),

  // --- under Haushalt -------------------------------------------------
  AppDestination(
    id: 'household-plan',
    title: (l) => l.householdPlanTitle,
    icon: Icons.assignment_outlined,
    area: ShellDestination.household,
    open: (p) => HouseholdPlanScreen(householdId: p.id),
    aliases: ['plan', 'treffpunkt', 'absprache'],
  ),
  AppDestination(
    id: 'emergency-cards',
    title: (l) => l.emergencyCardsTitle,
    icon: Icons.badge_outlined,
    area: ShellDestination.household,
    aliases: ['notfallkarte', 'allergie', 'blutgruppe', 'arzt'],
    open: (p) => EmergencyCardsScreen(householdId: p.id),
  ),
  AppDestination(
    id: 'possessions',
    title: (l) => l.possessionsTitle,
    icon: Icons.chair_outlined,
    area: ShellDestination.household,
    open: (p) => PossessionsScreen(householdId: p.id),
    aliases: ['hausrat', 'versicherung', 'inventar', 'wert'],
  ),
  AppDestination(
    id: 'readiness',
    title: (l) => l.readinessTitle,
    icon: Icons.verified_outlined,
    area: ShellDestination.household,
    open: (p) => ReadinessScreen(profile: p),
    aliases: ['bereitschaft', 'stand', 'readiness'],
  ),
  AppDestination(
    id: 'preparedness-hub',
    title: (l) => l.hubTitle,
    icon: Icons.hub_outlined,
    area: ShellDestination.household,
    open: (p) => PreparednessHubScreen(householdId: p.id),
  ),
  AppDestination(
    id: 'kids-comic',
    // The comic's own name, from its content file: it is a title, not
    // interface wording.
    title: (l) => kidsComic(l.localeName).title,
    icon: Icons.auto_stories_outlined,
    area: ShellDestination.household,
    open: (p) => const KidsComicScreen(),
    aliases: [
      'kinder',
      'kind',
      'comic',
      'familie',
      'mila',
      'nuss',
      'children',
      'kids',
    ],
  ),
  AppDestination(
    id: 'drills',
    title: (l) => l.drillsTitle,
    icon: Icons.school_outlined,
    area: ShellDestination.household,
    open: (p) => PreparednessToolsScreen(householdId: p.id),
    aliases: ['uebung', 'ubung', 'drill', 'lektion'],
  ),

  // --- under Einstellungen --------------------------------------------
  AppDestination(
    id: 'followed-places',
    title: (l) => l.followedPlacesTitle,
    icon: Icons.location_on_outlined,
    area: ShellDestination.settings,
    open: (p) => FollowedPlacesScreen(profile: p),
    aliases: ['warnorte', 'orte', 'regionen', 'angehoerige', 'arbeit'],
  ),
  AppDestination(
    id: 'transfer-nearby',
    title: (l) => l.transferNearbyTitle,
    icon: Icons.devices_outlined,
    area: ShellDestination.settings,
    open: (p) => LocalDevicesScreen(householdId: p.id),
    aliases: ['geraete', 'uebertragen', 'abgleich', 'sync'],
  ),
  AppDestination(
    id: 'transfer-send',
    title: (l) => l.transferSendTitle,
    icon: Icons.qr_code_2_outlined,
    area: ShellDestination.settings,
    open: (p) => QrSendScreen(householdId: p.id),
    aliases: ['qr', 'senden', 'send'],
  ),
  AppDestination(
    id: 'transfer-receive',
    title: (l) => l.transferReceiveTitle,
    icon: Icons.qr_code_scanner_outlined,
    area: ShellDestination.settings,
    open: (p) => QrReceiveScreen(householdId: p.id),
    aliases: ['qr', 'empfangen', 'scannen', 'receive'],
  ),
];

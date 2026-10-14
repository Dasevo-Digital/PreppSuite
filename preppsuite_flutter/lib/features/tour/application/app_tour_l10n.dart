import '../../../l10n/generated/app_localizations.dart';
import 'app_tour.dart';

/// What the band says at [stop].
///
/// The titles are the names the navigation already uses, so the band and
/// the bar underneath it agree on what the place is called.
String tourStopTitle(AppLocalizations l10n, TourStop stop) => switch (stop) {
  TourStop.emergency => l10n.navEmergency,
  TourStop.warnings => l10n.navWarnings,
  TourStop.inventory => l10n.navInventory,
  TourStop.checklists => l10n.checklistsTitle,
  TourStop.map => l10n.navMap,
  TourStop.knowledge => l10n.navKnowledge,
  TourStop.household => l10n.navHousehold,
  TourStop.settings => l10n.navSettings,
};

/// The text at [stop], with the controls it points at named by their own
/// labels.
///
/// Every button a text mentions is passed in from the getter that labels
/// it on the screen, never written out a second time: a renamed button is
/// renamed in the tour as well, and [tourStopAnchors] lets a test check
/// that the button is still where the text says it is.
String tourStopBody(AppLocalizations l10n, TourStop stop) => switch (stop) {
  TourStop.emergency => l10n.tourEmergencyBody(l10n.firstAidTitle),
  TourStop.warnings => l10n.tourWarningsBody(
    l10n.warningSituationMapTitle,
    l10n.navHousehold,
  ),
  TourStop.inventory => l10n.tourInventoryBody(l10n.addItemButton),
  TourStop.checklists => l10n.tourChecklistsBody(l10n.createTemplateButton),
  TourStop.map => l10n.tourMapBody(l10n.mapDownloadAction, l10n.navShelters),
  TourStop.knowledge => l10n.tourKnowledgeBody(l10n.knowledgeDocumentsTitle),
  TourStop.household => l10n.tourHouseholdBody(
    l10n.householdPlanTitle,
    l10n.emergencyCardsTitle,
    l10n.followedPlacesTitle,
  ),
  TourStop.settings => l10n.tourSettingsBody(
    l10n.settingsCategoryData,
    l10n.settingsCategoryAppearance,
    l10n.navOverview,
  ),
};

/// The labels [tourStopBody] names that have to stand on the stop's own
/// screen, as a text or as a button's tooltip.
///
/// The names of other destinations are left out: those are in the
/// navigation by construction, and the navigation is not the screen.
List<String> tourStopAnchors(AppLocalizations l10n, TourStop stop) =>
    switch (stop) {
      TourStop.emergency => [l10n.firstAidTitle],
      TourStop.warnings => [l10n.warningSituationMapTitle],
      TourStop.inventory => [l10n.addItemButton],
      TourStop.checklists => [l10n.createTemplateButton],
      TourStop.map => [l10n.mapDownloadAction],
      TourStop.knowledge => [l10n.knowledgeDocumentsTitle],
      TourStop.household => [
        l10n.householdPlanTitle,
        l10n.emergencyCardsTitle,
        l10n.followedPlacesTitle,
      ],
      TourStop.settings => [
        l10n.settingsCategoryData,
        l10n.settingsCategoryAppearance,
      ],
    };

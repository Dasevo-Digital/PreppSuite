import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/neighbour_offer_code.dart';

String localizeNeighbourOfferKind(
  AppLocalizations l10n,
  NeighbourOfferKind kind,
) => switch (kind) {
  NeighbourOfferKind.water => l10n.neighbourhoodKindWater,
  NeighbourOfferKind.food => l10n.neighbourhoodKindFood,
  NeighbourOfferKind.energy => l10n.neighbourhoodKindEnergy,
  NeighbourOfferKind.tools => l10n.neighbourhoodKindTools,
  NeighbourOfferKind.care => l10n.neighbourhoodKindCare,
  NeighbourOfferKind.help => l10n.neighbourhoodKindHelp,
  NeighbourOfferKind.other => l10n.neighbourhoodKindOther,
};

IconData neighbourOfferIcon(NeighbourOfferKind kind) => switch (kind) {
  NeighbourOfferKind.water => Icons.water_drop_outlined,
  NeighbourOfferKind.food => Icons.restaurant_outlined,
  NeighbourOfferKind.energy => Icons.bolt_outlined,
  NeighbourOfferKind.tools => Icons.handyman_outlined,
  NeighbourOfferKind.care => Icons.medical_services_outlined,
  NeighbourOfferKind.help => Icons.volunteer_activism_outlined,
  NeighbourOfferKind.other => Icons.category_outlined,
};

/// [offer] as the text of its QR code, in the language of this app.
String neighbourOfferText(AppLocalizations l10n, NeighbourOfferCode offer) =>
    offer.encode(
      kindLabel: localizeNeighbourOfferKind(l10n, offer.kind),
      contactLabel: l10n.neighbourhoodContactLabel,
    );

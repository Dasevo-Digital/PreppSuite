import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/shelter_bearing.dart';
import '../application/shelter_classification.dart';
import '../application/shelter_l10n.dart';

/// The shelters as a list, nearest first.
///
/// The map alone was the whole answer here, and a map is a drawing: a
/// screen reader reaching it finds an empty rectangle, so the one screen
/// in the app somebody might open in an emergency was the one screen that
/// could not be read out. It is also the more useful view sighted — the
/// nearest one and how far it is are the two things being looked for, and
/// a rectangle full of identical shields does not answer either.
class ShelterList extends StatelessWidget {
  const ShelterList({
    super.key,
    required this.shelters,
    required this.center,
    required this.l10n,
    required this.colorFor,
    required this.onShow,
  });

  final List<ClassifiedShelter> shelters;

  /// Null until a location or a search has resolved. Without it there is
  /// nothing to measure from, so the entries carry no distance.
  final LatLng? center;

  final AppLocalizations l10n;
  final Color Function(ShelterConfidence) colorFor;
  final ValueChanged<ClassifiedShelter> onShow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (center == null) return const SizedBox.shrink();

    if (shelters.isEmpty) {
      return Text(l10n.shelterListEmpty, style: theme.textTheme.bodySmall);
    }

    // Nearest first. The sources hand them over in their own order, which
    // for a list of places to walk to means no order at all.
    final sorted = [...shelters]
      ..sort(
        (a, b) => distanceMeters(center!, LatLng(a.lat, a.lon)).compareTo(
          distanceMeters(center!, LatLng(b.lat, b.lon)),
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.shelterListHeading, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final shelter in sorted)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.shield, color: colorFor(shelter.confidence)),
            title: Text(shelter.name),
            subtitle: Text(
              l10n.shelterListSubtitle(
                formatShelterDistance(
                  l10n,
                  distanceMeters(center!, LatLng(shelter.lat, shelter.lon)),
                  bearingFrom(center!, LatLng(shelter.lat, shelter.lon)),
                ),
                localizeShelterConfidence(l10n, shelter.confidence),
                shelter.sourceLabel,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: l10n.shelterShowOnMap(shelter.name),
              onPressed: () => onShow(shelter),
            ),
            onTap: () => onShow(shelter),
          ),
      ],
    );
  }
}

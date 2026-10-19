import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error_text.dart';
import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../maps/application/personal_place.dart';
import '../../maps/presentation/map_screen.dart';
import '../../shelters/application/shelter_bearing.dart';
import '../../shelters/application/shelter_l10n.dart';
import '../application/meeting_point_places.dart';

/// A meeting point's coordinates as they are read out: five decimals,
/// about a metre, with a point whatever the language -- the form every
/// map and every radio operator takes.
String formatPlaceCoordinates(PersonalPlace place) =>
    '${place.latitude.toStringAsFixed(5)}, '
    '${place.longitude.toStringAsFixed(5)}';

/// "How far, which way" to a meeting point, from wherever the device is
/// (#204). Satellites and the point on this device are all it needs; no
/// network.
class MeetingPointWayButton extends StatelessWidget {
  const MeetingPointWayButton({
    super.key,
    required this.place,
    this.geolocation,
  });

  final PersonalPlace place;

  /// Injectable for tests.
  final GeolocationService? geolocation;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context)!.meetingPlaceWay,
    icon: const Icon(Icons.near_me_outlined),
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) => _WayDialog(place: place, geolocation: geolocation),
    ),
  );
}

class _WayDialog extends StatefulWidget {
  const _WayDialog({required this.place, this.geolocation});

  final PersonalPlace place;
  final GeolocationService? geolocation;

  @override
  State<_WayDialog> createState() => _WayDialogState();
}

class _WayDialogState extends State<_WayDialog> {
  late final _geolocation = widget.geolocation ?? GeolocationService();
  ({double meters, CompassPoint direction})? _way;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  @override
  void dispose() {
    if (widget.geolocation == null) _geolocation.close();
    super.dispose();
  }

  Future<void> _measure() async {
    try {
      final here = await _geolocation.getCurrentLatLng();
      if (mounted) setState(() => _way = wayTo(here, widget.place));
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final way = _way;
    final error = _error;
    final place = widget.place;

    return AlertDialog(
      title: Text(place.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (way != null)
            Text(
              formatShelterDistance(l10n, way.meters, way.direction),
              style: theme.textTheme.headlineSmall,
            )
          else if (error != null)
            Text(describeError(l10n, error))
          else
            Row(
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.meetingPlaceLocating)),
              ],
            ),
          const SizedBox(height: 12),
          SelectableText(
            formatPlaceCoordinates(place),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final navigator = Navigator.of(context)..pop();
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => MapScreen(
                  focus: LatLng(place.latitude, place.longitude),
                  focusLabel: place.label,
                ),
              ),
            );
          },
          child: Text(l10n.meetingPlaceOnMap),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}

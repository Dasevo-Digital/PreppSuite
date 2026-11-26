import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error_text.dart';
import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../maps/application/personal_place.dart';
import '../../maps/application/readable_position.dart';
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

  /// The fix [_way] was measured from. Said when it is old (#390): the
  /// device hands over its last known position when it gets no fresh one,
  /// and "300 m north-east" from where somebody was yesterday is a wrong
  /// direction, not a rough one.
  ReadablePosition? _from;
  Object? _error;
  var _measuring = false;

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
    setState(() {
      _measuring = true;
      _error = null;
    });
    try {
      final fix = await _geolocation.getCurrentFix();
      if (!mounted) return;
      setState(() {
        _from = fix;
        _way = wayTo(LatLng(fix.latitude, fix.longitude), widget.place);
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _measuring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final way = _measuring ? null : _way;
    final error = _measuring ? null : _error;
    final place = widget.place;
    final now = DateTime.now();
    final from = _from;
    final staleAt = way != null && from != null && from.isStaleAt(now)
        ? from.takenAtLabel(l10n.localeName, now)
        : null;

    return AlertDialog(
      title: Text(place.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (way != null) ...[
            Text(
              formatShelterDistance(l10n, way.meters, way.direction),
              style: theme.textTheme.headlineSmall,
            ),
            if (staleAt != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.positionStaleWay(staleAt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ] else if (error != null)
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
        if (staleAt != null || error != null)
          TextButton(
            onPressed: _measure,
            child: Text(l10n.myPositionMeasure),
          ),
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

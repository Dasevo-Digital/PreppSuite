import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error_text.dart';
import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../first_aid/application/defibrillators.dart' show compassOctant;
import '../../first_aid/presentation/defibrillator_screen.dart'
    show compassLabel;
import '../application/emergency_points.dart';

/// Emergency wells, help points and the nearest siren (#127, #128).
///
/// Searched once with a network and kept, like the defibrillators. The
/// siren comes first because it is the one answer that changes what a
/// household has to do: where no siren reaches, the warning app and the
/// radio are not a second channel but the only one.
class EmergencyPointsScreen extends StatefulWidget {
  const EmergencyPointsScreen({
    super.key,
    this.client,
    this.geolocation,
    this.store = const EmergencyPointStore(),
  });

  /// Injectable for tests.
  final EmergencyPointClient? client;
  final GeolocationService? geolocation;
  final EmergencyPointStore store;

  @override
  State<EmergencyPointsScreen> createState() => _EmergencyPointsScreenState();
}

class _EmergencyPointsScreenState extends State<EmergencyPointsScreen> {
  late final EmergencyPointClient _client =
      widget.client ?? EmergencyPointClient();
  late final GeolocationService _geolocation =
      widget.geolocation ?? GeolocationService();

  EmergencyPointSearch? _search;
  var _restoring = true;
  var _busy = false;
  var _offline = false;

  @override
  void initState() {
    super.initState();
    widget.store.load().then((kept) {
      if (!mounted) return;
      setState(() {
        _search = kept;
        _restoring = false;
      });
    });
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    if (widget.geolocation == null) _geolocation.close();
    super.dispose();
  }

  Future<void> _useLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final here = await _geolocation.getCurrentLatLng();
      await _find(here.latitude, here.longitude, null);
    } on LocationUnavailableException catch (error) {
      _say(describeError(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enterAddress() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aedSearchAddress),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.heavyRainAddressHint),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.heavyRainCheck),
          ),
        ],
      ),
    );
    controller.dispose();
    if (query == null || query.trim().isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      final found = await _geolocation.searchPlace(query.trim());
      if (found == null) {
        _say(l10n.heavyRainNotFound);
        return;
      }
      await _find(found.latitude, found.longitude, query.trim());
    } on Object catch (error) {
      _say(describeError(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _find(double latitude, double longitude, String? name) async {
    final l10n = AppLocalizations.of(context)!;
    final List<EmergencyPoint> found;
    try {
      found = await _client.near(latitude, longitude);
    } on Object {
      if (!mounted) return;
      setState(() => _offline = true);
      _say(l10n.aedFailed);
      return;
    }
    final search = EmergencyPointSearch(
      latitude: latitude,
      longitude: longitude,
      placeName: name,
      checkedAt: DateTime.now(),
      found: found,
    );
    await widget.store.save(search);
    if (!mounted) return;
    setState(() {
      _search = search;
      _offline = false;
    });
  }

  Future<void> _openMap(EmergencyPoint point, String label) async {
    final lat = point.latitude;
    final lon = point.longitude;
    final query = Uri.encodeComponent(label);
    final Uri uri;
    if (!kIsWeb && Platform.isAndroid) {
      uri = Uri.parse('geo:$lat,$lon?q=$lat,$lon($query)');
    } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      uri = Uri.parse('https://maps.apple.com/?ll=$lat,$lon&q=$query');
    } else {
      uri = Uri.parse(
        'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=19/$lat/$lon',
      );
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final search = _search;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.emergencyPointsTitle)),
      body: _restoring
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.emergencyPointsIntro),
                const SizedBox(height: 12),
                if (_busy) const LinearProgressIndicator(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : _useLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(l10n.aedUseLocation),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _enterAddress,
                      icon: const Icon(Icons.search),
                      label: Text(l10n.aedSearchAddress),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_offline)
                  Text(l10n.aedOffline, style: theme.textTheme.bodySmall),
                if (search != null) ..._results(l10n, search),
                const SizedBox(height: 16),
                Text(
                  l10n.emergencyPointsIncomplete,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(l10n.aedSource, style: theme.textTheme.bodySmall),
              ],
            ),
    );
  }

  List<Widget> _results(AppLocalizations l10n, EmergencyPointSearch search) {
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(
      l10n.localeName,
    ).format(search.checkedAt.toLocal());
    final wells = search.of(EmergencyPointKind.well);
    final helpPoints = search.of(EmergencyPointKind.helpPoint);
    return [
      Text(
        l10n.emergencyPointsPlace(search.placeName ?? l10n.aedHere, date),
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      _sirenCard(l10n, search),
      const SizedBox(height: 16),
      Text(l10n.emergencyWellsTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(l10n.emergencyWellsWater, style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      if (wells.isEmpty)
        Text(l10n.emergencyWellsNone(EmergencyPointKind.well.radiusKm))
      else ...[
        Text(
          l10n.emergencyWellsFound(
            wells.length,
            EmergencyPointKind.well.radiusKm,
          ),
        ),
        for (final well in wells) _tile(l10n, search, well),
      ],
      const SizedBox(height: 16),
      Text(l10n.emergencyHelpPointsTitle, style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(l10n.emergencyHelpPointsHint, style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      if (helpPoints.isEmpty)
        Text(
          l10n.emergencyHelpPointsNone(EmergencyPointKind.helpPoint.radiusKm),
        )
      else ...[
        Text(
          l10n.emergencyHelpPointsFound(
            helpPoints.length,
            EmergencyPointKind.helpPoint.radiusKm,
          ),
        ),
        for (final point in helpPoints) _tile(l10n, search, point),
      ],
    ];
  }

  Widget _sirenCard(AppLocalizations l10n, EmergencyPointSearch search) {
    final theme = Theme.of(context);
    final sirens = search.of(EmergencyPointKind.siren);
    final reach = search.sirenReachHere;
    final nearest = sirens.isEmpty ? null : sirens.first;
    final where = nearest == null ? null : _whereFrom(l10n, search, nearest);
    final text = switch (reach) {
      SirenReach.likely => l10n.sirenLikely(where!.$1, where.$2),
      SirenReach.maybe => l10n.sirenMaybe(where!.$1, where.$2),
      SirenReach.unlikely => l10n.sirenUnlikely(where!.$1, where.$2),
      SirenReach.none => l10n.sirenNone(EmergencyPointKind.siren.radiusKm),
    };
    final colours = theme.colorScheme;
    final (background, foreground) = switch (reach) {
      SirenReach.likely => (
        colours.secondaryContainer,
        colours.onSecondaryContainer,
      ),
      SirenReach.maybe => (
        colours.tertiaryContainer,
        colours.onTertiaryContainer,
      ),
      _ => (colours.errorContainer, colours.onErrorContainer),
    };
    final range = nearest?.sirenRangeMetres;
    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.sirenTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                if (nearest != null)
                  IconButton(
                    tooltip: l10n.aedOpenMap,
                    color: foreground,
                    icon: const Icon(Icons.map_outlined),
                    onPressed: () => _openMap(nearest, l10n.sirenUnnamed),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(color: foreground)),
            if (range != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.sirenRangeMapped(_distance(l10n, range.toDouble())),
                style: TextStyle(color: foreground),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.sirenRule,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    AppLocalizations l10n,
    EmergencyPointSearch search,
    EmergencyPoint point,
  ) {
    final (distance, direction) = _whereFrom(l10n, search, point);
    final unnamed = switch (point.kind) {
      EmergencyPointKind.well => l10n.emergencyWellUnnamed,
      EmergencyPointKind.helpPoint => l10n.emergencyHelpPointUnnamed,
      EmergencyPointKind.siren => l10n.sirenUnnamed,
    };
    final label = point.name ?? unnamed;
    final details = [
      ?point.address,
      if (point.ref case final ref? when point.kind == EmergencyPointKind.well)
        l10n.emergencyWellNumber(ref),
      if (point.openingHours case final hours?) l10n.aedOpeningHours(hours),
      if (point.outOfOrder) l10n.emergencyWellOutOfOrder,
    ];
    return Card(
      child: ListTile(
        leading: Icon(switch (point.kind) {
          EmergencyPointKind.well => Icons.water_drop_outlined,
          EmergencyPointKind.helpPoint => Icons.info_outline,
          EmergencyPointKind.siren => Icons.campaign_outlined,
        }, color: point.outOfOrder ? Theme.of(context).disabledColor : null),
        title: Text('$label · ${l10n.aedDistance(distance, direction)}'),
        subtitle: details.isEmpty ? null : Text(details.join('\n')),
        isThreeLine: details.length > 1,
        trailing: IconButton(
          tooltip: l10n.aedOpenMap,
          icon: const Icon(Icons.map_outlined),
          onPressed: () => _openMap(point, label),
        ),
      ),
    );
  }

  (String, String) _whereFrom(
    AppLocalizations l10n,
    EmergencyPointSearch search,
    EmergencyPoint point,
  ) => (
    _distance(l10n, search.distanceTo(point)),
    compassLabel(
      l10n,
      compassOctant(
        search.latitude,
        search.longitude,
        point.latitude,
        point.longitude,
      ),
    ),
  );

  String _distance(AppLocalizations l10n, double metres) => metres < 1000
      ? '${(metres / 10).round() * 10} m'
      : '${NumberFormat('0.0', l10n.localeName).format(metres / 1000)} km';
}

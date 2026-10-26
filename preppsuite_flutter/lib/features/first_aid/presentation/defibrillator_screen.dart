import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error_log.dart';
import '../../../core/error_text.dart';
import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shelters/application/overpass_shelter_client.dart'
    show OverpassException;
import '../application/defibrillators.dart';
import '../../warnings/presentation/address_dialog.dart';

/// Where the nearest defibrillators hang (#117).
///
/// Searched once with a network and kept, like everything this app
/// expects to be needed on a bad day. The screen says first what to do
/// first -- 112 and compressions -- because the list is the second thing
/// somebody needs, and the person reading it may be the one who should be
/// pressing on a chest instead.
class DefibrillatorScreen extends StatefulWidget {
  const DefibrillatorScreen({
    super.key,
    this.client,
    this.geolocation,
    this.store = const DefibrillatorStore(),
  });

  /// Injectable for tests.
  final DefibrillatorClient? client;
  final GeolocationService? geolocation;
  final DefibrillatorStore store;

  @override
  State<DefibrillatorScreen> createState() => _DefibrillatorScreenState();
}

/// Why a search near a point brought nothing new (#217).
enum NearbySearchProblem {
  /// This device reached no server at all.
  offline,

  /// It reached them, and none answered in time or properly.
  noAnswer,
}

NearbySearchProblem nearbySearchProblemOf(Object error) =>
    error is OverpassException && error.noNetwork
    ? NearbySearchProblem.offline
    : NearbySearchProblem.noAnswer;

/// What to say about [problem], and about the last search only where
/// there is one. Before #217 every failure read "Keine Verbindung.
/// Gezeigt wird die letzte Suche." -- on a network that worked, above a
/// list that was not there.
String nearbySearchProblemText(
  AppLocalizations l10n,
  NearbySearchProblem problem, {
  required bool kept,
}) => switch ((problem, kept)) {
  (NearbySearchProblem.offline, true) => l10n.aedOffline,
  (NearbySearchProblem.offline, false) => l10n.aedOfflineNothingKept,
  (NearbySearchProblem.noAnswer, true) => l10n.aedNoAnswerKept,
  (NearbySearchProblem.noAnswer, false) => l10n.aedNoAnswer,
};

class _DefibrillatorScreenState extends State<DefibrillatorScreen> {
  late final DefibrillatorClient _client =
      widget.client ?? DefibrillatorClient();
  late final GeolocationService _geolocation =
      widget.geolocation ?? GeolocationService();

  DefibrillatorSearch? _search;
  var _restoring = true;
  var _busy = false;

  /// Why the last search brought nothing new, or null after one that did.
  NearbySearchProblem? _problem;

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
    final query = await askAddress(context, title: l10n.aedSearchAddress);
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
    final List<Defibrillator> found;
    try {
      found = await _client.near(latitude, longitude);
    } on Object catch (error, stack) {
      final problem = nearbySearchProblemOf(error);
      // A device without network is not a fault worth keeping. A network
      // that works and no answer is, and the protocol is what shows why.
      if (problem == NearbySearchProblem.noAnswer) {
        ErrorLog.instance.record(error, stack, context: 'Defibrillatoren');
      }
      if (!mounted) return;
      setState(() => _problem = problem);
      return;
    }
    final search = DefibrillatorSearch(
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
      _problem = null;
    });
  }

  Future<void> _openMap(Defibrillator aed, String label) async {
    final lat = aed.latitude;
    final lon = aed.longitude;
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
      appBar: AppBar(title: Text(l10n.aedTitle)),
      body: _restoring
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      l10n.aedCall112First,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
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
                if (_problem case final problem?)
                  Text(
                    nearbySearchProblemText(
                      l10n,
                      problem,
                      kept: search != null,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                if (search != null) ..._results(l10n, search),
                const SizedBox(height: 16),
                Text(l10n.aedIncomplete, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(l10n.aedSource, style: theme.textTheme.bodySmall),
              ],
            ),
    );
  }

  List<Widget> _results(AppLocalizations l10n, DefibrillatorSearch search) {
    final theme = Theme.of(context);
    final radius = defibrillatorRadiusMetres ~/ 1000;
    final date = DateFormat.yMMMd(
      l10n.localeName,
    ).format(search.checkedAt.toLocal());
    final place = search.placeName ?? l10n.aedHere;
    if (search.found.isEmpty) {
      return [Text(l10n.aedNone(radius))];
    }
    return [
      Text(
        l10n.aedFound(search.found.length, radius, place, date),
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      for (final aed in search.found) _tile(l10n, search, aed),
    ];
  }

  Widget _tile(
    AppLocalizations l10n,
    DefibrillatorSearch search,
    Defibrillator aed,
  ) {
    final metres = distanceMetres(
      search.latitude,
      search.longitude,
      aed.latitude,
      aed.longitude,
    );
    final distance = metres < 1000
        ? '${(metres / 10).round() * 10} m'
        : '${NumberFormat('0.0', l10n.localeName).format(metres / 1000)} km';
    final direction = compassLabel(
      l10n,
      compassOctant(
        search.latitude,
        search.longitude,
        aed.latitude,
        aed.longitude,
      ),
    );
    final where = aed.locationIn(l10n.localeName.split('_').first);
    final details = [
      ?where,
      if (aed.level case final level?) l10n.aedLevel(level),
      if (aed.openingHours case final hours?) l10n.aedOpeningHours(hours),
      if (aed.indoor case final indoor?)
        indoor ? l10n.aedIndoor : l10n.aedOutdoor,
      if (aed.restricted) l10n.aedRestricted,
    ];
    final label = aed.name ?? l10n.aedUnnamed;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_heart_outlined),
        title: Text('$label · ${l10n.aedDistance(distance, direction)}'),
        subtitle: details.isEmpty ? null : Text(details.join('\n')),
        isThreeLine: details.length > 1,
        trailing: IconButton(
          tooltip: l10n.aedOpenMap,
          icon: const Icon(Icons.map_outlined),
          onPressed: () => _openMap(aed, label),
        ),
      ),
    );
  }
}

String compassLabel(AppLocalizations l10n, int octant) => switch (octant) {
  0 => l10n.compassN,
  1 => l10n.compassNE,
  2 => l10n.compassE,
  3 => l10n.compassSE,
  4 => l10n.compassS,
  5 => l10n.compassSW,
  6 => l10n.compassW,
  _ => l10n.compassNW,
};

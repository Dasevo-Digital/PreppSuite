import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/geolocation_service.dart';
import '../../../core/error_text.dart';
import '../../../core/adaptive_columns.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/daylight_l10n.dart';
import '../application/daylight_store.dart';
import '../application/sun_moon.dart';

/// Sun and moon for one place, worked out here.
///
/// The only screen in this app whose answer is neither fetched nor
/// stored: it is arithmetic over the calendar, so it is as right on the
/// tenth day without a network as on the first. The place is remembered
/// precisely because the day it matters is the day the position lookup
/// has nothing to talk to either.
class DaylightScreen extends StatefulWidget {
  const DaylightScreen({
    super.key,
    this.store = const DaylightStore(),
    this.now,
  });

  final DaylightStore store;

  /// Overridden in tests. Null means the real clock.
  final DateTime? now;

  @override
  State<DaylightScreen> createState() => _DaylightScreenState();
}

class _DaylightScreenState extends State<DaylightScreen> {
  final _geolocation = GeolocationService();

  DaylightPlace? _place;
  var _loading = true;
  var _locating = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _geolocation.close();
    super.dispose();
  }

  Future<void> _restore() async {
    final place = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _place = place;
      _loading = false;
    });
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final position = await _geolocation.getCurrentLatLng();
      final place = DaylightPlace(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      await widget.store.save(place);
      if (mounted) setState(() => _place = place);
    } on LocationUnavailableException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(describeError(AppLocalizations.of(context)!, error)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _typePlace() async {
    final l10n = AppLocalizations.of(context)!;
    final coordinates = TextEditingController(
      text: _place == null
          ? ''
          : '${_place!.latitude.toStringAsFixed(4)}, '
                '${_place!.longitude.toStringAsFixed(4)}',
    );
    final name = TextEditingController(text: _place?.name ?? '');
    String? problem;

    final place = await showDialog<DaylightPlace>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.daylightSetPlace),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: coordinates,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.daylightCoordinates,
                  hintText: l10n.daylightCoordinatesHint,
                  errorText: problem,
                ),
              ),
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: l10n.daylightPlaceName,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                final parsed = parseCoordinates(
                  coordinates.text,
                  name: name.text,
                );
                if (parsed == null) {
                  setDialogState(
                    () => problem = l10n.daylightCoordinatesBad,
                  );
                  return;
                }
                Navigator.pop(context, parsed);
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );

    if (place == null) return;
    await widget.store.save(place);
    if (mounted) setState(() => _place = place);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final place = _place;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.daylightTitle),
        actions: [
          IconButton(
            tooltip: l10n.mapMyLocationAction,
            onPressed: _locating ? null : _useMyLocation,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : place == null
          ? _empty(l10n)
          : _almanac(l10n, place),
    );
  }

  Widget _empty(AppLocalizations l10n) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        l10n.daylightNoPlace,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(l10n.daylightNoPlaceWhy),
      const SizedBox(height: 16),
      FilledButton(onPressed: _typePlace, child: Text(l10n.daylightSetPlace)),
      const SizedBox(height: 24),
      Text(l10n.daylightWhy, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _almanac(AppLocalizations l10n, DaylightPlace place) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = widget.now ?? DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    final sun = sunTimesFor(now, place.latitude, place.longitude);
    final moon = moonFor(now, place.latitude, place.longitude);
    final nextSun = sunTimesFor(tomorrow, place.latitude, place.longitude);

    String clock(DateTime moment) => DateFormat.Hm(locale).format(moment);

    return AdaptiveColumns(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      // Sun, moon and tomorrow: three answers of the same shape, which a
      // wide window can show at once instead of one under the other.
      blocks: [
        _Part(
          children: [
            Text(
              place.name ??
                  '${place.latitude.toStringAsFixed(4)}, '
                      '${place.longitude.toStringAsFixed(4)}',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              DateFormat.yMMMMEEEEd(locale).format(now),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            if (sun.alwaysUp)
              _Note(text: l10n.daylightAlwaysUp)
            else if (sun.alwaysDown)
              _Note(text: l10n.daylightAlwaysDown),

            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // In the order the day happens, which is the order somebody
                  // reads it in.
                  ?_row(l10n.daylightCivilDawn, sun.civilDawn, clock),
                  ?_row(l10n.daylightSunrise, sun.sunrise, clock),
                  ?_row(l10n.daylightSolarNoon, sun.solarNoon, clock),
                  ?_row(l10n.daylightSunset, sun.sunset, clock),
                  ?_row(l10n.daylightCivilDusk, sun.civilDusk, clock),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (sun.dayLength case final length?)
              Text(
                l10n.daylightDayLength(formatSpan(l10n, length)),
                style: theme.textTheme.bodyMedium,
              ),
            if (sun.eveningTwilight case final twilight?)
              // The half hour that decides whether the walk home is a walk or
              // a stumble.
              Text(
                l10n.daylightEveningTwilight(formatSpan(l10n, twilight)),
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
        _Part(
          children: [
            Text(l10n.daylightMoon, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.nightlight_outlined),
                    title: Text(localizeMoonPhase(l10n, moon.phase)),
                    subtitle: Text(
                      l10n.daylightMoonIllumination(
                        (moon.illumination * 100).round(),
                      ),
                    ),
                  ),
                  if (moon.upAllDay)
                    ListTile(
                      dense: true,
                      title: Text(l10n.daylightMoonUpAllDay),
                    )
                  else if (moon.downAllDay)
                    ListTile(
                      dense: true,
                      title: Text(l10n.daylightMoonDownAllDay),
                    )
                  else ...[
                    _row(l10n.daylightMoonrise, moon.rise, clock) ??
                        ListTile(
                          dense: true,
                          title: Text(l10n.daylightMoonNoRise),
                        ),
                    _row(l10n.daylightMoonset, moon.set, clock) ??
                        ListTile(
                          dense: true,
                          title: Text(l10n.daylightMoonNoSet),
                        ),
                  ],
                ],
              ),
            ),
          ],
        ),
        _Part(
          children: [
            Text(l10n.daylightTomorrow, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ?_row(l10n.daylightSunrise, nextSun.sunrise, clock),
                  ?_row(l10n.daylightSunset, nextSun.sunset, clock),
                ],
              ),
            ),
          ],
        ),
        _Part(
          children: [
            OutlinedButton(
              onPressed: _typePlace,
              child: Text(l10n.daylightChangePlace),
            ),
            const SizedBox(height: 16),
            Text(l10n.daylightWhy, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(l10n.daylightAccuracy, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  /// One line, or nothing at all where the event does not happen.
  ///
  /// Null rather than a dash: north of the Arctic circle in June there is
  /// no sunrise, and a row reading "--:--" says the app failed rather
  /// than that the sun did not set.
  Widget? _row(String label, DateTime? at, String Function(DateTime) clock) {
    if (at == null) return null;
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(clock(at), style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(12), child: Text(text)),
    ),
  );
}

/// One answer of the screen, kept together when it is laid out in columns.
class _Part extends StatelessWidget {
  const _Part({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}

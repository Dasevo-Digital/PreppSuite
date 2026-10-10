import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/fire_danger_client.dart';
import '../application/fire_danger_level.dart';
import '../application/fire_danger_store.dart';
import '../../../core/adaptive_columns.dart';

/// The forest fire danger index at one DWD station, today and ahead.
///
/// The days ahead are the reason this is a screen and not a number: level
/// 2 today with level 5 on Friday is a different week from level 2
/// throughout, and both read as "2" if only today is shown.
///
/// It says plainly that the index is not a warning and not a ban. The
/// index is meteorological potential; whether a forest may be entered is
/// a Land's decision, and their warnings arrive through the BBK feed this
/// app already reads.
class FireDangerScreen extends StatefulWidget {
  const FireDangerScreen({
    super.key,
    this.client,
    this.store = const FireDangerStore(),
    this.now,
  });

  /// Injectable for tests; a real client otherwise.
  final FireDangerClient? client;
  final FireDangerStore store;

  /// Stands in for the clock when deciding whether a forecast is stale.
  final DateTime? now;

  @override
  State<FireDangerScreen> createState() => _FireDangerScreenState();
}

class _FireDangerScreenState extends State<FireDangerScreen> {
  late final FireDangerClient _client = widget.client ?? FireDangerClient();

  FireDangerStation? _station;
  FireDangerForecast? _forecast;
  var _loading = true;
  var _offline = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final station = await widget.store.loadStation();
    final kept = await widget.store.loadForecast();
    if (!mounted) return;
    setState(() {
      _station = station;
      _forecast = kept;
      _loading = station != null;
    });
    if (station != null) await _refresh();
  }

  Future<void> _refresh() async {
    final station = _station;
    if (station == null) return;
    setState(() => _loading = true);

    final fetched = await _client.fetchForecast(station);
    if (fetched != null) await widget.store.saveForecast(fetched);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _offline = fetched == null;
      _forecast = fetched ?? _forecast;
    });
  }

  Future<void> _choose() async {
    final picked = await Navigator.of(context).push<FireDangerStation>(
      MaterialPageRoute(builder: (_) => _StationPicker(client: _client)),
    );
    if (picked == null) return;
    await widget.store.saveStation(picked);
    if (!mounted) return;
    setState(() {
      _station = picked;
      _forecast = null;
      _offline = false;
    });
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fireDangerTitle),
        actions: [
          if (_station != null)
            IconButton(
              tooltip: l10n.fireDangerRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _refresh,
            ),
        ],
      ),
      body: _station == null ? _empty(l10n) : _chosen(l10n),
    );
  }

  Widget _empty(AppLocalizations l10n) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        l10n.fireDangerNoneChosen,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(l10n.fireDangerNoWarning),
      const SizedBox(height: 16),
      FilledButton(onPressed: _choose, child: Text(l10n.fireDangerChoose)),
      const SizedBox(height: 24),
      Text(l10n.fireDangerSource, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _chosen(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final station = _station!;
    final forecast = _forecast;

    // In columns on a wide window (#47): the reading beside what to do
    // next and where it comes from.
    return AdaptiveColumns(
      padding: const EdgeInsets.all(16),
      columnWidth: 480,
      spacing: 16,
      blocks: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(station.name, style: theme.textTheme.headlineSmall),
            if (station.state case final state?)
              Text(
                l10n.fireDangerState(state),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),
            if (_loading && forecast == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (forecast == null)
              Text(l10n.fireDangerLoadFailed)
            else
              ..._forecastCards(l10n, forecast),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              onPressed: _choose,
              child: Text(l10n.fireDangerChange),
            ),
            const SizedBox(height: 16),
            Text(l10n.fireDangerNoWarning, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(l10n.fireDangerSource, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  List<Widget> _forecastCards(
    AppLocalizations l10n,
    FireDangerForecast forecast,
  ) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMd(locale);
    final stale = forecast.isStale(now: widget.now);
    final peak = forecast.peakAhead;

    return [
      if (_offline)
        _Banner(text: l10n.fireDangerOffline, tone: theme.colorScheme.tertiary),
      if (stale)
        _Banner(
          text: l10n.fireDangerStale(date.format(forecast.issuedFor)),
          tone: theme.colorScheme.error,
        ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LevelChip(level: forecast.today),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _levelText(l10n, forecast.today),
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          l10n.fireDangerStep(forecast.today.step),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.fireDangerIssuedFor(date.format(forecast.issuedFor)),
                style: theme.textTheme.bodySmall,
              ),
              // The one thing a single number cannot say.
              if (peak != null) ...[
                const SizedBox(height: 8),
                Text(
                  peak.inDays == 1
                      ? l10n.fireDangerPeakTomorrow(peak.level.step)
                      : l10n.fireDangerPeak(peak.level.step, peak.inDays),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      if (forecast.days.length > 1) ...[
        const SizedBox(height: 16),
        Text(l10n.fireDangerAhead, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var day = 0; day < forecast.days.length; day++)
                ListTile(
                  dense: true,
                  leading: _LevelChip(level: forecast.days[day], small: true),
                  title: Text(_dayText(l10n, day)),
                  subtitle: Text(_levelText(l10n, forecast.days[day])),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  String _dayText(AppLocalizations l10n, int day) => switch (day) {
    0 => l10n.fireDangerToday,
    1 => l10n.fireDangerTomorrow,
    _ => l10n.fireDangerInDays(day),
  };

  String _levelText(AppLocalizations l10n, FireDangerLevel level) =>
      switch (level) {
        FireDangerLevel.veryLow => l10n.fireDangerLevel1,
        FireDangerLevel.low => l10n.fireDangerLevel2,
        FireDangerLevel.moderate => l10n.fireDangerLevel3,
        FireDangerLevel.high => l10n.fireDangerLevel4,
        FireDangerLevel.veryHigh => l10n.fireDangerLevel5,
      };
}

/// The step as a number in a circle.
///
/// The number as well as the colour, always: the DWD's own signs read
/// "Stufe 4", and red-green colour blindness is common enough that a
/// five-step scale cannot live in hue alone.
class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level, this.small = false});

  final FireDangerLevel level;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Two tones only, from the theme: the scheme's own error colour for
    // the two steps the DWD calls high and very high, and the ordinary
    // surface for the rest. Inventing a five-colour ramp here would put
    // this app's judgement on top of the DWD's numbers.
    final serious = level.step >= 4;

    return Container(
      width: small ? 28 : 44,
      height: small ? 28 : 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: serious ? colors.errorContainer : colors.surfaceContainerHighest,
      ),
      child: Text(
        '${level.step}',
        style:
            (small
                    ? Theme.of(context).textTheme.labelMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
                  color: serious ? colors.onErrorContainer : colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: tone),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

/// Search across the DWD's fire-danger stations.
class _StationPicker extends StatefulWidget {
  const _StationPicker({required this.client});

  final FireDangerClient client;

  @override
  State<_StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<_StationPicker> {
  late final TextEditingController _query = TextEditingController();
  var _stations = <FireDangerStation>[];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final fetched = await widget.client.fetchStations();
    if (!mounted) return;
    setState(() {
      // Copied before sorting: a failed fetch hands back a const empty
      // list, and sorting that throws.
      _stations = [...fetched]..sort((a, b) => a.name.compareTo(b.name));
      _loading = false;
    });
  }

  /// Matched on the place and on the Bundesland, because several stations
  /// share a place name and the state is what tells them apart.
  List<FireDangerStation> get _matches {
    final needle = _query.text.trim().toLowerCase();
    if (needle.isEmpty) return _stations;
    return [
      for (final station in _stations)
        if (station.name.toLowerCase().contains(needle) ||
            (station.state ?? '').toLowerCase().contains(needle))
          station,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matches = _matches;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fireDangerChoose)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.fireDangerSearchHint,
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_stations.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.fireDangerLoadFailed),
              ),
            )
          else if (matches.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.fireDangerSearchEmpty),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final station = matches[index];
                  return ListTile(
                    title: Text(station.name),
                    subtitle: station.state == null
                        ? null
                        : Text(station.state!),
                    onTap: () => Navigator.of(context).pop(station),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

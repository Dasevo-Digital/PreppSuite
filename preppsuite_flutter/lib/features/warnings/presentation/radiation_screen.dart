import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'hazard_release_screen.dart';
import 'iodine_tablets_screen.dart';
import '../application/radiation_client.dart';
import '../application/radiation_level.dart';
import '../application/radiation_store.dart';

/// The gamma dose rate at one probe, with what it means.
///
/// The context is the whole feature. A bare "0.16 µSv/h" tells nobody
/// anything, and a number with "radiation" written next to it frightens
/// people — so every band on this screen is the BfS's own, the ordinary
/// weather effect is named as the ordinary weather effect, and the screen
/// says outright that it is not a warning. If something were actually
/// happening, the warning would arrive through the BBK feed this app
/// already reads.
class RadiationScreen extends StatefulWidget {
  const RadiationScreen({
    super.key,
    this.client,
    this.store = const RadiationStore(),
    this.now,
  });

  /// Injectable for tests; a real client otherwise.
  final RadiationClient? client;
  final RadiationStore store;

  /// Stands in for the clock when deciding whether a reading is stale.
  final DateTime? now;

  @override
  State<RadiationScreen> createState() => _RadiationScreenState();
}

class _RadiationScreenState extends State<RadiationScreen> {
  late final RadiationClient _client = widget.client ?? RadiationClient();

  RadiationStation? _station;
  RadiationReading? _reading;
  var _loading = true;
  var _offline = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final station = await widget.store.loadStation();
    final kept = await widget.store.loadReading();
    if (!mounted) return;
    setState(() {
      _station = station;
      _reading = kept;
      _loading = station != null;
    });
    if (station != null) await _refresh();
  }

  Future<void> _refresh() async {
    final station = _station;
    if (station == null) return;
    setState(() => _loading = true);

    final fetched = await _client.fetchReading(station);
    if (fetched != null) await widget.store.saveReading(fetched);
    if (!mounted) return;
    setState(() {
      _loading = false;
      // A failed fetch keeps whatever was last read rather than blanking
      // the screen; the banner says which of the two is on show.
      _offline = fetched == null;
      _reading = fetched ?? _reading;
    });
  }

  Future<void> _choose() async {
    final picked = await Navigator.of(context).push<RadiationStation>(
      MaterialPageRoute(builder: (_) => _StationPicker(client: _client)),
    );
    if (picked == null) return;
    await widget.store.saveStation(picked);
    if (!mounted) return;
    setState(() {
      _station = picked;
      _reading = null;
      _offline = false;
    });
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.radiationTitle),
        actions: [
          if (_station != null)
            IconButton(
              tooltip: l10n.radiationRefresh,
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
        l10n.radiationNoneChosen,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(l10n.radiationNoWarning),
      const SizedBox(height: 16),
      FilledButton(onPressed: _choose, child: Text(l10n.radiationChoose)),
      const SizedBox(height: 24),
      Text(l10n.radiationSource, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _chosen(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final station = _station!;
    final reading = _reading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(station.name, style: theme.textTheme.headlineSmall),
        Text(
          [
            if (station.postalCode case final code? when code.isNotEmpty)
              l10n.radiationPostalCode(code),
            if (station.heightAboveSea case final metres?)
              l10n.radiationHeight('$metres'),
          ].join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_loading && reading == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (reading == null)
          Text(l10n.radiationLoadFailed)
        else
          ..._readingCards(l10n, reading),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _choose, child: Text(l10n.radiationChange)),
        const SizedBox(height: 16),
        // Below the measurement and above the disclaimer, because this
        // screen deliberately never says what to do -- and somebody who
        // just read "ueber dem, was Wetter erklaert" is owed somewhere to
        // go with that.
        Card(
          child: ListTile(
            leading: const Icon(Icons.masks_outlined),
            title: Text(l10n.hazardReleaseTitle),
            subtitle: Text(l10n.hazardReleaseEntryHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const HazardReleaseScreen(),
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.medication_outlined),
            title: Text(l10n.iodineTitle),
            subtitle: Text(l10n.iodineEntryHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const IodineTabletsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.radiationNoWarning, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(l10n.radiationSource, style: theme.textTheme.bodySmall),
      ],
    );
  }

  List<Widget> _readingCards(AppLocalizations l10n, RadiationReading reading) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final stale = reading.isStale(now: widget.now);
    final number = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 3,
    );

    return [
      if (_offline)
        _Banner(text: l10n.radiationOffline, tone: theme.colorScheme.tertiary),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read out as a unit rather than left to a screen reader to
              // spell "µSv/h" letter by letter.
              Semantics(
                value:
                    '${number.format(reading.microsievertsPerHour)} '
                    'Mikrosievert pro Stunde',
                child: Text(
                  '${number.format(reading.microsievertsPerHour)} µSv/h',
                  style: theme.textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _bandText(l10n, reading.band),
                style: theme.textTheme.titleMedium,
              ),
              if (reading.baseline case final baseline?) ...[
                const SizedBox(height: 4),
                Text(l10n.radiationBaseline(number.format(baseline))),
              ],
              if (reading.terrestrial case final ground?)
                if (reading.cosmic case final sky?) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.radiationSplit(
                      number.format(ground),
                      number.format(sky),
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              const SizedBox(height: 8),
              Text(
                l10n.radiationMeasuredAt(
                  DateFormat.yMd(
                    locale,
                  ).add_Hm().format(reading.measuredAt.toLocal()),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      if (stale)
        _Banner(text: l10n.radiationStale, tone: theme.colorScheme.error),
      if (!reading.validated)
        _Banner(
          text: l10n.radiationUnvalidated,
          tone: theme.colorScheme.tertiary,
        ),
      // The explanation belongs with the band and not in a help screen:
      // this is the moment somebody wants to know whether a raised
      // number means anything.
      if (reading.band == RadiationBand.weather) ...[
        const SizedBox(height: 8),
        Text(
          l10n.radiationWeatherExplained,
          style: theme.textTheme.bodySmall,
        ),
      ],
      if (reading.band == RadiationBand.unusual) ...[
        const SizedBox(height: 8),
        Text(
          l10n.radiationUnusualExplained,
          style: theme.textTheme.bodySmall,
        ),
      ],
      if (reading.baseline == null) ...[
        const SizedBox(height: 8),
        Text(
          l10n.radiationNoBaseline(
            number.format(naturalFloor),
            number.format(naturalCeiling),
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
    ];
  }

  String _bandText(AppLocalizations l10n, RadiationBand band) => switch (band) {
    RadiationBand.ordinary => l10n.radiationBandOrdinary,
    RadiationBand.weather => l10n.radiationBandWeather,
    RadiationBand.unusual => l10n.radiationBandUnusual,
    RadiationBand.unknown => l10n.radiationBandUnknown,
  };
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

/// Search across every probe in the network.
class _StationPicker extends StatefulWidget {
  const _StationPicker({required this.client});

  final RadiationClient client;

  @override
  State<_StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<_StationPicker> {
  late final TextEditingController _query = TextEditingController();
  var _stations = <RadiationStation>[];
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

  /// Matched on the place and on the postal code, because both are what
  /// somebody looking for their own probe types.
  List<RadiationStation> get _matches {
    final needle = _query.text.trim().toLowerCase();
    if (needle.isEmpty) return _stations;
    return [
      for (final station in _stations)
        if (station.name.toLowerCase().contains(needle) ||
            (station.postalCode ?? '').startsWith(needle))
          station,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matches = _matches;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.radiationChoose)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.radiationSearchHint,
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_stations.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.radiationLoadFailed),
              ),
            )
          else if (matches.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.radiationSearchEmpty),
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
                    subtitle: station.postalCode == null
                        ? null
                        : Text(
                            l10n.radiationPostalCode(station.postalCode!),
                          ),
                    trailing: station.heightAboveSea == null
                        ? null
                        : Text(
                            l10n.radiationHeight(
                              '${station.heightAboveSea}',
                            ),
                          ),
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

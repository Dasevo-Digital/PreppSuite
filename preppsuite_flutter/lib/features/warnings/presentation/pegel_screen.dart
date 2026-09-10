import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/pegel_client.dart';
import '../application/pegel_level.dart';
import '../application/pegel_store.dart';

/// The water level at one gauge, with what it means.
///
/// Chosen by the household rather than found by the app. For flooding the
/// useful gauge is the one *upstream*, and the nearest one can easily be
/// downstream -- where it reports what has already gone past. A wrong
/// gauge here reads exactly like a right one, which is the sort of
/// mistake worth refusing to make on somebody's behalf.
class PegelScreen extends StatefulWidget {
  const PegelScreen({
    super.key,
    this.client,
    this.store = const PegelStore(),
    this.now,
  });

  /// Injectable for tests; a real client otherwise.
  final PegelClient? client;
  final PegelStore store;

  /// Stands in for the clock when deciding whether a reading is stale.
  final DateTime? now;

  @override
  State<PegelScreen> createState() => _PegelScreenState();
}

class _PegelScreenState extends State<PegelScreen> {
  late final PegelClient _client = widget.client ?? PegelClient();

  PegelStation? _station;
  PegelReading? _reading;
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
    final picked = await Navigator.of(context).push<PegelStation>(
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
        title: Text(l10n.pegelTitle),
        actions: [
          if (_station != null)
            IconButton(
              tooltip: l10n.pegelRefresh,
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
        l10n.pegelNoneChosen,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(l10n.pegelUpstreamHint),
      const SizedBox(height: 16),
      FilledButton(onPressed: _choose, child: Text(l10n.pegelChoose)),
      const SizedBox(height: 24),
      Text(l10n.pegelSource, style: Theme.of(context).textTheme.bodySmall),
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
          station.water,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (station.kilometre != null)
          Text(
            l10n.pegelKilometre('${station.kilometre}'),
            style: theme.textTheme.bodySmall,
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
          Text(l10n.pegelLoadFailed)
        else
          ..._readingCards(l10n, reading),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _choose, child: Text(l10n.pegelChange)),
        const SizedBox(height: 16),
        Text(l10n.pegelNoMeldestufe, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(l10n.pegelSource, style: theme.textTheme.bodySmall),
      ],
    );
  }

  List<Widget> _readingCards(AppLocalizations l10n, PegelReading reading) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final stale = reading.isStale(now: widget.now);

    return [
      if (_offline)
        _Banner(text: l10n.pegelOffline, tone: theme.colorScheme.tertiary),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The value read out loud as well, because "66 cm" spelled
              // out letter by letter is not what a screen reader should
              // make of the one number on this screen.
              Semantics(
                value: '${reading.centimetres.round()} cm',
                child: Text(
                  '${reading.centimetres.round()} cm',
                  style: theme.textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _bandText(l10n, reading.band),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(_trendText(l10n, reading)),
              const SizedBox(height: 8),
              Text(
                l10n.pegelMeasuredAt(
                  DateFormat.yMd(locale).add_Hm().format(reading.measuredAt),
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      if (stale) _Banner(text: l10n.pegelStale, tone: theme.colorScheme.error),
      const SizedBox(height: 16),
      if (reading.references.isEmpty)
        Text(l10n.pegelNoReferences)
      else ...[
        Text(l10n.pegelReferences, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final reference in PegelReference.values)
                if (reading.reference(reference) case final level?)
                  ListTile(
                    dense: true,
                    title: Text(_referenceText(l10n, reference)),
                    trailing: Text('${level.round()} cm'),
                  ),
            ],
          ),
        ),
      ],
    ];
  }

  String _bandText(AppLocalizations l10n, PegelBand band) => switch (band) {
    PegelBand.recordLow => l10n.pegelBandRecordLow,
    PegelBand.low => l10n.pegelBandLow,
    PegelBand.ordinary => l10n.pegelBandOrdinary,
    PegelBand.elevated => l10n.pegelBandElevated,
    PegelBand.flood => l10n.pegelBandFlood,
    PegelBand.recordHigh => l10n.pegelBandRecordHigh,
    PegelBand.unknown => l10n.pegelBandUnknown,
  };

  String _trendText(AppLocalizations l10n, PegelReading reading) {
    final change = reading.changeOverDay;
    return switch (reading.trend) {
      PegelTrend.rising => l10n.pegelTrendRising('${change!.round()}'),
      PegelTrend.falling => l10n.pegelTrendFalling('${change!.round().abs()}'),
      PegelTrend.steady => l10n.pegelTrendSteady,
      PegelTrend.unknown => l10n.pegelTrendUnknown,
    };
  }

  String _referenceText(AppLocalizations l10n, PegelReference reference) =>
      switch (reference) {
        PegelReference.mean => l10n.pegelRefMean,
        PegelReference.meanFlood => l10n.pegelRefMeanFlood,
        PegelReference.highest => l10n.pegelRefHighest,
        PegelReference.meanLow => l10n.pegelRefMeanLow,
        PegelReference.lowest => l10n.pegelRefLowest,
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

/// Search across every gauge on the federal waterways.
class _StationPicker extends StatefulWidget {
  const _StationPicker({required this.client});

  final PegelClient client;

  @override
  State<_StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<_StationPicker> {
  late final TextEditingController _query = TextEditingController();
  var _stations = <PegelStation>[];
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
      // list, and sorting that throws "Cannot modify an unmodifiable
      // list" -- which is to say the picker crashed for anybody offline.
      _stations = [...fetched]
        ..sort((a, b) {
          final water = a.water.compareTo(b.water);
          return water != 0 ? water : a.name.compareTo(b.name);
        });
      _loading = false;
    });
  }

  List<PegelStation> get _matches {
    final needle = _query.text.trim().toLowerCase();
    if (needle.isEmpty) return _stations;
    return [
      for (final station in _stations)
        if (station.name.toLowerCase().contains(needle) ||
            station.water.toLowerCase().contains(needle))
          station,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matches = _matches;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pegelChoose)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.pegelSearchHint,
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_stations.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.pegelLoadFailed),
              ),
            )
          else if (matches.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.pegelSearchEmpty),
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
                    subtitle: Text(station.water),
                    trailing: station.kilometre == null
                        ? null
                        : Text(l10n.pegelKilometre('${station.kilometre}')),
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

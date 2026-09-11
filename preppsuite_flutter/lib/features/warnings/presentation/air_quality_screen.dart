import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/air_quality_client.dart';
import '../application/air_quality_level.dart';
import '../application/air_quality_store.dart';

/// The air quality index at one station, in the Umweltbundesamt's words.
///
/// The class, the five names and the thresholds behind them are all the
/// UBA's; the app computes none of them. What it adds is which pollutant
/// the class came from, because "moderate" means something different when
/// it is ozone on a summer afternoon than when it is particulates from a
/// fire.
///
/// The UBA's per-class behaviour advice is deliberately not reproduced
/// here: it is published only as images, and paraphrasing somebody else's
/// health advice is what the rule against invented scales exists to
/// prevent. The screen points at the source instead.
class AirQualityScreen extends StatefulWidget {
  const AirQualityScreen({
    super.key,
    this.client,
    this.store = const AirQualityStore(),
    this.now,
  });

  /// Injectable for tests; a real client otherwise.
  final AirQualityClient? client;
  final AirQualityStore store;

  /// Stands in for the clock when deciding whether a reading is stale.
  final DateTime? now;

  @override
  State<AirQualityScreen> createState() => _AirQualityScreenState();
}

class _AirQualityScreenState extends State<AirQualityScreen> {
  late final AirQualityClient _client = widget.client ?? AirQualityClient();

  AirQualityStation? _station;
  AirQualityReading? _reading;
  Map<int, List<AirQualityThreshold>> _thresholds = const {};
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

    AirQualityReading? fetched;
    try {
      fetched = await _client.fetchReading(station.id);
      // Only worth having beside a reading, and cheap to skip when the
      // first call already failed.
      if (_thresholds.isEmpty) _thresholds = await _client.fetchThresholds();
    } on Object {
      fetched = null;
    }

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
    final picked = await Navigator.of(context).push<AirQualityStation>(
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
        title: Text(l10n.airQualityTitle),
        actions: [
          if (_station != null)
            IconButton(
              tooltip: l10n.airQualityRefresh,
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
        l10n.airQualityNoneChosen,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(l10n.airQualityNoWarning),
      const SizedBox(height: 16),
      FilledButton(onPressed: _choose, child: Text(l10n.airQualityChoose)),
      const SizedBox(height: 24),
      Text(
        l10n.airQualitySource,
        style: Theme.of(context).textTheme.bodySmall,
      ),
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
            ?station.city,
            ?station.state,
            ?station.setting,
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
          Text(l10n.airQualityLoadFailed)
        else
          ..._readingCards(l10n, reading),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _choose, child: Text(l10n.airQualityChange)),
        const SizedBox(height: 16),
        Text(l10n.airQualityNoWarning, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(l10n.airQualityAdvice, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(l10n.airQualitySource, style: theme.textTheme.bodySmall),
      ],
    );
  }

  List<Widget> _readingCards(
    AppLocalizations l10n,
    AirQualityReading reading,
  ) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final stale = reading.isStaleAt(widget.now ?? DateTime.now());
    final number = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 0,
    );
    final leading = reading.leading;

    return [
      if (_offline)
        _Banner(text: l10n.airQualityOffline, tone: theme.colorScheme.tertiary),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _levelText(l10n, reading.level),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              _Scale(level: reading.level),
              if (leading != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.airQualityLeading(
                    leading.code,
                    number.format(leading.value),
                    leading.unit,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.airQualityMeasuredAt(
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
        _Banner(text: l10n.airQualityStale, tone: theme.colorScheme.error),
      if (reading.incomplete)
        _Banner(
          text: l10n.airQualityIncomplete,
          tone: theme.colorScheme.tertiary,
        ),
      if (reading.components.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(l10n.airQualityComponents, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final component in reading.components)
          _ComponentRow(
            component: component,
            label: _levelText(l10n, component.level),
            value: '${number.format(component.value)} ${component.unit}',
            span: _spanFor(component, number, l10n),
          ),
      ],
    ];
  }

  /// The class boundary this pollutant is measured against, in the UBA's
  /// own numbers — null where the thresholds have not been fetched.
  String? _spanFor(
    AirQualityComponent component,
    NumberFormat number,
    AppLocalizations l10n,
  ) {
    final spans = _thresholds[component.id];
    if (spans == null) return null;
    for (final span in spans) {
      if (span.level == component.level) {
        return l10n.airQualitySpan(
          number.format(span.min),
          number.format(span.max),
        );
      }
    }
    return null;
  }

  String _levelText(AppLocalizations l10n, AirQualityClass level) =>
      switch (level) {
        AirQualityClass.veryGood => l10n.airQualityVeryGood,
        AirQualityClass.good => l10n.airQualityGood,
        AirQualityClass.moderate => l10n.airQualityModerate,
        AirQualityClass.poor => l10n.airQualityPoor,
        AirQualityClass.veryPoor => l10n.airQualityVeryPoor,
        AirQualityClass.unknown => l10n.airQualityUnknown,
      };
}

/// Where the reading sits on the five-step scale.
///
/// Colour is not the only carrier: the class is written out above this,
/// and the filled step is the one named — so the bar adds a glance, not
/// the only way to read the screen.
class _Scale extends StatelessWidget {
  const _Scale({required this.level});

  final AirQualityClass level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = level.step;

    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: step == null
                    ? theme.colorScheme.surfaceContainerHighest
                    : i <= step
                    ? _colour(theme, i)
                    : theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          if (i < 4) const SizedBox(width: 4),
        ],
      ],
    );
  }

  /// Only the two worst steps take a warning colour. The first three are
  /// ordinary air, and painting them in traffic-light green would invite
  /// reading "gut" as an all-clear about something the index does not
  /// claim.
  Color _colour(ThemeData theme, int step) => switch (step) {
    3 => theme.colorScheme.tertiary,
    4 => theme.colorScheme.error,
    _ => theme.colorScheme.primary,
  };
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({
    required this.component,
    required this.label,
    required this.value,
    this.span,
  });

  final AirQualityComponent component;
  final String label;
  final String value;
  final String? span;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(component.code, style: theme.textTheme.titleSmall),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value),
                Text(
                  span == null ? label : '$label · $span',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
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

/// Search across every station in the network.
class _StationPicker extends StatefulWidget {
  const _StationPicker({required this.client});

  final AirQualityClient client;

  @override
  State<_StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<_StationPicker> {
  late final TextEditingController _query = TextEditingController();
  var _stations = <AirQualityStation>[];
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
    List<AirQualityStation> fetched;
    try {
      fetched = await widget.client.fetchStations();
    } on Object {
      fetched = const [];
    }
    if (!mounted) return;
    setState(() {
      _stations = fetched;
      _loading = false;
    });
  }

  /// Matched on the station's name, on the town it stands in and on the
  /// state — all three are what somebody types looking for their own.
  List<AirQualityStation> get _matches {
    final needle = _query.text.trim().toLowerCase();
    if (needle.isEmpty) return _stations;
    return [
      for (final station in _stations)
        if (station.name.toLowerCase().contains(needle) ||
            (station.city ?? '').toLowerCase().contains(needle) ||
            (station.state ?? '').toLowerCase().contains(needle))
          station,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final matches = _matches;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.airQualityChoose)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: l10n.airQualitySearchHint,
              ),
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_stations.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.airQualityLoadFailed),
              ),
            )
          else if (matches.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.airQualitySearchEmpty),
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
                    subtitle: Text(
                      [?station.city, ?station.state].join(' · '),
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

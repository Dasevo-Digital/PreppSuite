import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error_text.dart';
import '../../../core/geolocation_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../household/application/german_states.dart';
import '../../household/application/household_providers.dart';
import '../../inventory/application/inventory_providers.dart';
import '../application/heavy_rain_hazard.dart';
import '../application/river_flood.dart';

/// Water after a cloudburst, at one address (#115).
///
/// Asked once with a network and kept: the day this matters is a day the
/// network may not be there. What it shows is the BKG's legend and
/// nothing beyond it -- the depth class, the flow class, what the map
/// leaves out -- and one fact of the household's own: how many supplies
/// it keeps in the cellar.
class HeavyRainScreen extends ConsumerStatefulWidget {
  const HeavyRainScreen({
    super.key,
    this.client,
    this.riverClient,
    this.geolocation,
    this.store = const HeavyRainStore(),
  });

  /// Injectable for tests.
  final HeavyRainClient? client;
  final RiverFloodClient? riverClient;
  final GeolocationService? geolocation;
  final HeavyRainStore store;

  @override
  ConsumerState<HeavyRainScreen> createState() => _HeavyRainScreenState();
}

class _HeavyRainScreenState extends ConsumerState<HeavyRainScreen> {
  late final HeavyRainClient _client = widget.client ?? HeavyRainClient();
  late final RiverFloodClient _river = widget.riverClient ?? RiverFloodClient();
  late final GeolocationService _geolocation =
      widget.geolocation ?? GeolocationService();

  HeavyRainHazard? _hazard;
  var _restoring = true;
  var _busy = false;
  var _offline = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    if (widget.geolocation == null) _geolocation.close();
    super.dispose();
  }

  Future<void> _restore() async {
    final kept = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _hazard = kept;
      _restoring = false;
    });
  }

  Future<void> _useLocation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final position = await _geolocation.getCurrentLatLng();
      await _check(position.latitude, position.longitude, null);
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
        title: Text(l10n.heavyRainSearchAddress),
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
      await _check(found.latitude, found.longitude, query.trim());
    } on Object catch (error) {
      _say(describeError(l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    final hazard = _hazard;
    if (hazard == null) return;
    setState(() => _busy = true);
    try {
      await _check(hazard.latitude, hazard.longitude, hazard.placeName);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check(double latitude, double longitude, String? name) async {
    final l10n = AppLocalizations.of(context)!;
    // The state first: two of them have no layer, and a neighbour's layer
    // answers "dry" well past its border. A lookup that fails is not a
    // reason to stop -- the samples still say what they say.
    GermanState? state;
    try {
      state = await _geolocation.stateAt(latitude, longitude);
    } on Object {
      state = null;
    }
    final stateName = state?.nameDe;
    final stateCode = state?.bbkCode;

    final covered =
        stateCode == null ||
        !HeavyRainClient.uncoveredStates.contains(stateCode);
    Map<HeavyRainScenario, HeavyRainScenarioResult> results = const {};
    if (covered) {
      try {
        results = await _client.check(latitude, longitude);
      } on Object {
        if (!mounted) return;
        setState(() => _offline = true);
        _say(l10n.heavyRainFailed);
        return;
      }
    }

    // The river map is a second source, not a condition: one that does
    // not answer costs its own card, not the heavy rain one (#124).
    RiverFloodResult? river;
    try {
      river = await _river.check(latitude, longitude, stateCode: stateCode);
    } on Object {
      river = null;
      _say(l10n.riverFloodFailed);
    }

    final hazard = HeavyRainHazard(
      latitude: latitude,
      longitude: longitude,
      placeName: name,
      stateName: stateName,
      checkedAt: DateTime.now(),
      covered: covered,
      results: results,
      river: river,
    );
    await widget.store.save(hazard);
    if (!mounted) return;
    setState(() {
      _hazard = hazard;
      _offline = false;
    });
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
    final hazard = _hazard;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.heavyRainTitle),
        actions: [
          if (hazard != null)
            IconButton(
              tooltip: l10n.heavyRainRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: _busy ? null : _refresh,
            ),
        ],
      ),
      body: _restoring
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (hazard == null)
                  ..._empty(l10n)
                else
                  ..._result(l10n, hazard),
              ],
            ),
    );
  }

  List<Widget> _choices(AppLocalizations l10n) => [
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : _useLocation,
          icon: const Icon(Icons.my_location),
          label: Text(l10n.heavyRainUseLocation),
        ),
        OutlinedButton.icon(
          onPressed: _busy ? null : _enterAddress,
          icon: const Icon(Icons.search),
          label: Text(l10n.heavyRainSearchAddress),
        ),
      ],
    ),
  ];

  List<Widget> _empty(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return [
      Text(l10n.heavyRainIntro),
      const SizedBox(height: 16),
      ..._choices(l10n),
      const SizedBox(height: 16),
      Text(l10n.heavyRainPrivacy, style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      Text(
        l10n.heavyRainSource('${DateTime.now().year}'),
        style: theme.textTheme.bodySmall,
      ),
    ];
  }

  List<Widget> _result(AppLocalizations l10n, HeavyRainHazard hazard) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale).format(hazard.checkedAt.toLocal());
    final place =
        hazard.placeName ??
        '${l10n.heavyRainHerePlace} '
            '(${hazard.latitude.toStringAsFixed(4)}, '
            '${hazard.longitude.toStringAsFixed(4)})';
    final cellar = _cellarCount();

    return [
      Text(
        l10n.heavyRainCheckedAt(place, date),
        style: theme.textTheme.titleMedium,
      ),
      if (_offline) ...[
        const SizedBox(height: 8),
        Text(l10n.heavyRainOffline, style: theme.textTheme.bodySmall),
      ],
      const SizedBox(height: 12),
      if (!hazard.covered)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.heavyRainUncovered(hazard.stateName ?? '')),
          ),
        )
      else
        for (final scenario in HeavyRainScenario.values)
          _ScenarioCard(
            l10n: l10n,
            scenario: scenario,
            result: hazard.results[scenario] ?? const HeavyRainScenarioResult(),
          ),
      if (hazard.river case final river?) ...[
        const SizedBox(height: 4),
        _RiverCard(
          l10n: l10n,
          river: river,
          stateName: hazard.stateName,
        ),
      ],
      if (hazard.anyWater && cellar > 0) ...[
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(l10n.heavyRainCellar(cellar)),
          ),
        ),
      ],
      const SizedBox(height: 12),
      Text(l10n.heavyRainLimits, style: theme.textTheme.bodySmall),
      const SizedBox(height: 16),
      ..._choices(l10n),
      const SizedBox(height: 16),
      Text(l10n.heavyRainPrivacy, style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
      Text(
        l10n.heavyRainSource('${hazard.checkedAt.year}'),
        style: theme.textTheme.bodySmall,
      ),
    ];
  }

  /// Supplies whose storage place names a cellar, in any of the app's
  /// languages. The storage place is free text, so this is a word match
  /// and nothing more.
  int _cellarCount() {
    final profile = ref.watch(householdProfileProvider).value;
    if (profile == null) return 0;
    final items = ref.watch(inventoryItemsProvider(profile.id)).value;
    if (items == null) return 0;
    return items.where((item) => isCellar(item.storageLocation)).length;
  }
}

/// Whether a storage place is a cellar.
bool isCellar(String storageLocation) {
  final place = storageLocation.toLowerCase();
  return const [
    'keller',
    'untergeschoss',
    'souterrain',
    'cellar',
    'basement',
    'sótano',
    'sotano',
  ].any(place.contains);
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.l10n,
    required this.scenario,
    required this.result,
  });

  final AppLocalizations l10n;
  final HeavyRainScenario scenario;
  final HeavyRainScenarioResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final depthClass = result.depthClass;
    final velocityClass = result.velocityClass;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              switch (scenario) {
                HeavyRainScenario.exceptional =>
                  l10n.heavyRainScenarioExceptional,
                HeavyRainScenario.extreme => l10n.heavyRainScenarioExtreme,
              },
              style: theme.textTheme.titleMedium,
            ),
            Text(
              switch (scenario) {
                HeavyRainScenario.exceptional =>
                  l10n.heavyRainScenarioExceptionalBody,
                HeavyRainScenario.extreme => l10n.heavyRainScenarioExtremeBody,
              },
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (depthClass == null)
              Text(l10n.heavyRainNoValue)
            else ...[
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: depthClassColour(depthClass),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.heavyRainDepth(
                        hazardRadiusMetres.round(),
                        depthClassLabel(l10n, depthClass),
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              if (velocityClass != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.heavyRainFlow(
                    velocityClassLabel(l10n, velocityClass),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

String depthClassLabel(AppLocalizations l10n, int depthClass) =>
    switch (depthClass) {
      0 => l10n.heavyRainDepthClass0,
      1 => l10n.heavyRainDepthClass1,
      2 => l10n.heavyRainDepthClass2,
      3 => l10n.heavyRainDepthClass3,
      4 => l10n.heavyRainDepthClass4,
      5 => l10n.heavyRainDepthClass5,
      _ => l10n.heavyRainDepthClass6,
    };

String velocityClassLabel(AppLocalizations l10n, int velocityClass) =>
    switch (velocityClass) {
      0 => l10n.heavyRainVelocityClass0,
      1 => l10n.heavyRainVelocityClass1,
      2 => l10n.heavyRainVelocityClass2,
      3 => l10n.heavyRainVelocityClass3,
      _ => l10n.heavyRainVelocityClass4,
    };

/// The legend's own blues, light to dark, read off the service's
/// `GetLegendGraphic`. Below the first class the legend draws nothing,
/// and neither does this.
Color depthClassColour(int depthClass) => switch (depthClass) {
  0 => Colors.transparent,
  1 => const Color(0xFFCCECFF),
  2 => const Color(0xFF99CCFF),
  3 => const Color(0xFF6E99FF),
  4 => const Color(0xFF3D66FF),
  5 => const Color(0xFF0033CC),
  _ => const Color(0xFF08306B),
};

/// The Land's river flood map for the place (#124): three floods, each in
/// the LAWA's five depth classes, or a sentence saying the Land is not
/// in yet.
class _RiverCard extends StatelessWidget {
  const _RiverCard({
    required this.l10n,
    required this.river,
    required this.stateName,
  });

  final AppLocalizations l10n;
  final RiverFloodResult river;
  final String? stateName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.riverFloodTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!river.covered)
              Text(l10n.riverFloodUncovered(stateName ?? ''))
            else ...[
              for (final scenario in RiverFloodScenario.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: riverClassColour(river.classes[scenario] ?? 0),
                          // A scenario without a map shows no colour.
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${switch (scenario) {
                            RiverFloodScenario.frequent => l10n.riverFloodFrequent,
                            RiverFloodScenario.hundred => l10n.riverFloodHundred,
                            RiverFloodScenario.extreme => l10n.riverFloodExtreme,
                          }}: ${switch (river.classes[scenario]) {
                            // Not dry: nobody has mapped it here (#148).
                            null => l10n.riverFloodNoMap,
                            final depth => riverClassLabel(l10n, depth),
                          }}',
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(l10n.riverFloodLimits, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(switch (river.stateCode) {
                // Checked first: a Land's own service that did not answer
                // was replaced by the national map.
                _ when river.national => l10n.riverFloodSourceNational,
                'BY' => l10n.riverFloodSourceBY,
                'NW' => l10n.riverFloodSourceNW,
                _ => l10n.riverFloodSource,
              }, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

String riverClassLabel(AppLocalizations l10n, int depthClass) =>
    switch (depthClass) {
      1 => l10n.riverFloodClass1,
      2 => l10n.riverFloodClass2,
      3 => l10n.riverFloodClass3,
      4 => l10n.riverFloodClass4,
      5 => l10n.riverFloodClass5,
      floodDepthUnknown => l10n.riverFloodClassUnknown,
      _ => l10n.riverFloodDry,
    };

/// The NLWKN legend's blues, read off its own legend swatches.
Color riverClassColour(int depthClass) => switch (depthClass) {
  1 => const Color(0xFFCCECFF),
  2 => const Color(0xFF98CCFF),
  3 => const Color(0xFF6798FF),
  4 => const Color(0xFF3D67FF),
  5 => const Color(0xFF0033CC),
  // Water, depth not given: the lightest blue, hatched would be better.
  floodDepthUnknown => const Color(0xFFB3D9F2),
  _ => Colors.transparent,
};

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../../model/household_profile.dart';
import '../../energy/application/energy_store.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../maps/application/offline_poi_search.dart';
import '../../maps/presentation/base_map_layer.dart';
import '../../maps/presentation/nearby_screen.dart';
import '../../preparedness/application/autonomy_overview.dart';
import '../../preparedness/application/preparedness_hub_store.dart';
import '../../inventory/application/supply_calculator.dart';
import '../application/drinking_water_warning.dart';
import '../application/warning_polygon_codec.dart';
import '../application/warning_providers.dart';
import '../application/warning_relevance.dart';
import '../application/warning_severity_l10n.dart';

/// All active CAP areas in one place.
///
/// The individual warning page remains the place for complete offline text.
/// This view answers the preceding question: what is active around the areas
/// a household follows, and which polygons overlap each other?
class WarningSituationMapScreen extends ConsumerStatefulWidget {
  const WarningSituationMapScreen({super.key, required this.profile});

  final HouseholdProfile profile;

  @override
  ConsumerState<WarningSituationMapScreen> createState() =>
      _WarningSituationMapScreenState();
}

class _WarningSituationMapScreenState
    extends ConsumerState<WarningSituationMapScreen> {
  final _controller = MapController();
  static const _hubStore = PreparednessHubStore();

  /// Only for the hand-entered fallback: a household whose water is in
  /// crates rather than litres has typed its own figure, and a drinking
  /// water warning is exactly when that figure matters.
  var _entered = const AutonomySnapshot();

  @override
  void initState() {
    super.initState();
    unawaited(
      _hubStore.load().then((data) {
        if (mounted) setState(() => _entered = data.autonomy);
      }),
    );
  }

  /// How long the household's own drinking water lasts.
  ///
  /// Worked out in `build` and carried into the tap handler: the
  /// inventory is a stream, and asking it for the first time at the
  /// moment somebody taps would answer "still loading" — which on this
  /// card would read as "you have no water".
  AutonomyReach _waterReach(List<InventoryItem> items) {
    return autonomyReaches(
      items: items,
      household: SupplyHousehold(
        adults: widget.profile.personCount,
        children: widget.profile.children,
        dogs: widget.profile.dogs,
        cats: widget.profile.cats,
      ),
      energy: const EnergyPlan(),
      entered: _entered,
    ).firstWhere((reach) => reach.resource == AutonomyResource.water);
  }

  // Decoding the areas is the expensive part of drawing this screen, and
  // nothing about it changes when a filter chip is tapped.
  final _polygons = WarningPolygonCache();
  // The nationwide BBK feed is the input; the warning map is about the
  // household's situation. Keep unrelated state and district polygons out
  // until someone explicitly asks to inspect the national picture.
  var _onlyMyRegions = true;
  var _onlySevere = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final warnings = ref.watch(activeWarningsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.warningSituationMapTitle)),
      body: warnings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.warningSituationMapFailed)),
        data: (all) => _body(context, l10n, all),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    List<Warning> all,
  ) {
    _polygons.retain(all);
    final water = _waterReach(
      ref.watch(inventoryItemsProvider(widget.profile.id)).value ?? const [],
    );
    final selected = [
      for (final warning in all)
        if (warning.countryCode == widget.profile.countryCode)
          if (!_onlyMyRegions ||
              isWarningRelevant(
                warning: warning,
                filter: widget.profile.warningFilter,
              ))
            if (!_onlySevere ||
                warningSeverityRank(
                      warningSeverityFromName(warning.severity),
                    ) >=
                    warningSeverityRank(WarningSeverity.severe))
              (warning: warning, polygons: _polygons.of(warning)),
    ];
    final onMap = [
      for (final item in selected)
        if (item.polygons.isNotEmpty) item,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                selected: _onlyMyRegions,
                label: Text(l10n.warningFilterMyRegions),
                onSelected: (value) => setState(() => _onlyMyRegions = value),
              ),
              FilterChip(
                selected: _onlySevere,
                label: Text(l10n.warningFilterSevere),
                onSelected: (value) => setState(() => _onlySevere = value),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            l10n.warningSituationMapTapHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          flex: 3,
          child: onMap.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      selected.isEmpty
                          ? l10n.warningSituationMapEmpty
                          : l10n.warningSituationMapNoGeometry,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _Map(
                  controller: _controller,
                  entries: onMap,
                  l10n: l10n,
                  onTap: (point) => _showAt(onMap, point, l10n, water),
                ),
        ),
        SizedBox(
          height: 184,
          child: _WarningSummary(entries: selected, l10n: l10n),
        ),
      ],
    );
  }

  /// What applies at one spot.
  ///
  /// The list below the map answers "what is active in my area"; this
  /// answers the question somebody actually has in front of a map with
  /// three overlapping outlines on it — which of them covers the street
  /// I am standing in, and what does it tell me to do. The instruction
  /// comes first for that reason; the headline alone is not an answer.
  Future<void> _showAt(
    List<({Warning warning, List<List<LatLng>> polygons})> entries,
    LatLng point,
    AppLocalizations l10n,
    AutonomyReach waterReach,
  ) {
    final here = [
      for (final entry in entries)
        if (polygonsCover(entry.polygons, point)) entry.warning,
    ];
    final water = drinkingWaterWarnings(here).isEmpty ? null : waterReach;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: here.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Text(
                  l10n.warningSituationMapNothingHere,
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Text(
                    l10n.warningSituationMapAtPoint,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // First, because it is the one thing on this sheet the
                  // warning itself cannot tell somebody: how long their
                  // own water lasts.
                  if (water != null)
                    _DrinkingWater(reach: water, point: point, l10n: l10n),
                  for (final warning in here)
                    _WarningAtPoint(warning: warning, l10n: l10n),
                ],
              ),
      ),
    );
  }
}

/// What a drinking-water warning cannot say, and this app can.
///
/// The warning names the area and what to do; only the household's own
/// records know how long its stored water lasts, and only the downloaded
/// map knows where there is more. What this deliberately does **not** do
/// is say anything about treating the water: boiling times were looked
/// up for this app and rejected, because the CDC, the WHO and the UBA
/// give three different ones and picking one would be inventing a figure.
/// The authority's own instruction is on the card below this.
class _DrinkingWater extends StatelessWidget {
  const _DrinkingWater({
    required this.reach,
    required this.point,
    required this.l10n,
  });

  final AutonomyReach reach;
  final LatLng point;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.mapWaterTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              switch (reach.days) {
                final days? => l10n.mapWaterStock(l10n.hubAutonomyDays(days)),
                _ => l10n.mapWaterStockUnknown(l10n.hubAutonomyOpen),
              },
              style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.mapWaterAdviceNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NearbyScreen(
                      centre: point,
                      kinds: const {PoiKind.water},
                    ),
                  ),
                ),
                icon: const Icon(Icons.travel_explore),
                label: Text(l10n.mapWaterNearby),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningAtPoint extends StatelessWidget {
  const _WarningAtPoint({required this.warning, required this.l10n});

  final Warning warning;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final severity = warningSeverityFromName(warning.severity);
    final colors = warningSeverityColors(context, severity);
    final guidance = warning.instruction?.trim().isNotEmpty == true
        ? warning.instruction!.trim()
        : warning.description?.trim();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warning.headline,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(localizeWarningSeverity(l10n, severity)),
                    ],
                  ),
                ),
              ],
            ),
            if (guidance != null && guidance.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(guidance),
            ],
          ],
        ),
      ),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({
    required this.controller,
    required this.entries,
    required this.l10n,
    required this.onTap,
  });

  final MapController controller;
  final List<({Warning warning, List<List<LatLng>> polygons})> entries;
  final AppLocalizations l10n;
  final void Function(LatLng point) onTap;

  @override
  Widget build(BuildContext context) {
    final points = entries
        .expand((entry) => entry.polygons.expand((p) => p))
        .toList();
    final center = LatLng(
      points.fold<double>(0, (sum, point) => sum + point.latitude) /
          points.length,
      points.fold<double>(0, (sum, point) => sum + point.longitude) /
          points.length,
    );
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 7,
        onTap: (_, point) => onTap(point),
        onMapReady: () => controller.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(28),
          ),
        ),
      ),
      children: [
        const BaseMapLayer(),
        PolygonLayer(
          polygons: [
            for (final entry in entries)
              for (final polygon in entry.polygons)
                Polygon(
                  points: polygon,
                  color: warningSeverityColors(
                    context,
                    warningSeverityFromName(entry.warning.severity),
                  ).background.withValues(alpha: .42),
                  borderColor: warningSeverityColors(
                    context,
                    warningSeverityFromName(entry.warning.severity),
                  ).foreground,
                  borderStrokeWidth: 2,
                ),
          ],
        ),
        BaseMapAttribution(l10n: l10n),
      ],
    );
  }
}

class _WarningSummary extends StatelessWidget {
  const _WarningSummary({required this.entries, required this.l10n});

  final List<({Warning warning, List<List<LatLng>> polygons})> entries;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final warning = entries[index].warning;
        final severity = warningSeverityFromName(warning.severity);
        final colors = warningSeverityColors(context, severity);
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            leading: Icon(
              Icons.warning_amber_rounded,
              color: colors.foreground,
            ),
            title: Text(
              warning.headline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(localizeWarningSeverity(l10n, severity)),
            trailing: entries[index].polygons.isEmpty
                ? const Icon(Icons.text_snippet_outlined)
                : const Icon(Icons.map_outlined),
          ),
        );
      },
    );
  }
}

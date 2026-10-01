import 'package:flutter/material.dart';

import '../../../core/content_swap.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../model/categories.dart';
import '../../../model/household_profile.dart';

import '../../../core/adaptive_columns.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../checklists/application/checklist_providers.dart';
import '../../checklists/application/hazard_response_lists.dart';
import '../../checklists/presentation/checklist_detail_screen.dart';
import '../../household/application/household_providers.dart';
import '../application/warning_filter.dart';
import '../application/warning_polygon_codec.dart';
import '../application/warning_relevance.dart';
import '../application/warning_region_filter.dart';
import 'warning_situation_map_screen.dart';
import 'warning_day_notice.dart';
import '../application/warning_providers.dart';
import '../application/warning_order.dart';
import '../application/warning_severity_l10n.dart';
import '../../../core/error_text.dart';
import '../../maps/presentation/base_map_layer.dart';

class WarningListScreen extends ConsumerStatefulWidget {
  const WarningListScreen({super.key, required this.profile, this.now});

  final HouseholdProfile profile;

  /// Stands in for the clock the warning-day notice reads.
  ///
  /// Injectable only so tests can pin a date. Without it, whether this
  /// screen carries the notice depends on the day the suite happens to
  /// run -- which would make the layout tests below pass for fifty-one
  /// weeks a year and fail in the fifty-second.
  final DateTime? now;

  @override
  ConsumerState<WarningListScreen> createState() => _WarningListScreenState();
}

class _WarningListScreenState extends ConsumerState<WarningListScreen> {
  // The BBK map feeds cover the whole country. Showing that whole feed by
  // default made the dedicated warning screen contradict both its banner
  // and its notifications: a household in one state opened the screen and
  // saw alerts from the others. The chip stays reversible for deliberately
  // browsing the national picture, but the safe everyday view is the places
  // this household follows.
  var _filter = const WarningFilter(onlyMyRegions: true);
  final _searchController = TextEditingController();

  HouseholdProfile get profile => widget.profile;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilter() {
    _searchController.clear();
    // "Clear" returns to the normal, region-scoped view; it must not quietly
    // re-enable every warning in the country.
    setState(() => _filter = const WarningFilter(onlyMyRegions: true));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final warningsAsync = ref.watch(allWarningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.warningsTitle),
        actions: [
          IconButton(
            tooltip: l10n.warningSituationMapTitle,
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WarningSituationMapScreen(profile: profile),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            filter: _filter,
            searchController: _searchController,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          Expanded(child: _buildList(context, l10n, warningsAsync)),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Warning>> warningsAsync,
  ) {
    // NINA is the BBK's app and only covers Germany — recommending it to
    // an Austrian household would be wrong.
    //
    // It scrolls with the list rather than sitting pinned below it. Pinned,
    // it and the filter bar together took the whole screen at twice the
    // system font size: the list got nothing and the card overflowed by 62
    // pixels. The filter bar has to stay — a warning list that is quietly
    // filtered is dangerous — so the advisory is the one that gives way.
    final hint = profile.countryCode == 'DE' ? _NinaHint(l10n: l10n) : null;

    // Only where the day applies. The warning day is a German exercise,
    // and announcing it to a household in Austria would be noise on the
    // one screen that must not carry any.
    final warningDay = profile.countryCode == 'DE'
        ? WarningDayNotice.forList(l10n, now: widget.now)
        : null;

    /// A message with the advisory under it, scrollable as a pair.
    ///
    /// Not vertically centred any more: centring means filling the
    /// viewport, which pushed the card below the fold — and a hint nobody
    /// scrolls to is a hint nobody reads.
    Widget messageWithHint(Widget message) =>
        ListView(children: [?warningDay, message, ?hint]);

    return ContentSwap(
      child: warningsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(describeError(l10n, error))),
        data: (all) {
          if (all.isEmpty) {
            return messageWithHint(
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.warningsEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          final warnings = applyWarningFilter(
            all,
            filter: _filter,
            regions: profile.warningFilter,
          );

          if (warnings.isEmpty) {
            // Distinct from "nothing has come in": one is the feeds being
            // quiet, the other is this screen hiding what did arrive, and a
            // list that cannot tell them apart looks broken.
            return messageWithHint(
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.warningsEmptyFiltered(all.length),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _clearFilter,
                      child: Text(l10n.warningFilterClear),
                    ),
                  ],
                ),
              ),
            );
          }

          // Region first, then what is still running; see
          // [compareWarningsForList]. Unlike the banner, which only ever
          // shows one warning and therefore leads with severity.
          final now = DateTime.now();
          final sorted = [...warnings]
            ..sort(
              (a, b) => compareWarningsForList(
                a,
                b,
                filter: profile.warningFilter,
                now: now,
              ),
            );

          // Both are context for the whole list rather than entries in it,
          // and the notice goes first: it explains what the list may be
          // about to contain, while the count is about the filter.
          final leading = <Widget>[
            ?warningDay,
            // WarningFilter has isEmpty and no isNotEmpty.
            if (!_filter.isEmpty)
              _ResultCount(
                shown: sorted.length,
                total: all.length,
                onClear: _clearFilter,
              ),
          ];

          // Columns rather than one stretched list: a warning tile at
          // desktop width puts its headline at one edge and its time at the
          // other. Everything is built rather than only what is on screen,
          // which is affordable here and nowhere else in the app -- this
          // list is what the subscribed regions currently have out, tens of
          // entries at the very worst, not a household's whole inventory.
          return AdaptiveColumns(
            blocks: [
              ...leading,
              for (final warning in sorted)
                _WarningTile(
                  warning: warning,
                  l10n: l10n,
                  regions: profile.warningFilter,
                ),
              ?hint,
            ],
          );
        },
      ),
    );
  }
}

/// Search field plus the four conditions the list can be narrowed by.
///
/// Always on screen rather than behind a button: a warning list that is
/// quietly filtered is dangerous, so what is being hidden has to be
/// visible at a glance.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.searchController,
    required this.onChanged,
  });

  final WarningFilter filter;
  final TextEditingController searchController;
  final ValueChanged<WarningFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.warningFilterSearchHint,
              border: const OutlineInputBorder(),
              suffixIcon: filter.query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.warningFilterSearchClear,
                      onPressed: () {
                        searchController.clear();
                        onChanged(filter.copyWith(query: ''));
                      },
                    ),
            ),
            onChanged: (value) => onChanged(filter.copyWith(query: value)),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                // Active and expired are one either/or rather than two
                // switches: picking both would mean "everything", which is
                // what picking neither already means.
                FilterChip(
                  label: Text(l10n.warningFilterActive),
                  selected: filter.status == WarningStatus.active,
                  onSelected: (selected) => onChanged(
                    filter.copyWith(
                      status: selected
                          ? WarningStatus.active
                          : WarningStatus.any,
                    ),
                  ),
                ),
                FilterChip(
                  label: Text(l10n.warningFilterExpired),
                  selected: filter.status == WarningStatus.expired,
                  onSelected: (selected) => onChanged(
                    filter.copyWith(
                      status: selected
                          ? WarningStatus.expired
                          : WarningStatus.any,
                    ),
                  ),
                ),
                FilterChip(
                  label: Text(l10n.warningFilterMyRegions),
                  selected: filter.onlyMyRegions,
                  onSelected: (selected) =>
                      onChanged(filter.copyWith(onlyMyRegions: selected)),
                ),
                FilterChip(
                  label: Text(l10n.warningFilterSevere),
                  selected: filter.onlySevere,
                  onSelected: (selected) =>
                      onChanged(filter.copyWith(onlySevere: selected)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Says how much of the list is being hidden, and offers the way back.
class _ResultCount extends StatelessWidget {
  const _ResultCount({
    required this.shown,
    required this.total,
    required this.onClear,
  });

  final int shown;
  final int total;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.warningFilterResultCount(shown, total),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: Text(l10n.warningFilterClear),
          ),
        ],
      ),
    );
  }
}

/// Points at NINA for the job PreppSuite deliberately does not do.
///
/// The 15-minute poll is the honest reason: even with push, a warning here
/// would be minutes behind the BBK's own app, which delivers in about 30
/// seconds. Saying so is more useful than quietly being slower.
class _NinaHint extends StatelessWidget {
  const _NinaHint({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.notifications_active_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.warningsNinaHintTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.warningsNinaHintBody,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningTile extends StatelessWidget {
  const _WarningTile({
    required this.warning,
    required this.l10n,
    required this.regions,
  });

  final Warning warning;
  final AppLocalizations l10n;
  final WarningRegionFilter regions;

  @override
  Widget build(BuildContext context) {
    final severity = warningSeverityFromName(warning.severity);
    final source = WarningSource.fromName(warning.source);
    final isExpired =
        warning.expires != null && warning.expires!.isBefore(DateTime.now());

    final colors = warningSeverityColors(context, severity);

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: colors.background,
        // Without this the icon takes `onPrimaryContainer`, which is what
        // CircleAvatar falls back to under Material 3 — a green, on a red.
        foregroundColor: colors.foreground,
        child: const Icon(Icons.warning_amber_rounded, size: 18),
      ),
      title: Text(warning.headline),
      subtitle: Text(
        [
          localizeWarningSeverity(l10n, severity),
          if (isExpired) l10n.warningExpiredLabel,
        ].join(' · '),
      ),
      children: [
        _WarningDetails(
          warning: warning,
          severity: severity,
          colors: colors,
          source: source,
          l10n: l10n,
          regions: regions,
        ),
      ],
    );
  }
}

/// The complete, locally cached CAP message. This deliberately lives in the
/// expansion rather than behind a network request: when a warning is already
/// visible, its area, instructions and publisher must remain readable offline.
class _WarningDetails extends StatelessWidget {
  const _WarningDetails({
    required this.warning,
    required this.severity,
    required this.colors,
    required this.source,
    required this.l10n,
    required this.regions,
  });

  final Warning warning;
  final WarningSeverity severity;
  final WarningSeverityColors colors;
  final WarningSource source;
  final AppLocalizations l10n;
  final WarningRegionFilter regions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final material = MaterialLocalizations.of(context);
    final polygons = warningPolygons(warning);
    final end = warning.expires == null
        ? l10n.warningDetailsUntilFurtherNotice
        : _formatDateTime(material, warning.expires!);
    final period = l10n.warningDetailsPeriod(
      _formatDateTime(material, warning.effective),
      end,
    );
    final sourceName = switch (source) {
      WarningSource.bbk => l10n.warningSourceBbk,
      WarningSource.meteoalarm => l10n.warningSourceMeteoalarm,
    };

    final recommendation = _DetailSection(
      icon: Icons.accessibility_new_outlined,
      title: l10n.warningInstructionsTitle,
      body: warning.instruction ?? l10n.warningDetailsNoInstructions,
    );
    final area = _DetailSection(
      icon: Icons.map_outlined,
      title: l10n.warningDetailsAffectedRegions,
      body: warning.areaDescription ?? l10n.warningDetailsNoArea,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (polygons.isNotEmpty) ...[
            _WarningMapPreview(
              title: warning.headline,
              polygons: polygons,
              colors: colors,
              expandLabel: l10n.warningShowMap,
            ),
            const SizedBox(height: 16),
          ],
          Text(period, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(warning.headline, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(
                Icons.warning_amber_rounded,
                color: colors.foreground,
              ),
              label: Text(
                l10n.warningDetailsLevel(
                  localizeWarningSeverity(l10n, severity),
                ),
              ),
              backgroundColor: colors.background,
              side: BorderSide.none,
            ),
          ),
          if (warning.description != null) ...[
            const SizedBox(height: 12),
            Text(warning.description!, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 620
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: recommendation),
                      const SizedBox(width: 24),
                      Expanded(child: area),
                    ],
                  )
                : Column(
                    children: [
                      recommendation,
                      const SizedBox(height: 20),
                      area,
                    ],
                  ),
          ),
          const SizedBox(height: 24),
          _DetailSection(
            icon: Icons.my_location_outlined,
            title: l10n.warningDetailsRelevance,
            body: _relevanceText(
              l10n,
              warningRelevance(warning: warning, filter: regions),
            ),
          ),
          const SizedBox(height: 24),
          _DetailSection(
            icon: Icons.info_outline,
            title: l10n.warningDetailsSource,
            body: [
              sourceName,
              if (warning.senderContact != null) warning.senderContact!,
              l10n.warningDetailsPublished(
                _formatDateTime(material, warning.sent),
              ),
            ].join('\n'),
          ),
          const SizedBox(height: 12),
          // Before the link to the official page, which needs a browser
          // and a network. This one is the app's own answer to the
          // question the warning raises, and it works with neither.
          _ResponseListButton(eventType: warning.eventType, l10n: l10n),
          Text(
            l10n.warningDetailsOfflineHint,
            style: theme.textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => launchUrl(
                switch (source) {
                  WarningSource.bbk => Uri.https(
                    'warnung.bund.de',
                    '/meldungen/${warning.externalId}',
                  ),
                  WarningSource.meteoalarm => Uri.https(
                    'meteoalarm.org',
                    '/de/live/',
                  ),
                },
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.warningMoreInformation),
            ),
          ),
        ],
      ),
    );
  }
}

String _relevanceText(
  AppLocalizations l10n,
  WarningRelevance relevance,
) => switch (relevance) {
  WarningRelevance.ownDistrict => l10n.warningRelevanceOwnDistrict,
  WarningRelevance.followedDistrict => l10n.warningRelevanceFollowedDistrict,
  WarningRelevance.ownState => l10n.warningRelevanceOwnState,
  WarningRelevance.followedState => l10n.warningRelevanceFollowedState,
  WarningRelevance.nationwide => l10n.warningRelevanceNationwide,
  WarningRelevance.noPlacesSelected => l10n.warningRelevanceNoPlaces,
  WarningRelevance.otherRegion => l10n.warningRelevanceOtherRegion,
};

String _formatDateTime(MaterialLocalizations material, DateTime value) =>
    '${material.formatMediumDate(value)} · '
    '${material.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ],
        ),
        const SizedBox(height: 8),
        Text(body, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}

class _WarningMapPreview extends StatefulWidget {
  const _WarningMapPreview({
    required this.title,
    required this.polygons,
    required this.colors,
    required this.expandLabel,
  });

  final String title;
  final List<List<LatLng>> polygons;
  final WarningSeverityColors colors;
  final String expandLabel;

  @override
  State<_WarningMapPreview> createState() => _WarningMapPreviewState();
}

class _WarningMapPreviewState extends State<_WarningMapPreview> {
  final _controller = MapController();

  void _fitArea() {
    final all = widget.polygons.expand((polygon) => polygon).toList();
    if (all.isEmpty) return;
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(all),
        padding: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.expandLabel,
    child: AspectRatio(
      aspectRatio: 16 / 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: widget.polygons.first.first,
                  initialZoom: 8,
                  onMapReady: _fitArea,
                ),
                children: [
                  const BaseMapLayer(),
                  _WarningPolygons(
                    polygons: widget.polygons,
                    colors: widget.colors,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _WarningAreaMap(
                      title: widget.title,
                      polygons: widget.polygons,
                      colors: widget.colors,
                    ),
                  ),
                ),
                icon: const Icon(Icons.fullscreen),
                label: Text(widget.expandLabel),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WarningPolygons extends StatelessWidget {
  const _WarningPolygons({required this.polygons, required this.colors});

  final List<List<LatLng>> polygons;
  final WarningSeverityColors colors;

  @override
  Widget build(BuildContext context) => PolygonLayer(
    polygons: [
      for (final points in polygons)
        Polygon(
          points: points,
          color: colors.background.withValues(alpha: .45),
          borderColor: colors.foreground,
          borderStrokeWidth: 3,
        ),
    ],
  );
}

class _WarningAreaMap extends StatelessWidget {
  const _WarningAreaMap({
    required this.title,
    required this.polygons,
    required this.colors,
  });

  final String title;
  final List<List<LatLng>> polygons;
  final WarningSeverityColors colors;

  @override
  Widget build(BuildContext context) {
    final all = polygons.expand((polygon) => polygon).toList();
    final center = LatLng(
      all.fold<double>(0, (sum, point) => sum + point.latitude) / all.length,
      all.fold<double>(0, (sum, point) => sum + point.longitude) / all.length,
    );
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FlutterMap(
        options: MapOptions(initialCenter: center, initialZoom: 9),
        children: [
          const BaseMapLayer(),
          _WarningPolygons(polygons: polygons, colors: colors),
          BaseMapAttribution(l10n: AppLocalizations.of(context)!),
        ],
      ),
    );
  }
}

/// The way from a warning to the list of what to do about it.
///
/// Renders nothing at all when the event has no matching list — most
/// warnings do not, and an offer that does not fit is worse than none on
/// a screen somebody is reading in a hurry. See `hazard_response_lists`.
class _ResponseListButton extends ConsumerWidget {
  const _ResponseListButton({required this.eventType, required this.l10n});

  final String eventType;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientId = responseListFor(eventType);
    if (clientId == null) return const SizedBox.shrink();

    final profile = ref.watch(householdProfileProvider).value;
    if (profile == null) return const SizedBox.shrink();

    final templates =
        ref.watch(checklistTemplatesProvider(profile.id)).value ?? const [];
    final template = templates
        .where((candidate) => candidate.clientId == clientId)
        .firstOrNull;
    // Absent on a household seeded before the list existed and not yet
    // relaunched. Nothing to offer rather than a button that opens
    // nothing.
    if (template == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChecklistDetailScreen(
                template: template,
                householdId: profile.id,
              ),
            ),
          ),
          icon: const Icon(Icons.checklist_rtl),
          label: Text(l10n.warningWhatToDoNow),
        ),
      ),
    );
  }
}

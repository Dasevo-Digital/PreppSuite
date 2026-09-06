import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/categories.dart';
import '../../../model/household_profile.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/warning_filter.dart';
import '../application/warning_providers.dart';
import '../application/warning_relevance.dart';
import '../application/warning_severity_l10n.dart';

class WarningListScreen extends ConsumerStatefulWidget {
  const WarningListScreen({super.key, required this.profile});

  final HouseholdProfile profile;

  @override
  ConsumerState<WarningListScreen> createState() => _WarningListScreenState();
}

class _WarningListScreenState extends ConsumerState<WarningListScreen> {
  var _filter = const WarningFilter();
  final _searchController = TextEditingController();

  HouseholdProfile get profile => widget.profile;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilter() {
    _searchController.clear();
    setState(() => _filter = const WarningFilter());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final warningsAsync = ref.watch(allWarningsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.warningsTitle)),
      body: Column(
        children: [
          _FilterBar(
            filter: _filter,
            searchController: _searchController,
            onChanged: (filter) => setState(() => _filter = filter),
          ),
          Expanded(
            child: _buildList(context, l10n, warningsAsync),
          ),
          // NINA is the BBK's app and only covers Germany — recommending it
          // to an Austrian household would be wrong.
          if (profile.countryCode == 'DE') _NinaHint(l10n: l10n),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Warning>> warningsAsync,
  ) {
    return warningsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text(l10n.errorGeneric(error.toString()))),
      data: (all) {
        if (all.isEmpty) {
          return Center(
            child: Padding(
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
          return Center(
            child: Padding(
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

        // "Show region-relevant warnings first" — relevance is the
        // primary key here (unlike the banner, which prioritizes
        // severity since it only ever shows a single, most-urgent
        // warning); severity and recency break ties.
        final sorted = [...warnings]
          ..sort((a, b) {
            final relevanceCompare =
                warningRelevanceRank(
                  warning: b,
                  filter: profile.warningFilter,
                ).compareTo(
                  warningRelevanceRank(
                    warning: a,
                    filter: profile.warningFilter,
                  ),
                );
            if (relevanceCompare != 0) return relevanceCompare;

            final severityCompare =
                warningSeverityRank(
                  warningSeverityFromName(b.severity),
                ).compareTo(
                  warningSeverityRank(warningSeverityFromName(a.severity)),
                );
            if (severityCompare != 0) return severityCompare;

            return b.sent.compareTo(a.sent);
          });

        return ListView.builder(
          itemCount: sorted.length + (_filter.isEmpty ? 0 : 1),
          itemBuilder: (context, index) {
            if (!_filter.isEmpty) {
              if (index == 0) {
                return _ResultCount(
                  shown: sorted.length,
                  total: all.length,
                  onClear: _clearFilter,
                );
              }
              return _WarningTile(warning: sorted[index - 1], l10n: l10n);
            }
            return _WarningTile(warning: sorted[index], l10n: l10n);
          },
        );
      },
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
  const _WarningTile({required this.warning, required this.l10n});

  final Warning warning;
  final AppLocalizations l10n;

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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (warning.description != null) ...[
                Text(warning.description!),
                const SizedBox(height: 8),
              ],
              Text(
                switch (source) {
                  WarningSource.bbk => l10n.warningSourceBbk,
                  WarningSource.meteoalarm => l10n.warningSourceMeteoalarm,
                },
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(warning.sent),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

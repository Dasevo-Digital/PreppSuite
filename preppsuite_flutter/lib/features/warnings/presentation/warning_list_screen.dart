import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart'
    show Household, WarningRegionSubscription, WarningSource;

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../household/application/household_providers.dart';
import '../application/warning_providers.dart';
import '../application/warning_relevance.dart';
import '../application/warning_severity_l10n.dart';

class WarningListScreen extends ConsumerWidget {
  const WarningListScreen({super.key, required this.household});

  final Household household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final warningsAsync = ref.watch(allWarningsProvider);
    final subscriptions =
        ref.watch(householdWarningRegionsProvider(household.id!)).value ??
        const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.warningsTitle)),
      body: Column(
        children: [
          Expanded(
            child: _buildList(context, l10n, warningsAsync, subscriptions),
          ),
          // NINA is the BBK's app and only covers Germany — recommending it
          // to an Austrian household would be wrong.
          if (household.countryCode == 'DE') _NinaHint(l10n: l10n),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<List<Warning>> warningsAsync,
    List<WarningRegionSubscription> subscriptions,
  ) {
    return warningsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text(l10n.errorGeneric(error.toString()))),
      data: (warnings) {
        if (warnings.isEmpty) {
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

        // "Show region-relevant warnings first" — relevance is the
        // primary key here (unlike the banner, which prioritizes
        // severity since it only ever shows a single, most-urgent
        // warning); severity and recency break ties.
        final filter = warningRegionFilterFor(household, subscriptions);
        final sorted = [...warnings]
          ..sort((a, b) {
            final relevanceCompare =
                warningRelevanceRank(
                  warning: b,
                  filter: filter,
                ).compareTo(
                  warningRelevanceRank(warning: a, filter: filter),
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
          itemCount: sorted.length,
          itemBuilder: (context, index) =>
              _WarningTile(warning: sorted[index], l10n: l10n),
        );
      },
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
    final source = WarningSource.values.byName(warning.source);
    final isExpired =
        warning.expires != null && warning.expires!.isBefore(DateTime.now());

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: warningSeverityColor(context, severity),
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

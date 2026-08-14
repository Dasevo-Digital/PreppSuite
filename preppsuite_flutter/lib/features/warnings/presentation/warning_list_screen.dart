import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart' show WarningSource;

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/warning_providers.dart';
import '../application/warning_severity_l10n.dart';

class WarningListScreen extends ConsumerWidget {
  const WarningListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final warningsAsync = ref.watch(allWarningsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.warningsTitle)),
      body: warningsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.errorGeneric(error.toString()))),
        data: (warnings) => warnings.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.warningsEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: warnings.length,
                itemBuilder: (context, index) =>
                    _WarningTile(warning: warnings[index], l10n: l10n),
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
                MaterialLocalizations.of(context).formatMediumDate(warning.sent),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

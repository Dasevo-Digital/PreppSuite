import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/warning_freshness.dart';

/// "Stand: heute 14:32" while the warnings are current, and a card that
/// cannot be missed once they are not (#138).
class WarningFreshnessNotice extends StatelessWidget {
  const WarningFreshnessNotice({
    super.key,
    required this.freshness,
    required this.at,
    required this.now,
  });

  final WarningFreshness freshness;
  final DateTime? at;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final at = this.at;
    if (freshness == WarningFreshness.current && at != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          l10n.warningsUpdatedAt(formatWarningTime(l10n, at, now)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final colours = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: colours.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off_outlined, color: colours.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.warningsStaleTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colours.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    at == null
                        ? l10n.warningsNeverBody
                        : l10n.warningsStaleBody(
                            formatWarningTime(l10n, at, now),
                          ),
                    style: TextStyle(color: colours.onErrorContainer),
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

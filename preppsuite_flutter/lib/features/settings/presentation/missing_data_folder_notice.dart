import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Says that the data folder somebody picked is not reachable right now.
///
/// The app deliberately starts anyway — a household manager that refuses
/// to open because a disk is missing would be useless at exactly the
/// wrong moment — but starting quietly is the dangerous half. What it
/// opens instead is a *different* household: the one still on this
/// machine, probably older, possibly empty. Without a word on the screen
/// that reads as "my data is gone", and anything typed into it goes into
/// the wrong database and is apparently lost once the disk is back.
///
/// So it is loud: error colours, and it says where the folder was and
/// what to do. The one thing it does not do is offer a button — plugging
/// a disk in is not something the app can do.
class MissingDataFolderNotice extends StatelessWidget {
  const MissingDataFolderNotice({super.key, required this.path});

  /// What the choice pointed at, as far as it can still be named.
  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.report_problem_outlined,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.portableChoiceMissingTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.portableChoiceMissingBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 6),
                // The path itself, because "a folder" is not something
                // anybody can go and look for.
                Text(
                  l10n.portableChoiceMissingWhere(path),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.portableChoiceMissingHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
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

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// What to do when a household arrives that is not this device's.
///
/// Refusing outright was the old answer everywhere, and it is the right
/// *default*: two merged sets of data cannot be separated again, so it
/// must never happen by accident. It is a poor answer to somebody who
/// meant it, though — two devices of one household set up separately,
/// before joining during setup existed, had no way to each other.
///
/// Both roads into a household ask the same question with the same words:
/// the QR code and the shared folder. The folder used to be the careless
/// one — it adopted whatever it found and said so afterwards — which made
/// the two roads disagree about the most irreversible step in the app.
enum HouseholdConflictChoice {
  /// Keep both: this device's rows are re-stamped into the other
  /// household and travel across on the next exchange.
  merge,

  /// Drop this device's own rows and take the other household alone.
  replace,

  /// Touch nothing.
  keep,
}

/// Asks, with the row counts on screen.
///
/// Null when the dialog was dismissed, which means the same as [keep].
Future<HouseholdConflictChoice?> askAboutHouseholdConflict(
  BuildContext context, {
  required String mine,
  required int rows,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<HouseholdConflictChoice>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.merge_type),
      title: Text(l10n.transferConflictTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.transferConflictBody(mine)),
            const SizedBox(height: 16),
            _Option(
              title: l10n.transferConflictMerge,
              body: l10n.transferConflictMergeBody(rows),
              onTap: () =>
                  Navigator.pop(context, HouseholdConflictChoice.merge),
            ),
            _Option(
              title: l10n.transferConflictReplace,
              body: l10n.transferConflictReplaceBody(rows),
              onTap: () =>
                  Navigator.pop(context, HouseholdConflictChoice.replace),
            ),
            _Option(
              title: l10n.transferConflictKeep,
              body: l10n.transferConflictKeepBody,
              onTap: () => Navigator.pop(context, HouseholdConflictChoice.keep),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(body),
      isThreeLine: true,
      onTap: onTap,
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/warning_day.dart';

/// Says that the nationwide warning day is coming, or is today.
///
/// It sits above the warning list rather than anywhere else for one
/// reason: on that day this app shows a test warning that looks like any
/// other, because it comes down the same official feeds. Without a word of
/// explanation on the screen where it appears, the choice is between
/// frightening people and teaching them to distrust the list.
///
/// The other half is the point of the day at all. A warning route that
/// does not work fails silently -- nobody notices a notification that
/// never came -- and this is the one day a year on which that can be
/// found out on purpose.
class WarningDayNotice extends StatelessWidget {
  const WarningDayNotice({super.key, required this.l10n, this.now});

  /// Injectable so the notice can be tested on a date other than today;
  /// null means the real clock.
  final DateTime? now;

  final AppLocalizations l10n;

  /// How far ahead the notice starts appearing.
  ///
  /// A week: long enough to be a reminder to set something up, short
  /// enough not to stand above a warning list for a month. The list is
  /// this screen's job, and the notice is a guest on it.
  static const noticeDays = 7;

  /// The notice, or null when the day is too far off to mention.
  ///
  /// Returned rather than rendered as an empty box, because the caller
  /// builds a list and an invisible item still takes a slot.
  static Widget? forList(AppLocalizations l10n, {DateTime? now}) {
    final days = daysUntilFederalWarningDay(from: now);
    if (days > noticeDays) return null;
    return WarningDayNotice(l10n: l10n, now: now);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = daysUntilFederalWarningDay(from: now);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    days == 0 ? l10n.warningDayToday : l10n.warningDayIn(days),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.warningDayBody, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

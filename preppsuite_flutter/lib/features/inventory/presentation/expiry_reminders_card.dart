import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/expiry_reminder_provider.dart';

/// Lead-time picker for expiry reminders. Deliberately shows the chips
/// even when notifications are off — hiding them would leave no hint that
/// the feature exists — but says plainly that nothing will be scheduled
/// until notifications are switched on.
class ExpiryRemindersCard extends ConsumerWidget {
  const ExpiryRemindersCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(expiryLeadDaysProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    final hint = !notificationsEnabled
        ? l10n.settingsExpiryRemindersDisabledHint
        : selected.isEmpty
        ? l10n.settingsExpiryRemindersNoneHint
        : l10n.settingsExpiryRemindersHint;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hint, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in selectableExpiryLeadDays)
                  FilterChip(
                    label: Text(
                      days == 1
                          ? l10n.expiryLeadDayOneLabel
                          : l10n.expiryLeadDaysLabel(days),
                    ),
                    selected: selected.contains(days),
                    onSelected: (_) =>
                        ref.read(expiryLeadDaysProvider.notifier).toggle(days),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

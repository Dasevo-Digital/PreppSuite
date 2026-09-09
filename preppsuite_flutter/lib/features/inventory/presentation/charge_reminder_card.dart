import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/charge_reminder_provider.dart';

class ChargeReminderCard extends ConsumerWidget {
  const ChargeReminderCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(chargeReminderDaysProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);
    final hint = !notificationsEnabled
        ? l10n.settingsChargeReminderDisabledHint
        : days == 0
        ? l10n.settingsChargeReminderNoneHint
        : l10n.settingsChargeReminderHint;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hint),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final interval in selectableChargeReminderDays)
                  ChoiceChip(
                    label: Text(
                      interval == 0
                          ? l10n.settingsChargeReminderOff
                          : l10n.chargeReminderInterval(interval),
                    ),
                    selected: days == interval,
                    onSelected: (_) => ref
                        .read(chargeReminderDaysProvider.notifier)
                        .setDays(interval),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

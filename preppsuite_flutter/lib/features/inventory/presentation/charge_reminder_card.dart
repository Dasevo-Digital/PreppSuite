import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // A value the chips do not offer, reached through "own interval". The
    // chip then has to show it, or the setting would read as unset while a
    // reminder is in fact pending.
    final isCustom = !selectableChargeReminderDays.contains(days);

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
                ChoiceChip(
                  label: Text(
                    isCustom
                        ? l10n.chargeReminderInterval(days)
                        : l10n.settingsChargeReminderCustom,
                  ),
                  selected: isCustom,
                  onSelected: (_) => _askInterval(context, ref, days),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _askInterval(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    // The dialog owns its controller. Held out here and disposed after
    // `showDialog` returns, it was disposed while the closing animation
    // still had the field mounted, and the rebuild then used a dead
    // controller.
    final chosen = await showDialog<int>(
      context: context,
      builder: (_) => _IntervalDialog(l10n: l10n, initialDays: current),
    );
    if (chosen == null) return;
    await ref.read(chargeReminderDaysProvider.notifier).setDays(chosen);
  }
}

class _IntervalDialog extends StatefulWidget {
  const _IntervalDialog({required this.l10n, required this.initialDays});

  final AppLocalizations l10n;
  final int initialDays;

  @override
  State<_IntervalDialog> createState() => _IntervalDialogState();
}

class _IntervalDialogState extends State<_IntervalDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialDays == 0 ? '' : '${widget.initialDays}',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final days = int.tryParse(_controller.text.trim());
    if (days == null || !isChargeReminderDays(days) || days == 0) {
      // Zero is rejected here rather than accepted as "off": there is a
      // chip that says off in words, and typing a nought into a field
      // asking for an interval is more likely a slip than an intention.
      setState(() {
        _error = widget.l10n.settingsChargeReminderCustomInvalid(
          minimumChargeReminderDays,
          maximumChargeReminderDays,
        );
      });
      return;
    }
    Navigator.pop(context, days);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.settingsChargeReminderCustomTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: widget.l10n.settingsChargeReminderCustomLabel,
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

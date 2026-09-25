import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/expiry_reminder_planner.dart';
import '../application/expiry_reminder_provider.dart';

/// What the dialog decided, as distinct from "the dialog was dismissed".
///
/// The stored value has three meaningful states and one of them is null,
/// so a bare `String?` return could not say whether null meant "follow the
/// household" or "the user backed out". This wrapper can: the dialog
/// returns null when nothing was chosen, and an instance — whose [value]
/// may itself be null — when something was.
class ItemLeadDaysChoice {
  const ItemLeadDaysChoice(this.value);

  /// Null follows the household, an empty string means never, and a
  /// comma-separated list is this item's own. See
  /// `InventoryItems.expiryLeadDays`.
  final String? value;
}

/// Picks the expiry lead times for one item.
///
/// Deliberately a dialog and not a row of chips on the form. Nearly every
/// item follows the household, so the form should show one line saying so
/// — three states and seven chips inline would give a rare decision more
/// room than the name of the thing.
Future<ItemLeadDaysChoice?> showItemLeadDays(
  BuildContext context, {
  required String? current,
  required List<int> householdLeadDays,
}) {
  return showDialog<ItemLeadDaysChoice>(
    context: context,
    builder: (context) => _ItemLeadDaysDialog(
      current: current,
      householdLeadDays: householdLeadDays,
    ),
  );
}

enum _Mode { household, none, own }

class _ItemLeadDaysDialog extends StatefulWidget {
  const _ItemLeadDaysDialog({
    required this.current,
    required this.householdLeadDays,
  });

  final String? current;
  final List<int> householdLeadDays;

  @override
  State<_ItemLeadDaysDialog> createState() => _ItemLeadDaysDialogState();
}

class _ItemLeadDaysDialogState extends State<_ItemLeadDaysDialog> {
  late _Mode _mode;
  late List<int> _selected;

  @override
  void initState() {
    super.initState();
    final decoded = decodeItemLeadDays(widget.current);
    _mode = decoded == null
        ? _Mode.household
        : decoded.isEmpty
        ? _Mode.none
        : _Mode.own;
    // Something to start from when "own" is chosen from one of the other
    // two: an empty chip row with an OK button under it is a trap.
    _selected = decoded == null || decoded.isEmpty
        ? List.of(widget.householdLeadDays)
        : decoded;
  }

  String? get _result => switch (_mode) {
    _Mode.household => null,
    _Mode.none => '',
    _Mode.own => encodeItemLeadDays(_selected),
  };

  /// "Own" with nothing ticked is the same thing as "none", and offering
  /// to save it as a third spelling of the same state would make the
  /// line on the form disagree with the dialog that wrote it.
  bool get _canSave => _mode != _Mode.own || _selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      icon: const Icon(Icons.notifications_active_outlined),
      title: Text(l10n.itemExpiryRemindersTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.itemExpiryRemindersHint,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            RadioGroup<_Mode>(
              groupValue: _mode,
              onChanged: (mode) {
                if (mode != null) setState(() => _mode = mode);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<_Mode>(
                    value: _Mode.household,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.itemExpiryRemindersDefault),
                    subtitle: Text(
                      widget.householdLeadDays.isEmpty
                          ? l10n.itemExpiryRemindersNone
                          : _daysSentence(l10n, widget.householdLeadDays),
                    ),
                  ),
                  RadioListTile<_Mode>(
                    value: _Mode.own,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.itemExpiryRemindersOwn),
                  ),
                  RadioListTile<_Mode>(
                    value: _Mode.none,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.itemExpiryRemindersNever),
                  ),
                ],
              ),
            ),
            if (_mode == _Mode.own) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final days in selectableExpiryLeadDays)
                    FilterChip(
                      label: Text(_dayLabel(l10n, days)),
                      selected: _selected.contains(days),
                      onSelected: (_) => setState(() {
                        if (!_selected.remove(days)) _selected.add(days);
                      }),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _canSave
              ? () => Navigator.of(context).pop(ItemLeadDaysChoice(_result))
              : null,
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}

String _dayLabel(AppLocalizations l10n, int days) =>
    days == 1 ? l10n.expiryLeadDayOneLabel : l10n.expiryLeadDaysLabel(days);

/// "30 Tage, 7 Tage" — the same wording as the chips, joined, so the line
/// on the form reads as the row in the dialog and not as a second scheme.
String _daysSentence(AppLocalizations l10n, List<int> days) =>
    (days.toList()..sort((a, b) => b.compareTo(a)))
        .map((day) => _dayLabel(l10n, day))
        .join(', ');

/// The one line the form shows for [stored].
String itemLeadDaysSummary(
  AppLocalizations l10n,
  String? stored,
  List<int> householdLeadDays,
) {
  final decoded = decodeItemLeadDays(stored);
  if (decoded == null) {
    return householdLeadDays.isEmpty
        ? l10n.itemExpiryRemindersDefaultNone
        : l10n.itemExpiryRemindersDefaultWith(
            _daysSentence(l10n, householdLeadDays),
          );
  }
  if (decoded.isEmpty) return l10n.itemExpiryRemindersNever;
  return _daysSentence(l10n, decoded);
}

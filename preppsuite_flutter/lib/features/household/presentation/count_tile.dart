import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// One head count with a minus and a plus.
///
/// Shared between setting a household up and editing it later, on purpose.
/// These four numbers — adults, children, dogs, cats — are the whole input
/// to the supply calculation, and the app has already had the bug that
/// comes from asking for them in two places: the inventory screen used to
/// keep a person count of its own, and the two drifted apart.
class CountTile extends StatelessWidget {
  const CountTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minimum = 0,
  });

  final IconData icon;
  final String label;
  final int value;

  /// One for the adults — a household with nobody in it has nothing to
  /// plan for. Zero for everyone else.
  final int minimum;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: l10n.stepperDecrease(label),
            onPressed: value > minimum ? () => onChanged(value - 1) : null,
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium,
            semanticsLabel: l10n.stepperValue(label, value),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.stepperIncrease(label),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

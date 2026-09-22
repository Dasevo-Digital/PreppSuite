import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/food_amount.dart';

/// Why a tin is not a unit.
///
/// The rule — food and water are counted in g, kg, ml or l — is enforced
/// by the form and explained by a helper line under the field. That line
/// has room for one sentence, and this is a question with three answers:
/// why the measure is needed at all, which spellings are taken, and what
/// happens to the rows that already say "Dose".
///
/// The last of those is the one worth being asked for by name. Somebody
/// who has just been refused wants to know whether their pantry is about
/// to be rewritten. It is not.
///
/// Returns the unit that was tapped, or null. Offering the units as
/// something to tap rather than a list to read is the difference between
/// an explanation and an answer: the field is right behind the dialog,
/// and it is the thing that needs filling in.
Future<String?> showUnitInfo(BuildContext context, {int uncounted = 0}) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.scale_outlined),
      title: Text(l10n.unitInfoTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // What was actually asked, where the question came from the
            // inventory rather than from the field.
            if (uncounted > 0) ...[
              Text(
                l10n.foodWithoutMeasureBody(uncounted),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            Text(l10n.unitInfoWhy, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final unit in suggestedFoodUnits)
                  ActionChip(
                    label: Text(unit),
                    onPressed: () => Navigator.of(context).pop(unit),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.unitInfoAccepted,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _Note(text: l10n.unitInfoKept, icon: Icons.inventory_2_outlined),
            const SizedBox(height: 8),
            _Note(text: l10n.unitInfoExempt, icon: Icons.medication_outlined),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          // Flutter's own, so it is already in every language the app
          // is in and in the wording that platform uses.
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

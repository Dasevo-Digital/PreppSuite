import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/inventory_controller.dart';
import '../application/inventory_providers.dart';
import '../application/rotation.dart';
import 'consume_dialog.dart';
import 'inventory_item_form_screen.dart';

/// What to use next.
///
/// The overview counts how many items are expired or close to it. A count
/// is not an errand — it does not say which tin to open tonight. This is
/// the same data in the order it has to be dealt with, and each row can
/// be used up on the spot.
class RotationScreen extends ConsumerWidget {
  const RotationScreen({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(inventoryItemsProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rotationTitle)),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorGeneric('$error'))),
        data: (items) {
          final rotation = buildRotation(items);
          if (rotation.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.rotationEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          // Built as one flat list with headings rather than three lists,
          // so the order the queue is in survives on screen.
          final rows = <Widget>[];
          RotationUrgency? lastUrgency;
          for (final entry in rotation) {
            if (entry.urgency != lastUrgency) {
              rows.add(_Heading(urgency: entry.urgency, l10n: l10n));
              lastUrgency = entry.urgency;
            }
            rows.add(_RotationTile(entry: entry, l10n: l10n));
          }
          rows.add(_Hint(l10n: l10n));

          return ListView(children: rows);
        },
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.urgency, required this.l10n});

  final RotationUrgency urgency;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        switch (urgency) {
          RotationUrgency.expired => l10n.rotationExpiredHeading,
          RotationUrgency.soon => l10n.rotationSoonHeading,
          RotationUrgency.later => l10n.rotationLaterHeading,
        },
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _RotationTile extends ConsumerWidget {
  const _RotationTile({required this.entry, required this.l10n});

  final RotationEntry entry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    // Both halves of the pair, so the text cannot end up on a ground it
    // is unreadable against — the same rule the warning colours follow.
    final (background, foreground) = switch (entry.urgency) {
      RotationUrgency.expired => (scheme.error, scheme.onError),
      RotationUrgency.soon => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      RotationUrgency.later => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: background,
        foregroundColor: foreground,
        child: const Icon(Icons.schedule, size: 18),
      ),
      title: Text(entry.item.name),
      subtitle: Text(
        '${_remaining()} · ${_date(entry.item.expirationDate!)}'
        ' · ${_quantity(entry.item)}',
      ),
      trailing: entry.item.quantity > 0
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: l10n.consumeAction,
              onPressed: () => _consume(context, ref),
            )
          : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InventoryItemFormScreen(
            householdId: entry.item.householdId,
            existing: entry.item,
          ),
        ),
      ),
    );
  }

  String _remaining() => switch (entry.daysLeft) {
    < 0 => l10n.rotationExpiredSince(-entry.daysLeft),
    0 => l10n.rotationExpiresToday,
    _ => l10n.rotationDaysLeft(entry.daysLeft),
  };

  Future<void> _consume(BuildContext context, WidgetRef ref) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => ConsumeDialog(item: entry.item, l10n: l10n),
    );
    if (amount == null) return;

    await ref
        .read(inventoryControllerProvider(entry.item.householdId))
        .consumeQuantity(entry.item, amount);
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Text(
        l10n.rotationHint,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

String _date(DateTime value) =>
    DateFormat.yMd().format(value.isUtc ? value.toLocal() : value);

String _quantity(InventoryItem item) {
  final quantity = item.quantity == item.quantity.roundToDouble()
      ? item.quantity.toStringAsFixed(0)
      : item.quantity.toString();
  return '$quantity ${item.unit}';
}

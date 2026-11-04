import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/adaptive_columns.dart';
import '../../../core/error_text.dart';
import '../../../core/settings_arrival.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../inventory/application/inventory_controller.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/application/stock_today.dart';
import '../application/cold_store_contents.dart';
import '../application/outage_food_safety.dart';
import '../application/outage_store.dart';

/// The blackout clock: how long the cold lasts.
///
/// Deliberately one tap from nothing to a running clock. Everything else
/// on this screen — the freezer question, the start time, the rules — can
/// be corrected afterwards, because the moment this screen is opened is
/// usually a moment of being busy with something else.
///
/// The figures are FEMA's and the USDA's, and the screen says so at the
/// bottom. See `outage_food_safety.dart` for why they are not German.
///
/// With a [householdId], each store also says what the household's
/// stores keep in it, and once its time is up offers to book that out
/// (#276); see `cold_store_contents.dart`.
class OutageScreen extends StatefulWidget {
  const OutageScreen({
    super.key,
    this.store = const OutageClockStore(),
    this.householdId,
  });

  final OutageClockStore store;
  final String? householdId;

  @override
  State<OutageScreen> createState() => _OutageScreenState();
}

class _OutageScreenState extends State<OutageScreen>
    with RereadOnSettingsArrival {
  OutageClock? _clock;
  var _loading = true;
  var _freezerFill = FreezerFill.full;
  Timer? _tick;

  /// Read once per build rather than per card, so the two countdowns on
  /// screen can never be a second apart.
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    // A minute is the resolution the numbers are stated in; a second
    // would spend battery redrawing during the one situation where the
    // battery is what is left.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// A blackout started or ended on another device is started or ended
  /// here too, also while this screen is open (#258).
  @override
  void settingsArrived() => _load();

  Future<void> _load() async {
    final clock = await widget.store.load();
    final fill = clock?.freezerFill ?? await widget.store.loadFill();
    if (!mounted) return;
    setState(() {
      _clock = clock;
      _freezerFill = fill;
      _loading = false;
      _now = DateTime.now().toUtc();
    });
  }

  Future<void> _start() async {
    // A clock another device started first is the earlier, and so the
    // truer, start. Restarting it at "now" would tell the household the
    // food has longer than it has.
    final running = await widget.store.load();
    final clock =
        running ??
        OutageClock(
          startedAt: DateTime.now().toUtc(),
          freezerFill: _freezerFill,
        );
    if (running == null) await widget.store.save(clock);
    if (!mounted) return;
    setState(() {
      _clock = clock;
      _freezerFill = clock.freezerFill;
      _now = DateTime.now().toUtc();
    });
  }

  Future<void> _stop() async {
    await widget.store.clear();
    if (!mounted) return;
    setState(() => _clock = null);
  }

  Future<void> _setFill(FreezerFill fill) async {
    setState(() => _freezerFill = fill);
    await widget.store.saveFill(fill);
    final clock = await widget.store.load();
    if (mounted) setState(() => _clock = clock);
  }

  /// Corrects the start time. A blackout that began during the night is
  /// noticed hours later, and a clock started at "now" would then be
  /// telling the household the food is fine when it is not.
  Future<void> _editStart() async {
    final clock = _clock;
    if (clock == null) return;
    final local = clock.startedAt.toLocal();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
    );
    if (picked == null || !mounted) return;

    var startedAt = DateTime(
      local.year,
      local.month,
      local.day,
      picked.hour,
      picked.minute,
    );
    // A time later than now means the household meant yesterday: at
    // 02:00 one enters "22:30" for a blackout that began last night.
    // Yesterday's date at the same time, not 24 hours back, which is an
    // hour off when the clocks changed overnight.
    if (startedAt.isAfter(DateTime.now())) {
      startedAt = DateTime(
        local.year,
        local.month,
        local.day - 1,
        picked.hour,
        picked.minute,
      );
    }

    // Ended elsewhere while the picker was open: correcting the start
    // of a blackout that is over must not begin another one.
    final stored = await widget.store.load();
    if (stored == null) {
      if (mounted) setState(() => _clock = null);
      return;
    }
    final updated = OutageClock(
      startedAt: startedAt.toUtc(),
      freezerFill: stored.freezerFill,
    );
    await widget.store.save(updated);
    if (!mounted) return;
    setState(() {
      _clock = updated;
      _now = DateTime.now().toUtc();
    });
  }

  /// The two cards, and with a household what its stores keep in each.
  Widget _stores(OutageClock clock, AppLocalizations l10n) {
    final statuses = coldStoreStatuses(
      startedAt: clock.startedAt,
      now: _now,
      freezerFill: clock.freezerFill,
    );
    Widget cards(
      ColdStoreContents? contents,
      InventoryController Function()? stock,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final status in statuses)
          _StoreCard(
            status: status,
            endsAt: windowEndsAt(clock.startedAt, status),
            l10n: l10n,
            items: contents?.of(status.store) ?? const [],
            onDiscard: stock == null || !status.isOver
                ? null
                : () => _discard(
                    status,
                    contents!.of(status.store),
                    stock(),
                    l10n,
                  ),
          ),
        if (contents != null && contents.isEmpty)
          Text(
            l10n.outageContentsNone,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );

    final householdId = widget.householdId;
    if (householdId == null) return cards(null, null);
    return Consumer(
      builder: (context, ref, _) {
        final items = ref.watch(inventoryItemsProvider(householdId)).value;
        return cards(
          items == null ? null : coldStoreContents(items, now: _now),
          () => ref.read(inventoryControllerProvider(householdId)),
        );
      },
    );
  }

  /// What the household throws out of [store], out of the stock as well
  /// (#276), with a way back for a slip.
  Future<void> _discard(
    ColdStoreStatus status,
    List<InventoryItem> items,
    InventoryController stock,
    AppLocalizations l10n,
  ) async {
    final chosen = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _DiscardDialog(
        store: status.store,
        spoilt: status.isSpoilt,
        items: items,
        l10n: l10n,
      ),
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final taken = await stock.bookOutAll(chosen);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.outageDiscarded(taken.length)),
            action: taken.isEmpty
                ? null
                : SnackBarAction(
                    label: l10n.undoAction,
                    onPressed: () => stock.bookPurchases(taken),
                  ),
          ),
        );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(l10n, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final clock = _clock;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.outageTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AdaptiveColumns(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              blocks: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.outageIntro),
                    const SizedBox(height: 16),
                    if (clock == null)
                      FilledButton.icon(
                        onPressed: _start,
                        icon: const Icon(Icons.power_off),
                        label: Text(l10n.outageStart),
                      )
                    else ...[
                      _stores(clock, l10n),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.outageRunningSince(
                                DateFormat.Hm(
                                  l10n.localeName,
                                ).format(clock.startedAt.toLocal()),
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: _editStart,
                            child: Text(l10n.outageChangeStart),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _stop,
                        icon: const Icon(Icons.power),
                        label: Text(l10n.outageEnded),
                      ),
                    ],
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.outageFreezerFill,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<FreezerFill>(
                      segments: [
                        ButtonSegment(
                          value: FreezerFill.full,
                          label: Text(l10n.outageFreezerFull),
                        ),
                        ButtonSegment(
                          value: FreezerFill.half,
                          label: Text(l10n.outageFreezerHalf),
                        ),
                      ],
                      selected: {_freezerFill},
                      onSelectionChanged: (selected) =>
                          _setFill(selected.first),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.outageFreezerWhy,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.outageRulesTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final rule in [
                      l10n.outageRuleClosed,
                      l10n.outageRuleTwoHours(safeTemperatureCelsius),
                      l10n.outageRuleTaste,
                      l10n.outageRuleRefreeze,
                      l10n.outageRuleGenerator,
                      l10n.outageRuleUnplug,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• $rule'),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.outageSource,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.status,
    required this.endsAt,
    required this.l10n,
    this.items = const [],
    this.onDiscard,
  });

  final ColdStoreStatus status;
  final DateTime endsAt;
  final AppLocalizations l10n;

  /// What the stores keep in this one.
  final List<InventoryItem> items;

  /// Offered once the window is over and there is something in it.
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spoilt = status.isSpoilt;
    final over = status.isOver;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: spoilt
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              switch (status.store) {
                ColdStore.refrigerator => l10n.outageStoreRefrigerator,
                ColdStore.freezer => l10n.outageStoreFreezer,
              },
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              spoilt
                  ? l10n.outageSpoilt
                  : over
                  ? l10n.outageGrace(_words(l10n, status.graceRemaining))
                  : l10n.outageRemaining(_words(l10n, status.remaining)),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.outageUntil(
                DateFormat.Hm(l10n.localeName).format(endsAt.toLocal()),
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: status.fraction,
              // A window that is over reads as full rather than as empty:
              // the bar measures how much of the cold is spent.
              semanticsLabel: l10n.outageTitle,
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.outageContents(_names(items))),
              if (onDiscard != null) ...[
                const SizedBox(height: 8),
                spoilt
                    ? FilledButton.icon(
                        onPressed: onDiscard,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.outageDiscardButton),
                      )
                    : OutlinedButton.icon(
                        onPressed: onDiscard,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.outageDiscardButton),
                      ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Three names and how many more: a card, not the list. The whole list
  /// is in the dialog that books it out.
  static String _names(List<InventoryItem> items) {
    final shown = items.take(3).map((item) => item.name).join(', ');
    return items.length > 3 ? '$shown +${items.length - 3}' : shown;
  }

  /// Hours and minutes, or minutes alone under an hour.
  static String _words(AppLocalizations l10n, Duration left) {
    if (left.inHours < 1) return l10n.outageRemainingMinutes(left.inMinutes);
    return l10n.outageRemainingHours(left.inHours, left.inMinutes % 60);
  }
}

/// What goes out of one store: everything in it, the food ticked once
/// it is to be thrown out.
class _DiscardDialog extends StatefulWidget {
  const _DiscardDialog({
    required this.store,
    required this.spoilt,
    required this.items,
    required this.l10n,
  });

  final ColdStore store;

  /// The store's time is up entirely. A freezer past its window but
  /// within its two hours is not (#278): the card still says "discard
  /// in ...", and what has ice crystals left may be refrozen, so nothing
  /// is ticked for the household then.
  final bool spoilt;

  final List<InventoryItem> items;
  final AppLocalizations l10n;

  @override
  State<_DiscardDialog> createState() => _DiscardDialogState();
}

class _DiscardDialogState extends State<_DiscardDialog> {
  late final _ticked = {
    if (widget.spoilt)
      for (final item in widget.items)
        if (proposedForDiscard(item)) item.clientId,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final number = NumberFormat.decimalPattern(l10n.localeName);
    return AlertDialog(
      title: Text(switch (widget.store) {
        ColdStore.refrigerator => l10n.outageDiscardTitleRefrigerator,
        ColdStore.freezer => l10n.outageDiscardTitleFreezer,
      }),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.spoilt
                  ? l10n.outageDiscardHint
                  : l10n.outageDiscardGraceHint,
            ),
            const SizedBox(height: 8),
            for (final item in widget.items)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _ticked.contains(item.clientId),
                onChanged: (ticked) => setState(() {
                  ticked == true
                      ? _ticked.add(item.clientId)
                      : _ticked.remove(item.clientId);
                }),
                title: Text(item.name),
                subtitle: Text(
                  '${number.format(stockToday(item))} ${item.unit}'.trim(),
                ),
              ),
            if (widget.items.any(isColdMedicine)) ...[
              const SizedBox(height: 8),
              Text(
                l10n.outageDiscardMedicine,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _ticked.isEmpty
              ? null
              : () => Navigator.pop(context, Set.of(_ticked)),
          child: Text(l10n.outageDiscardConfirm(_ticked.length)),
        ),
      ],
    );
  }
}

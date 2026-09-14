import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/adaptive_columns.dart';
import '../../../l10n/generated/app_localizations.dart';
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
class OutageScreen extends StatefulWidget {
  const OutageScreen({super.key, this.store = const OutageClockStore()});

  final OutageClockStore store;

  @override
  State<OutageScreen> createState() => _OutageScreenState();
}

class _OutageScreenState extends State<OutageScreen> {
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

  Future<void> _load() async {
    final clock = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _clock = clock;
      _freezerFill = clock?.freezerFill ?? FreezerFill.full;
      _loading = false;
      _now = DateTime.now().toUtc();
    });
  }

  Future<void> _start() async {
    final clock = OutageClock(
      startedAt: DateTime.now().toUtc(),
      freezerFill: _freezerFill,
    );
    await widget.store.save(clock);
    if (!mounted) return;
    setState(() {
      _clock = clock;
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
    final clock = _clock;
    if (clock == null) return;
    final updated = OutageClock(startedAt: clock.startedAt, freezerFill: fill);
    await widget.store.save(updated);
    if (mounted) setState(() => _clock = updated);
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
    if (startedAt.isAfter(DateTime.now())) {
      startedAt = startedAt.subtract(const Duration(days: 1));
    }

    final updated = OutageClock(
      startedAt: startedAt.toUtc(),
      freezerFill: clock.freezerFill,
    );
    await widget.store.save(updated);
    if (!mounted) return;
    setState(() {
      _clock = updated;
      _now = DateTime.now().toUtc();
    });
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
                      for (final status in coldStoreStatuses(
                        startedAt: clock.startedAt,
                        now: _now,
                        freezerFill: clock.freezerFill,
                      ))
                        _StoreCard(
                          status: status,
                          endsAt: windowEndsAt(clock.startedAt, status),
                          l10n: l10n,
                        ),
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
  });

  final ColdStoreStatus status;
  final DateTime endsAt;
  final AppLocalizations l10n;

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
          ],
        ),
      ),
    );
  }

  /// Hours and minutes, or minutes alone under an hour.
  static String _words(AppLocalizations l10n, Duration left) {
    if (left.inHours < 1) return l10n.outageRemainingMinutes(left.inMinutes);
    return l10n.outageRemainingHours(left.inHours, left.inMinutes % 60);
  }
}

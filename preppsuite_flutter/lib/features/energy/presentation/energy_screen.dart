import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/adaptive_columns.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/energy_l10n.dart';
import '../application/energy_range.dart';
import '../application/energy_store.dart';

/// How long the light, the cooking and the radio last.
///
/// The companion to the supply calculator: that one answers how long the
/// food and water hold out, this one everything else. Same arithmetic,
/// same rule about figures — every number on this screen was typed in by
/// the household, off the stove and off the packet. The app divides; it
/// does not estimate.
class EnergyScreen extends StatefulWidget {
  const EnergyScreen({super.key, this.store = const EnergyPlanStore()});

  final EnergyPlanStore store;

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> {
  var _plan = const EnergyPlan();
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final plan = await widget.store.load();
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _loading = false;
    });
  }

  Future<void> _write(EnergyPlan plan) async {
    setState(() => _plan = plan);
    await widget.store.save(plan);
  }

  Future<void> _editReserve([EnergyReserve? existing]) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<_EntryResult>(
      context: context,
      builder: (context) => _EntryDialog(
        title: existing == null
            ? l10n.energyAddReserve
            : l10n.energyEditReserve,
        kind: existing?.kind ?? EnergyKind.gas,
        label: existing?.label ?? '',
        first: existing?.amount,
        firstLabel: l10n.energyAmount,
        deletable: existing != null,
      ),
    );
    if (result == null) return;

    final remaining = [
      for (final item in _plan.reserves)
        if (item.id != existing?.id) item,
    ];
    if (result.deleted) {
      await _write(EnergyPlan(reserves: remaining, draws: _plan.draws));
      return;
    }
    await _write(
      EnergyPlan(
        reserves: [
          ...remaining,
          EnergyReserve(
            id: existing?.id ?? const Uuid().v4(),
            kind: result.kind,
            label: result.label,
            amount: result.first,
          ),
        ],
        draws: _plan.draws,
      ),
    );
  }

  Future<void> _editDraw([EnergyDraw? existing]) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<_EntryResult>(
      context: context,
      builder: (context) => _EntryDialog(
        title: existing == null ? l10n.energyAddDraw : l10n.energyEditDraw,
        kind: existing?.kind ?? EnergyKind.gas,
        label: existing?.label ?? '',
        first: existing?.perHour,
        firstLabel: l10n.energyPerHour,
        second: existing?.hoursPerDay,
        secondLabel: l10n.energyHoursPerDay,
        deletable: existing != null,
      ),
    );
    if (result == null) return;

    final remaining = [
      for (final item in _plan.draws)
        if (item.id != existing?.id) item,
    ];
    if (result.deleted) {
      await _write(EnergyPlan(reserves: _plan.reserves, draws: remaining));
      return;
    }
    await _write(
      EnergyPlan(
        reserves: _plan.reserves,
        draws: [
          ...remaining,
          EnergyDraw(
            id: existing?.id ?? const Uuid().v4(),
            kind: result.kind,
            label: result.label,
            perHour: result.first,
            hoursPerDay: result.second ?? 1,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ranges = energyRanges(
      reserves: _plan.reserves,
      draws: _plan.draws,
    );
    final shortest = firstToRunOut(ranges);

    String number(double value) => NumberFormat.decimalPattern(
      l10n.localeName,
    ).format(double.parse(value.toStringAsFixed(2)));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.energyTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AdaptiveColumns(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              // Four blocks: the answer, what is stored, what draws on
              // it, and the rules of thumb. On a desktop window they sit
              // beside each other instead of one 1400 px column with
              // "Strom" at one edge and "14 Tage" at the other.
              blocks: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.energyIntro),
                    const SizedBox(height: 16),

                    if (_plan.isEmpty) ...[
                      Text(
                        l10n.energyNothingYet,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.energyNothingYetWhy),
                      const SizedBox(height: 16),
                    ] else ...[
                      // The answer first. Everything under it is the working.
                      if (shortest?.days case final days?)
                        Card(
                          margin: EdgeInsets.zero,
                          color: theme.colorScheme.surfaceContainerHigh,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.energyShortest(
                                    localizeEnergyKind(l10n, shortest!.kind),
                                    localizeEnergyDays(l10n, days)!,
                                  ),
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(l10n.energyShortestWhy),
                              ],
                            ),
                          ),
                        )
                      else
                        Text(l10n.energyNoAnswer),
                      const SizedBox(height: 16),

                      for (final range in ranges)
                        _RangeCard(range: range, l10n: l10n, number: number),
                    ],
                  ],
                ),

                _ListSection(
                  title: l10n.energyReserves,
                  addLabel: l10n.energyAddReserve,
                  onAdd: _editReserve,
                  rows: [
                    for (final reserve in _plan.reserves)
                      (
                        title: reserve.label.isEmpty
                            ? localizeEnergyKind(l10n, reserve.kind)
                            : reserve.label,
                        subtitle:
                            '${localizeEnergyKind(l10n, reserve.kind)} · '
                            '${number(reserve.amount)} '
                            '${localizeEnergyUnit(l10n, reserve.kind.unit)}',
                        onTap: () => _editReserve(reserve),
                      ),
                  ],
                ),
                _ListSection(
                  title: l10n.energyDraws,
                  addLabel: l10n.energyAddDraw,
                  onAdd: _editDraw,
                  rows: [
                    for (final draw in _plan.draws)
                      (
                        title: draw.label.isEmpty
                            ? localizeEnergyKind(l10n, draw.kind)
                            : draw.label,
                        subtitle:
                            '${localizeEnergyKind(l10n, draw.kind)} · '
                            '${number(draw.perHour)} '
                            '${localizeEnergyUnit(l10n, draw.kind.unit)}/h · '
                            '${number(draw.hoursPerDay)} h',
                        onTap: () => _editDraw(draw),
                      ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.energyHelperTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(l10n.energyHelperGasBottle),
                            const SizedBox(height: 8),
                            Text(l10n.energyHelperCandles),
                            const SizedBox(height: 8),
                            Text(l10n.energyHelperPowerbank),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.energySources, style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
    );
  }
}

/// One kind: what is stored, what draws on it, and how long that lasts.
class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.range,
    required this.l10n,
    required this.number,
  });

  final EnergyRange range;
  final AppLocalizations l10n;
  final String Function(double) number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = localizeEnergyUnit(l10n, range.kind.unit);
    final days = localizeEnergyDays(l10n, range.days);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizeEnergyKind(l10n, range.kind),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (days != null)
                  Text(
                    days,
                    style: theme.textTheme.titleMedium?.copyWith(
                      // Coloured only where it is nothing, the same rule
                      // the fire-danger scale follows: a colour that is
                      // always on says nothing when it matters.
                      color: range.days == 0 ? theme.colorScheme.error : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (range.unused)
              Text(l10n.energyUnused, style: theme.textTheme.bodySmall)
            else if (range.empty)
              Text(l10n.energyEmpty, style: theme.textTheme.bodySmall)
            else
              // The working, said out loud: a range nobody can check is a
              // range nobody will act on.
              Text(
                l10n.energyPerDayIs(
                  number(range.perDay),
                  unit,
                  number(range.stored),
                ),
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

typedef _Row = ({String title, String subtitle, VoidCallback onTap});

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.rows,
  });

  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            IconButton.filledTonal(
              tooltip: addLabel,
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (rows.isNotEmpty)
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < rows.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    title: Text(rows[index].title),
                    subtitle: Text(rows[index].subtitle),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: rows[index].onTap,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _EntryResult {
  const _EntryResult({
    required this.kind,
    required this.label,
    required this.first,
    this.second,
  }) : deleted = false;

  const _EntryResult.deleted()
    : kind = EnergyKind.gas,
      label = '',
      first = 0,
      second = null,
      deleted = true;

  final EnergyKind kind;
  final String label;
  final double first;
  final double? second;
  final bool deleted;
}

/// Adds or changes one row of either list.
///
/// One dialog for both, because they are the same shape: a kind, a name
/// and one or two numbers. What differs is what the numbers are called,
/// and the caller says that.
class _EntryDialog extends StatefulWidget {
  const _EntryDialog({
    required this.title,
    required this.kind,
    required this.label,
    required this.first,
    required this.firstLabel,
    this.second,
    this.secondLabel,
    required this.deletable,
  });

  final String title;
  final EnergyKind kind;
  final String label;
  final double? first;
  final String firstLabel;
  final double? second;
  final String? secondLabel;
  final bool deletable;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late var _kind = widget.kind;
  late final _label = TextEditingController(text: widget.label);
  late final _first = TextEditingController(
    text: widget.first == null ? '' : _plain(widget.first!),
  );
  late final _second = TextEditingController(
    text: widget.second == null ? '' : _plain(widget.second!),
  );

  String? _labelProblem;
  String? _firstProblem;
  String? _secondProblem;

  static String _plain(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();

  @override
  void dispose() {
    _label.dispose();
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  /// Reads a number typed on a German keyboard as readily as on an
  /// English one — a comma is a decimal point here, not a thousands
  /// separator, because nobody stocks four thousand cartridges.
  static double? _number(String input) =>
      double.tryParse(input.trim().replaceAll(',', '.'));

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final first = _number(_first.text);
    final second = widget.secondLabel == null ? null : _number(_second.text);

    setState(() {
      _labelProblem = _label.text.trim().isEmpty
          ? l10n.energyLabelNeeded
          : null;
      _firstProblem = first == null || first <= 0
          ? l10n.energyNumberNeeded
          : null;
      _secondProblem =
          widget.secondLabel != null && (second == null || second <= 0)
          ? l10n.energyNumberNeeded
          : null;
    });
    if (_labelProblem != null ||
        _firstProblem != null ||
        _secondProblem != null) {
      return;
    }

    Navigator.pop(
      context,
      _EntryResult(
        kind: _kind,
        label: _label.text.trim(),
        first: first!,
        second: second,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unit = localizeEnergyUnit(l10n, _kind.unit);

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<EnergyKind>(
              initialValue: _kind,
              decoration: InputDecoration(labelText: l10n.energyKind),
              items: [
                for (final kind in EnergyKind.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(localizeEnergyKind(l10n, kind)),
                  ),
              ],
              onChanged: (kind) => setState(() => _kind = kind ?? _kind),
            ),
            const SizedBox(height: 4),
            // What the unit means, next to the field that uses it. This
            // is where an answer goes wrong by a factor of a thousand.
            Text(
              localizeEnergyKindHint(l10n, _kind),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextField(
              controller: _label,
              decoration: InputDecoration(
                labelText: l10n.energyLabel,
                errorText: _labelProblem,
              ),
            ),
            TextField(
              controller: _first,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: widget.secondLabel == null
                    ? '${widget.firstLabel} ($unit)'
                    : '${widget.firstLabel} ($unit/h)',
                errorText: _firstProblem,
              ),
            ),
            if (widget.secondLabel case final label?)
              TextField(
                controller: _second,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  errorText: _secondProblem,
                ),
              ),
          ],
        ),
      ),
      actions: [
        if (widget.deletable)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _EntryResult.deleted()),
            child: Text(l10n.energyDelete),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.saveButton)),
      ],
    );
  }
}

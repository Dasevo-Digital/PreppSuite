import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/adaptive_columns.dart';
import '../../../core/settings_arrival.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../household/application/german_states.dart';
import '../../household/application/household_providers.dart';
import '../application/broadcast_radio.dart';

/// Which radio programme informs here when the internet is gone, and the
/// household's own frequencies for them (#267). See `broadcast_radio.dart`
/// for why the app names programmes and leaves frequencies to the
/// household.
///
/// Works without a household as well, and then asks for the Land.
class BroadcastRadioScreen extends ConsumerStatefulWidget {
  const BroadcastRadioScreen({super.key}) : withHousehold = true;

  /// For the emergency access in front of a locked or broken household
  /// (`emergency_access.dart`), which shows nothing private (#269). The
  /// household's Land and the frequencies it wrote down are both a
  /// pointer to where it lives, so here the page asks for the Land, shows
  /// no frequencies and takes none.
  const BroadcastRadioScreen.withoutHousehold({super.key})
    : withHousehold = false;

  final bool withHousehold;

  @override
  ConsumerState<BroadcastRadioScreen> createState() =>
      _BroadcastRadioScreenState();
}

class _BroadcastRadioScreenState extends ConsumerState<BroadcastRadioScreen>
    with RereadOnSettingsArrival {
  static const _store = BroadcastFrequencyStore();

  /// Chosen here; until then the household's own Land.
  String? _chosenState;
  Map<String, double> _frequencies = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Frequencies are the household's, and another device's arrive here.
  @override
  void settingsArrived() => unawaited(_load());

  Future<void> _load() async {
    if (!widget.withHousehold) return;
    final frequencies = await _store.load();
    if (mounted) setState(() => _frequencies = frequencies);
  }

  String? get _householdState {
    if (!widget.withHousehold) return null;
    final region = ref.watch(householdProfileProvider).value?.regionKey;
    return region == null
        ? null
        : germanStateForKreisSchluessel(region)?.bbkCode;
  }

  Future<void> _editFrequency(BroadcastProgramme programme) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<_FrequencyAnswer>(
      context: context,
      builder: (_) => _FrequencyDialog(
        programme: programme,
        current: _frequencies[programme.id],
        l10n: l10n,
      ),
    );
    if (result == null) return;
    final updated = await _store.set(programme.id, result.mhz);
    if (mounted) setState(() => _frequencies = updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = _chosenState ?? _householdState;
    final programmes = state == null
        ? const <BroadcastProgramme>[]
        : broadcastProgrammesByState[state] ?? const [];
    final stateName = state == null
        ? null
        : germanStateByBbkCode(state)?.nameDe;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.broadcastRadioTitle)),
      body: AdaptiveColumns(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        blocks: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.broadcastRadioIntro),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                // A FormField reads `initialValue` once; keyed, it follows
                // the household's Land when that arrives after the first
                // frame.
                key: ValueKey(state),
                initialValue: state,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.broadcastRadioState,
                  border: const OutlineInputBorder(),
                ),
                hint: Text(l10n.broadcastRadioChooseState),
                items: [
                  for (final each in germanStates)
                    DropdownMenuItem(
                      value: each.bbkCode,
                      child: Text(each.nameDe),
                    ),
                ],
                onChanged: (value) => setState(() => _chosenState = value),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (final programme in [...programmes, deutschlandfunk])
                      _ProgrammeTile(
                        programme: programme,
                        stateName: stateName,
                        frequency: _frequencies[programme.id],
                        l10n: l10n,
                        onEdit: widget.withHousehold
                            ? () => _editFrequency(programme)
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.broadcastRadioTuneTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.broadcastRadioTuneUkw),
                  const SizedBox(height: 10),
                  Text(l10n.broadcastRadioTuneDab),
                  const SizedBox(height: 10),
                  Text(
                    widget.withHousehold
                        ? l10n.broadcastRadioTuneNow
                        : l10n.broadcastRadioLockedNote,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final programme in {
                        for (final each in [...programmes, deutschlandfunk])
                          each.website: each,
                      }.values)
                        TextButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(programme.website),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(
                            l10n.broadcastRadioLookUp(
                              Uri.parse(programme.website).host,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Text(
            l10n.broadcastRadioSource,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProgrammeTile extends StatelessWidget {
  const _ProgrammeTile({
    required this.programme,
    required this.stateName,
    required this.frequency,
    required this.l10n,
    required this.onEdit,
  });

  final BroadcastProgramme programme;
  final String? stateName;
  final double? frequency;
  final AppLocalizations l10n;

  /// Null where frequencies are not the page's to show (#269).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final role = switch (programme.role) {
      BroadcastRole.state => l10n.broadcastRadioRoleState(stateName ?? ''),
      BroadcastRole.news => l10n.broadcastRadioRoleNews,
      BroadcastRole.national => l10n.broadcastRadioRoleNational,
    };
    final reach = switch (programme.ukwOnlyIn) {
      final place? => l10n.broadcastRadioDabUkwOnlyIn(place),
      null => l10n.broadcastRadioUkwAndDab,
    };
    final mhz = frequency;
    return ListTile(
      leading: const Icon(Icons.radio),
      title: Text(programme.name),
      subtitle: Text('$role · ${programme.broadcaster} · $reach'),
      trailing: onEdit == null
          ? null
          : TextButton(
              onPressed: onEdit,
              child: Text(
                mhz == null
                    ? l10n.broadcastRadioFrequencyAdd
                    : l10n.broadcastRadioFrequencyHere(
                        _megahertz(mhz, l10n.localeName),
                      ),
              ),
            ),
    );
  }
}

/// What the dialog was closed with: a frequency, or none to remove it.
class _FrequencyAnswer {
  const _FrequencyAnswer(this.mhz);
  final double? mhz;
}

class _FrequencyDialog extends StatefulWidget {
  const _FrequencyDialog({
    required this.programme,
    required this.current,
    required this.l10n,
  });

  final BroadcastProgramme programme;
  final double? current;
  final AppLocalizations l10n;

  @override
  State<_FrequencyDialog> createState() => _FrequencyDialogState();
}

class _FrequencyDialogState extends State<_FrequencyDialog> {
  late final _field = TextEditingController(
    text: widget.current == null
        ? ''
        : _megahertz(widget.current!, widget.l10n.localeName),
  );
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _field.text.trim();
    if (text.isEmpty) {
      Navigator.pop(context, const _FrequencyAnswer(null));
      return;
    }
    final mhz = parseUkwFrequency(text);
    if (mhz == null) {
      setState(() => _error = widget.l10n.broadcastRadioFrequencyInvalid);
      return;
    }
    Navigator.pop(context, _FrequencyAnswer(mhz));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.broadcastRadioFrequencyTitle(widget.programme.name)),
      content: TextField(
        controller: _field,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          helperText: l10n.broadcastRadioFrequencyHint,
          helperMaxLines: 3,
          errorText: _error,
          errorMaxLines: 3,
          suffixText: 'MHz',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.saveButton)),
      ],
    );
  }
}

/// 95.6 as "95,6" where the language writes a decimal comma; two places
/// only where the frequency has them (95.85).
String _megahertz(double mhz, String localeName) {
  final hundredths = (mhz * 100).round();
  final text = hundredths % 10 == 0
      ? (hundredths / 100).toStringAsFixed(1)
      : (hundredths / 100).toStringAsFixed(2);
  return localeName.startsWith('en') ? text : text.replaceAll('.', ',');
}

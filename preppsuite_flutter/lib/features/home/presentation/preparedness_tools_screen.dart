import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/drill_progress_store.dart';

/// A deliberately small, offline exercise and incident guide. It does not
/// create a cloud account or transmit a "safe" status; contacts remain under
/// the user's control in the emergency directory.
class PreparednessToolsScreen extends StatefulWidget {
  const PreparednessToolsScreen({super.key});

  @override
  State<PreparednessToolsScreen> createState() =>
      _PreparednessToolsScreenState();
}

class _PreparednessToolsScreenState extends State<PreparednessToolsScreen> {
  static const _store = DrillProgressStore();

  Set<String> _checked = {};
  Map<String, DateTime> _completed = {};

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final result = await Future.wait([_store.load(), _store.loadCompleted()]);
    if (mounted) {
      setState(() {
        _checked = result[0] as Set<String>;
        _completed = result[1] as Map<String, DateTime>;
      });
    }
  }

  void _toggle(_Scenario scenario, String step, {required bool on}) {
    final key = '${scenario.id}:$step';
    final updated = {..._checked};
    if (on) {
      updated.add(key);
    } else {
      updated.remove(key);
    }
    setState(() {
      _checked = updated;
    });
    unawaited(_store.save(updated));
    if (on &&
        scenario.steps.every(
          (item) => updated.contains('${scenario.id}:$item'),
        )) {
      final completedAt = DateTime.now();
      setState(() => _completed = {..._completed, scenario.id: completedAt});
      unawaited(_store.markCompleted(scenario.id, completedAt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.drillsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.drillsEmergencyMode,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.drillsImmediateDanger),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: '112')),
                    icon: const Icon(Icons.call),
                    label: Text(l10n.drillsCallEmergency),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.drillsSectionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // Ticks outlive the screen now, so there has to be a way
              // back to zero — otherwise the second run of a drill starts
              // already finished.
              if (_checked.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(_checked.clear);
                    unawaited(_store.clear());
                  },
                  child: Text(l10n.drillsReset),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.drillsHarmless),
          const SizedBox(height: 8),
          for (final scenario in _scenarios)
            Card(
              child: ExpansionTile(
                title: Text(scenario.title),
                subtitle: Text(
                  switch (_completed[scenario.id]) {
                    final DateTime completed =>
                      '${scenario.duration} · ${l10n.drillsLastCompleted(MaterialLocalizations.of(context).formatMediumDate(completed))}',
                    null => scenario.duration,
                  },
                ),
                children: [
                  for (final step in scenario.steps)
                    CheckboxListTile(
                      value: _checked.contains('${scenario.id}:$step'),
                      title: Text(step),
                      onChanged: (value) =>
                          _toggle(scenario, step, on: value == true),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Scenario {
  const _Scenario(this.id, this.title, this.duration, this.steps);
  final String id;
  final String title;
  final String duration;
  final List<String> steps;
}

/// The drills themselves, in German only.
///
/// Unlike the labels above, this is content rather than interface: three
/// scenarios from the BBK's own guidance with fifteen strings between
/// them. Translating civil-protection instructions is not a code change,
/// and a half-translated drill is worse than an untranslated one — so
/// until somebody writes the English, it stays as it is and stays visible
/// here rather than hiding in the widget tree.
const _scenarios = [
  _Scenario(
    'power-outage',
    '72 Stunden ohne Strom',
    'Vorbereitung: 20 Minuten',
    [
      'Licht, Radio und Powerbank bereitlegen',
      'Wasser, Kocher und Vorräte prüfen',
      'Kühlgeräte geschlossen halten',
    ],
  ),
  _Scenario(
    'evacuation',
    'Evakuierung in 15 Minuten',
    'Vorbereitung: 15 Minuten',
    [
      'Dokumente und Medikamente einpacken',
      'Treffpunkt und Weg auf Offlinekarte prüfen',
      'Haushaltsmitglieder und Kontaktweg abgleichen',
    ],
  ),
  _Scenario(
    'communication',
    'Kommunikation ausgefallen',
    'Vorbereitung: 10 Minuten',
    [
      'Lokales Radio und Warnungen prüfen',
      'Nahe Kontakte und Treffpunkt bereithalten',
      'Funkgerät nur im erlaubten Funkdienst einsetzen',
    ],
  ),
];

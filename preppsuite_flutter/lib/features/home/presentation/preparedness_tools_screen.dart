import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../preparedness/presentation/preparedness_hub_screen.dart';
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
  final Map<String, bool> _learningAnswers = {};

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
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_special_outlined),
              title: const Text('Krisenorganisation'),
              subtitle: const Text(
                'Radio, Notfallmappe, Wartung, Evakuierungs-Karten und Ereignisprotokoll',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PreparednessHubScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kurz lernen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'Kurze Offline-Wiederholungen ergänzen Übungen und Wissensarchiv.',
          ),
          const SizedBox(height: 8),
          for (final lesson in _lessons)
            Card(
              child: ExpansionTile(
                leading: Icon(lesson.icon),
                title: Text(lesson.title),
                subtitle: Text(lesson.summary),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(lesson.question),
                  const SizedBox(height: 8),
                  for (final answer in lesson.answers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: OutlinedButton(
                        onPressed: () => setState(
                          () => _learningAnswers[lesson.id] =
                              lesson.answers.indexOf(answer) ==
                              lesson.correctAnswer,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(answer),
                        ),
                      ),
                    ),
                  if (_learningAnswers.containsKey(lesson.id))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _learningAnswers[lesson.id] == true
                            ? 'Richtig. ${lesson.explanation}'
                            : 'Noch einmal nachsehen: ${lesson.explanation}',
                        style: TextStyle(
                          color: _learningAnswers[lesson.id] == true
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
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

class _Lesson {
  const _Lesson(
    this.id,
    this.icon,
    this.title,
    this.summary,
    this.question,
    this.answers,
    this.correctAnswer,
    this.explanation,
  );
  final String id, title, summary, question, explanation;
  final IconData icon;
  final List<String> answers;
  final int correctAnswer;
}

const _lessons = [
  _Lesson(
    'communication',
    Icons.forum_outlined,
    'Kommunikation',
    'Netze entlasten und Kontakte koordinieren.',
    'Welcher Weg ist bei überlastetem Mobilfunk meist sinnvoll?',
    [
      'Langer Anruf',
      'Kurze Nachricht mit Rückmeldezeit',
      'Fortlaufend neu wählen',
    ],
    1,
    'Kurze Nachrichten benötigen weniger Netzkapazität und schonen den Akku.',
  ),
  _Lesson(
    'evacuation',
    Icons.route_outlined,
    'Evakuierung',
    'Plan, Notgepäck und Treffpunkt bereithalten.',
    'Was sollte vor einer Evakuierung geprüft werden?',
    [
      'Treffpunkt, Weg und benötigte Unterstützung',
      'Nur die Wetter-App',
      'Nur der Tankstand',
    ],
    0,
    'Ein klarer Treffpunkt, der Weg und individuelle Bedarfe verhindern Stress und Fehlentscheidungen.',
  ),
  _Lesson(
    'power',
    Icons.battery_charging_full_outlined,
    'Stromausfall',
    'Licht, Information und Energie sichern.',
    'Wofür dient das batteriebetriebene oder Kurbelradio?',
    [
      'Als Ersatz für amtliche Warnungen',
      'Als zusätzlicher Informationskanal',
      'Nur zum Musikhören',
    ],
    1,
    'Radio ergänzt Systemwarnungen und funktioniert auch bei ausgefallenem Internet.',
  ),
];

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

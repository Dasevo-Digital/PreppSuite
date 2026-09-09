import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _checked = <String>{};

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notfallmodus und Übungen')),
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
                  'Notfallmodus',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bei unmittelbarer Gefahr zuerst 112 wählen. Danach amtliche Warnungen prüfen, Angehörige nach dem Haushaltsplan informieren und Strom sparen.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: '112')),
                  icon: const Icon(Icons.call),
                  label: const Text('112 anrufen'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Übungsmodus', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text(
          'Die Übung verändert keine Vorräte und verschickt keine Nachrichten.',
        ),
        const SizedBox(height: 8),
        for (final scenario in _scenarios)
          Card(
            child: ExpansionTile(
              title: Text(scenario.title),
              subtitle: Text(scenario.duration),
              children: [
                for (final step in scenario.steps)
                  CheckboxListTile(
                    value: _checked.contains('${scenario.title}:$step'),
                    title: Text(step),
                    onChanged: (value) => setState(() {
                      final key = '${scenario.title}:$step';
                      if (value == true) {
                        _checked.add(key);
                      } else {
                        _checked.remove(key);
                      }
                    }),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _Scenario {
  const _Scenario(this.title, this.duration, this.steps);
  final String title;
  final String duration;
  final List<String> steps;
}

const _scenarios = [
  _Scenario('72 Stunden ohne Strom', 'Vorbereitung: 20 Minuten', [
    'Licht, Radio und Powerbank bereitlegen',
    'Wasser, Kocher und Vorräte prüfen',
    'Kühlgeräte geschlossen halten',
  ]),
  _Scenario('Evakuierung in 15 Minuten', 'Vorbereitung: 15 Minuten', [
    'Dokumente und Medikamente einpacken',
    'Treffpunkt und Weg auf Offlinekarte prüfen',
    'Haushaltsmitglieder und Kontaktweg abgleichen',
  ]),
  _Scenario('Kommunikation ausgefallen', 'Vorbereitung: 10 Minuten', [
    'Lokales Radio und Warnungen prüfen',
    'Nahe Kontakte und Treffpunkt bereithalten',
    'Funkgerät nur im erlaubten Funkdienst einsetzen',
  ]),
];

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Offline reference for radio users. Frequencies are centres of activity,
/// never a promise that a station is listening or a substitute for 112.
class RadioEmergencyScreen extends StatelessWidget {
  const RadioEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.radioEmergencyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _IntroCard(text: l10n.radioEmergencyIntro),
          const SizedBox(height: 20),
          _SectionTitle(text: l10n.radioCbTitle),
          const SizedBox(height: 8),
          _FrequencyCard(
            color: Theme.of(context).colorScheme.tertiary,
            rows: const [
              _FrequencyRow(
                'Kanal 9 AM',
                '27,065 MHz',
                'Üblicher Anruf- und Hilfekanal im CB-Funk.',
              ),
              _FrequencyRow(
                'Kanal 19 FM',
                '27,185 MHz',
                'Häufig genutzter Straßen- und Fernfahrkanal.',
              ),
            ],
          ),
          _HintCard(
            title: l10n.radioCbHintsTitle,
            lines: [
              l10n.radioCbRule,
              l10n.radioListenFirst,
              l10n.radioEmergencyCall,
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(text: l10n.radioAmateurTitle),
          _HintCard(
            title: l10n.radioLegalTitle,
            lines: [l10n.radioAmateurLegal, l10n.radioNoGuaranteedMonitoring],
          ),
          const SizedBox(height: 8),
          _FrequencyCard(
            color: Theme.of(context).colorScheme.primary,
            rows: const [
              _FrequencyRow('80 m · LSB', '3,760 MHz', 'IARU Region 1'),
              _FrequencyRow('40 m · LSB', '7,110 MHz', 'IARU Region 1'),
              _FrequencyRow('20 m · USB', '14,300 MHz', 'International'),
              _FrequencyRow('17 m · USB', '18,160 MHz', 'International'),
              _FrequencyRow('15 m · USB', '21,360 MHz', 'International'),
              _FrequencyRow('2 m · FM', '145,500 MHz', 'Regionaler Anrufkanal'),
              _FrequencyRow(
                '70 cm · FM',
                '433,500 MHz',
                'Regionaler Anrufkanal',
              ),
            ],
          ),
          _HintCard(
            title: l10n.radioUseHintsTitle,
            lines: [l10n.radioListenFirst, l10n.radioBriefMessage],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://www.bundesnetzagentur.de/865198'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.radioOfficialRules),
          ),
          TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(
                'https://www.darc.de/fileadmin/filemounts/distrikte/i/Notfunk/Notfunkfrequenzen.pdf',
              ),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.radioIaruSource),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleLarge,
  );
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
  );
}

class _FrequencyCard extends StatelessWidget {
  const _FrequencyCard({required this.color, required this.rows});
  final Color color;
  final List<_FrequencyRow> rows;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          ListTile(
            leading: Icon(Icons.settings_input_antenna_outlined, color: color),
            title: Text(rows[index].label),
            subtitle: Text('${rows[index].frequency}\n${rows[index].detail}'),
            isThreeLine: true,
          ),
          if (index + 1 < rows.length) const Divider(height: 1),
        ],
      ],
    ),
  );
}

class _FrequencyRow {
  const _FrequencyRow(this.label, this.frequency, this.detail);
  final String label;
  final String frequency;
  final String detail;
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.title, required this.lines});
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            for (final line in lines) ...[
              const SizedBox(height: 10),
              Text(line),
            ],
          ],
        ),
      ),
    ),
  );
}

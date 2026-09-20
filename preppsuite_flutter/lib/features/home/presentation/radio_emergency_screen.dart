import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/adaptive_columns.dart';
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
      body: AdaptiveColumns(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        // One band per block. On a wide window the three sit beside each
        // other, which is also how they are compared.
        blocks: [
          _IntroCard(text: l10n.radioEmergencyIntro),

          _Band(
            children: [
              // First, because these are the two bands a household is most
              // likely to already own and the only ones here that need
              // neither a licence nor an examination. They are also the only
              // ones that keep working with no infrastructure whatsoever —
              // which is the case this screen exists for.
              _SectionTitle(text: l10n.radioEverydayTitle),
              const SizedBox(height: 4),
              Text(l10n.radioEverydayIntro),
              const SizedBox(height: 12),
              _RuleCard(
                title: l10n.radioPmrTitle,
                headline: l10n.radioPmrRange,
                lines: [
                  l10n.radioPmrChannels,
                  l10n.radioPmrPower,
                  l10n.radioPmrAntenna,
                  l10n.radioPmrPeerToPeer,
                ],
                source: l10n.radioPmrSource,
              ),
              const SizedBox(height: 12),
              _RuleCard(
                title: l10n.radioFreenetTitle,
                headline: l10n.radioFreenetRange,
                lines: [
                  l10n.radioFreenetAnalogue,
                  l10n.radioFreenetDigital,
                  l10n.radioFreenetPower,
                  l10n.radioFreenetHandheld,
                  l10n.radioFreenetAntenna,
                  l10n.radioFreenetPeerToPeer,
                  l10n.radioFreenetDuration,
                  l10n.radioFreenetExtras,
                  l10n.radioFreenetGermanyOnly,
                ],
                source: l10n.radioFreenetSource,
              ),
              // The six analogue channels written out, because they are the
              // ones a radio is set to by hand. The twelve digital ones are
              // said as a count in the card above rather than listed: a
              // digital radio is programmed from a file, not from a screen.
              const SizedBox(height: 8),
              _FrequencyCard(
                color: Theme.of(context).colorScheme.secondary,
                rows: const [
                  _FrequencyRow('Freenet 1', '149,0250 MHz', '12,5 kHz'),
                  _FrequencyRow('Freenet 2', '149,0375 MHz', '12,5 kHz'),
                  _FrequencyRow('Freenet 3', '149,0500 MHz', '12,5 kHz'),
                  _FrequencyRow('Freenet 4', '149,0875 MHz', '12,5 kHz'),
                  _FrequencyRow('Freenet 5', '149,1000 MHz', '12,5 kHz'),
                  _FrequencyRow('Freenet 6', '149,1125 MHz', '12,5 kHz'),
                ],
              ),
              _HintCard(
                title: l10n.radioCallingChannelTitle,
                lines: [
                  l10n.radioCallingChannelNone,
                  l10n.radioCallingChannelThree,
                  l10n.radioCallingChannelNoListener,
                  l10n.radioListenFirst,
                ],
              ),
            ],
          ),
          _Band(
            children: [
              _SectionTitle(text: l10n.radioCbTitle),
              const SizedBox(height: 8),
              _FrequencyCard(
                color: Theme.of(context).colorScheme.tertiary,
                rows: [
                  _FrequencyRow(
                    'Kanal 9 AM',
                    '27,065 MHz',
                    l10n.radioCbCallingChannel,
                  ),
                  _FrequencyRow(
                    'Kanal 19 FM',
                    '27,185 MHz',
                    l10n.radioCbRoadChannel,
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
            ],
          ),
          _Band(
            children: [
              _SectionTitle(text: l10n.radioAmateurTitle),
              _HintCard(
                title: l10n.radioLegalTitle,
                lines: [
                  l10n.radioAmateurLegal,
                  l10n.radioNoGuaranteedMonitoring,
                ],
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
                  _FrequencyRow(
                    '2 m · FM',
                    '145,500 MHz',
                    'Regionaler Anrufkanal',
                  ),
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
        ],
      ),
    );
  }
}

/// One band with everything that belongs to it, kept in one column.
class _Band extends StatelessWidget {
  const _Band({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
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

/// One band's rules, with the allocation they come from named under
/// them.
///
/// The source line is not decoration: every figure on this screen is
/// somebody else's, and a power limit that turns out to be wrong is a
/// fine rather than an inconvenience. Naming the Verfügung is what lets
/// a reader check it, and what makes it obvious when it has been
/// superseded.
class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.title,
    required this.headline,
    required this.lines,
    required this.source,
  });

  final String title;
  final String headline;
  final List<String> lines;
  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            Text(headline, style: theme.textTheme.titleSmall),
            for (final line in lines) ...[
              const SizedBox(height: 8),
              Text(line),
            ],
            const SizedBox(height: 12),
            Text(source, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
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

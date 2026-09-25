import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Iodine tablets, and the two things about them that are easy to get
/// wrong.
///
/// They are the one countermeasure in a radiological emergency that a
/// household holds in its own hand, which is exactly why they are taken
/// too early, too often, or by the wrong people. Two sentences carry this
/// screen: only when the authorities say so, and only against radioactive
/// iodine. Both sit above everything else, because a reader who stops
/// after the first card has still read the part that matters.
///
/// Every line is the BfS's, reproduced. This app states no medical advice
/// of its own — the same rule the first aid guides follow.
class IodineTabletsScreen extends StatelessWidget {
  const IodineTabletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.iodineTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(l10n.iodineIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          _Warning(
            icon: Icons.campaign_outlined,
            title: l10n.iodineOnlyOnOrderTitle,
            body: l10n.iodineOnlyOnOrderBody,
          ),
          const SizedBox(height: 12),
          _Warning(
            icon: Icons.shield_outlined,
            title: l10n.iodineOnlyThyroidTitle,
            body: l10n.iodineOnlyThyroidBody,
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.iodineWhoTitle,
            lines: [
              l10n.iodineWhoUnder45,
              l10n.iodineWhoChildren,
              l10n.iodineWhoPregnant,
              l10n.iodineWhoOver45,
              l10n.iodineWhoThyroid,
            ],
          ),
          _Section(title: l10n.iodineWhenTitle, lines: [l10n.iodineWhenBody]),
          _Section(
            title: l10n.iodineHowOftenTitle,
            lines: [l10n.iodineHowOftenBody],
          ),
          _Section(title: l10n.iodineWhereTitle, lines: [l10n.iodineWhereBody]),
          _Section(title: l10n.iodineRangeTitle, lines: [l10n.iodineRangeBody]),
          const SizedBox(height: 8),
          Text(l10n.iodineSource, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// The two rules that come before everything else on this page.
class _Warning extends StatelessWidget {
  const _Warning({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.onErrorContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: scheme.onErrorContainer)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(child: Text(line)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

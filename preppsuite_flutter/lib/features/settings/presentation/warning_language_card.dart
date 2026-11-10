import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../warnings/application/warning_language_provider.dart';
import '../../warnings/application/warning_translations.dart';
import '../../warnings/presentation/warning_translation_sections.dart';

/// Which second language a warning is shown in, where the BBK sends one
/// (#357).
class WarningLanguageCard extends ConsumerWidget {
  const WarningLanguageCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(warningExtraLanguageProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.warningExtraLanguageTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.warningExtraLanguageHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: ValueKey(current),
              initialValue: current,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.warningExtraLanguageNone),
                ),
                for (final language in warningTranslationLanguages)
                  DropdownMenuItem(
                    value: language,
                    child: Text(warningLanguageName(l10n, language)),
                  ),
              ],
              onChanged: (value) =>
                  ref.read(warningExtraLanguageProvider.notifier).choose(value),
            ),
          ],
        ),
      ),
    );
  }
}

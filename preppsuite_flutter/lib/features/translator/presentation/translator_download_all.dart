import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../downloads/application/byte_size.dart';
import '../application/translator_catalogue.dart';
import '../application/translator_providers.dart';
import '../application/translator_store.dart';

/// "Alle Sprachpakete laden" (#182): every direction Mozilla offers that
/// this device lacks, after saying how many and how much.
///
/// On the translator and beside the map in "Offline und Speicher". The
/// run belongs to [translatorInstallProvider], so it carries on when the
/// screen that started it is left, and both places show the same run.
class TranslatorDownloadAll extends ConsumerStatefulWidget {
  const TranslatorDownloadAll({super.key});

  @override
  ConsumerState<TranslatorDownloadAll> createState() =>
      _TranslatorDownloadAllState();
}

class _TranslatorDownloadAllState extends ConsumerState<TranslatorDownloadAll> {
  /// Mozilla's list being asked for.
  var _asking = false;

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _asking = true);

    final TranslatorCatalogue catalogue;
    final List<InstalledTranslatorPack> installed;
    // Listened to while it loads: the list is an auto-disposed provider,
    // and read on its own it could be thrown away before it answers.
    final keep = ref.listenManual(translatorCatalogueProvider, (_, _) {});
    try {
      catalogue = await ref.read(translatorCatalogueProvider.future);
      installed = await ref.read(installedTranslatorPacksProvider.future);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _asking = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.translatorCatalogueFailed(describeError(l10n, error)),
            ),
          ),
        );
      }
      return;
    } finally {
      keep.close();
    }
    if (!mounted) return;
    setState(() => _asking = false);

    final missing = missingTranslatorPacks(
      catalogue,
      installed.map((pack) => pack.direction),
    );
    if (missing.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.translatorDownloadAllNothing)),
      );
      return;
    }

    final size = missing.fold(0, (sum, pack) => sum + pack.size);
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translatorDownloadAllTitle),
        content: Text(
          l10n.translatorDownloadAllBody(missing.length, formatByteSize(size)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translatorDownload),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    unawaited(
      ref.read(translatorInstallProvider.notifier).installAll(missing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final installs = ref.watch(translatorInstallProvider);

    if (installs.batch case final batch?) {
      final current = installs.progress.values.firstOrNull?.fraction ?? 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.translatorDownloadAllProgress(batch.done, batch.total)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: ((batch.done + current) / batch.total).clamp(0.0, 1.0),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: batch.stopping
                  ? null
                  : ref.read(translatorInstallProvider.notifier).stopAll,
              child: Text(
                batch.stopping
                    ? l10n.translatorDownloadAllStopping
                    : l10n.translatorDownloadAllStop,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _asking ? null : _start,
          icon: _asking
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_for_offline_outlined),
          label: Text(l10n.translatorDownloadAll),
        ),
        if (installs.failed.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            l10n.translatorDownloadAllFailed(installs.failed.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

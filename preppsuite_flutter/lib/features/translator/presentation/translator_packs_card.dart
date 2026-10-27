import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../downloads/application/byte_size.dart';
import '../../knowledge/application/tesseract_data.dart';
import '../application/translator_providers.dart';
import 'translator_download_all.dart';
import 'translator_screen.dart';

/// The translator's language packs beside the map and the archives, in
/// "Offline und Speicher" (#192): what is on the device, how much room it
/// takes, and the way to remove it. Single directions are fetched on the
/// translator's own screen, where it is clear which one a sentence needs;
/// all of them at once can be fetched here too, like the map (#182).
class TranslatorPacksCard extends ConsumerWidget {
  const TranslatorPacksCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(translatorAvailableProvider)) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.g_translate),
          title: Text(l10n.translatorPacksTitle),
          subtitle: Text(l10n.translatorNotInBuild),
        ),
      );
    }
    final installed = ref.watch(installedTranslatorPacksProvider);
    // The text recognition data "Text aus Foto" fetched on Android (#205):
    // the same kind of thing, a language's data for the translator.
    final ocr =
        ref.watch(installedTesseractLanguagesProvider).value ?? const [];
    final ocrData = ref.watch(tesseractDataProvider);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.g_translate),
            title: Text(l10n.translatorPacksTitle),
            subtitle: Text(switch (installed) {
              AsyncData(:final value) when value.isEmpty =>
                l10n.translatorPacksNone,
              AsyncData(:final value) => l10n.translatorPacksSummary(
                value.length,
                formatByteSize(value.fold(0, (sum, p) => sum + p.size)),
              ),
              AsyncError(:final error) => describeError(l10n, error),
              _ => '…',
            }),
          ),
          for (final pack in installed.value ?? const [])
            ListTile(
              dense: true,
              contentPadding: const EdgeInsetsDirectional.only(
                start: 72,
                end: 8,
              ),
              title: Text(
                l10n.translatorDirection(
                  pack.direction.from.endonym,
                  pack.direction.to.endonym,
                ),
              ),
              subtitle: Text(
                l10n.translatorPackVersion(
                  formatByteSize(pack.size),
                  pack.version,
                ),
              ),
              trailing: IconButton(
                tooltip: l10n.translatorRemove,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref
                    .read(translatorInstallProvider.notifier)
                    .remove(pack.direction),
              ),
            ),
          if (ocr.isNotEmpty && ocrData is DownloadedTesseractData) ...[
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(l10n.translatorOcrDataTitle),
              subtitle: Text(
                l10n.translatorOcrDataSummary(
                  ocr.map((language) => language.endonym).join(', '),
                  formatByteSize(
                    ocr.fold(
                      0,
                      (sum, language) =>
                          sum + tesseractLanguages[language]!.size,
                    ),
                  ),
                ),
              ),
            ),
            for (final language in ocr)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsetsDirectional.only(
                  start: 72,
                  end: 8,
                ),
                title: Text(language.endonym),
                subtitle: Text(
                  formatByteSize(tesseractLanguages[language]!.size),
                ),
                trailing: IconButton(
                  tooltip: l10n.translatorRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ocrData.remove(tesseractLanguages[language]!);
                    ref.invalidate(installedTesseractLanguagesProvider);
                  },
                ),
              ),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TranslatorDownloadAll(),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TranslatorScreen(),
                  ),
                ),
                icon: const Icon(Icons.download_outlined),
                label: Text(l10n.translatorPacksOpen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

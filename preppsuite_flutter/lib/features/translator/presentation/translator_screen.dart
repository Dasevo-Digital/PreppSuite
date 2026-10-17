import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../downloads/application/byte_size.dart';
import '../../phrasebook/application/phrasebook.dart';
import '../application/translator_catalogue.dart';
import '../application/translator_providers.dart';
import '../application/translator_store.dart';

/// Free text, translated on this device (#182).
///
/// Beside the phrasebook, not instead of it. The phrasebook's sentences
/// are fixed and can be read through once; this translates anything, and
/// a machine translation is sometimes wrong. The screen says so, every
/// time, under the result.
class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final _input = TextEditingController();
  PhraseLanguage? _from;
  PhraseLanguage? _to;
  String? _result;
  Object? _error;
  var _translating = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final own = PhraseLanguage.forLocale(l10n.localeName);
    final from = _from ?? own;
    final to =
        _to ??
        (own == PhraseLanguage.en ? PhraseLanguage.de : PhraseLanguage.en);

    if (!ref.watch(translatorAvailableProvider)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.translatorTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [Text(l10n.translatorNotInBuild)],
        ),
      );
    }

    final installed =
        ref.watch(installedTranslatorPacksProvider).value ??
        const <InstalledTranslatorPack>[];
    final needed = directionsFor(from, to);
    final present = {for (final pack in installed) pack.direction: pack};
    final missing = [
      for (final direction in needed)
        if (!present.containsKey(direction)) direction,
    ];
    final ready = missing.isEmpty && needed.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translatorTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _LanguageField(
                  label: l10n.translatorFrom,
                  value: from,
                  onChanged: (language) => setState(() {
                    _from = language;
                    _result = null;
                  }),
                ),
              ),
              IconButton(
                tooltip: l10n.translatorSwap,
                icon: const Icon(Icons.swap_horiz),
                onPressed: () => setState(() {
                  _from = to;
                  _to = from;
                  // The answer becomes the question, which is how a reply
                  // is read back.
                  if (_result != null) _input.text = _result!;
                  _result = null;
                }),
              ),
              Expanded(
                child: _LanguageField(
                  label: l10n.translatorTo,
                  value: to,
                  onChanged: (language) => setState(() {
                    _to = language;
                    _result = null;
                  }),
                ),
              ),
            ],
          ),
          if (needed.isEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.translatorSameLanguage),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MissingPacks(missing: missing),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _input,
            minLines: 3,
            maxLines: 8,
            textDirection: from.isRtl ? TextDirection.rtl : null,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.translatorInput,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: ready && !_translating && _input.text.trim().isNotEmpty
                ? () => _translate(needed, present)
                : null,
            icon: _translating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.translate),
            label: Text(l10n.translatorTranslate),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.translatorFailed(describeError(l10n, _error!)),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.translatorResult,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.morseCopy,
                          icon: const Icon(Icons.copy_outlined),
                          onPressed: () => _copy(l10n, _result!),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        _result!,
                        textDirection: to.isRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.translatorMachineNote,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _InstalledPacks(installed: installed),
          const SizedBox(height: 12),
          Text(l10n.translatorSource, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _translate(
    List<TranslatorDirection> needed,
    Map<TranslatorDirection, InstalledTranslatorPack> present,
  ) async {
    setState(() {
      _translating = true;
      _error = null;
    });
    try {
      final result = await ref.read(translateTextProvider)(_input.text, [
        for (final direction in needed) present[direction]!,
      ]);
      if (mounted) setState(() => _result = result);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  Future<void> _copy(AppLocalizations l10n, String text) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.morseCopied)));
  }
}

class _LanguageField extends StatelessWidget {
  const _LanguageField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final PhraseLanguage value;
  final ValueChanged<PhraseLanguage> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<PhraseLanguage>(
    isExpanded: true,
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: [
      for (final language in PhraseLanguage.values)
        DropdownMenuItem(value: language, child: Text(language.endonym)),
    ],
    onChanged: (language) {
      if (language != null) onChanged(language);
    },
  );
}

/// The directions a translation needs and this device lacks, with their
/// size from Mozilla's list and a button each.
class _MissingPacks extends ConsumerWidget {
  const _MissingPacks({required this.missing});

  final List<TranslatorDirection> missing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final catalogue = ref.watch(translatorCatalogueProvider);
    final installs = ref.watch(translatorInstallProvider);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.translatorPacksNeeded,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            ...catalogue.when(
              loading: () => [const LinearProgressIndicator()],
              error: (error, _) => [
                Text(
                  l10n.translatorCatalogueFailed(describeError(l10n, error)),
                  style: TextStyle(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(translatorCatalogueProvider),
                    child: Text(l10n.translatorRetry),
                  ),
                ),
              ],
              data: (list) => [
                for (final direction in missing)
                  _MissingRow(
                    direction: direction,
                    pack: list.packs[direction],
                    progress: installs.progress[direction],
                    failure: installs.failed[direction],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingRow extends ConsumerWidget {
  const _MissingRow({
    required this.direction,
    required this.pack,
    required this.progress,
    required this.failure,
  });

  final TranslatorDirection direction;
  final TranslatorPack? pack;
  final TranslatorInstallProgress? progress;
  final Object? failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSecondaryContainer;
    final name = l10n.translatorDirection(
      direction.from.endonym,
      direction.to.endonym,
    );
    final pack = this.pack;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pack == null
                      ? l10n.translatorPackUnavailable(name)
                      : '$name · ${formatByteSize(pack.size)}',
                  style: TextStyle(color: color),
                ),
              ),
              if (pack != null && progress == null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: color),
                  onPressed: () => ref
                      .read(translatorInstallProvider.notifier)
                      .install(pack),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.translatorDownload),
                ),
            ],
          ),
          if (progress case final p?)
            LinearProgressIndicator(value: p.fraction),
          if (failure case final error?)
            Text(
              l10n.translatorDownloadFailed(describeError(l10n, error)),
              style: TextStyle(color: theme.colorScheme.error),
            ),
        ],
      ),
    );
  }
}

/// What is on this device, and the way to take it off again.
class _InstalledPacks extends ConsumerWidget {
  const _InstalledPacks({required this.installed});

  final List<InstalledTranslatorPack> installed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (installed.isEmpty) return const SizedBox.shrink();
    final total = installed.fold(0, (sum, pack) => sum + pack.size);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.translatorInstalled(formatByteSize(total)),
          style: theme.textTheme.titleSmall,
        ),
        for (final pack in installed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.translatorDirection(
                pack.direction.from.endonym,
                pack.direction.to.endonym,
              ),
            ),
            subtitle: Text(formatByteSize(pack.size)),
            trailing: IconButton(
              tooltip: l10n.translatorRemove,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref
                  .read(translatorInstallProvider.notifier)
                  .remove(pack.direction),
            ),
          ),
      ],
    );
  }
}

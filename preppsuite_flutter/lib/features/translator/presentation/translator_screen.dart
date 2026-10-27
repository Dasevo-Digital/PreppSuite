import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../downloads/application/byte_size.dart';
import '../../knowledge/application/tesseract_data.dart';
import '../../knowledge/application/text_recognition.dart';
import '../../phrasebook/application/phrasebook.dart';
import '../../phrasebook/presentation/phrase_display.dart';
import '../application/photo_text.dart';
import '../application/translator_catalogue.dart';
import '../application/translator_providers.dart';
import '../application/translator_store.dart';
import 'translator_conversation_screen.dart';
import 'translator_download_all.dart';

/// Free text, translated on this device (#182).
///
/// Beside the phrasebook, not instead of it. The phrasebook's sentences
/// are fixed and can be read through once; this translates anything, and
/// a machine translation is sometimes wrong. The screen says so, every
/// time, under the result.
class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({
    super.key,
    this.initialText,
    this.initialFrom,
    this.initialTo,
  });

  /// What the phrasebook's search was given and did not find (#190),
  /// with the languages it was searching in.
  final String? initialText;
  final PhraseLanguage? initialFrom;
  final PhraseLanguage? initialTo;

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  late final _input = TextEditingController(text: widget.initialText);
  late PhraseLanguage? _from = widget.initialFrom;
  late PhraseLanguage? _to = widget.initialTo;
  String? _result;
  Object? _error;
  var _translating = false;
  var _reading = false;

  /// Whether the text in the field came from a photo, and should be
  /// checked before it is translated.
  var _fromPhoto = false;

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
                  _fromPhoto = false;
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
            TranslatorMissingPacks(missing: missing),
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
              helperText: _fromPhoto ? l10n.translatorPhotoNote : null,
              helperMaxLines: 2,
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _reading ? null : () => _readPhoto(from),
                icon: _reading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner_outlined),
                label: Text(
                  _reading
                      ? l10n.translatorPhotoReading
                      : l10n.translatorFromPhoto,
                ),
              ),
              // Both ways, for an answer: the other person writes back in
              // their language (#202).
              OutlinedButton.icon(
                onPressed: needed.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TranslatorConversationScreen(
                            mine: from,
                            theirs: to,
                            opening: _result == null
                                ? null
                                : ConversationTurn(
                                    from: from,
                                    text: _input.text.trim(),
                                    translation: _result,
                                  ),
                          ),
                        ),
                      ),
                icon: const Icon(Icons.forum_outlined),
                label: Text(l10n.translatorConversation),
              ),
            ],
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
                        // Read out and held up: the result is for the person
                        // on the other side, as a phrasebook sentence is
                        // (#189).
                        SpeakPhraseButton(text: _result!, language: to),
                        IconButton(
                          tooltip: l10n.phrasebookShow,
                          icon: const Icon(Icons.open_in_full),
                          onPressed: () => showPhraseLarge(
                            context,
                            target: _result!,
                            source: _input.text.trim(),
                            language: to,
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
          const SizedBox(height: 8),
          const TranslatorDownloadAll(),
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

  /// Text from a photo into the field (#203). Asks whether the engine
  /// can read the language before asking for a photo, so nobody takes a
  /// picture for nothing.
  Future<void> _readPhoto(PhraseLanguage from) async {
    final l10n = AppLocalizations.of(context)!;
    final List<String> languages;
    if (!kIsWeb && readsWithTesseractOn(defaultTargetPlatform)) {
      final chosen = await _tesseractLanguages(from, l10n);
      if (chosen == null || !mounted) return;
      languages = chosen;
    } else {
      languages = recognitionLanguagesFor(from);
    }
    final support = await ref
        .read(textRecognizerProvider)
        .support(languages: languages);
    if (!mounted) return;
    switch (support) {
      case TextRecognitionSupport.available:
        break;
      case TextRecognitionSupport.needsLanguagePack:
        _say(l10n.translatorPhotoNeedsLanguagePack(from.endonym));
        return;
      case TextRecognitionSupport.needsTesseract:
        _say(l10n.knowledgeRecognizeNeedsTesseract);
        return;
      case TextRecognitionSupport.needsLanguageData:
        _say(l10n.translatorPhotoScript);
        return;
      case TextRecognitionSupport.unsupported:
        _say(
          isLatinScript(from)
              ? l10n.knowledgeRecognizeUnsupported
              : l10n.translatorPhotoScript,
        );
        return;
    }

    final source = await _photoSource(l10n);
    if (source == null || !mounted) return;
    final bytes = await ref.read(translatorPhotoPickerProvider)(source);
    if (bytes == null || !mounted) return;

    setState(() => _reading = true);
    try {
      final text = (await ref.read(photoTextReaderProvider)(
        bytes,
        languages,
      )).trim();
      if (!mounted) return;
      if (text.isEmpty) {
        _say(l10n.translatorPhotoNothing);
      } else {
        setState(() {
          _input.text = text;
          _result = null;
          _fromPhoto = true;
        });
      }
    } on Object {
      if (mounted) _say(l10n.knowledgeRecognizeFailed);
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  /// What Tesseract is to read [from] with, after offering the language's
  /// data where it is missing (#205); null when the photo cannot be read
  /// or the person changed their mind.
  Future<List<String>?> _tesseractLanguages(
    PhraseLanguage from,
    AppLocalizations l10n,
  ) async {
    final pack = tesseractLanguages[from];
    final data = ref.read(tesseractDataProvider);
    if (pack == null || data == null) {
      return tesseractRecognitionLanguagesFor(from, hasData: pack == null);
    }
    if (await data.has(pack)) {
      return tesseractRecognitionLanguagesFor(from, hasData: true);
    }
    if (!mounted) return null;

    if (data is DownloadedTesseractData) {
      final latin = isLatinScript(from);
      final size = formatByteSize(pack.size);
      final choice = await showDialog<_DataChoice>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.translatorPhotoDataTitle),
          content: Text(
            latin
                ? l10n.translatorPhotoDataBetter(from.endonym, size)
                : l10n.translatorPhotoDataNeeded(from.endonym, size),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelButton),
            ),
            if (latin)
              TextButton(
                onPressed: () => Navigator.of(context).pop(_DataChoice.without),
                child: Text(l10n.translatorPhotoDataWithout),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_DataChoice.fetch),
              child: Text(l10n.translatorPhotoDataFetch),
            ),
          ],
        ),
      );
      if (!mounted) return null;
      switch (choice) {
        case _DataChoice.fetch:
          return await _fetchData(data, pack, from, l10n)
              ? tesseractRecognitionLanguagesFor(from, hasData: true)
              : null;
        case _DataChoice.without:
          return tesseractRecognitionLanguagesFor(from, hasData: false);
        case null:
          return null;
      }
    }

    // The system's Tesseract: Latin letters without the package, and the
    // package to install for another script.
    if (isLatinScript(from)) {
      return tesseractRecognitionLanguagesFor(from, hasData: false);
    }
    _say(
      l10n.translatorPhotoNeedsTesseractLanguage(
        from.endonym,
        pack.linuxPackage,
      ),
    );
    return null;
  }

  Future<bool> _fetchData(
    DownloadedTesseractData data,
    TesseractLanguage pack,
    PhraseLanguage language,
    AppLocalizations l10n,
  ) async {
    final outcome = await showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DataDownloadDialog(
        progress: data.install(pack),
        total: pack.size,
        title: l10n.translatorPhotoDataLoading(language.endonym),
      ),
    );
    ref.invalidate(installedTesseractLanguagesProvider);
    if (outcome == true) return true;
    if (outcome != null && outcome != false && mounted) {
      _say(l10n.translatorPhotoDataFailed(describeError(l10n, outcome)));
    }
    return false;
  }

  /// The camera where there is one the picker can use -- a phone -- and
  /// the library everywhere. On a computer there is only the library, so
  /// there is nothing to choose.
  Future<ImageSource?> _photoSource(AppLocalizations l10n) async {
    final hasCamera =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!hasCamera) return ImageSource.gallery;
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.translatorPhotoCamera),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.translatorPhotoGallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _say(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

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
class TranslatorMissingPacks extends ConsumerWidget {
  const TranslatorMissingPacks({super.key, required this.missing});

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
      ],
    );
  }
}

enum _DataChoice { fetch, without }

/// Fetching one language's text recognition data, with how far it has
/// got. Pops with true when the data is in place, false when stopped, and
/// the error when it failed.
class _DataDownloadDialog extends StatefulWidget {
  const _DataDownloadDialog({
    required this.progress,
    required this.total,
    required this.title,
  });

  final Stream<int> progress;
  final int total;
  final String title;

  @override
  State<_DataDownloadDialog> createState() => _DataDownloadDialogState();
}

class _DataDownloadDialogState extends State<_DataDownloadDialog> {
  late final StreamSubscription<int> _subscription;
  var _received = 0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.progress.listen(
      (received) => setState(() => _received = received),
      onError: (Object error) {
        if (mounted) Navigator.of(context).pop(error);
      },
      onDone: () {
        if (mounted) Navigator.of(context).pop(true);
      },
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: widget.total == 0
                ? null
                : (_received / widget.total).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 8),
          Text(
            '${formatByteSize(_received)} / ${formatByteSize(widget.total)}',
          ),
        ],
      ),
      actions: [
        TextButton(
          // Stopping keeps what has arrived; the next try picks it up.
          onPressed: () {
            _subscription.cancel();
            Navigator.of(context).pop(false);
          },
          child: Text(l10n.cancelButton),
        ),
      ],
    );
  }
}

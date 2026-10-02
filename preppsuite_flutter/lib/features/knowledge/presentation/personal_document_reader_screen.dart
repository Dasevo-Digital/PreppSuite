import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/platform_storage.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../downloads/application/byte_size.dart';
import '../application/personal_document_index.dart';
import '../application/personal_document_store.dart';

/// Shows a household document inside PreppSuite.
///
/// Files remain at their original location.  The reader only asks the
/// platform for a stream when Android gave us a content URI; it does not copy
/// documents into the application directory or upload them anywhere.
class PersonalDocumentReaderScreen extends StatelessWidget {
  const PersonalDocumentReaderScreen({required this.document, super.key});

  final PersonalDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(document.label),
        actions: [
          IconButton(
            tooltip: l10n.knowledgeDocumentOpenExternal,
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openOutside(context),
          ),
        ],
      ),
      body: switch (document.extension) {
        'pdf' => _PdfReader(document: document),
        _ => _TextReader(document: document),
      },
    );
  }

  Future<void> _openOutside(BuildContext context) async {
    if (await openPersonalDocument(document) || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.knowledgeDocumentOpenFailed,
        ),
      ),
    );
  }
}

class _PdfReader extends StatefulWidget {
  const _PdfReader({required this.document});

  final PersonalDocument document;

  @override
  State<_PdfReader> createState() => _PdfReaderState();
}

/// A PDF is drawn by the PDF renderer, page by page, straight from the
/// file where there is a path. Only an Android document behind a content
/// URI has to be read into memory first, and that read is bounded, shown
/// and can be cancelled like the text reader's.
class _PdfReaderState extends State<_PdfReader> {
  // Started once, not on every rebuild: a future made in `build` read the
  // whole file again whenever the screen was redrawn.
  late final Future<({String? path, Uint8List? bytes})> _source = _load();
  final _received = ValueNotifier<int>(0);
  var _cancelled = false;

  @override
  void dispose() {
    _cancelled = true;
    _received.dispose();
    super.dispose();
  }

  Future<({String? path, Uint8List? bytes})> _load() async {
    var location = widget.document.location;
    if (location.startsWith('bookmark://')) {
      location = await resolveStoragePath(location) ?? location;
    }
    if (!isNativeStorageHandle(location)) return (path: location, bytes: null);
    return (
      path: null,
      bytes: await readPersonalDocumentBytes(
        location,
        maxBytes: personalDocumentByteLimit(),
        onProgress: (received) {
          if (!_cancelled) _received.value = received;
        },
        isCancelled: () => _cancelled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _source,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return ValueListenableBuilder(
          valueListenable: _received,
          builder: (context, received, _) => _ReaderProgress(
            progress: received == 0
                ? null
                : PersonalDocumentReading(received, null),
          ),
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return _ReaderFailure(
          document: widget.document,
          error: snapshot.error,
        );
      }
      final source = snapshot.data!;
      final params = PdfViewerParams(
        backgroundColor: Theme.of(context).colorScheme.surface,
      );
      if (source.path case final path?) {
        return PdfViewer.file(path, params: params);
      }
      return PdfViewer.data(
        source.bytes!,
        sourceName: widget.document.label,
        params: params,
      );
    },
  );
}

class _TextReader extends StatefulWidget {
  const _TextReader({required this.document});

  final PersonalDocument document;

  @override
  State<_TextReader> createState() => _TextReaderState();
}

/// EPUB and Markdown, as selectable text the app lays out itself.
///
/// Read and extracted by [PersonalDocumentTextJob], away from the
/// interface, and laid out one paragraph at a time by a lazy list. Both
/// halves used to happen here, on the interface's thread: the extraction
/// in full, then the whole text as a single paragraph of up to four
/// million characters. A large EPUB froze the screen twice over.
class _TextReaderState extends State<_TextReader> {
  final _scroll = ScrollController();
  late final PersonalDocumentTextJob _job;
  PersonalDocumentProgress? _progress;
  PersonalDocumentText? _text;
  Object? _error;
  var _restored = false;
  var _lastSaved = 0.0;

  @override
  void initState() {
    super.initState();
    _lastSaved = widget.document.readerOffset;
    _scroll.addListener(_saveIfNeeded);
    _job = PersonalDocumentTextJob.start(widget.document);
    _job.progress.listen((progress) {
      if (mounted) setState(() => _progress = progress);
    });
    _job.result.then(
      (text) {
        if (mounted) setState(() => _text = text);
      },
      onError: (Object error) {
        if (mounted && error is! PersonalDocumentCancelled) {
          setState(() => _error = error);
        }
      },
    );
  }

  @override
  void dispose() {
    // Leaving the screen stops the work: nobody is waiting for it any more.
    _job.cancel();
    _scroll.removeListener(_saveIfNeeded);
    unawaited(_save(force: true));
    _scroll.dispose();
    super.dispose();
  }

  void _restorePosition() {
    if (_restored || !_scroll.hasClients) return;
    _restored = true;
    final offset = widget.document.readerOffset
        .clamp(0, _scroll.position.maxScrollExtent)
        .toDouble();
    if (offset > 0) _scroll.jumpTo(offset);
  }

  void _saveIfNeeded() {
    if ((_scroll.offset - _lastSaved).abs() >= 240) {
      unawaited(_save());
    }
  }

  Future<void> _save({bool force = false}) async {
    if (!_scroll.hasClients) return;
    final offset = _scroll.offset;
    if (!force && (offset - _lastSaved).abs() < 240) return;
    _lastSaved = offset;
    await const PersonalDocumentStore().updateReaderOffset(
      widget.document.id,
      offset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    if (_error != null || (text != null && text.paragraphs.isEmpty)) {
      return _ReaderFailure(document: widget.document, error: _error);
    }
    if (text == null) {
      return _ReaderProgress(
        progress: _progress,
        onCancel: () {
          _job.cancel();
          Navigator.of(context).maybePop();
        },
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _restorePosition());
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge?.copyWith(height: 1.55);
    final count = text.paragraphs.length + (text.truncated ? 1 : 0);
    return Scrollbar(
      controller: _scroll,
      child: SelectionArea(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          itemCount: count,
          itemBuilder: (context, index) {
            if (index == text.paragraphs.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  AppLocalizations.of(context)!.knowledgeDocumentTruncated,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(text.paragraphs[index], style: style),
            );
          },
        ),
      ),
    );
  }
}

/// How far the reading has got, and the way out of it.
class _ReaderProgress extends StatelessWidget {
  const _ReaderProgress({required this.progress, this.onCancel});

  final PersonalDocumentProgress? progress;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (value, label) = switch (progress) {
      PersonalDocumentReading(:final received, total: final total?) => (
        total == 0 ? null : received / total,
        l10n.knowledgeDocumentReadingProgress(
          formatByteSize(received),
          formatByteSize(total),
        ),
      ),
      PersonalDocumentReading(:final received) => (
        null,
        l10n.knowledgeDocumentReadingBytes(formatByteSize(received)),
      ),
      PersonalDocumentExtracting(:final done, :final total) => (
        total == 0 ? null : done / total,
        l10n.knowledgeDocumentPreparing(done, total),
      ),
      null => (null, null),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value),
              if (label != null) ...[
                const SizedBox(height: 12),
                Text(label, textAlign: TextAlign.center),
              ],
              if (onCancel != null) ...[
                const SizedBox(height: 16),
                TextButton(onPressed: onCancel, child: Text(l10n.cancelButton)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderFailure extends StatelessWidget {
  const _ReaderFailure({required this.document, this.error});

  final PersonalDocument document;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = this.error;
    final message = switch (error) {
      PersonalDocumentTooLarge(bytes: final bytes?, :final limit) =>
        l10n.knowledgeDocumentTooLargeForReader(
          formatByteSize(bytes),
          formatByteSize(limit),
        ),
      PersonalDocumentTooLarge() => l10n.knowledgeDocumentTooLargeInside,
      _ => l10n.knowledgeDocumentOpenFailed,
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              // The file is fine, only too much for this reader: the
              // system's own app is the way to read it after all.
              OutlinedButton.icon(
                onPressed: () => openPersonalDocument(document),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.knowledgeDocumentOpenExternal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

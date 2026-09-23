import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/platform_storage.dart';
import '../../../l10n/generated/app_localizations.dart';
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

class _PdfReader extends StatelessWidget {
  const _PdfReader({required this.document});

  final PersonalDocument document;

  Future<({String? path, Uint8List? bytes})> _source() async {
    var location = document.location;
    if (location.startsWith('bookmark://')) {
      location = await resolveStoragePath(location) ?? location;
    }
    if (!isNativeStorageHandle(location)) return (path: location, bytes: null);
    return (
      path: null,
      bytes: await readPersonalDocumentBytes(
        location,
        maxBytes: PersonalDocumentIndexer.maxReaderDocumentBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _source(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return _ReaderFailure(document: document);
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
        sourceName: document.label,
        params: params,
      );
    },
  );
}

class _TextReader extends StatelessWidget {
  const _TextReader({required this.document});

  final PersonalDocument document;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: PersonalDocumentIndexer.readForReader(document),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final text = snapshot.data;
      if (snapshot.hasError || text == null || text.isEmpty) {
        return _ReaderFailure(document: document);
      }
      return Scrollbar(
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
            children: [
              Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ReaderFailure extends StatelessWidget {
  const _ReaderFailure({required this.document});

  final PersonalDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.knowledgeDocumentOpenFailed,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

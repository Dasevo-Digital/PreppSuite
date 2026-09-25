import 'package:flutter/material.dart';

import '../../../core/feel.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../maps/application/map_archive_access.dart' show pickMapArchive;
import '../application/document_folder_import.dart';
import '../application/personal_document_index.dart';
import '../application/personal_document_store.dart';
import 'personal_document_reader_screen.dart';

class PersonalDocumentsScreen extends StatefulWidget {
  const PersonalDocumentsScreen({super.key});

  @override
  State<PersonalDocumentsScreen> createState() =>
      _PersonalDocumentsScreenState();
}

class _PersonalDocumentsScreenState extends State<PersonalDocumentsScreen> {
  static const _store = PersonalDocumentStore();
  late Future<List<PersonalDocument>> _documents = _store.load();

  /// How far a folder import has got, or null when none is running.
  ({int done, int total})? _import;

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await pickMapArchive(dialogTitle: l10n.knowledgeDocumentAdd);
    if (picked == null) return;
    final extension = picked.label.split('.').last.toLowerCase();
    if (!const {'pdf', 'epub', 'md', 'markdown'}.contains(extension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.knowledgeDocumentOpenFailed)),
        );
      }
      return;
    }

    final index = await _askToIndex(l10n);
    if (index == null) return;
    final updated = await _store.add(
      location: picked.value,
      label: picked.label,
    );
    final document = updated.firstWhere(
      (item) => item.location == picked.value,
    );
    if (mounted) setState(() => _documents = Future.value(updated));
    if (index) await _index(document);
  }

  /// Takes in what lies in one folder.
  ///
  /// Asked once for the whole folder rather than once per file: the
  /// question is the same for all of them, and forty dialogs is not a
  /// question, it is an obstacle.
  Future<void> _addFolder() async {
    final l10n = AppLocalizations.of(context)!;
    final folder = await pickDocumentFolder(
      dialogTitle: l10n.knowledgeDocumentAddFolder,
    );
    if (folder == null) return;

    final DocumentFolderContents contents;
    try {
      contents = await listFolderDocuments(folder.value);
    } on DocumentFolderUnreadable {
      // "Could not look" and "nothing in it" are different answers, and
      // a folder the app cannot read must not be reported as empty.
      _say(l10n.knowledgeDocumentFolderUnreadable);
      return;
    }
    if (contents.documents.isEmpty) {
      _say(l10n.knowledgeDocumentFolderEmpty);
      return;
    }
    if (!mounted) return;

    final index = await _askToImport(l10n, folder.label, contents);
    if (index == null) return;

    final result = await _store.addAll([
      for (final document in contents.documents)
        (location: document.value, label: document.label),
    ]);
    if (!mounted) return;
    setState(() => _documents = Future.value(result.all));
    _say(
      l10n.knowledgeDocumentFolderAdded(
        result.added.length,
        contents.documents.length - result.added.length,
      ),
    );
    if (!index) return;

    // One at a time. Each run reads a whole document into memory, and
    // several at once on a laptop is the same peak several times over.
    for (var done = 0; done < result.added.length; done++) {
      if (!mounted) return;
      setState(() => _import = (done: done, total: result.added.length));
      await _index(result.added[done], quiet: true);
    }
    if (mounted) setState(() => _import = null);
  }

  Future<bool?> _askToImport(
    AppLocalizations l10n,
    String folderLabel,
    DocumentFolderContents contents,
  ) {
    var enabled = true;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(folderLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.knowledgeDocumentFolderFound(contents.found)),
              const SizedBox(height: 8),
              Text(l10n.knowledgeDocumentFolderScope),
              if (contents.isTruncated) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.knowledgeDocumentFolderLimit(contents.documents.length),
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                value: enabled,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) =>
                    setDialogState(() => enabled = value ?? true),
                title: Text(l10n.knowledgeDocumentIndexOption),
                subtitle: Text(l10n.knowledgeDocumentIndexPrivacy),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(enabled),
              child: Text(l10n.knowledgeDocumentAdd),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _askToIndex(AppLocalizations l10n) {
    var enabled = true;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.knowledgeDocumentIndexTitle),
          content: CheckboxListTile(
            value: enabled,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setDialogState(() => enabled = value ?? true),
            title: Text(l10n.knowledgeDocumentIndexOption),
            subtitle: Text(l10n.knowledgeDocumentIndexPrivacy),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(enabled),
              child: Text(l10n.knowledgeDocumentAdd),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _index(PersonalDocument document, {bool quiet = false}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(
      () => _documents = _store.updateIndex(document.id, status: 'indexing'),
    );
    final result = await PersonalDocumentIndexer().index(document);
    final updated = await _store.updateIndex(
      document.id,
      status: result.status.name,
      characters: result.characters,
    );
    if (mounted) {
      setState(() => _documents = Future.value(updated));
      // During a folder import the outcome of each file is already in
      // its own row; a snackbar per document would bury the list it is
      // reporting on.
      if (!quiet && result.status != PersonalDocumentIndexStatus.ready) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_indexStatus(l10n, result.status.name))),
        );
      }
    }
  }

  Future<void> _open(PersonalDocument document) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => PersonalDocumentReaderScreen(document: document),
    ),
  );

  Future<void> _remove(String id) async {
    await PersonalDocumentIndexer().remove(id);
    final updated = await _store.remove(id);
    if (mounted) setState(() => _documents = Future.value(updated));
  }

  Future<void> _clearIndex() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.knowledgeDocumentClearIndex),
        content: Text(l10n.knowledgeDocumentClearIndexBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.knowledgeDocumentClearIndex),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    Feel.removed();
    final database = PersonalDocumentIndex();
    await database.clear();
    await database.close();
    final updated = await _store.clearIndex();
    if (mounted) setState(() => _documents = Future.value(updated));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.knowledgeDocumentsTitle),
        actions: [
          if (canImportDocumentFolder)
            IconButton(
              tooltip: l10n.knowledgeDocumentAddFolder,
              icon: const Icon(Icons.folder_open_outlined),
              onPressed: _import == null ? _addFolder : null,
            ),
          IconButton(
            tooltip: l10n.knowledgeDocumentClearIndex,
            icon: const Icon(Icons.manage_search_outlined),
            onPressed: _clearIndex,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l10n.knowledgeDocumentAdd),
      ),
      body: FutureBuilder<List<PersonalDocument>>(
        future: _documents,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final documents = snapshot.data!;
          final indexed = documents.where((item) => item.isSearchable).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.manage_search_outlined),
                  title: Text(
                    l10n.knowledgeDocumentIndexSummary(
                      indexed,
                      documents.length,
                    ),
                  ),
                  subtitle: Text(
                    canImportDocumentFolder
                        ? l10n.knowledgeDocumentsIntro
                        // Said rather than left out: on a phone the folder
                        // button is absent, and an absent button explains
                        // nothing by itself.
                        : '${l10n.knowledgeDocumentsIntro} '
                              '${l10n.knowledgeDocumentFolderOnComputer}',
                  ),
                ),
              ),
              if (_import case final progress?) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.total == 0
                      ? null
                      : progress.done / progress.total,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.knowledgeDocumentFolderProgress(
                    progress.done,
                    progress.total,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (documents.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.knowledgeDocumentsEmpty,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                for (final document in documents)
                  Card(
                    child: ListTile(
                      leading: Icon(_icon(document.extension)),
                      title: Text(document.label),
                      subtitle: Text(
                        '${document.extension.toUpperCase()} · ${_indexStatus(l10n, document.indexStatus)}'
                        '${document.readerOffset > 0 ? ' · ${l10n.knowledgeDocumentContinue}' : ''}',
                      ),
                      onTap: () => _open(document),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.knowledgeDocumentReindex,
                            icon: const Icon(Icons.manage_search_outlined),
                            onPressed: document.indexStatus == 'indexing'
                                ? null
                                : () => _index(document),
                          ),
                          IconButton(
                            tooltip: l10n.knowledgeDocumentRemove,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _remove(document.id),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  String _indexStatus(AppLocalizations l10n, String status) => switch (status) {
    'ready' => l10n.knowledgeDocumentIndexed,
    'indexing' => l10n.knowledgeDocumentIndexing,
    'noText' => l10n.knowledgeDocumentNoText,
    'tooLarge' => l10n.knowledgeDocumentTooLarge,
    'failed' => l10n.knowledgeDocumentIndexFailed,
    _ => l10n.knowledgeDocumentNotIndexed,
  };

  IconData _icon(String extension) => switch (extension) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'epub' => Icons.book_outlined,
    _ => Icons.description_outlined,
  };
}

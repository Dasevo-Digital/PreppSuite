import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/platform_storage.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../maps/application/map_archive_access.dart' show pickMapArchive;
import '../application/personal_document_store.dart';

class PersonalDocumentsScreen extends StatefulWidget {
  const PersonalDocumentsScreen({super.key});

  @override
  State<PersonalDocumentsScreen> createState() =>
      _PersonalDocumentsScreenState();
}

class _PersonalDocumentsScreenState extends State<PersonalDocumentsScreen> {
  static const _store = PersonalDocumentStore();
  late Future<List<PersonalDocument>> _documents = _store.load();

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
    final updated = await _store.add(
      location: picked.value,
      label: picked.label,
    );
    if (mounted) setState(() => _documents = Future.value(updated));
  }

  Future<void> _open(PersonalDocument document) async {
    var location = document.location;
    if (location.startsWith('bookmark://')) {
      location = await resolveStoragePath(location) ?? location;
    }
    final uri = location.startsWith('content://')
        ? Uri.parse(location)
        : Uri.file(location);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.knowledgeDocumentOpenFailed,
          ),
        ),
      );
    }
  }

  Future<void> _remove(String id) async {
    final updated = await _store.remove(id);
    if (mounted) setState(() => _documents = Future.value(updated));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.knowledgeDocumentsTitle)),
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.knowledgeDocumentsIntro),
                ),
              ),
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
                      subtitle: Text(document.extension.toUpperCase()),
                      onTap: () => _open(document),
                      trailing: IconButton(
                        tooltip: l10n.knowledgeDocumentRemove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(document.id),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  IconData _icon(String extension) => switch (extension) {
    'pdf' => Icons.picture_as_pdf_outlined,
    'epub' => Icons.book_outlined,
    _ => Icons.description_outlined,
  };
}

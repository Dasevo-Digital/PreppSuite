import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../maps/application/map_archive_access.dart' show pickMapArchive;
import '../application/article_viewer.dart';
import '../application/article_viewer_choice.dart';
import '../application/knowledge_providers.dart';
import '../application/knowledge_bookmark_store.dart';
import '../application/personal_document_index.dart';
import '../application/personal_document_store.dart';
import '../application/zim_store.dart';
import '../application/recommended_archives.dart';
import '../application/zim_archive.dart';
import '../../downloads/presentation/download_banner.dart';
import 'article_reader_screen.dart';
import 'article_screen.dart';
import 'apollo_library_screen.dart';
import 'kiwix_library_screen.dart';
import 'knowledge_index_panel.dart';
import 'personal_documents_screen.dart';
import '../../../core/error_text.dart';

/// Looking things up without a network: search an offline archive by
/// title, open what it finds.
class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  final _queryController = TextEditingController();

  /// What the search actually runs on — the field's text a moment later.
  ///
  /// Every keystroke would otherwise start a binary search over the whole
  /// archive, each step a read from a file measured in gigabytes.
  String _query = '';
  Timer? _debounce;

  /// Titles or text. Titles come from the archive's own index and are
  /// instant; text needs one the app builds itself.
  var _mode = _SearchMode.titles;

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(knowledgeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.knowledgeTitle),
        actions: [
          IconButton(
            tooltip: 'Lesezeichen',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => _showBookmarks(l10n, async.value),
          ),
          IconButton(
            tooltip: l10n.knowledgeApolloTitle,
            icon: const Icon(Icons.auto_stories_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ApolloLibraryScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.knowledgeDocumentsTitle,
            icon: const Icon(Icons.folder_copy_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PersonalDocumentsScreen(),
              ),
            ),
          ),
          if (async.value?.isConfigured ?? false)
            PopupMenuButton<_ArchiveAction>(
              onSelected: (action) => switch (action) {
                _ArchiveAction.manage => _manageArchives(),
                _ArchiveAction.download => _openLibrary(),
                _ArchiveAction.add => _choose(l10n),
                _ArchiveAction.remove => _remove(async.value),
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _ArchiveAction.manage,
                  child: Text(l10n.knowledgeManageArchives),
                ),
                PopupMenuItem(
                  value: _ArchiveAction.download,
                  child: Text(l10n.knowledgeDownloadAction),
                ),
                PopupMenuItem(
                  value: _ArchiveAction.add,
                  child: Text(l10n.knowledgeAddAction),
                ),
                PopupMenuItem(
                  value: _ArchiveAction.remove,
                  child: Text(l10n.knowledgeRemoveAction),
                ),
              ],
            ),
        ],
      ),
      body: switch (async) {
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
        AsyncError(:final error) => Center(
          child: Text(describeError(l10n, error)),
        ),
        _ => _body(l10n, async.requireValue),
      },
    );
  }

  Widget _body(AppLocalizations l10n, KnowledgeState state) {
    if (!state.isReady) {
      // Keep the first-use view compact, but make the same full-text screen
      // available when the person has already added their own documents.
      // This also avoids presenting a search field that could only return an
      // empty list on a completely fresh installation.
      return FutureBuilder<List<PersonalDocument>>(
        future: const PersonalDocumentStore().load(),
        builder: (context, snapshot) {
          if (snapshot.data?.isNotEmpty == true) {
            return _searchBody(l10n, state);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The first download is the one that most needs saying: a
              // fresh install has no archive, so this branch is where
              // somebody sits while 52 GB come down — and it was the one
              // branch with no banner on it. Leaving the library screen
              // meant the progress vanished.
              const DownloadBanner(),
              _ArchiveSwitcher(state: state, l10n: l10n),
              Expanded(
                child: _EmptyState(
                  state: state,
                  l10n: l10n,
                  onChoose: () => _choose(l10n),
                  onDownload: _openLibrary,
                ),
              ),
            ],
          );
        },
      );
    }
    return _searchBody(l10n, state);
  }

  Widget _searchBody(AppLocalizations l10n, KnowledgeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DownloadBanner(),
        // Only over results. On the start page the tiles below are the
        // chooser, and two of them stacked is one too many.
        if (_query.trim().isNotEmpty)
          _ArchiveSwitcher(state: state, l10n: l10n),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _queryController,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: l10n.knowledgeSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<_SearchMode>(
                segments: [
                  ButtonSegment(
                    value: _SearchMode.titles,
                    label: Text(l10n.knowledgeModeTitles),
                  ),
                  ButtonSegment(
                    value: _SearchMode.fullText,
                    label: Text(l10n.knowledgeModeFullText),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) =>
                    setState(() => _mode = selection.first),
              ),
              const SizedBox(height: 6),
              Text(
                _mode == _SearchMode.titles
                    ? l10n.knowledgeSearchNote
                    : l10n.knowledgeFullTextNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (state.title != null)
                Text(
                  l10n.knowledgeSource(state.title!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        Expanded(child: _results(l10n, state)),
      ],
    );
  }

  Widget _results(AppLocalizations l10n, KnowledgeState state) {
    if (_query.trim().isEmpty) {
      // Nothing to show a library of yet.
      if (!state.isConfigured) {
        return _EmptyState(
          state: state,
          l10n: l10n,
          onChoose: () => _choose(l10n),
          onDownload: _openLibrary,
        );
      }

      // The library first, as tiles: each archive's own cover, title and
      // one-line description. What is on the device is the thing to see
      // on arriving here, and a row of chips said far less about it than
      // the archives say about themselves.
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.knowledgeLibraryTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _ArchiveGrid(
              state: state,
              nested: true,
              onSelect: (id) => _select(l10n, state, id),
            ),
            if (state.isReady)
              _BrowseArchive(
                nested: true,
                l10n: l10n,
                onMainPage: () => _openMainPage(l10n, state),
                onRandom: () => _openRandom(l10n, state),
                onLetter: (letter) {
                  _queryController.text = letter;
                  setState(() {
                    _query = letter;
                    _mode = _SearchMode.titles;
                  });
                },
              )
            else
              // Registered but not open — a moved file, an unplugged
              // disk. The tiles above are how to pick another one.
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.knowledgeErrorUnreadable,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (_mode == _SearchMode.fullText) {
      return _fullTextResults(l10n, state);
    }

    if (!state.isReady) {
      return _Centered(text: l10n.knowledgeNoResults(_query.trim()));
    }

    final results = ref.watch(knowledgeSearchProvider(_query));
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Centered(
        child: Text(describeError(l10n, error)),
      ),
      data: (matches) {
        if (matches.isEmpty) {
          return _Centered(text: l10n.knowledgeNoResults(_query.trim()));
        }

        return ListView.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final entry = matches[index];
            return ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(entry.title),
              onTap: () => _open(l10n, state, entry),
            );
          },
        );
      },
    );
  }

  Widget _fullTextResults(AppLocalizations l10n, KnowledgeState state) {
    final personal = ref.watch(personalDocumentSearchProvider(_query));
    final index = state.isReady
        ? ref.watch(knowledgeIndexProvider).value
        : null;
    final zimResults =
        state.isReady &&
            index != null &&
            index.isUsable &&
            index.status != KnowledgeIndexStatus.running
        ? ref.watch(knowledgeFullTextProvider(_query))
        : null;

    final personalMatches = personal.when(
      data: (matches) => matches,
      error: (_, _) => const <PersonalDocumentMatch>[],
      loading: () => const <PersonalDocumentMatch>[],
    );
    final zimMatches =
        zimResults?.when(
          data: (matches) => matches,
          error: (_, _) => const <ZimEntry>[],
          loading: () => const <ZimEntry>[],
        ) ??
        const <ZimEntry>[];
    final loading = personal.isLoading || zimResults?.isLoading == true;
    final noUsableZimIndex =
        state.isReady &&
        (index == null ||
            !index.isUsable ||
            index.status == KnowledgeIndexStatus.running);

    if (loading && personalMatches.isEmpty && zimMatches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (noUsableZimIndex)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: KnowledgeIndexPanel(l10n: l10n),
          ),
        if (personalMatches.isNotEmpty) ...[
          ListTile(
            leading: const Icon(Icons.folder_copy_outlined),
            title: Text(l10n.knowledgePersonalResults),
            subtitle: Text(l10n.knowledgePersonalResultHint),
          ),
          for (final match in personalMatches)
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(match.label),
              subtitle: Text(
                match.excerpt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _openPersonal(l10n, match.id),
            ),
        ],
        if (zimMatches.isNotEmpty) ...[
          if (personalMatches.isNotEmpty) const Divider(),
          for (final entry in zimMatches)
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text(entry.title),
              onTap: () => _open(l10n, state, entry),
            ),
          if (index?.status == KnowledgeIndexStatus.partial)
            Padding(
              padding: const EdgeInsets.all(16),
              child: KnowledgeIndexPanel(l10n: l10n, compact: true),
            ),
        ],
        if (personalMatches.isEmpty && zimMatches.isEmpty && !noUsableZimIndex)
          _Centered(text: l10n.knowledgeNoResults(_query.trim())),
        if (personal.hasError)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(describeError(l10n, personal.error!)),
          ),
      ],
    );
  }

  Future<void> _openPersonal(AppLocalizations l10n, String id) async {
    final documents = await const PersonalDocumentStore().load();
    PersonalDocument? document;
    for (final item in documents) {
      if (item.id == id) document = item;
    }
    if (document == null) return;
    if (await openPersonalDocument(document) || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.knowledgeDocumentOpenFailed)),
    );
  }

  Future<void> _openMainPage(
    AppLocalizations l10n,
    KnowledgeState state,
  ) async {
    final entry = await state.archive!.mainPage();
    if (entry != null && mounted) await _open(l10n, state, entry);
  }

  Future<void> _openRandom(
    AppLocalizations l10n,
    KnowledgeState state,
  ) async {
    final archive = state.archive!;
    final random = Random.secure();
    for (var attempt = 0; attempt < 100; attempt++) {
      final candidate = await archive.resolve(
        await archive.entryAt(random.nextInt(archive.header.entryCount)),
      );
      if (candidate == null ||
          !const {'A', 'C'}.contains(candidate.namespace) ||
          !archive.mimeTypeOf(candidate).startsWith('text/html') ||
          candidate.title.trim().isEmpty) {
        continue;
      }
      if (mounted) await _open(l10n, state, candidate);
      return;
    }
  }

  Future<void> _open(
    AppLocalizations l10n,
    KnowledgeState state,
    ZimEntry entry,
  ) async {
    final resolved = await state.archive!.resolve(entry);
    if (resolved == null || !mounted) return;

    final uri = state.server!.uriFor(resolved);

    switch (articleViewer) {
      case ArticleViewer.panel:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => ArticleScreen(
              title: entry.title,
              uri: uri,
              archiveId: state.selectedId,
              entryUrl: resolved.url,
            ),
          ),
        );

      case ArticleViewer.window:
        // Where somebody has said they would rather stay in the app,
        // that is the end of it — no window is opened and none is
        // needed.
        final choice = await const ArticleViewerChoiceStore().load();
        if (choice == ArticleViewerChoice.systemWindow) {
          // Whether an engine is actually installed is only knowable by
          // asking for one, so the fallback comes after the attempt
          // rather than instead of it.
          if (await openArticleWindow(title: entry.title, uri: uri)) return;
        }
        if (!mounted) return;
        // No engine on this machine, and on a machine with no network
        // there is no getting one. The app draws the article itself
        // rather than saying which package is missing and stopping —
        // that message was correct and useless in the one situation this
        // app is for.
        await _readHere(entry.title, uri);

      case ArticleViewer.builtIn:
        await _readHere(entry.title, uri);

      case ArticleViewer.none:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.knowledgeArticleUnsupported)),
        );
    }
  }

  Future<void> _showBookmarks(
    AppLocalizations l10n,
    KnowledgeState? state,
  ) async {
    final bookmarks = await const KnowledgeBookmarkStore().load();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: bookmarks.isEmpty
            ? Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  l10n.knowledgeNoBookmarks,
                ),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(title: Text('Lesezeichen')),
                  for (final bookmark in bookmarks)
                    ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(bookmark.title),
                      subtitle: Text(
                        state?.selectedId == bookmark.archiveId
                            ? l10n.knowledgeInOpenArchive
                            : l10n.knowledgeOpenArchiveFirst,
                      ),
                      onTap:
                          state?.selectedId == bookmark.archiveId &&
                              state?.archive != null
                          ? () async {
                              final entry =
                                  await state!.archive!.findByUrl(
                                    'C',
                                    bookmark.entryUrl,
                                  ) ??
                                  await state.archive!.findByUrl(
                                    'A',
                                    bookmark.entryUrl,
                                  );
                              if (entry == null || !context.mounted) return;
                              Navigator.of(context).pop();
                              await _open(l10n, state, entry);
                            }
                          : null,
                    ),
                ],
              ),
      ),
    );
  }

  /// Reads the article without any engine.
  Future<void> _readHere(String title, Uri uri) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ArticleReaderScreen(title: title, uri: uri),
      ),
    );
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const KiwixLibraryScreen()),
    );
  }

  /// The library as a sheet: switch, remove, add.
  ///
  /// It watches the library rather than being handed a copy of it, and it
  /// stays open across a removal. Closing on every delete meant reopening
  /// the sheet for each archive in turn, and the count at the top went on
  /// naming the number there had been before.
  Future<void> _manageArchives() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .75,
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final l10n = AppLocalizations.of(context)!;
              final state =
                  ref.watch(knowledgeProvider).value ?? const KnowledgeState();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      l10n.knowledgeManageArchives,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(
                      l10n.knowledgeArchiveCount(state.library.length),
                    ),
                  ),
                  if (state.library.any((archive) => archive.sizeBytes != null))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.knowledgeTotalSize(
                            _formatBytes(
                              state.library.fold<int>(
                                0,
                                (sum, archive) =>
                                    sum + (archive.sizeBytes ?? 0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Flexible(
                    child: state.library.isEmpty
                        // Emptied from in here. The sheet stays put — the
                        // add button below is the obvious next step, and
                        // having it vanish under the finger would not be.
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(l10n.knowledgeLibraryEmpty),
                          )
                        : _ArchiveGrid(
                            state: state,
                            onSelect: (id) async {
                              // Switching is done with, so the sheet
                              // closes; removing is not.
                              Navigator.pop(sheetContext);
                              await ref
                                  .read(knowledgeProvider.notifier)
                                  .select(id);
                            },
                            onRemove: (id) =>
                                ref.read(knowledgeProvider.notifier).remove(id),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _choose(l10n);
                        },
                        icon: const Icon(Icons.add),
                        label: Text(l10n.knowledgeAddAction),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Opens an archive from the library tiles.
  ///
  /// The entry stays in the library when it will not open — an unplugged
  /// disk comes back — so the refusal has to be said out loud rather than
  /// left to a tile that silently declines to become the open one.
  Future<void> _select(
    AppLocalizations l10n,
    KnowledgeState state,
    String id,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final problem = await ref.read(knowledgeProvider.notifier).select(id);
    if (problem == null) return;

    final archive = state.library.firstWhere(
      (entry) => entry.id == id,
      orElse: () => state.library.first,
    );
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.knowledgeSwitchFailed(archive.label))),
    );
  }

  Future<void> _remove(KnowledgeState? state) async {
    final id = state?.selectedId;
    if (id == null) return;
    await ref.read(knowledgeProvider.notifier).remove(id);
  }

  Future<void> _choose(AppLocalizations l10n) async {
    final picked = await pickMapArchive(dialogTitle: l10n.knowledgeTitle);
    if (picked == null) return;

    final problem = await ref
        .read(knowledgeProvider.notifier)
        .useArchive(location: picked.value, label: picked.label);
    if (problem == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.knowledgeErrorUnreadable)),
    );
  }
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value >= 10 || unit == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1)} ${units[unit]}';
}

/// The library as tiles, each showing what the archive says about itself.
///
/// A list of file names was what this used to be — including
/// `bookmark://BFDD0E14-...` under each one, which is a security handle
/// and means nothing to anybody. What an archive actually carries is a
/// title, a one-line description and a cover image, all three written by
/// whoever built it, and all three read when the archive was opened.
///
/// The cover is the archive's own illustration rather than a rendering of
/// its start page: a screenshot per tile would mean opening every archive
/// and a browser engine for each, for a library that is meant to be
/// allowed to grow.
class _ArchiveGrid extends StatelessWidget {
  const _ArchiveGrid({
    required this.state,
    required this.onSelect,
    this.onRemove,
    this.nested = false,
  });

  final KnowledgeState state;
  final ValueChanged<String> onSelect;

  /// Null where removing is not on offer. The start page shows the same
  /// tiles to choose from, and a delete button one tap away from the
  /// archive somebody is trying to open is a trap rather than a
  /// convenience; that belongs in "manage archives".
  final ValueChanged<String>? onRemove;

  /// Whether this sits inside something that already scrolls.
  final bool nested;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;

    // Two tiles on a phone, more as there is room. A tile whose text has
    // grown with the system font size needs the height, so the aspect
    // ratio follows the text scale rather than being fixed.
    final columns = (width / 220).floor().clamp(2, 4);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: (1 / (0.95 + 0.35 * (scale - 1))).clamp(0.45, 1.1),
      ),
      physics: nested ? const NeverScrollableScrollPhysics() : null,
      itemCount: state.library.length,
      itemBuilder: (context, index) {
        final archive = state.library[index];
        final remove = onRemove;
        return _ArchiveTile(
          archive: archive,
          open: archive.id == state.selectedId,
          l10n: l10n,
          onSelect: () => onSelect(archive.id),
          onRemove: remove == null ? null : () => remove(archive.id),
        );
      },
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({
    required this.archive,
    required this.open,
    required this.l10n,
    required this.onSelect,
    this.onRemove,
  });

  final StoredArchive archive;
  final bool open;
  final AppLocalizations l10n;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = archive.cover;

    return Card(
      clipBehavior: Clip.antiAlias,
      // The open one is marked by its frame as well as by the tick, so
      // which archive is being searched is visible at a glance rather
      // than by reading every tile.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: open
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onSelect,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: cover == null
                    ? Icon(
                        Icons.menu_book_outlined,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant,
                        semanticLabel: l10n.knowledgeArchiveNoCover,
                      )
                    // The illustration is 48x48; letting it fill the tile
                    // would be four times its own size and visibly soft.
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.memory(
                          cover,
                          width: 48,
                          height: 48,
                          filterQuality: FilterQuality.medium,
                          // A cover that will not decode is a cosmetic
                          // problem, never a reason a library will not
                          // draw.
                          errorBuilder: (context, error, stack) => Icon(
                            Icons.menu_book_outlined,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (open) ...[
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          // Its own title where it has one; a file name
                          // only where it does not.
                          archive.title ?? archive.label,
                          style: theme.textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Full size, not compact: `VisualDensity.compact`
                      // took it to 40x40, under the 48x48 a tap target
                      // has to be. The icon inside it is small; the
                      // thing being aimed at is not.
                      if (onRemove != null)
                        IconButton(
                          tooltip: l10n.knowledgeRemoveAction,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: onRemove,
                        ),
                    ],
                  ),
                  if (archive.description != null)
                    Text(
                      archive.description!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (archive.entryCount != null && archive.sizeBytes != null)
                    Text(
                      l10n.knowledgeArchiveStats(
                        archive.entryCount!,
                        _formatBytes(archive.sizeBytes!),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseArchive extends StatelessWidget {
  const _BrowseArchive({
    required this.l10n,
    required this.onMainPage,
    required this.onRandom,
    required this.onLetter,
    this.nested = false,
  });

  /// Whether this sits inside something that already scrolls.
  final bool nested;

  final AppLocalizations l10n;
  final VoidCallback onMainPage;
  final VoidCallback onRandom;
  final ValueChanged<String> onLetter;

  @override
  Widget build(BuildContext context) => _Scroller(
    nested: nested,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.knowledgeBrowseTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(l10n.knowledgeBrowseBody),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onMainPage,
                  icon: const Icon(Icons.home_outlined),
                  label: Text(l10n.knowledgeMainPageAction),
                ),
                FilledButton.tonalIcon(
                  onPressed: onRandom,
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(l10n.knowledgeRandomAction),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final code in List.generate(26, (index) => 65 + index))
                  ActionChip(
                    label: Text(String.fromCharCode(code)),
                    onPressed: () => onLetter(String.fromCharCode(code)),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// One row of the library, so switching is a tap.
///
/// Hidden while there is only one archive: a chooser with a single choice
/// is a line of clutter above every search.
class _ArchiveSwitcher extends ConsumerWidget {
  const _ArchiveSwitcher({required this.state, required this.l10n});

  final KnowledgeState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.library.length < 2) return const SizedBox.shrink();

    // A horizontal list has to be given a height, and 48 with 6 of padding
    // above and below left the chips 36 tall — under the 48 a tap target
    // needs. 56 gives them their full height back and leaves the row room
    // to grow a little when the system font is enlarged.
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          for (final archive in state.library)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                // Its own title where it has one, the same as the
                // library tiles: a chip reading
                // "wikipedia_de_all_maxi_2026-01.zim" is a file name
                // sitting above every search.
                label: Text(archive.title ?? archive.label),
                selected: archive.id == state.selectedId,
                onSelected: (_) => _switch(context, ref, archive),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _switch(
    BuildContext context,
    WidgetRef ref,
    StoredArchive archive,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final problem = await ref
        .read(knowledgeProvider.notifier)
        .select(archive.id);
    if (problem == null) return;

    // The entry stays in the library — an unplugged disk comes back — so
    // the failure has to be said out loud rather than left to a chip that
    // silently refuses to become selected.
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.knowledgeSwitchFailed(archive.label))),
    );
  }
}

enum _SearchMode { titles, fullText }

enum _ArchiveAction { manage, download, add, remove }

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.state,
    required this.l10n,
    required this.onChoose,
    required this.onDownload,
  });

  final KnowledgeState state;
  final AppLocalizations l10n;
  final VoidCallback onChoose;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.knowledgeEmptyTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.knowledgeEmptyBody,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (state.problem != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.knowledgeErrorUnreadable,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(l10n.knowledgeDownloadAction),
                ),
                FilledButton.tonalIcon(
                  onPressed: onChoose,
                  icon: const Icon(Icons.folder_open),
                  label: Text(
                    state.isConfigured
                        ? l10n.knowledgeChangeAction
                        : l10n.knowledgeChooseAction,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _Suggestions(l10n: l10n),
          ],
        ),
      ),
    );
  }
}

/// What to download first.
///
/// The library search is no help to somebody who does not already know
/// that the German school maths course lives in Wikibooks. Each row opens
/// the library on that search, in that archive's language.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.knowledgeSuggestionsTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.knowledgeSuggestionsBody, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final archive in RecommendedArchive.values)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(archive.name),
            subtitle: Text(recommendedArchiveDescription(l10n, archive)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => KiwixLibraryScreen(
                  initialQuery: archive.query,
                  initialLanguage: archive.language,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Scrolls, or leaves the scrolling to whatever it sits in.
///
/// A card that scrolls inside a page that also scrolls swallows the
/// page's gestures over its own area, which on the start page is most of
/// the screen.
class _Scroller extends StatelessWidget {
  const _Scroller({required this.nested, required this.child});

  final bool nested;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.all(16);
    if (nested) return Padding(padding: padding, child: child);
    return SingleChildScrollView(padding: padding, child: child);
  }
}

class _Centered extends StatelessWidget {
  const _Centered({this.text, this.child});

  final String? text;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child:
            child ??
            Text(
              text!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
      ),
    );
  }
}

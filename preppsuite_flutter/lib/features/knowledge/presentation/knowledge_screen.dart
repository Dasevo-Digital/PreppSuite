import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../maps/application/map_archive_access.dart' show pickMapArchive;
import '../application/article_viewer.dart';
import '../application/knowledge_providers.dart';
import '../application/zim_store.dart';
import '../application/recommended_archives.dart';
import '../application/zim_archive.dart';
import '../../downloads/presentation/download_banner.dart';
import 'article_screen.dart';
import 'kiwix_library_screen.dart';
import 'knowledge_index_panel.dart';
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
          if (async.value?.isConfigured ?? false)
            PopupMenuButton<_ArchiveAction>(
              onSelected: (action) => switch (action) {
                _ArchiveAction.download => _openLibrary(),
                _ArchiveAction.add => _choose(l10n),
                _ArchiveAction.remove => _remove(async.value),
              },
              itemBuilder: (context) => [
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
      // The switcher stays: when one archive fails to open and others are
      // there, getting to them is the first thing somebody wants.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DownloadBanner(),
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
    if (_mode == _SearchMode.fullText) {
      final index = ref.watch(knowledgeIndexProvider).value;
      // Nothing to search in yet, or a run in progress: the panel is what
      // belongs on screen, not an empty result list.
      if (index == null ||
          !index.isUsable ||
          index.status == KnowledgeIndexStatus.running) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: KnowledgeIndexPanel(l10n: l10n),
        );
      }
    }

    if (_query.trim().isEmpty) {
      return _Centered(text: l10n.knowledgeSearchPrompt);
    }

    final results = _mode == _SearchMode.titles
        ? ref.watch(knowledgeSearchProvider(_query))
        : ref.watch(knowledgeFullTextProvider(_query));

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
          itemCount: matches.length + 1,
          itemBuilder: (context, index) {
            if (index == matches.length) {
              // A partial index answers about what it has; saying so
              // beats letting a missing article read as "not in
              // Wikipedia".
              return _PartialIndexNote(l10n: l10n, mode: _mode);
            }

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
            builder: (context) => ArticleScreen(title: entry.title, uri: uri),
          ),
        );

      case ArticleViewer.window:
        // Whether an engine is actually installed is only knowable by
        // asking for one, so the message comes after the attempt rather
        // than instead of it.
        if (await openArticleWindow(title: entry.title, uri: uri)) return;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.knowledgeArticleNoEngine)),
        );

      case ArticleViewer.none:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.knowledgeArticleUnsupported)),
        );
    }
  }

  void _openLibrary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const KiwixLibraryScreen()),
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

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final archive in state.library)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(archive.label),
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

enum _ArchiveAction { download, add, remove }

/// Sits under the results when the index is not finished.
class _PartialIndexNote extends ConsumerWidget {
  const _PartialIndexNote({required this.l10n, required this.mode});

  final AppLocalizations l10n;
  final _SearchMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mode != _SearchMode.fullText) return const SizedBox.shrink();

    final index = ref.watch(knowledgeIndexProvider).value;
    if (index?.status != KnowledgeIndexStatus.partial) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: KnowledgeIndexPanel(l10n: l10n, compact: true),
    );
  }
}

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

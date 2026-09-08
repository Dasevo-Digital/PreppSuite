import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/platform_storage.dart';
import '../../downloads/application/byte_size.dart';
import '../../downloads/application/download_folder.dart';
import '../../downloads/application/download_providers.dart';
import '../../downloads/presentation/download_banner.dart';
import '../application/kiwix_catalogue.dart';
import '../application/knowledge_providers.dart';

/// Overridden in tests so the screen can be shown against a captured
/// catalogue instead of the live library.
final kiwixCatalogueProvider = Provider((ref) => KiwixCatalogue());

final _languagesProvider = FutureProvider(
  (ref) => ref.read(kiwixCatalogueProvider).languages(),
);

/// Browses the public Kiwix library and downloads an archive from it.
///
/// The alternative was telling people to find a ZIM file themselves,
/// which meant a browser, a mirror listing and a file manager before the
/// feature could be used at all.
class KiwixLibraryScreen extends ConsumerStatefulWidget {
  const KiwixLibraryScreen({
    super.key,
    this.initialQuery,
    this.initialLanguage,
  });

  /// What to search for on opening, when the screen was reached from a
  /// suggestion rather than from the menu.
  final String? initialQuery;

  /// ISO 639-3. A suggestion names its own language, because half of them
  /// only exist in one.
  final String? initialLanguage;

  @override
  ConsumerState<KiwixLibraryScreen> createState() => _KiwixLibraryScreenState();
}

class _KiwixLibraryScreenState extends ConsumerState<KiwixLibraryScreen> {
  static const _pageSize = 25;

  final _queryController = TextEditingController();

  String? _language;
  String _query = '';
  final _entries = <KiwixEntry>[];
  int _total = 0;
  bool _loading = false;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_language == null) {
      _language =
          widget.initialLanguage ??
          _isoThreeFor(Localizations.localeOf(context).languageCode);
      _query = widget.initialQuery ?? '';
      _queryController.text = _query;
      _reload();
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  /// The catalogue speaks ISO 639-3; the app's locales are two-letter.
  static String _isoThreeFor(String languageCode) => switch (languageCode) {
    'de' => 'deu',
    'en' => 'eng',
    _ => 'eng',
  };

  Future<void> _reload() async {
    setState(() {
      _entries.clear();
      _total = 0;
      _error = null;
    });
    await _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final page = await ref
          .read(kiwixCatalogueProvider)
          .entries(
            language: _language,
            query: _query,
            start: _entries.length,
            count: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _entries.addAll(page.entries);
        _total = page.total;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _download(KiwixEntry entry, AppLocalizations l10n) async {
    if (ref.read(archiveDownloadProvider).isRunning) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.downloadBusyMessage)));
      return;
    }

    final folder = await const DownloadFolder().current();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.downloadConfirmTitle),
        content: Text(
          l10n.downloadConfirmBody(
            entry.title,
            formatByteSize(entry.size),
            folder.path,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.downloadStartAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref
        .read(archiveDownloadProvider.notifier)
        .start(
          ArchiveDownloadRequest(
            url: entry.downloadUrl,
            fileName: entry.fileName,
            label: entry.title,
            estimatedLength: entry.size,
          ),
          // Taking it into use straight away is the point of downloading
          // it; there is no second step worth asking about.
          onFinished: (path, label) async {
            // Sandboxed macOS can read the freshly written path only for
            // the current folder scope. Persist a security bookmark so the
            // archive remains reachable after the app is restarted.
            final remembered = await rememberStoragePath(path, label: label);
            final problem = await ref
                .read(knowledgeProvider.notifier)
                .useArchive(
                  location: remembered?.value ?? path,
                  label: remembered?.label ?? label,
                );

            if (problem != null) {
              return switch (problem) {
                KnowledgeProblem.unreadable => l10n.knowledgeErrorUnreadable,
              };
            }

            // Back to the encyclopedia, where the archive now is: the
            // library was the way there, not the destination. Only from
            // on top of the stack — a download can finish long after the
            // user has gone somewhere else, and the banner says so
            // wherever they are.
            if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
              Navigator.of(context).pop();
            }
            return null;
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.kiwixTitle)),
      body: Column(
        children: [
          const DownloadBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.kiwixIntro, style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                _LanguagePicker(
                  value: _language,
                  l10n: l10n,
                  onChanged: (code) {
                    setState(() => _language = code);
                    _reload();
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _queryController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: l10n.kiwixSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (value) {
                    _query = value;
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _results(l10n, theme)),
        ],
      ),
    );
  }

  Widget _results(AppLocalizations l10n, ThemeData theme) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.kiwixLoadError(_error.toString()),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l10n.kiwixNoResults, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      itemCount: _entries.length + 1,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == _entries.length) return _footer(l10n);
        final entry = _entries[index];
        return ListTile(
          title: Text(entry.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.summary.isNotEmpty)
                Text(
                  entry.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                _details(entry, l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          isThreeLine: entry.summary.isNotEmpty,
          trailing: IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: l10n.downloadStartAction,
            onPressed: () => _download(entry, l10n),
          ),
          onTap: () => _download(entry, l10n),
        );
      },
    );
  }

  /// Size first: it is the number that decides whether an archive is
  /// worth starting on this device at all.
  String _details(KiwixEntry entry, AppLocalizations l10n) {
    final parts = <String>[formatByteSize(entry.size)];

    final flavour = switch (entry.flavour) {
      'maxi' => l10n.kiwixFlavourMaxi,
      'mini' => l10n.kiwixFlavourMini,
      'nopic' => l10n.kiwixFlavourNopic,
      _ => null,
    };
    if (flavour != null) parts.add(flavour);

    if (entry.articleCount > 0) {
      parts.add(l10n.kiwixArticleCount('${entry.articleCount}'));
    }
    if (entry.hasFullTextIndex) parts.add(l10n.kiwixFullTextTag);

    return parts.join(' · ');
  }

  Widget _footer(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_entries.length >= _total) return const SizedBox(height: 16);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(l10n.kiwixResultCount('${_entries.length}', '$_total')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _fetch, child: Text(l10n.kiwixLoadMore)),
        ],
      ),
    );
  }
}

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({
    required this.value,
    required this.l10n,
    required this.onChanged,
  });

  final String? value;
  final AppLocalizations l10n;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages = ref.watch(_languagesProvider);

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.kiwixLanguageLabel,
        border: const OutlineInputBorder(),
      ),
      items: switch (languages) {
        AsyncData(:final value) => [
          for (final language in value)
            DropdownMenuItem(
              value: language.code,
              child: Text('${language.name} (${language.archiveCount})'),
            ),
        ],
        // Until the list arrives the current choice is the only item, so
        // the field shows what is in effect rather than going blank.
        _ => [
          if (value != null)
            DropdownMenuItem(value: value, child: Text(value!)),
        ],
      },
      onChanged: (code) {
        if (code != null) onChanged(code);
      },
    );
  }
}

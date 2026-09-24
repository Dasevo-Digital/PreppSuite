import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/feel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/adaptive_columns.dart';
import '../../../core/error_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/content_swap.dart';
import '../../downloads/application/byte_size.dart';
import '../application/first_aid_providers.dart';
import '../application/first_aid_video_pack.dart';

/// Getting the optional video pack onto the device, and off it again.
///
/// Two ways in, and the order on the screen is deliberate: the address
/// first for somebody with a connection, the file underneath for somebody
/// with a memory stick. The second one is the one that still works when
/// the situation this app exists for has actually happened.
class FirstAidVideosScreen extends ConsumerStatefulWidget {
  const FirstAidVideosScreen({super.key});

  @override
  ConsumerState<FirstAidVideosScreen> createState() =>
      _FirstAidVideosScreenState();
}

class _FirstAidVideosScreenState extends ConsumerState<FirstAidVideosScreen> {
  final _url = TextEditingController();
  var _urlLoaded = false;

  /// A manifest that has been fetched but not yet installed.
  FirstAidVideoPack? _offered;
  String? _problem;
  var _busy = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final installed = ref.watch(installedFirstAidPackProvider);
    final download = ref.watch(firstAidDownloadProvider);

    // Filled once, from what was stored. Rewriting it on every build
    // would fight whatever is being typed.
    final stored = ref.watch(firstAidPackUrlProvider).value;
    if (!_urlLoaded && stored != null) {
      _urlLoaded = true;
      _url.text = stored;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.firstAidVideoPackTitle)),
      body: AdaptiveColumns(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        blocks: [
          Text(l10n.firstAidVideoPackWhy),
          if (download.isRunning || download.finished)
            _Progress(state: download, l10n: l10n),
          ContentSwap(
            child: installed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(describeError(l10n, error)),
              data: (state) => _Installed(state: state, l10n: l10n),
            ),
          ),
          // The question the screen used to leave hanging. It said "enter
          // the address you published your pack at", which assumes the
          // pack already exists -- and the reason none ships is exactly
          // the reason finding one is hard.
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.firstAidVideoPackWhereTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.firstAidVideoPackWhereBody,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.firstAidVideoPackWhereHow,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.firstAidVideoPackFromNetwork,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.firstAidVideoPackUrlLabel,
                  helperText: l10n.firstAidVideoPackUrlHelper,
                  helperMaxLines: 4,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _busy || download.isRunning ? null : _fetch,
                icon: const Icon(Icons.cloud_download_outlined),
                label: Text(l10n.firstAidVideoPackFetch),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.firstAidVideoPackFromFile,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.firstAidVideoPackFromFileWhy,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy || download.isRunning ? null : _import,
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(l10n.firstAidVideoPackImport),
              ),
            ],
          ),
          if (_problem case final problem?)
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  problem,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          if (_offered case final pack?) _Offer(pack: pack, l10n: l10n),
          Text(
            l10n.firstAidVideoPackLicenceNote,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _fetch() async {
    final text = _url.text.trim();
    if (text.isEmpty) return;
    final url = Uri.tryParse(text);
    if (url == null || !url.hasScheme) {
      setState(
        () => _problem = AppLocalizations.of(context)!.firstAidVideoPackBadUrl,
      );
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
      _offered = null;
    });
    try {
      final pack = await ref
          .read(firstAidDownloadProvider.notifier)
          .fetchManifest(url);
      await const FirstAidPackUrlStore().write(text);
      ref.invalidate(firstAidPackUrlProvider);
      if (mounted) setState(() => _offered = pack);
    } on FormatException catch (error) {
      if (mounted) setState(() => _problem = error.message);
    } on Object catch (error) {
      if (mounted) setState(() => _problem = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: AppLocalizations.of(context)!.firstAidVideoPackImport,
      // Not a custom-extension filter, for the same reason the map
      // archive picker does not use one: several desktop platforms
      // refuse extensions they do not know.
      type: FileType.any,
    );
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final library = await ref.read(firstAidLibraryProvider.future);
      final problem = await library.importZip(path);
      ref.invalidate(installedFirstAidPackProvider);
      if (mounted) setState(() => _problem = problem);
    } on Object catch (error) {
      if (mounted) setState(() => _problem = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Installed extends ConsumerWidget {
  const _Installed({required this.state, required this.l10n});

  final InstalledFirstAidPack state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pack = state.pack;
    if (pack == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.videocam_off_outlined),
        title: Text(l10n.firstAidVideoPackNone),
      );
    }
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.video_library),
            title: Text(pack.name),
            subtitle: Text(
              l10n.firstAidVideoPackInstalled(
                state.present.length,
                pack.videos.length,
                formatByteSize(state.bytesOnDisk),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.firstAidVideoPackRemove),
            onTap: () => _confirmRemove(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.firstAidVideoPackRemove),
        content: Text(l10n.firstAidVideoPackRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    Feel.removed();
    final library = await ref.read(firstAidLibraryProvider.future);
    await library.removeAll();
    ref.invalidate(installedFirstAidPackProvider);
  }
}

/// A fetched manifest, waiting to be accepted.
///
/// Shown before anything is downloaded, with the total size spelled out,
/// because that is the one number somebody on a metered connection needs
/// before and not after.
class _Offer extends ConsumerWidget {
  const _Offer({required this.pack, required this.l10n});

  final FirstAidVideoPack pack;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pack.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.firstAidVideoPackOffer(
                pack.videos.length,
                formatByteSize(pack.totalBytes),
              ),
            ),
            const SizedBox(height: 8),
            for (final video in pack.videos)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(video.title),
                subtitle: Text(
                  [
                    if (video.credit.isNotEmpty) video.credit,
                    if (video.licence.isNotEmpty) video.licence,
                  ].join(' · '),
                ),
                trailing: Text(
                  video.bytes == null ? '' : formatByteSize(video.bytes!),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => ref
                  .read(firstAidDownloadProvider.notifier)
                  .install(pack, pack.videos),
              icon: const Icon(Icons.download),
              label: Text(l10n.firstAidVideoPackStart),
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends ConsumerWidget {
  const _Progress({required this.state, required this.l10n});

  final FirstAidDownloadState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = state.current;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isRunning) ...[
              Text(
                current?.title ?? '',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: state.progress?.fraction),
              const SizedBox(height: 8),
              Text(l10n.firstAidVideoPackProgress(state.done, state.total)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(firstAidDownloadProvider.notifier).cancel(),
                child: Text(l10n.cancelButton),
              ),
            ] else ...[
              Text(
                l10n.firstAidVideoPackDone(state.done, state.total),
                style: theme.textTheme.titleMedium,
              ),
              // Every clip that failed is named. A pack that quietly
              // arrives two videos short is a pack somebody trusts.
              for (final problem in state.problems)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    problem,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(firstAidDownloadProvider.notifier).dismiss(),
                child: Text(l10n.firstAidVideoPackClose),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

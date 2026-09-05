import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/map_archive_access.dart';
import '../application/offline_map_providers.dart';

/// Settings card for the offline map.
///
/// One decision to make — which file — and one thing worth showing back:
/// how far the archive actually zooms, because that is what decides
/// whether it is a street map or a country outline.
class OfflineMapCard extends ConsumerWidget {
  const OfflineMapCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(offlineMapProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.offlineMapIntro, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            switch (async) {
              AsyncLoading() => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              AsyncError(:final error) => Text(
                l10n.errorGeneric(error.toString()),
              ),
              _ => _Body(state: async.requireValue, l10n: l10n),
            },
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state, required this.l10n});

  final OfflineMapState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final archive = state.archive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!state.isConfigured)
          Text(l10n.offlineMapInactive, style: theme.textTheme.bodyMedium)
        else ...[
          Text(
            l10n.offlineMapActive(state.label!),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          if (archive != null)
            Text(
              l10n.offlineMapZoomRange(
                archive.header.minZoom,
                archive.header.maxZoom,
              ),
              style: theme.textTheme.bodySmall,
            ),
          if (state.problem != null)
            Text(
              _explain(state.problem!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _choose(context, ref),
              icon: const Icon(Icons.map_outlined),
              label: Text(
                state.isConfigured
                    ? l10n.offlineMapChangeAction
                    : l10n.offlineMapChooseAction,
              ),
            ),
            if (state.isConfigured)
              TextButton(
                onPressed: () => ref.read(offlineMapProvider.notifier).forget(),
                child: Text(l10n.offlineMapForgetAction),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final picked = await pickMapArchive(
      dialogTitle: l10n.settingsOfflineMapTitle,
    );
    if (picked == null) return;

    final problem = await ref
        .read(offlineMapProvider.notifier)
        .useArchive(location: picked.value, label: picked.label);
    if (problem == null || !context.mounted) return;

    // The card shows the same reason, but a file that was just picked and
    // refused deserves an answer at the moment of picking.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_explain(problem))));
  }

  String _explain(OfflineMapProblem problem) => switch (problem) {
    OfflineMapProblem.unreadable => l10n.offlineMapErrorUnreadable,
    OfflineMapProblem.notVectorTiles => l10n.offlineMapErrorNotVector,
    OfflineMapProblem.unknownSchema => l10n.offlineMapErrorSchema,
  };
}

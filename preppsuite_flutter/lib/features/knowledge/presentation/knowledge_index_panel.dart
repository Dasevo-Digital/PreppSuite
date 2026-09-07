import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/knowledge_indexer.dart';
import '../application/knowledge_providers.dart';

/// The state of the full-text index, and the one decision it needs.
///
/// Building it is the expensive part of searching text at all, so the
/// screen says how much work it is before asking for it rather than
/// starting a job of unknown length.
class KnowledgeIndexPanel extends ConsumerWidget {
  const KnowledgeIndexPanel({
    super.key,
    required this.l10n,
    this.compact = false,
  });

  final AppLocalizations l10n;

  /// Below a result list, where only the "not finished yet" case matters.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(knowledgeIndexProvider);
    final state = index.value;
    if (state == null) {
      // Finding out costs a moment: the archive's own index has to be
      // looked for and opened before anyone can be told whether one needs
      // building. A blank panel would read as "there is nothing here".
      if (!index.isLoading) return const SizedBox.shrink();
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final theme = Theme.of(context);
    final controller = ref.read(knowledgeIndexProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: switch (state.status) {
            KnowledgeIndexStatus.running => _running(theme, state, controller),
            KnowledgeIndexStatus.partial => _partial(theme, state, controller),
            KnowledgeIndexStatus.ready => _ready(theme, state, controller),
            KnowledgeIndexStatus.none => _missing(theme, state, controller),
            KnowledgeIndexStatus.builtIn => _builtIn(theme, state),
          },
        ),
      ),
    );
  }

  /// The archive brought its own. Nothing to decide, so nothing is asked
  /// — this only says why there is no button.
  List<Widget> _builtIn(ThemeData theme, KnowledgeIndexState state) {
    return [
      Text(l10n.knowledgeIndexBuiltInTitle, style: theme.textTheme.titleSmall),
      const SizedBox(height: 6),
      Text(
        l10n.knowledgeIndexBuiltIn(state.articleCount ?? 0),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 6),
      Text(
        l10n.knowledgeIndexBuiltInStemming,
        style: theme.textTheme.bodySmall,
      ),
    ];
  }

  List<Widget> _missing(
    ThemeData theme,
    KnowledgeIndexState state,
    KnowledgeIndexController controller,
  ) {
    final count = state.articleCount;

    return [
      Text(l10n.knowledgeIndexMissingTitle, style: theme.textTheme.titleSmall),
      const SizedBox(height: 6),
      Text(l10n.knowledgeIndexMissingBody, style: theme.textTheme.bodySmall),
      if (count != null) ...[
        const SizedBox(height: 8),
        Text(
          l10n.knowledgeIndexArticles(count),
          style: theme.textTheme.bodyMedium,
        ),
        if (count > indexConfirmThreshold) ...[
          const SizedBox(height: 4),
          Text(
            l10n.knowledgeIndexLargeWarning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          // Counting first is the same walk the indexing starts with, so
          // it costs nothing extra and turns "this will take a while" into
          // a number.
          onPressed: count == null
              ? controller.countArticles
              : controller.buildIndex,
          icon: const Icon(Icons.manage_search),
          label: Text(
            count == null
                ? l10n.knowledgeIndexCountAction
                : l10n.knowledgeIndexBuildAction,
          ),
        ),
      ),
    ];
  }

  List<Widget> _running(
    ThemeData theme,
    KnowledgeIndexState state,
    KnowledgeIndexController controller,
  ) {
    final progress = state.progress;

    return [
      Text(
        switch (progress?.phase) {
          IndexPhase.scanning => l10n.knowledgeIndexScanning(
            progress!.done,
            progress.total,
          ),
          IndexPhase.indexing => l10n.knowledgeIndexIndexing(
            progress!.done,
            progress.total,
          ),
          null => l10n.knowledgeIndexBuildAction,
        },
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 10),
      LinearProgressIndicator(value: progress?.fraction),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: controller.cancel,
          child: Text(l10n.knowledgeIndexCancelAction),
        ),
      ),
    ];
  }

  List<Widget> _partial(
    ThemeData theme,
    KnowledgeIndexState state,
    KnowledgeIndexController controller,
  ) {
    return [
      Text(
        l10n.knowledgeIndexPartial(
          state.progress?.done ?? 0,
          state.articleCount ?? 0,
        ),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: [
          FilledButton.tonal(
            onPressed: controller.buildIndex,
            child: Text(l10n.knowledgeIndexContinueAction),
          ),
          if (!compact)
            TextButton(
              onPressed: controller.discard,
              child: Text(l10n.knowledgeIndexDiscardAction),
            ),
        ],
      ),
    ];
  }

  List<Widget> _ready(
    ThemeData theme,
    KnowledgeIndexState state,
    KnowledgeIndexController controller,
  ) {
    return [
      Text(
        l10n.knowledgeIndexReady(state.articleCount ?? 0),
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: controller.discard,
          child: Text(l10n.knowledgeIndexDiscardAction),
        ),
      ),
    ];
  }
}

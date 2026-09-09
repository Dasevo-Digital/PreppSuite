import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/knowledge_providers.dart';
import '../application/recommended_archives.dart';
import 'kiwix_library_screen.dart';

/// A small, deliberate offline curriculum rather than an unstructured list
/// of very large downloads.  The content itself stays in standard ZIM files,
/// so it can be read by Kiwix too and remains under the person's control.
class ApolloLibraryScreen extends ConsumerWidget {
  const ApolloLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(knowledgeProvider).value;
    final archives = state?.library ?? const [];
    final installedLabels = {for (final archive in archives) archive.label};
    final knownSize = archives.fold<int>(
      0,
      (total, archive) => total + (archive.sizeBytes ?? 0),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.knowledgeApolloTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.knowledgeApolloMissionTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.knowledgeApolloMissionBody),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _OfflineStatus(
            l10n: l10n,
            archiveCount: archives.length,
            isOpen: state?.isReady ?? false,
            knownSize: knownSize,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.knowledgeApolloStartTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(l10n.knowledgeApolloStartBody),
          const SizedBox(height: 8),
          _PathCard(
            icon: Icons.health_and_safety_outlined,
            title: l10n.knowledgeApolloMedicalTitle,
            body: l10n.knowledgeApolloMedicalBody,
            archives: const [
              RecommendedArchive.medicine,
            ],
            installedLabels: installedLabels,
          ),
          _PathCard(
            icon: Icons.backpack_outlined,
            title: l10n.knowledgeApolloSurvivalTitle,
            body: l10n.knowledgeApolloSurvivalBody,
            archives: const [
              RecommendedArchive.wikibooks,
              RecommendedArchive.ifixit,
            ],
            installedLabels: installedLabels,
          ),
          _PathCard(
            icon: Icons.handyman_outlined,
            title: l10n.knowledgeApolloRepairTitle,
            body: l10n.knowledgeApolloRepairBody,
            archives: const [
              RecommendedArchive.ifixit,
              RecommendedArchive.wikibooks,
            ],
            installedLabels: installedLabels,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.knowledgeApolloFoundationsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _PathCard(
            icon: Icons.science_outlined,
            title: l10n.knowledgeApolloBasicsTitle,
            body: l10n.knowledgeApolloBasicsBody,
            archives: const [
              RecommendedArchive.wikipedia,
              RecommendedArchive.wikibooks,
            ],
            installedLabels: installedLabels,
          ),
          _PathCard(
            icon: Icons.school_outlined,
            title: l10n.knowledgeApolloSchoolTitle,
            body: l10n.knowledgeApolloSchoolBody,
            archives: const [
              RecommendedArchive.klexikon,
              RecommendedArchive.wikibooks,
              RecommendedArchive.phet,
              RecommendedArchive.wikiversity,
            ],
            installedLabels: installedLabels,
          ),
          _PathCard(
            icon: Icons.language_outlined,
            title: l10n.knowledgeApolloAdvancedTitle,
            body: l10n.knowledgeApolloAdvancedBody,
            archives: const [
              RecommendedArchive.khanAcademy,
              RecommendedArchive.wikiversity,
            ],
            installedLabels: installedLabels,
          ),
          if (archives.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.knowledgeApolloDownloadedTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final archive in archives)
                    ListTile(
                      leading: Icon(
                        archive.id == state?.selectedId
                            ? Icons.menu_book
                            : Icons.download_done_outlined,
                      ),
                      title: Text(archive.label),
                      subtitle: Text(
                        archive.id == state?.selectedId
                            ? l10n.knowledgeApolloOpened
                            : l10n.knowledgeApolloDownloaded,
                      ),
                      trailing: archive.id == state?.selectedId
                          ? const Icon(Icons.check_circle_outline)
                          : null,
                      onTap: () => ref
                          .read(knowledgeProvider.notifier)
                          .select(archive.id),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_copy_outlined),
              title: Text(l10n.knowledgeApolloPersonalTitle),
              subtitle: Text(l10n.knowledgeApolloPersonalBody),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineStatus extends StatelessWidget {
  const _OfflineStatus({
    required this.l10n,
    required this.archiveCount,
    required this.isOpen,
    required this.knownSize,
  });

  final AppLocalizations l10n;
  final int archiveCount;
  final bool isOpen;
  final int knownSize;

  @override
  Widget build(BuildContext context) {
    final progress = (archiveCount / 8).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOpen ? Icons.verified_outlined : Icons.inventory_2_outlined,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOpen
                        ? l10n.knowledgeApolloReady
                        : l10n.knowledgeApolloNotReady,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.knowledgeApolloStatus(archiveCount, _formatBytes(knownSize)),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 6),
            Text(
              l10n.knowledgeApolloStatusHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.archives,
    required this.installedLabels,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<RecommendedArchive> archives;
  final Set<String> installedLabels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(body),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final archive in archives)
                  OutlinedButton.icon(
                    icon: Icon(
                      archive.isInstalled(installedLabels)
                          ? Icons.download_done_outlined
                          : Icons.download_for_offline_outlined,
                      size: 18,
                    ),
                    label: Text(
                      archive.isInstalled(installedLabels)
                          ? '${archive.name} · ${l10n.knowledgeApolloDownloaded}'
                          : archive.name,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => KiwixLibraryScreen(
                          initialQuery: archive.query,
                          initialLanguage: archive.language,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.knowledgeApolloDownloadHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
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

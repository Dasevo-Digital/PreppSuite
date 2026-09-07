import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform_storage.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/download_folder.dart';
import '../application/download_providers.dart';

/// Where downloaded maps and archives are put.
///
/// Worth a settings entry of its own because the files are the largest
/// thing the app ever writes: on a desktop they may belong on another
/// disk entirely.
class DownloadFolderCard extends ConsumerWidget {
  const DownloadFolderCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(downloadFolderProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l10n.downloadFolderTitle),
            subtitle: Text(switch (folder) {
              AsyncData(:final value) => value.path,
              AsyncError(:final error) => l10n.errorGeneric(error.toString()),
              _ => '…',
            }),
          ),
          // Only where there is a folder picker worth the name — see
          // supportsChosenDownloadFolder. macOS has one and also goes
          // through the storage bridge, so this cannot be read off
          // usesNativeStoragePicker.
          if (supportsChosenDownloadFolder)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await const DownloadFolder().reset();
                        ref.invalidate(downloadFolderProvider);
                      },
                      child: Text(l10n.downloadFolderReset),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _choose(context, ref),
                      icon: const Icon(Icons.folder_open),
                      label: Text(l10n.downloadFolderChange),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final String path;
    String? handle;

    if (usesStorageBookmarks) {
      // The panel and the bookmark have to happen in one native call:
      // the permission hangs on the URL the panel hands back, not on its
      // path, and a path passed through Dart has already lost it.
      final Map<String, String>? picked;
      try {
        picked = await nativeStorageChannel.invokeMapMethod<String, String>(
          'pick',
          {'dialogTitle': l10n.downloadFolderTitle},
        );
      } on PlatformException catch (error) {
        // A folder the sandbox will not hand over permanently. Saying so
        // beats a button that closes a panel and changes nothing.
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorGeneric(error.message ?? error.code)),
            ),
          );
        }
        return;
      }
      final chosen = picked?['path'];
      if (chosen == null) return;
      path = chosen;
      handle = picked?['uri'];
    } else {
      final chosen = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.downloadFolderTitle,
      );
      if (chosen == null) return;
      path = chosen;
    }

    await Directory(path).create(recursive: true);
    await const DownloadFolder().use(path, handle: handle);
    ref.invalidate(downloadFolderProvider);
  }
}

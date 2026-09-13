import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/platform_storage.dart';
import '../../../core/portable_data.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'missing_data_folder_notice.dart';

/// Where this copy keeps its data, and how to move it onto a disk.
///
/// The card exists mostly to answer a question the app cannot answer any
/// other way: *which* copy am I looking at. A household on a stick and a
/// household on the machine look identical from the inside, and somebody
/// who has both needs to be able to tell which one they just edited.
class PortableDataCard extends StatefulWidget {
  const PortableDataCard({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  State<PortableDataCard> createState() => _PortableDataCardState();
}

class _PortableDataCardState extends State<PortableDataCard> {
  /// What the next start will use, once it has been changed here.
  ///
  /// The current run keeps the folder it started with — the databases
  /// are open and the settings are being written — so what this card
  /// reports after a change is a promise about the next launch, and it
  /// says so.
  String? _pending;
  var _cleared = false;

  Future<void> _choose() async {
    final l10n = widget.l10n;
    final String path;
    String? handle;

    if (usesStorageBookmarks) {
      // The panel and the bookmark have to happen in one native call: the
      // permission hangs on the URL the panel hands back, not on its
      // path. This is the whole macOS story — the sandbox cannot find a
      // folder beside the program, so it is pointed at one instead.
      final Map<String, String>? picked;
      try {
        picked = await nativeStorageChannel.invokeMapMethod<String, String>(
          'pick',
          {'dialogTitle': l10n.portableTitle},
        );
      } on PlatformException {
        if (mounted) _say(l10n.portableFolderUnusable);
        return;
      }
      final chosen = picked?['path'];
      if (chosen == null) return;
      path = chosen;
      handle = picked?['uri'];
    } else {
      final chosen = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.portableTitle,
      );
      if (chosen == null) return;
      path = chosen;
    }

    await rememberPortableFolder(location: path, handle: handle);
    if (!mounted) return;
    setState(() {
      _pending = path;
      _cleared = false;
    });
  }

  Future<void> _forget() async {
    await forgetPortableFolder();
    if (!mounted) return;
    setState(() {
      _pending = null;
      _cleared = true;
    });
  }

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);

    if (!supportsPortableData) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(l10n.portableTitle),
          subtitle: Text(l10n.portableUnsupported),
        ),
      );
    }

    final location = portableLocation;
    final changed = _pending != null || _cleared;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.portableTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Before anything else, because it contradicts the line
            // underneath: without this the card reads "Auf diesem
            // Rechner" to somebody who chose a disk and simply has not
            // plugged it in.
            if (location.missingChoice case final chosen?) ...[
              MissingDataFolderNotice(path: chosen),
              const SizedBox(height: 12),
            ],

            Text(
              location.isPortable
                  ? l10n.portableCarried
                  : l10n.portableInstalled,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            // The path itself, always. "It is portable" without "and here
            // is where" is not something anybody can act on.
            Text(
              location.directory?.path ?? l10n.portableInstalledHint,
              style: theme.textTheme.bodySmall,
            ),
            if (_sourceLine(l10n, location.source) case final line?) ...[
              const SizedBox(height: 2),
              Text(line, style: theme.textTheme.bodySmall),
            ],

            if (changed) ...[
              const SizedBox(height: 12),
              Text(
                _pending ?? l10n.portableInstalled,
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                l10n.portableRestartNeeded,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],

            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: _choose,
                  child: Text(l10n.portableChoose),
                ),
                if (location.isPortable || _pending != null)
                  OutlinedButton(
                    onPressed: _forget,
                    child: Text(l10n.portableForget),
                  ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              // On Windows and Linux the folder is found by itself, which
              // is the whole convenience; on macOS it cannot be, and
              // saying why beats letting somebody try it and wonder.
              findsPortableFolderByItself
                  ? l10n.portableExplain(portableFolderName)
                  : l10n.portableExplainMac,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(l10n.portableTakeover, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(l10n.portableRelativeNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  String? _sourceLine(AppLocalizations l10n, PortableSource source) =>
      switch (source) {
        PortableSource.installed => null,
        PortableSource.besideTheProgram => l10n.portableSourceBeside(
          portableFolderName,
        ),
        PortableSource.chosen => l10n.portableSourceChosen,
        PortableSource.environment => l10n.portableSourceEnvironment(
          portableEnvironmentVariable,
        ),
      };
}

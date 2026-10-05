import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/save_file.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../downloads/application/byte_size.dart';
import '../../downloads/application/download_folder.dart';
import '../../knowledge/application/document_fingerprint.dart';
import '../../knowledge/application/knowledge_providers.dart';
import '../../knowledge/application/personal_document_index.dart';
import '../../knowledge/application/personal_document_store.dart';
import '../../knowledge/application/zim_store.dart';
import '../../maps/application/map_archive_access.dart';
import '../../maps/application/offline_map_providers.dart';
import '../../maps/application/offline_map_store.dart';
import '../../maps/application/pmtiles_archive.dart' show ByteRangeSource;
import '../../transfer/application/handover_photos.dart';
import '../application/backup_container.dart';
import '../application/backup_files.dart';
import '../application/backup_service.dart';

/// The screens around a format 3 backup (#114): what goes in, how far it
/// has got, and what comes back.
///
/// Shared by the settings, the setup screen and the backup check, which
/// used to read a JSON file each in their own way.

/// A picked backup file, and the source it is read through. The source
/// has to stay open until the files are restored, so the caller closes
/// it.
typedef PickedBackup = ({BackupFile file, ByteRangeSource source});

/// Lets the person pick a backup and reads it as far as its envelope.
///
/// Null when nothing was picked. A file that is not a backup comes back
/// as an exception from [BackupFile.read]'s caller, the same as a wrong
/// passphrase later: "this did not open".
///
/// Any file type: a format 3 backup has an extension no platform knows,
/// and filtering for `.json` would hide every new backup while showing
/// every old one.
Future<PickedBackup?> pickBackup({required String dialogTitle}) async {
  final picked = await pickMapArchive(dialogTitle: dialogTitle);
  if (picked == null) return null;
  final source = await openMapArchive(picked.value);
  try {
    final file = await BackupFile.read(source);
    if (file == null) {
      await source.close();
      throw const BackupFormatException('not a backup');
    }
    return (file: file, source: source);
  } on Object {
    await source.close();
    rethrow;
  }
}

/// How a long backup job tells the dialog where it is.
class BackupProgress {
  final cancellation = BackupCancellation();
  final label = ValueNotifier<String?>(null);

  /// Null while the total is not known.
  final fraction = ValueNotifier<double?>(null);

  int _done = 0;
  int? _total;

  void start(int? totalBytes) {
    _done = 0;
    _total = totalBytes == null || totalBytes == 0 ? null : totalBytes;
    fraction.value = _total == null ? null : 0;
  }

  void add(int bytes) {
    _done += bytes;
    final total = _total;
    if (total != null) fraction.value = (_done / total).clamp(0, 1);
  }

  void dispose() {
    label.dispose();
    fraction.dispose();
  }
}

/// Runs [job] behind a dialog that shows its progress and can cancel it.
///
/// The dialog cannot be swiped away: leaving a backup half written by
/// tapping beside the dialog is not something anybody means to do.
Future<T> runWithBackupProgress<T>(
  BuildContext context, {
  required String title,
  required Future<T> Function(BackupProgress progress) job,
}) async {
  final progress = BackupProgress();
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => _BackupProgressDialog(title: title, progress: progress),
    ),
  );
  try {
    return await job(progress);
  } finally {
    navigator.pop();
    // After the dialog's last frame, which still listens to these.
    WidgetsBinding.instance.addPostFrameCallback((_) => progress.dispose());
  }
}

class _BackupProgressDialog extends StatelessWidget {
  const _BackupProgressDialog({required this.title, required this.progress});

  final String title;
  final BackupProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<double?>(
              valueListenable: progress.fraction,
              builder: (context, value, _) =>
                  LinearProgressIndicator(value: value),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String?>(
              valueListenable: progress.label,
              builder: (context, value, _) => Text(
                value ?? l10n.backupProgressPreparing,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: progress.cancellation.cancel,
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ],
      ),
    );
  }
}

/// One line in the list of what a backup holds: a group of entries that
/// is taken or left together.
class _Choice {
  _Choice({
    required this.title,
    required this.entries,
    this.present = false,
  }) : selected = !present;

  final String title;
  final List<BackupFileEntry> entries;

  /// Already on this device, which only a restore asks.
  final bool present;
  bool selected;

  int? get size {
    var total = 0;
    for (final entry in entries) {
      final size = entry.size;
      if (size == null) return null;
      total += size;
    }
    return total;
  }
}

/// The groups the list is made of: the photos as one, the documents as
/// one, the map, and each archive on its own -- those are the large
/// parts, and whether a fifty-gigabyte encyclopedia goes along is a
/// question worth asking per encyclopedia.
List<_Choice> _choices(
  AppLocalizations l10n,
  List<BackupFileEntry> entries, {
  Set<int> present = const {},
}) {
  List<BackupFileEntry> of(BackupFileKind kind) => [
    for (final entry in entries)
      if (entry.kind == kind) entry,
  ];
  final photos = of(BackupFileKind.photo);
  final documents = of(BackupFileKind.document);
  return [
    if (photos.isNotEmpty)
      _Choice(
        title: l10n.backupContentsPhotos(photos.length),
        entries: photos,
      ),
    if (documents.isNotEmpty)
      _Choice(
        title: l10n.backupContentsDocuments(documents.length),
        entries: documents,
        present: documents.every((entry) => present.contains(entry.index)),
      ),
    for (final entry in of(BackupFileKind.map))
      _Choice(
        title: '${l10n.backupContentsMap}: ${entry.label}',
        entries: [entry],
        present: present.contains(entry.index),
      ),
    for (final entry in of(BackupFileKind.archive))
      _Choice(
        title: entry.meta['title'] is String
            ? '${entry.meta['title']} (${entry.label})'
            : entry.label,
        entries: [entry],
        present: present.contains(entry.index),
      ),
  ];
}

/// Asks which files go into, or come out of, a backup. Answers the
/// chosen indexes, or null when the person backed out.
Future<Set<int>?> chooseBackupFiles(
  BuildContext context, {
  required List<BackupFileEntry> entries,
  required bool restoring,
  Set<int> present = const {},
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<Set<int>>(
    context: context,
    builder: (_) => _BackupContentsDialog(
      l10n: l10n,
      restoring: restoring,
      choices: _choices(l10n, entries, present: present),
    ),
  );
}

class _BackupContentsDialog extends StatefulWidget {
  const _BackupContentsDialog({
    required this.l10n,
    required this.restoring,
    required this.choices,
  });

  final AppLocalizations l10n;
  final bool restoring;
  final List<_Choice> choices;

  @override
  State<_BackupContentsDialog> createState() => _BackupContentsDialogState();
}

class _BackupContentsDialogState extends State<_BackupContentsDialog> {
  String _size(int? bytes) => bytes == null
      ? widget.l10n.backupContentsSizeUnknown
      : formatByteSize(bytes);

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final chosen = [
      for (final choice in widget.choices)
        if (choice.selected) choice,
    ];
    int? total = 0;
    for (final choice in chosen) {
      final size = choice.size;
      total = size == null || total == null ? null : total + size;
    }

    return AlertDialog(
      title: Text(
        widget.restoring
            ? l10n.backupRestoreContentsTitle
            : l10n.backupContentsTitle,
      ),
      content: SizedBox(
        width: 480,
        child: ListView(
          shrinkWrap: true,
          children: [
            CheckboxListTile(
              value: true,
              onChanged: null,
              title: Text(l10n.backupContentsHousehold),
              subtitle: Text(l10n.backupContentsAlways),
              contentPadding: EdgeInsets.zero,
            ),
            for (final choice in widget.choices)
              CheckboxListTile(
                value: choice.selected,
                onChanged: (value) =>
                    setState(() => choice.selected = value ?? false),
                title: Text(choice.title),
                subtitle: Text(
                  choice.present
                      ? '${_size(choice.size)} · ${l10n.backupContentsPresent}'
                      : _size(choice.size),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            const SizedBox(height: 8),
            Text(
              l10n.backupContentsTotal(
                total == null ? l10n.backupContentsSizeUnknown : _size(total),
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (!widget.restoring) ...[
              const SizedBox(height: 8),
              Text(
                l10n.backupContentsLargeHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            for (final choice in chosen)
              for (final entry in choice.entries) entry.index,
          }),
          child: Text(l10n.backupContentsContinue),
        ),
      ],
    );
  }
}

/// What a finished backup write reports.
typedef WrittenBackup = ({File file, List<String> unreadable});

/// Asks what goes in, then writes a format 3 backup to [file] behind a
/// progress dialog. Null when the person backed out of the list.
///
/// A cancelled or failed write leaves nothing behind: half a backup that
/// looks like a whole one is worse than none.
Future<WrittenBackup?> writeBackupWithProgress(
  BuildContext context,
  WidgetRef ref, {
  required String householdId,
  required String passphrase,
  required Future<File?> Function() target,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final database = ref.read(appDatabaseProvider);
  final candidates = await collectBackupFiles(
    database,
    householdId: householdId,
  );
  if (!context.mounted) return null;

  var files = candidates;
  if (candidates.isNotEmpty) {
    final chosen = await chooseBackupFiles(
      context,
      entries: [for (final candidate in candidates) candidate.entry],
      restoring: false,
    );
    if (chosen == null || !context.mounted) return null;
    files = [
      for (final candidate in candidates)
        if (chosen.contains(candidate.entry.index)) candidate,
    ];
  }

  final file = await target();
  if (file == null || !context.mounted) return null;

  int? total = 0;
  for (final candidate in files) {
    final size = candidate.entry.size;
    total = size == null || total == null ? null : total + size;
  }

  return runWithBackupProgress(
    context,
    title: l10n.backupProgressWriting,
    job: (progress) async {
      progress.start(total);
      final out = await file.open(mode: FileMode.write);
      try {
        final unreadable = await BackupService(database).writeBackup(
          out: out,
          householdId: householdId,
          passphrase: passphrase,
          files: files,
          cancellation: progress.cancellation,
          onFile: (entry) => progress.label.value = entry.label,
          onBytes: progress.add,
        );
        await out.close();
        return (file: file, unreadable: unreadable);
      } on Object {
        await out.close();
        try {
          await file.delete();
        } on FileSystemException {
          // Never written.
        }
        rethrow;
      }
    },
  );
}

/// Where "Datensicherung erstellen" writes.
///
/// On the desktops the save dialog names a path and the backup is
/// written straight there, however large it is. On iOS and Android the
/// dialog writes the file itself and wants the bytes in hand, which a
/// backup with archives in it cannot be -- so it is written into the
/// app's temporary folder first, and [saveOrShareBackup] decides what
/// happens next.
Future<File?> backupTarget({required String dialogTitle}) async {
  final name = backupFileName();
  if (_pickerWritesItself) {
    return File(
      '${(await getTemporaryDirectory()).path}${Platform.pathSeparator}$name',
    );
  }
  final path = await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: name,
  );
  return path == null ? null : File(path);
}

/// A temporary file for a backup that is handed to the share sheet.
Future<File> sharedBackupTarget() async => File(
  '${(await getTemporaryDirectory()).path}'
  '${Platform.pathSeparator}${backupFileName()}',
);

bool get _pickerWritesItself =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid);

/// `preppsuite-backup-2026-10-05.preppsuite`. Dated, so a second backup
/// does not quietly replace the first in a folder that keeps both.
String backupFileName([DateTime? now]) {
  final day = (now ?? DateTime.now()).toIso8601String().substring(0, 10);
  return 'preppsuite-backup-$day.preppsuite';
}

/// Up to this size a backup on iOS and Android goes through the save
/// dialog, which wants it in memory. Above it the share sheet takes the
/// file instead -- "In Dateien sichern" is there too.
const _pickerLimitBytes = 100 * 1024 * 1024;

/// Finishes a backup written by [backupTarget] on iOS and Android.
/// Answers false when the person backed out.
Future<bool> saveOrShareBackup(
  File file, {
  required String dialogTitle,
  required String subject,
}) async {
  if (!_pickerWritesItself) return true;
  try {
    if (await file.length() <= _pickerLimitBytes) {
      return await saveFileWithPicker(
        dialogTitle: dialogTitle,
        fileName: backupFileName(),
        extension: 'preppsuite',
        bytes: await file.readAsBytes(),
      );
    }
    await shareBackup(file, subject: subject);
    return true;
  } finally {
    await _deleteQuietly(file);
  }
}

Future<void> shareBackup(File file, {required String subject}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/octet-stream')],
      subject: subject,
    ),
  );
}

Future<void> _deleteQuietly(File file) async {
  try {
    await file.delete();
  } on FileSystemException {
    // Gone already.
  }
}

/// Which of [entries] this device already has, readable where it is.
///
/// By name, and only when the file can actually be opened: a library
/// entry whose permission was lost -- the case a new app identity leaves
/// behind -- is exactly the one the backup should put back.
Future<Set<int>> presentBackupFiles(List<BackupFileEntry> entries) async {
  final documents = {
    for (final document in await const PersonalDocumentStore().load())
      document.label: document.location,
  };
  final archives = {
    for (final archive in (await const ZimStore().library()).archives)
      archive.label: archive.location,
  };
  final map = await const OfflineMapStore().archive();

  final present = <int>{};
  for (final entry in entries) {
    final location = switch (entry.kind) {
      BackupFileKind.document => documents[entry.label],
      BackupFileKind.archive => archives[entry.label],
      BackupFileKind.map => map?.label == entry.label ? map?.location : null,
      BackupFileKind.photo => null,
    };
    if (location != null && await _opens(location)) present.add(entry.index);
  }
  return present;
}

Future<bool> _opens(String location) async {
  try {
    final source = await openMapArchive(location);
    final first = await source.read(0, 1);
    await source.close();
    return first.isNotEmpty;
  } on Object {
    return false;
  }
}

/// Puts back the files of an opened backup, after asking which.
///
/// Null when there were none, or the person chose none. The rows have
/// to be restored before this: a picture is attached to its row.
Future<BackupFilesRestored?> restoreBackupFilesWithProgress(
  BuildContext context,
  WidgetRef ref, {
  required OpenedBackup opened,
}) async {
  final reader = opened.file.reader;
  if (reader == null || opened.files.isEmpty) return null;
  final l10n = AppLocalizations.of(context)!;

  final present = await presentBackupFiles(opened.files);
  if (!context.mounted) return null;
  final selected = await chooseBackupFiles(
    context,
    entries: opened.files,
    restoring: true,
    present: present,
  );
  if (selected == null || selected.isEmpty || !context.mounted) return null;

  final database = ref.read(appDatabaseProvider);
  final householdId = opened.snapshot.householdId;
  String? selectedArchive;
  final targets = BackupFileTargets(
    folder: () => const DownloadFolder().current(),
    addPhotos: (photos) => applyHouseholdPhotos(
      database,
      householdId: householdId,
      photos: photos,
    ),
    addDocument: (location, label, entry) async {
      // An entry of the same name that could not be opened -- which is
      // why this one is being restored -- makes way for it rather than
      // standing beside it as a second, broken copy.
      for (final stale in await const PersonalDocumentStore().load()) {
        if (stale.label == label && stale.location != location) {
          await PersonalDocumentIndexer().remove(stale.id);
          await const PersonalDocumentStore().remove(stale.id);
        }
      }
      final documents = await const PersonalDocumentStore().add(
        location: location,
        label: label,
      );
      // Indexed again where it was indexed before, so a search finds it
      // as it did. The index itself is not in the backup: it is derived
      // from the file and sealed with this device's key.
      if (entry.meta['indexed'] != true) return;
      final document = documents.firstWhere((d) => d.location == location);
      final fingerprint = await documentFingerprint(location);
      final result = await PersonalDocumentIndexer().index(document);
      await const PersonalDocumentStore().updateIndex(
        document.id,
        status: result.status.name,
        characters: result.characters,
        fingerprint: fingerprint,
      );
    },
    useMap: (location, label) async {
      await ref.read(offlineMapProvider.future);
      await ref
          .read(offlineMapProvider.notifier)
          .useArchive(location: location, label: label);
    },
    addArchive: (location, label, entry) async {
      // Awaited first, or the library written next is the empty one of a
      // provider still building -- and every other archive is gone.
      final library = await ref.read(knowledgeProvider.future);
      // The same for an archive the library holds by name and cannot
      // open any more.
      for (final stale in library.library) {
        if (stale.label == label && stale.location != location) {
          await ref.read(knowledgeProvider.notifier).remove(stale.id);
        }
      }
      await ref
          .read(knowledgeProvider.notifier)
          .useArchive(location: location, label: label);
      if (entry.meta['selected'] == true) selectedArchive = location;
    },
  );

  int? total = 0;
  for (final entry in opened.files) {
    if (!selected.contains(entry.index)) continue;
    final size = entry.size;
    total = size == null || total == null ? null : total + size;
  }

  final result = await runWithBackupProgress(
    context,
    title: l10n.backupProgressRestoring,
    job: (progress) async {
      progress.start(total);
      String? current;
      return restoreBackupFiles(
        reader: reader,
        key: opened.key,
        manifest: opened.files,
        selected: selected,
        targets: targets,
        cancellation: progress.cancellation,
        onBytes: (entry, bytes) {
          if (current != entry.label) {
            current = entry.label;
            progress.label.value = entry.label;
          }
          progress.add(bytes);
        },
      );
    },
  );

  // The archive that was open when the backup was made is the one that
  // is open now, rather than whichever happened to be restored last.
  final open = selectedArchive;
  if (open != null) {
    await ref
        .read(knowledgeProvider.notifier)
        .useArchive(location: open, label: '');
  }
  return result;
}

/// One line saying how a file restore went, or null when it went
/// without a word worth saying.
String? describeFilesRestored(
  AppLocalizations l10n,
  BackupFilesRestored? result,
) {
  if (result == null) return null;
  final parts = [
    if (result.restored > 0) l10n.backupFilesRestored(result.restored),
    if (result.failed.isNotEmpty)
      l10n.backupFilesFailed(result.failed.join(', ')),
  ];
  return parts.isEmpty ? null : parts.join(' ');
}

/// Whether [error] is a cancelled backup job rather than a failed one.
bool isBackupCancelled(Object error) => error is BackupCancelled;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../../core/photo_vault.dart';
import '../../../core/platform_storage.dart';
import '../../../local_db/database.dart';
import '../../knowledge/application/personal_document_store.dart';
import '../../knowledge/application/zim_store.dart';
import '../../maps/application/map_archive_access.dart';
import '../../maps/application/offline_map_store.dart';
import '../../maps/application/pmtiles_archive.dart' show ByteRangeSource;
import '../../sharing/application/folder_crypto.dart';
import '../../transfer/application/handover_photos.dart';
import 'backup_container.dart';

/// The files of a household that are not rows: what format 3 adds to a
/// backup (#114).
///
/// The rows say a photo, a document, an archive or a map exists. The
/// files are where they are, on this device -- and a backup that restores
/// the household without them restores a library with no books in it.
enum BackupFileKind {
  photo('photo'),
  document('document'),
  archive('archive'),
  map('map');

  const BackupFileKind(this.marker);

  /// Written into the file rather than the enum's name, so renaming the
  /// enum cannot change the format.
  final String marker;

  /// Private files are encrypted in the backup; public ones are not. See
  /// `backup_container.dart` for why.
  bool get encrypted => this == photo || this == document;

  static BackupFileKind? fromMarker(Object? raw) {
    for (final kind in values) {
      if (kind.marker == raw) return kind;
    }
    return null;
  }
}

/// One file in a backup's list.
class BackupFileEntry {
  const BackupFileEntry({
    required this.index,
    required this.kind,
    required this.label,
    this.size,
    this.meta = const {},
  });

  /// Its place in the container. Matches the entry that carries the bytes.
  final int index;
  final BackupFileKind kind;

  /// The file's name, which is what a person recognises.
  final String label;

  /// What it measured when the backup was written, where that was known.
  /// Android hands out documents without a size.
  final int? size;

  /// What the kind needs to put it back: the row a photo belongs to, the
  /// title of an archive, when a document was added.
  final Map<String, Object?> meta;

  BackupFileEntry withIndex(int index) => BackupFileEntry(
    index: index,
    kind: kind,
    label: label,
    size: size,
    meta: meta,
  );

  Map<String, Object?> toJson() => {
    'index': index,
    'kind': kind.marker,
    'label': label,
    'size': size,
    'meta': meta,
  };

  static BackupFileEntry? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final index = raw['index'];
    final kind = BackupFileKind.fromMarker(raw['kind']);
    final label = raw['label'];
    final size = raw['size'];
    final meta = raw['meta'];
    if (index is! int || index < 0 || kind == null) return null;
    if (label is! String || label.isEmpty) return null;
    return BackupFileEntry(
      index: index,
      kind: kind,
      label: label,
      size: size is int && size >= 0 ? size : null,
      meta: meta is Map<String, Object?> ? meta : const {},
    );
  }
}

/// A file this device could put into a backup, and how to read it.
class BackupCandidate {
  const BackupCandidate({required this.entry, required this.open});

  final BackupFileEntry entry;
  final Future<ByteRangeSource> Function() open;
}

/// Everything beside the rows that belongs to [householdId] on this
/// device, in the order it goes into the file: the small private things
/// first, the archives last, so that a backup cut short by a full disk
/// has lost the part that can be downloaded again.
Future<List<BackupCandidate>> collectBackupFiles(
  AppDatabase db, {
  required String householdId,
}) async {
  final candidates = <BackupCandidate>[];
  void add(
    BackupFileKind kind,
    String label,
    int? size,
    Map<String, Object?> meta,
    Future<ByteRangeSource> Function() open,
  ) => candidates.add(
    BackupCandidate(
      entry: BackupFileEntry(
        index: candidates.length,
        kind: kind,
        label: label,
        size: size,
        meta: meta,
      ),
      open: open,
    ),
  );

  for (final photo in await householdPhotoFiles(db, householdId: householdId)) {
    add(
      BackupFileKind.photo,
      p.basename(photo.file.path),
      await _length(photo.file),
      {'owner': photo.owner.marker, 'clientId': photo.clientId},
      () async {
        // Opened here: the vault's key belongs to this installation, and
        // the backup has to open on another one.
        final bytes = await const PhotoVault().read(photo.file);
        if (bytes == null) {
          throw FileSystemException('photo unreadable', photo.file.path);
        }
        return MemoryByteRangeSource(bytes);
      },
    );
  }

  for (final document in await const PersonalDocumentStore().load()) {
    add(
      BackupFileKind.document,
      document.label,
      await locationSize(document.location),
      {
        'addedAt': document.addedAt.toUtc().toIso8601String(),
        'indexed': document.isSearchable,
      },
      () => openMapArchive(document.location),
    );
  }

  final map = await const OfflineMapStore().archive();
  if (map != null) {
    add(
      BackupFileKind.map,
      map.label,
      await locationSize(map.location),
      const {},
      () => openMapArchive(map.location),
    );
  }

  final library = await const ZimStore().library();
  for (final archive in library.archives) {
    add(
      BackupFileKind.archive,
      archive.label,
      archive.sizeBytes ?? await locationSize(archive.location),
      {
        'title': ?archive.title,
        'selected': archive.id == library.selectedId,
      },
      () => openMapArchive(archive.location),
    );
  }
  return candidates;
}

/// How large the file at [location] is, or null where that cannot be
/// asked without reading it -- an Android document.
Future<int?> locationSize(String location) async {
  var path = location;
  if (isNativeStorageHandle(location)) {
    final resolved = await resolveStoragePath(location);
    if (resolved == null) return null;
    path = resolved;
  }
  return _length(File(path));
}

Future<int?> _length(File file) async {
  try {
    return await file.length();
  } on FileSystemException {
    return null;
  }
}

/// Where restored files go, and how they are taken into use.
///
/// Callbacks rather than providers: taking an archive into use opens it
/// and tells every screen, and that belongs to the controllers, which
/// this file does not know.
class BackupFileTargets {
  const BackupFileTargets({
    required this.folder,
    required this.addPhotos,
    required this.addDocument,
    required this.useMap,
    required this.addArchive,
  });

  /// Where documents, archives and the map are written. The download
  /// folder in the app: the place the user already knows these files go.
  final Future<Directory> Function() folder;

  /// Returns how many pictures the household gained.
  final Future<int> Function(List<HandoverPhoto> photos) addPhotos;

  final Future<void> Function(
    String location,
    String label,
    BackupFileEntry entry,
  )
  addDocument;
  final Future<void> Function(String location, String label) useMap;
  final Future<void> Function(
    String location,
    String label,
    BackupFileEntry entry,
  )
  addArchive;
}

/// How a file restore went.
class BackupFilesRestored {
  const BackupFilesRestored({required this.restored, required this.failed});

  final int restored;

  /// Labels of the files that did not come back: damaged, missing from
  /// the container, or refused by the disk.
  final List<String> failed;
}

/// Pictures are gathered and handed over in batches of about this much,
/// so a household with thousands of them is never all in memory at once.
const _photoBatchBytes = 20 * 1024 * 1024;

/// The subfolder documents are written into. They are the household's own
/// papers, and a folder of their own keeps them apart from the archives.
const restoredDocumentsFolder = 'PreppSuite-Dokumente';

/// Reads the files out of [reader] and puts the ones in [selected] back.
///
/// The rows have to be restored first: a picture is attached to its row,
/// and a row that is not there yet has nothing to attach it to.
Future<BackupFilesRestored> restoreBackupFiles({
  required BackupReader reader,
  required FolderKey key,
  required List<BackupFileEntry> manifest,
  required Set<int> selected,
  required BackupFileTargets targets,
  BackupCancellation? cancellation,
  void Function(BackupFileEntry entry, int bytes)? onBytes,
}) async {
  final byIndex = {for (final entry in manifest) entry.index: entry};
  final seen = <int>{};
  final failed = <String>[];
  var restored = 0;

  var photos = <HandoverPhoto>[];
  var photoBytes = 0;
  Future<void> flushPhotos() async {
    if (photos.isEmpty) return;
    restored += await targets.addPhotos(photos);
    photos = [];
    photoBytes = 0;
  }

  while (true) {
    final index = await reader.nextEntry();
    if (index == null) break;
    final entry = byIndex[index];
    if (entry == null || !selected.contains(index) || !seen.add(index)) {
      await reader.skipEntry();
      continue;
    }

    void progress(int bytes) => onBytes?.call(entry, bytes);

    if (entry.kind == BackupFileKind.photo) {
      final buffer = BytesBuilder(copy: false);
      final ok = await reader.copyEntry(
        index,
        encrypted: true,
        key: key,
        write: (bytes) async => buffer.add(bytes),
        cancellation: cancellation,
        onBytes: progress,
      );
      final owner = PhotoOwner.fromMarker(entry.meta['owner']);
      final clientId = entry.meta['clientId'];
      final name = HandoverPhoto.safeName(entry.label);
      if (!ok || owner == null || clientId is! String || name == null) {
        failed.add(entry.label);
        continue;
      }
      final bytes = buffer.takeBytes();
      photos.add(
        HandoverPhoto(
          owner: owner,
          clientId: clientId,
          name: name,
          bytes: bytes,
        ),
      );
      photoBytes += bytes.length;
      if (photoBytes >= _photoBatchBytes) await flushPhotos();
      continue;
    }

    final written = await _restoreToFile(
      reader,
      entry,
      key: key,
      targets: targets,
      cancellation: cancellation,
      onBytes: progress,
    );
    if (written == null) {
      failed.add(entry.label);
      continue;
    }
    try {
      final remembered = await rememberStoragePath(written, label: entry.label);
      final location = remembered?.value ?? written;
      switch (entry.kind) {
        case BackupFileKind.document:
          await targets.addDocument(location, entry.label, entry);
        case BackupFileKind.map:
          await targets.useMap(location, entry.label);
        case BackupFileKind.archive:
          await targets.addArchive(location, entry.label, entry);
        case BackupFileKind.photo:
          break;
      }
      restored++;
    } on Object {
      failed.add(entry.label);
    }
  }
  await flushPhotos();

  // Listed and asked for, but no bytes in the file: the backup could not
  // read it when it was written.
  for (final index in selected) {
    final entry = byIndex[index];
    if (entry != null && !seen.contains(index)) failed.add(entry.label);
  }
  return BackupFilesRestored(restored: restored, failed: failed);
}

/// Writes one entry into the target folder and returns its path, or null
/// when it did not survive the check.
///
/// A file of the same name and size that is already there is taken as it
/// is: restoring onto the machine that made the backup should not copy
/// fifty gigabytes over themselves.
Future<String?> _restoreToFile(
  BackupReader reader,
  BackupFileEntry entry, {
  required FolderKey key,
  required BackupFileTargets targets,
  BackupCancellation? cancellation,
  void Function(int bytes)? onBytes,
}) async {
  final name = HandoverPhoto.safeName(entry.label);
  if (name == null) {
    await reader.skipEntry();
    return null;
  }
  var directory = await targets.folder();
  if (entry.kind == BackupFileKind.document) {
    directory = Directory(p.join(directory.path, restoredDocumentsFolder));
  }
  await directory.create(recursive: true);

  var target = File(p.join(directory.path, name));
  if (await target.exists()) {
    if (entry.size != null && await _length(target) == entry.size) {
      await reader.skipEntry();
      return target.path;
    }
    target = await _freeName(directory, name);
  }

  final partial = File('${target.path}.part');
  final out = await partial.open(mode: FileMode.write);
  bool ok;
  try {
    ok = await reader.copyEntry(
      entry.index,
      encrypted: entry.kind.encrypted,
      key: key,
      write: out.writeFrom,
      cancellation: cancellation,
      onBytes: onBytes,
    );
    await out.flush();
  } on Object {
    await out.close();
    await _delete(partial);
    rethrow;
  }
  await out.close();
  if (!ok) {
    await _delete(partial);
    return null;
  }
  await partial.rename(target.path);
  await excludeFromBackup(target.path);
  return target.path;
}

/// `name (2).ext`, `name (3).ext` … whichever is free first.
Future<File> _freeName(Directory directory, String name) async {
  final extension = p.extension(name);
  final stem = p.basenameWithoutExtension(name);
  for (var n = 2; ; n++) {
    final candidate = File(p.join(directory.path, '$stem ($n)$extension'));
    if (!await candidate.exists()) return candidate;
  }
}

Future<void> _delete(File file) async {
  try {
    await file.delete();
  } on FileSystemException {
    // Never written, or already gone.
  }
}

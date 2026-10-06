import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/platform_storage.dart';
import '../../../core/portable_data.dart';
import '../../knowledge/application/personal_document_store.dart';
import '../../knowledge/application/zim_store.dart';
import '../../maps/application/map_archive_access.dart';
import '../../maps/application/offline_map_store.dart';
import 'download_folder.dart';

/// Finds the map, the knowledge archives and the household's documents
/// again after an update has cut the app off from them (#120).
///
/// The files did not move. What breaks is the way the app remembered
/// them, and it breaks differently per platform:
///
/// * **iOS** keeps the app's own folder at a path with a container id in
///   it, and that id can change with an update. A download remembered by
///   its full path then points into a folder that no longer exists, while
///   the same file sits in the new one.
/// * **macOS** remembers a picked file by a security-scoped bookmark, and
///   the sandbox ties that to the signature of the app that made it. A
///   build signed ad hoc has a new signature every time, so a bookmark
///   from the last version may not open in this one.
///
/// In both cases the file is usually still in a folder the app *can* reach:
/// the download folder, or the data folder the household lives in. So at
/// start-up every remembered file is tried, and one that does not open is
/// looked for there -- by its name, and for an archive by its exact size
/// -- and remembered anew. The archive keeps its id and with it its
/// search index. What is not found is left exactly as it was: a disk that
/// is not plugged in is not a reason to forget anything.
class FileRelinker {
  FileRelinker({
    Future<List<Directory>> Function()? folders,
    Future<bool> Function(String location)? opens,
    Future<String> Function(String path, String label)? remember,
  }) : _folders = folders ?? _reachableFolders,
       _opens = opens ?? _locationOpens,
       _remember = remember ?? _rememberPath;

  final Future<List<Directory>> Function() _folders;
  final Future<bool> Function(String location) _opens;
  final Future<String> Function(String path, String label) _remember;

  /// How deep below each folder files are looked for. The download folder
  /// holds its archives at the top and documents one level down; anything
  /// deeper is somebody's own filing and not the app's to search.
  static const searchDepth = 2;

  /// Relinks what it can and answers how many files it found again.
  Future<int> run() async {
    List<_Candidate>? index;
    Future<List<_Candidate>> candidates() async =>
        index ??= await _index(await _folders());

    var found = 0;

    final map = await const OfflineMapStore().archive();
    if (map != null && !await _opens(map.location)) {
      final match = _byName(await candidates(), map.label);
      if (match != null) {
        await const OfflineMapStore().save(
          location: await _remember(match.path, map.label),
          label: map.label,
        );
        found++;
      }
    }

    final library = await const ZimStore().library();
    var changed = false;
    final archives = <StoredArchive>[];
    for (final archive in library.archives) {
      if (await _opens(archive.location)) {
        archives.add(archive);
        continue;
      }
      final all = await candidates();
      final match =
          _byName(all, archive.label) ??
          _bySize(all, archive.sizeBytes, extension: '.zim');
      if (match == null) {
        archives.add(archive);
        continue;
      }
      archives.add(
        StoredArchive(
          id: archive.id,
          location: await _remember(match.path, archive.label),
          label: archive.label,
          sizeBytes: archive.sizeBytes,
          entryCount: archive.entryCount,
          title: archive.title,
          description: archive.description,
          cover: archive.cover,
        ),
      );
      changed = true;
      found++;
    }
    if (changed) {
      await const ZimStore().save(archives, selectedId: library.selectedId);
    }

    const documents = PersonalDocumentStore();
    for (final document in await documents.load()) {
      if (await _opens(document.location)) continue;
      final match = _byName(await candidates(), document.label);
      if (match == null) continue;
      await documents.relocate(
        document.id,
        await _remember(match.path, document.label),
      );
      found++;
    }
    return found;
  }

  /// Every file below [folders], to [searchDepth], with its size.
  static Future<List<_Candidate>> _index(List<Directory> folders) async {
    final found = <_Candidate>[];
    final seen = <String>{};
    Future<void> walk(Directory folder, int depth) async {
      if (found.length > 20000) return;
      try {
        await for (final entry in folder.list(followLinks: false)) {
          final name = p.basename(entry.path);
          if (name.startsWith('.') || name.endsWith('.part')) continue;
          if (entry is File) {
            if (!seen.add(entry.path)) continue;
            try {
              found.add(_Candidate(entry.path, await entry.length()));
            } on FileSystemException {
              continue;
            }
          } else if (entry is Directory && depth < searchDepth) {
            await walk(entry, depth + 1);
          }
        }
      } on FileSystemException {
        // A folder the app may not read. Nothing to find there.
      }
    }

    for (final folder in folders) {
      await walk(folder, 0);
    }
    return found;
  }

  static _Candidate? _byName(List<_Candidate> candidates, String label) {
    for (final candidate in candidates) {
      if (p.basename(candidate.path) == label) return candidate;
    }
    return null;
  }

  /// An archive whose label is its title rather than its file name -- the
  /// Gutenberg library is called "Projekt Gutenberg-Bibliothek" -- is
  /// found by its size. Archives are gigabytes and their sizes do not
  /// repeat; two candidates of the same size are not guessed between.
  static _Candidate? _bySize(
    List<_Candidate> candidates,
    int? size, {
    required String extension,
  }) {
    if (size == null) return null;
    final matches = [
      for (final candidate in candidates)
        if (candidate.size == size &&
            candidate.path.toLowerCase().endsWith(extension))
          candidate,
    ];
    return matches.length == 1 ? matches.single : null;
  }
}

class _Candidate {
  const _Candidate(this.path, this.size);

  final String path;
  final int size;
}

/// The folders the app can reach without asking: where downloads go, and
/// the data folder where there is one. On macOS asking for the download
/// folder is also what opens its security scope.
Future<List<Directory>> _reachableFolders() async {
  final folders = <Directory>[];
  try {
    folders.add(await const DownloadFolder().current());
  } on Object {
    // No download folder to be had.
  }
  final portable = portableSupportDirectory;
  if (portable != null) folders.add(portable);
  return folders;
}

Future<bool> _locationOpens(String location) async {
  try {
    final source = await openMapArchive(location);
    try {
      return (await source.read(0, 1)).isNotEmpty;
    } finally {
      await source.close();
    }
  } on Object {
    return false;
  }
}

/// A handle that survives the next start where the platform has them,
/// and the path where it does not.
Future<String> _rememberPath(String path, String label) async =>
    (await rememberStoragePath(path, label: label))?.value ?? path;

/// Runs the relinker at start-up, bounded: a slow network volume must
/// not keep the app from opening. Whatever it did not finish, the next
/// start does.
Future<void> relinkMovedFiles() async {
  try {
    final found = await FileRelinker().run().timeout(
      const Duration(seconds: 10),
    );
    if (found > 0) debugPrint('relinked $found file(s)');
  } on Object {
    // Never a reason not to start.
  }
}

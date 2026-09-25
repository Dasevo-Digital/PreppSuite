/// Taking a whole folder of documents into the library at once.
///
/// The documents themselves are never copied — the library keeps a
/// location, and this only produces a list of them. What makes it worth a
/// file of its own is that "a folder" means something different on every
/// platform, and only some of those differences can be papered over.
///
/// * **Linux and Windows** hand out an ordinary path. Listing it is a
///   plain directory read and every file inside is reachable tomorrow by
///   its own path.
/// * **macOS** hands out a security-scoped bookmark. Resolving it opens
///   the door, `dart:io` then works behind it, and each file found gets
///   its own bookmark through [rememberStoragePath] — the same step the
///   app already takes for a finished download. Without that the children
///   would be bare paths into a sandbox that is shut again on the next
///   launch.
/// * **Android and iOS** hand out a tree the app may only reach through
///   the platform channel, and a child of that tree has no form this app
///   can store today: Android would need the document URI of each entry,
///   iOS a bookmark per file, and neither bridge offers one. So the
///   feature is **not available there**, [canImportDocumentFolder] says
///   so, and the screen says it in words rather than offering a button
///   that cannot work.
///
/// One folder, not the tree below it. A document archive is often deep
/// and wide, and walking into it would turn one tap into thousands of
/// entries that nobody asked for. What lies directly in the folder is
/// predictable, and the screen says that is what it takes.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/platform_storage.dart';
import '../../sharing/application/shared_folder_access.dart'
    show pickSharedFolder;

/// What the library can read. Kept beside the picker because the two have
/// to agree: a file that is accepted here must be one the reader opens.
const documentFileExtensions = {'pdf', 'epub', 'md', 'markdown'};

/// At most this many files from one folder.
///
/// Not a technical limit but a brake. Every entry costs an index run of
/// its own, and a folder picked by accident — a whole Downloads
/// directory — should not become a quarter of an hour of work that has
/// to be undone by hand.
const maxDocumentsPerFolder = 200;

/// Whether a folder can be taken in on this platform at all.
bool get canImportDocumentFolder {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
}

/// The folder could not be read. Thrown rather than returning an empty
/// list, because "no documents in it" and "could not look" are different
/// answers and the screen says different things about them.
class DocumentFolderUnreadable implements Exception {
  const DocumentFolderUnreadable();
}

/// What was found in a folder, and whether that was all of it.
class DocumentFolderContents {
  const DocumentFolderContents({required this.documents, required this.found});

  /// The files that will be taken in, at most [maxDocumentsPerFolder].
  final List<PickedStorage> documents;

  /// How many readable files the folder actually holds. Larger than
  /// `documents.length` when the brake came on, and the screen says so.
  final int found;

  bool get isTruncated => found > documents.length;
}

/// Opens the platform's folder picker.
///
/// The same dialog the shared folder uses — it is the operating system's
/// folder picker, and there is only one. What the two features do with
/// the answer is what differs.
Future<PickedStorage?> pickDocumentFolder({String? dialogTitle}) =>
    pickSharedFolder(dialogTitle: dialogTitle);

/// The documents lying directly in [folderLocation].
Future<DocumentFolderContents> listFolderDocuments(
  String folderLocation,
) async {
  var path = folderLocation;
  if (isNativeStorageHandle(path)) {
    final resolved = await resolveStoragePath(path);
    if (resolved == null) throw const DocumentFolderUnreadable();
    path = resolved;
  }

  final directory = Directory(path);
  if (!await directory.exists()) throw const DocumentFolderUnreadable();

  final names = <String>[];
  try {
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is! File) continue;
      final name = p.basename(entry.path);
      if (name.startsWith('.')) continue;
      if (!documentFileExtensions.contains(_extensionOf(name))) continue;
      names.add(entry.path);
    }
  } on FileSystemException {
    throw const DocumentFolderUnreadable();
  }

  // Sorted before the brake comes on, so which files get taken is the
  // same on every run instead of whatever order the filesystem returned.
  names.sort(
    (a, b) =>
        p.basename(a).toLowerCase().compareTo(p.basename(b).toLowerCase()),
  );
  final found = names.length;

  final documents = <PickedStorage>[];
  for (final file in names.take(maxDocumentsPerFolder)) {
    final label = p.basename(file);
    final remembered = await rememberStoragePath(file, label: label);
    documents.add(remembered ?? PickedStorage(value: file, label: label));
  }
  return DocumentFolderContents(documents: documents, found: found);
}

String _extensionOf(String name) {
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

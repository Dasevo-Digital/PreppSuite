import '../../../core/platform_storage.dart';
import '../../knowledge/application/personal_document_store.dart';
import '../../knowledge/application/zim_store.dart';
import '../../maps/application/offline_map_store.dart';

/// Gives back the lasting permission on each of [locations] that nothing
/// the app remembers names any more (#410).
///
/// Android keeps a grant for every file picked with the app's own picker,
/// so that a map, an archive or a document still opens after a restart.
/// It keeps 128 of them up to Android 10 and 512 after, and past that it
/// drops the oldest without a word -- often the grant on the shared
/// folder, which was picked first. So a file that is removed, replaced or
/// refused gives its grant back.
///
/// Only when none of the places that remember picked files names it: the
/// map, the knowledge archives and the household's documents, the same
/// three `FileRelinker` looks after. One file can be in more than one of
/// them, and the same file picked again comes back under the same handle.
/// When they cannot be read, nothing is given back: a grant too many costs
/// a place in the list, one too few costs the file.
///
/// Only `content://` handles; everything else is a no-op. Picking a file
/// for once (a backup to restore) takes no lasting grant in the first
/// place, see `pickMapArchive`.
Future<void> releaseUnkeptFiles(Iterable<String> locations) async {
  final handles = {
    for (final location in locations)
      if (location.startsWith('content://')) location,
  };
  if (handles.isEmpty) return;
  final Set<String> kept;
  try {
    kept = await keptFileLocations();
  } on Object {
    return;
  }
  for (final handle in handles.difference(kept)) {
    await releaseStorageGrant(handle);
  }
}

/// Every picked file the app remembers: the map, the knowledge archives
/// and the household's documents.
Future<Set<String>> keptFileLocations() async {
  final map = await const OfflineMapStore().archive();
  final archives = (await const ZimStore().library()).archives;
  final documents = await const PersonalDocumentStore().load();
  return {
    ?map?.location,
    for (final archive in archives) archive.location,
    for (final document in documents) document.location,
  };
}

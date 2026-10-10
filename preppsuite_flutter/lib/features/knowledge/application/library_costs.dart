/// What the whole library costs the device (#26).
///
/// Each archive's index panel said what that one index took. Nothing said
/// what all of them together do -- which is the question before
/// downloading the next one, and the one a full disk asks afterwards.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'knowledge_index_database.dart';
import 'knowledge_providers.dart';

class LibraryCosts {
  const LibraryCosts({
    required this.archives,
    required this.archiveBytes,
    required this.unknownSizes,
    required this.indexBytes,
  });

  final int archives;

  /// The archives' own files, as far as their sizes are known.
  final int archiveBytes;

  /// Archives whose size has not been read yet -- added, never opened.
  final int unknownSizes;

  /// The full-text indexes the app built itself, every one of them.
  final int indexBytes;
}

/// How many bytes the index built over an archive takes. Overridden in
/// tests, where there is no app directory to look in.
final indexStorageBytesProvider = Provider<Future<int> Function(String id)>(
  (ref) => KnowledgeIndexDatabase.storageBytesFor,
);

final libraryCostsProvider = FutureProvider.autoDispose<LibraryCosts>((
  ref,
) async {
  final indexBytesOf = ref.watch(indexStorageBytesProvider);
  final library =
      ref.watch(knowledgeProvider.select((state) => state.value?.library)) ??
      const [];
  var archiveBytes = 0;
  var unknown = 0;
  var indexBytes = 0;
  for (final archive in library) {
    final size = archive.sizeBytes;
    if (size == null) {
      unknown++;
    } else {
      archiveBytes += size;
    }
    indexBytes += await indexBytesOf(archive.id);
  }
  return LibraryCosts(
    archives: library.length,
    archiveBytes: archiveBytes,
    unknownSizes: unknown,
    indexBytes: indexBytes,
  );
});

import 'package:preppsuite_flutter/features/sharing/application/sync_folder.dart';

import 'in_memory_sync_folder.dart';

/// An [InMemorySyncFolder] that also holds pictures (#376).
///
/// Apart from the plain one so that the tests written before pictures
/// travelled keep testing a folder without them.
class InMemoryPhotoFolder extends InMemorySyncFolder
    implements SyncPhotoFolder {
  final Map<String, String> photoFiles = {};

  /// How many picture files have been written, for "sent once" checks.
  int photoWrites = 0;

  @override
  Future<List<String>> listPhotoFiles() async => photoFiles.keys.toList();

  @override
  Future<String?> readPhotoFile(String fileName) async => photoFiles[fileName];

  @override
  Future<void> writePhotoFile(String fileName, String contents) async {
    photoWrites++;
    photoFiles[fileName] = contents;
  }

  @override
  Future<void> deletePhotoFile(String fileName) async {
    photoFiles.remove(fileName);
  }
}

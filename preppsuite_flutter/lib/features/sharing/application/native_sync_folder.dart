import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';

import '../../../core/bounded_input.dart';
import '../../../core/resource_limits.dart';

import '../../../core/platform_storage.dart';
import 'sync_folder.dart';

/// A [SyncFolder] the app cannot reach with `dart:io`.
///
/// Two platforms end up here for different reasons. Android's scoped
/// storage returns a `content://` tree that `dart:io` cannot open at all.
/// iOS returns a URL that works only inside a security scope and only
/// until the process ends, so what is stored is a bookmark and the scope
/// is entered per operation. Both are answered by the same channel — see
/// `MainActivity.kt` and `StorageBridge.swift`.
///
/// The layout inside the folder is identical to [IoSyncFolder]'s, so a
/// phone and a laptop sharing the same Nextcloud directory are sharing the
/// same folder, not two that merely look alike.
class NativeSyncFolder implements SyncFolder, SyncPhotoFolder {
  const NativeSyncFolder(this.treeUri);

  /// The handle the picker returned, with whatever permission the
  /// platform grants alongside it taken at pick time.
  final String treeUri;

  @override
  Future<bool> isWritable() async {
    // Also answers "has the grant survived" — neither an Android grant
    // nor an iOS bookmark survives a reinstall, and on Android the user
    // can revoke it in the system settings.
    final granted = await nativeStorageChannel.invokeMethod<bool>(
      'ensureWritable',
      {
        'uri': treeUri,
      },
    );
    return granted ?? false;
  }

  @override
  Future<List<String>> listDeviceIds() async {
    final names = await nativeStorageChannel.invokeListMethod<String>('list', {
      'uri': treeUri,
      'path': devicesDirectoryPath,
    });

    return [
      for (final name in names ?? const <String>[])
        if (name.endsWith('.json')) p.basenameWithoutExtension(name),
    ];
  }

  @override
  Future<String?> readDeviceFile(String deviceId) async {
    try {
      return await _read(deviceFilePath(deviceId), maxSnapshotBytes);
    } on PlatformException catch (error) {
      // A file the sync engine is mid-download on, or one held open. It
      // costs this file and not the run, and the next run picks it up.
      if (error.code == 'read-failed') return null;
      rethrow;
    }
  }

  @override
  Future<void> writeDeviceFile(String deviceId, String contents) =>
      _write(deviceFilePath(deviceId), contents);

  @override
  Future<String?> readHouseholdFile() =>
      _read(householdFilePath, maxHouseholdMetadataBytes);

  @override
  Future<void> writeHouseholdFile(String contents) =>
      _write(householdFilePath, contents);

  @override
  Future<List<String>> listPhotoFiles() async {
    final names = await nativeStorageChannel.invokeListMethod<String>('list', {
      'uri': treeUri,
      'path': photosDirectoryPath,
    });
    return [
      for (final name in names ?? const <String>[])
        if (name.endsWith('.json')) name,
    ];
  }

  @override
  Future<String?> readPhotoFile(String fileName) async {
    try {
      return await _read(
        photoFilePath(p.basename(fileName)),
        maxFolderPhotoBytes,
      );
    } on PlatformException catch (error) {
      // Mid-download, held open, or larger than any picture this app
      // writes: that picture waits, the run goes on.
      if (error.code == 'read-failed') return null;
      rethrow;
    } on InputTooLarge {
      return null;
    }
  }

  @override
  Future<void> writePhotoFile(String fileName, String contents) =>
      _write(photoFilePath(p.basename(fileName)), contents);

  @override
  Future<void> deletePhotoFile(String fileName) async {
    try {
      await nativeStorageChannel.invokeMethod<void>('delete', {
        'uri': treeUri,
        'path': photoFilePath(p.basename(fileName)),
      });
    } on PlatformException {
      // Held open, or already gone; the next run tries again.
    } on MissingPluginException {
      // A platform whose bridge cannot delete. The file stays, sealed.
    }
  }

  Future<String?> _read(String path, int maxBytes) async {
    try {
      return await nativeStorageChannel.invokeMethod<String>('read', {
        'uri': treeUri,
        'path': path,
        'maxBytes': maxBytes,
      });
    } on PlatformException catch (error) {
      if (error.code == 'read-too-large') throw InputTooLarge(maxBytes);
      rethrow;
    }
  }

  Future<void> _write(String path, String contents) async {
    final limit = path == householdFilePath
        ? maxHouseholdMetadataBytes
        : path.startsWith('$photosDirectoryPath/')
        ? maxFolderPhotoBytes
        : maxSnapshotBytes;
    if (utf8.encode(contents).length > limit) throw InputTooLarge(limit);
    await nativeStorageChannel.invokeMethod<void>('write', {
      'uri': treeUri,
      'path': path,
      'contents': contents,
    });
  }
}

import 'package:path/path.dart' as p;

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
class NativeSyncFolder implements SyncFolder {
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
  Future<String?> readDeviceFile(String deviceId) =>
      _read(deviceFilePath(deviceId));

  @override
  Future<void> writeDeviceFile(String deviceId, String contents) =>
      _write(deviceFilePath(deviceId), contents);

  @override
  Future<String?> readHouseholdFile() => _read(householdFilePath);

  @override
  Future<void> writeHouseholdFile(String contents) =>
      _write(householdFilePath, contents);

  Future<String?> _read(String path) => nativeStorageChannel
      .invokeMethod<String>('read', {'uri': treeUri, 'path': path});

  Future<void> _write(String path, String contents) =>
      nativeStorageChannel.invokeMethod<void>('write', {
        'uri': treeUri,
        'path': path,
        'contents': contents,
      });
}

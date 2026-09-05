import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'sync_folder.dart';

/// The channel `MainActivity` answers on. Android only.
const _channel = MethodChannel('preppsuite/shared_folder_saf');

/// A [SyncFolder] reached through Android's Storage Access Framework.
///
/// Android stopped letting apps open arbitrary paths with scoped storage:
/// the folder picker returns a `content://` tree, and `dart:io` cannot
/// open one. Every operation therefore goes through the platform channel
/// — see `MainActivity.kt`, which holds the whole native side.
///
/// The layout inside the folder is identical to [IoSyncFolder]'s, so a
/// phone and a laptop sharing the same Nextcloud directory are sharing the
/// same folder, not two that merely look alike.
class SafSyncFolder implements SyncFolder {
  const SafSyncFolder(this.treeUri);

  /// The `content://` tree the user picked, with a persisted read/write
  /// grant taken at pick time.
  final String treeUri;

  @override
  Future<bool> isWritable() async {
    // Also answers "has the grant survived" — it does not survive a
    // reinstall, and the user can revoke it in the system settings.
    final granted = await _channel.invokeMethod<bool>('ensureWritable', {
      'uri': treeUri,
    });
    return granted ?? false;
  }

  @override
  Future<List<String>> listDeviceIds() async {
    final names = await _channel.invokeListMethod<String>('list', {
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

  Future<String?> _read(String path) =>
      _channel.invokeMethod<String>('read', {'uri': treeUri, 'path': path});

  Future<void> _write(String path, String contents) =>
      _channel.invokeMethod<void>('write', {
        'uri': treeUri,
        'path': path,
        'contents': contents,
      });
}

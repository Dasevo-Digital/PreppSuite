import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'saf_sync_folder.dart';
import 'sync_folder.dart';

/// Where a shared folder lives, in a form that survives a restart.
///
/// A filesystem path everywhere except Android, where it is a `content://`
/// tree — hence [label], because a content URI is not something to show
/// anyone.
class SharedFolderLocation {
  const SharedFolderLocation({required this.value, required this.label});

  final String value;
  final String label;
}

/// Android is the one platform where a picked folder is not a path.
bool get usesStorageAccessFramework {
  if (kIsWeb) return false;
  return Platform.isAndroid;
}

/// Opens the platform's folder picker, or null if the user backed out.
///
/// On Android this goes through the app's own channel rather than
/// `file_picker`: the point is not the dialog but the *persistable*
/// permission taken afterwards, which is what lets the folder still be
/// readable on the next launch.
Future<SharedFolderLocation?> pickSharedFolder({String? dialogTitle}) async {
  if (usesStorageAccessFramework) {
    const channel = MethodChannel('preppsuite/shared_folder_saf');
    final picked = await channel.invokeMapMethod<String, String>('pick');
    final uri = picked?['uri'];
    if (uri == null) return null;

    final label = picked?['label'];
    return SharedFolderLocation(
      value: uri,
      label: label == null || label.isEmpty ? uri : label,
    );
  }

  final path = await FilePicker.platform.getDirectoryPath(
    dialogTitle: dialogTitle,
  );
  if (path == null) return null;
  return SharedFolderLocation(value: path, label: path);
}

/// The right [SyncFolder] for a stored location.
SyncFolder syncFolderFor(String location) {
  return location.startsWith('content://')
      ? SafSyncFolder(location)
      : IoSyncFolder(location);
}

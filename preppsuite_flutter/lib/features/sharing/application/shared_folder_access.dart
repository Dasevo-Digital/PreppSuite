import 'package:file_picker/file_picker.dart';

import '../../../core/platform_storage.dart';
import 'saf_sync_folder.dart';
import 'sync_folder.dart';

/// Where a shared folder lives, in a form that survives a restart.
typedef SharedFolderLocation = PickedStorage;

/// Opens the platform's folder picker, or null if the user backed out.
///
/// On Android this goes through the app's own channel rather than
/// `file_picker`: the point is not the dialog but the *persistable*
/// permission taken afterwards, which is what lets the folder still be
/// readable on the next launch.
Future<SharedFolderLocation?> pickSharedFolder({String? dialogTitle}) async {
  if (usesStorageAccessFramework) {
    final picked = await nativeStorageChannel.invokeMapMethod<String, String>(
      'pick',
    );
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

/// Kept for the callers that only have the raw stored value.
SharedFolderLocation sharedFolderLocation(String value, String label) =>
    SharedFolderLocation(value: value, label: label);

import 'package:file_picker/file_picker.dart';

import '../../../core/platform_storage.dart';
import 'native_sync_folder.dart';
import 'sync_folder.dart';

/// Where a shared folder lives, in a form that survives a restart.
typedef SharedFolderLocation = PickedStorage;

/// Opens the platform's folder picker, or null if the user backed out.
///
/// On Android and iOS this goes through the app's own channel rather than
/// `file_picker`: the point is not the dialog but what is kept
/// afterwards — a persisted grant there, a bookmark here — which is what
/// lets the folder still be readable on the next launch.
Future<SharedFolderLocation?> pickSharedFolder({String? dialogTitle}) async {
  if (usesNativeStoragePicker) {
    final picked = await nativeStorageChannel.invokeMapMethod<String, String>(
      'pick',
      // Only the macOS panel shows it; Android and iOS ignore it.
      {'dialogTitle': dialogTitle},
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
  return isNativeStorageHandle(location)
      ? NativeSyncFolder(location)
      : IoSyncFolder(location);
}

/// Kept for the callers that only have the raw stored value.
SharedFolderLocation sharedFolderLocation(String value, String label) =>
    SharedFolderLocation(value: value, label: label);

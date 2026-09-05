import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../../core/platform_storage.dart';
import 'pmtiles_archive.dart';

/// Opens the platform's file picker for a `.pmtiles` archive, or null if
/// the user backed out.
///
/// On Android and iOS this goes through the app's own channel rather than
/// `file_picker`, for two reasons: the picker there copies the chosen file
/// into the app's own storage, which for a country extract means several
/// gigabytes written twice; and the copy would be thrown away on the next
/// cache clear, taking the map with it.
Future<PickedStorage?> pickMapArchive({String? dialogTitle}) async {
  if (usesNativeStoragePicker) {
    final picked = await nativeStorageChannel.invokeMapMethod<String, String>(
      'pickFile',
    );
    final uri = picked?['uri'];
    if (uri == null) return null;

    final label = picked?['label'];
    return PickedStorage(
      value: uri,
      label: label == null || label.isEmpty ? uri : label,
    );
  }

  final result = await FilePicker.platform.pickFiles(
    dialogTitle: dialogTitle,
    // Not a custom-extension filter: several desktop platforms refuse
    // extensions they do not recognize, and `.pmtiles` is one of them.
    type: FileType.any,
  );
  final path = result?.files.single.path;
  if (path == null) return null;

  return PickedStorage(value: path, label: result!.files.single.name);
}

/// Random access to the archive at [location], whatever kind it is.
Future<ByteRangeSource> openMapArchive(String location) {
  return isNativeStorageHandle(location)
      ? NativeByteRangeSource.open(location)
      : FileByteRangeSource.open(File(location));
}

/// Reads ranges out of an archive the app cannot open with `dart:io`.
///
/// The archive is never copied and never fully read: the native side keeps
/// one descriptor open and answers a few kilobytes at a time, once per
/// tile, off the main thread. On iOS the security scope is held open
/// alongside that descriptor, because it is what the descriptor hangs on.
class NativeByteRangeSource implements ByteRangeSource {
  NativeByteRangeSource._(this.uri);

  final String uri;

  static Future<NativeByteRangeSource> open(String uri) async {
    final opened = await nativeStorageChannel.invokeMethod<bool>('openFile', {
      'uri': uri,
    });
    if (opened != true) {
      // The usual cause is a permission that did not survive: a
      // reinstall, the user revoking it in the system settings, or a
      // bookmark whose file has been moved out from under it.
      throw const PmTilesException('cannot open the archive');
    }
    return NativeByteRangeSource._(uri);
  }

  @override
  Future<Uint8List> read(int offset, int length) async {
    final bytes = await nativeStorageChannel.invokeMethod<Uint8List>(
      'readRange',
      {'uri': uri, 'offset': offset, 'length': length},
    );
    if (bytes == null) throw const PmTilesException('read returned nothing');
    return bytes;
  }

  @override
  Future<void> close() =>
      nativeStorageChannel.invokeMethod<void>('closeFile', {'uri': uri});
}

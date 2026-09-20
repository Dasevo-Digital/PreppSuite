import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/app_database_directory.dart';
import '../../../core/portable_data.dart';
import '../../../core/portable_paths.dart';

/// Captures or picks a product photo and stores it on local disk, inside
/// the app's own support directory.
///
/// [InventoryItems.photoPath] is a plain local file path, which is why no
/// snapshot carries it: it would name a directory on somebody else's
/// machine. The pictures themselves do travel, but on **one road only** —
/// a local handover, two devices in one room, one request — where the
/// bytes can ride beside the rows; see `handover_photos.dart`. The shared
/// folder and the QR chain still carry none, for the reasons set out
/// there.
class InventoryPhotoService {
  const InventoryPhotoService();

  /// The folder photos go in, under whichever support directory this
  /// copy uses. Public because resolving an old absolute path falls back
  /// to looking for the same file name in here.
  static const subdirectory = 'inventory_photos';

  /// Public because a handover writes the pictures it received straight
  /// into it, without going through the picker.
  Future<Directory> photosDirectory() => _photosDirectory();

  Future<Directory> _photosDirectory() async {
    final appDir = await appSupportDirectory();
    final dir = Directory(p.join(appDir.path, subdirectory));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Opens the platform's photo library/file picker. Returns the saved
  /// copy's local path, or `null` if the user cancelled.
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  /// Opens the camera. Works out of the box on iOS/Android; on macOS/
  /// Windows/Linux, `image_picker` throws a [StateError] for
  /// [ImageSource.camera] unless a platform camera delegate is separately
  /// wired up, which this app doesn't do (desktop already has a working
  /// camera capture path for barcodes via `mobile_scanner`, so this isn't
  /// needed there). Gate showing a "take photo" button behind
  /// `!Platform.isMacOS` (and similarly for other desktop platforms) until
  /// then — see [InventoryItemFormScreen].
  Future<String?> pickFromCamera() => _pick(ImageSource.camera);

  Future<String?> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final dir = await _photosDirectory();
    final extension = p.extension(picked.path);
    final destination = p.join(
      dir.path,
      '${const Uuid().v4()}${extension.isEmpty ? '.jpg' : extension}',
    );
    await File(picked.path).copy(destination);
    // Written down relative to the data folder where there is one, so a
    // photo carried on the same disk is still found when the disk comes
    // up under another letter.
    return storeLocation(destination);
  }

  /// Writes edited bytes as a new photo and returns its path.
  ///
  /// A new file rather than the one it came from: the caller only deletes
  /// the original once this has returned, so a write that fails part-way
  /// cannot leave the item pointing at half a picture.
  Future<String> saveBytes(Uint8List bytes) async {
    final dir = await _photosDirectory();
    final destination = p.join(dir.path, '${const Uuid().v4()}.jpg');
    await File(destination).writeAsBytes(bytes, flush: true);
    return storeLocation(destination);
  }

  /// Best-effort delete of a photo that's no longer referenced (replaced or
  /// removed from an item). Failures are ignored — a stray file on disk is
  /// harmless.
  Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      await File(resolvePhotoPath(path)).delete();
    } catch (_) {
      // Already gone, or some other benign issue — nothing to do.
    }
  }

  /// The stored path as a file on this machine.
  ///
  /// Three cases, in order. A path written down relative to the data
  /// folder resolves against it. An absolute one written by an installed
  /// copy is used as it stands. And an absolute one that is *not* there
  /// — the case that turns up when a household is taken over onto a
  /// carried copy, where the photos came along but their paths named the
  /// old machine — is looked for by name in this copy's own photo
  /// folder, which is where the copy put it.
  static String resolvePhotoPath(String stored) {
    final located = readLocation(stored);
    if (File(located).existsSync()) return located;

    final folder = photoDirectoryPath;
    if (folder == null) return located;

    final candidate = p.join(folder, p.basename(located));
    return File(candidate).existsSync() ? candidate : located;
  }

  /// Where this copy keeps photos, once that is known.
  ///
  /// Null for an installed copy, where stored paths are already right and
  /// no fallback is needed.
  static String? get photoDirectoryPath {
    final root = portableSupportDirectory;
    return root == null ? null : p.join(root.path, subdirectory);
  }
}

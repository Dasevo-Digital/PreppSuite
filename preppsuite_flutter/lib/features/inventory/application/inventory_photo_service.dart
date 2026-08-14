import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Captures or picks a product photo and stores it on local disk, inside
/// the app's own support directory.
///
/// Local-only for now: [InventoryItems.photoPath] is a plain local file
/// path. Syncing photos across devices is a deliberately deferred, separate
/// piece of work — binary uploads need their own endpoint, not the generic
/// JSON push/pull sync channel (same reasoning the project already applies
/// to map tiles; see docs/sync-protocol.md).
class InventoryPhotoService {
  const InventoryPhotoService();

  static const _subdirectory = 'inventory_photos';

  Future<Directory> _photosDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, _subdirectory));
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
    return destination;
  }

  /// Best-effort delete of a photo that's no longer referenced (replaced or
  /// removed from an item). Failures are ignored — a stray file on disk is
  /// harmless.
  Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (_) {
      // Already gone, or some other benign issue — nothing to do.
    }
  }
}

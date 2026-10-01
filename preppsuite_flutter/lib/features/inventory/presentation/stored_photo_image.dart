import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/photo_vault.dart';

/// A product or possession photo, read through [PhotoVault].
///
/// `FileImage` would hand the sealed bytes straight to the decoder, which
/// sees no image in them. Keyed by path, like `FileImage`: replacing a
/// picture always writes a new file under a new name, so a path never
/// comes to mean a different picture.
@immutable
class StoredPhotoImage extends ImageProvider<StoredPhotoImage> {
  const StoredPhotoImage(this.path);

  /// The resolved file on this machine — see
  /// `InventoryPhotoService.resolvePhotoPath`.
  final String path;

  @override
  Future<StoredPhotoImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    StoredPhotoImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(decode),
    scale: 1,
    debugLabel: path,
  );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await const PhotoVault().read(File(path));
    if (bytes == null || bytes.isEmpty) {
      // Missing, or sealed under a key this installation does not hold.
      // Evicted so that a later look — after recovery — tries again.
      PaintingBinding.instance.imageCache.evict(this);
      throw StateError('photo unavailable: $path');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is StoredPhotoImage && other.path == path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => 'StoredPhotoImage("$path")';
}

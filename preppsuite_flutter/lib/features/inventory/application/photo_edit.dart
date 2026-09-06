/// Rough editing for a product photo: turn it the right way up and cut
/// away what is not the label.
///
/// Pixels only, no widgets — the editor screen decides what the rectangle
/// is, this decides what comes out, and the arithmetic in between is the
/// part that is worth a test.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The part of the picture to keep, in fractions of the whole.
///
/// Normalized rather than in pixels because the rectangle is dragged over
/// a scaled-down preview: storing screen pixels would tie the result to
/// the size of the phone it was cropped on.
class CropRect {
  const CropRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  static const full = CropRect(left: 0, top: 0, width: 1, height: 1);

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;

  bool get isFull => left <= 0 && top <= 0 && width >= 1 && height >= 1;

  /// Clamped into the picture and never smaller than [minimumSide].
  ///
  /// A drag can be flung past the edge, and a rectangle of zero width
  /// would crop to nothing at all — `copyCrop` would throw and the photo
  /// would be lost.
  CropRect get normalized {
    final w = width.clamp(minimumSide, 1.0);
    final h = height.clamp(minimumSide, 1.0);
    return CropRect(
      left: left.clamp(0.0, 1.0 - w),
      top: top.clamp(0.0, 1.0 - h),
      width: w,
      height: h,
    );
  }

  /// About a tenth of the picture. Small enough to zoom in on a
  /// best-before date, large enough that a stray drag cannot destroy the
  /// photo.
  static const minimumSide = 0.1;

  CropRect copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) => CropRect(
    left: left ?? this.left,
    top: top ?? this.top,
    width: width ?? this.width,
    height: height ?? this.height,
  );

  @override
  bool operator ==(Object other) =>
      other is CropRect &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'CropRect($left, $top, $width x $height)';
}

/// What the editor asks for: some quarter turns, then a rectangle.
class PhotoEdit {
  const PhotoEdit({this.quarterTurns = 0, this.crop = CropRect.full});

  /// Clockwise quarter turns, taken modulo four.
  final int quarterTurns;

  /// In the coordinates of the *turned* picture — the rectangle is drawn
  /// on what the person is looking at.
  final CropRect crop;

  bool get isIdentity => quarterTurns % 4 == 0 && crop.isFull;

  PhotoEdit copyWith({int? quarterTurns, CropRect? crop}) => PhotoEdit(
    quarterTurns: quarterTurns ?? this.quarterTurns,
    crop: crop ?? this.crop,
  );
}

/// Applies [edit] and re-encodes as JPEG.
///
/// Returns null when the bytes are not a picture this can read, which is
/// the caller's cue to keep the original rather than lose it.
///
/// Order is fixed: orientation, then rotation, then crop. The EXIF
/// orientation has to be baked in first or a photo taken sideways would
/// be cropped along the wrong axis — the phone shows it upright and
/// stores it lying down. The user's own turns come next, because the
/// rectangle was drawn on the result of both.
Uint8List? applyPhotoEdit(Uint8List bytes, PhotoEdit edit) {
  // Caught rather than checked for null: `decodeImage` sniffs the format
  // by reading a header out of the buffer, and on a truncated or
  // corrupted file that read runs off the end and throws. Left
  // uncaught it would take the worker isolate with it, and the save would
  // fail with no picture and no message.
  final img.Image decoded;
  try {
    final result = img.decodeImage(bytes);
    if (result == null) return null;
    decoded = result;
  } catch (_) {
    return null;
  }

  var image = img.bakeOrientation(decoded);

  final turns = edit.quarterTurns % 4;
  if (turns != 0) {
    image = img.copyRotate(image, angle: turns * 90);
  }

  final crop = edit.crop.normalized;
  if (!crop.isFull) {
    final width = (image.width * crop.width).round().clamp(1, image.width);
    final height = (image.height * crop.height).round().clamp(1, image.height);
    image = img.copyCrop(
      image,
      x: (image.width * crop.left).round().clamp(0, image.width - width),
      y: (image.height * crop.top).round().clamp(0, image.height - height),
      width: width,
      height: height,
    );
  }

  return img.encodeJpg(image, quality: jpegQuality);
}

/// The same quality `image_picker` is already asked for, so re-saving an
/// untouched photo does not visibly cost anything.
const jpegQuality = 85;

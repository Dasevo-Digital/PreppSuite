import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:preppsuite_flutter/features/inventory/application/photo_edit.dart';

void main() {
  /// A picture wide enough to tell landscape from portrait, with one
  /// coloured quarter so a rotation is visible rather than merely
  /// plausible.
  Uint8List source({int width = 200, int height = 100}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: (width / 2).floor() - 1,
      y2: (height / 2).floor() - 1,
      color: img.ColorRgb8(255, 0, 0),
    );
    return Uint8List.fromList(img.encodeJpg(image));
  }

  img.Image decode(Uint8List? bytes) {
    expect(bytes, isNotNull);
    final image = img.decodeImage(bytes!);
    expect(image, isNotNull);
    return image!;
  }

  /// Roughly, because JPEG is lossy: a red corner comes back as nearly
  /// red, never exactly.
  bool isRed(img.Pixel pixel) => pixel.r > 180 && pixel.g < 90 && pixel.b < 90;

  group('CropRect', () {
    test('the whole picture is recognised as such', () {
      expect(CropRect.full.isFull, isTrue);
      expect(
        const CropRect(left: 0, top: 0, width: 0.5, height: 1).isFull,
        isFalse,
      );
    });

    test('a rectangle dragged off the edge comes back inside', () {
      final fixed = const CropRect(
        left: -0.3,
        top: 0.9,
        width: 0.5,
        height: 0.5,
      ).normalized;

      expect(fixed.left, 0);
      expect(fixed.top, closeTo(0.5, 0.001));
      expect(fixed.right, lessThanOrEqualTo(1));
      expect(fixed.bottom, lessThanOrEqualTo(1));
    });

    test('a rectangle dragged shut keeps a usable size', () {
      // Zero width would crop to nothing, which throws — and the photo
      // would be gone rather than merely badly cropped.
      final fixed = const CropRect(
        left: 0.5,
        top: 0.5,
        width: 0,
        height: -0.2,
      ).normalized;

      expect(fixed.width, CropRect.minimumSide);
      expect(fixed.height, CropRect.minimumSide);
    });

    test('a rectangle bigger than the picture is cut back to it', () {
      final fixed = const CropRect(
        left: 0.2,
        top: 0.2,
        width: 2,
        height: 2,
      ).normalized;

      expect(fixed, CropRect.full);
    });
  });

  group('applying an edit', () {
    test('doing nothing changes nothing but the encoding', () {
      final result = decode(applyPhotoEdit(source(), const PhotoEdit()));

      expect(result.width, 200);
      expect(result.height, 100);
    });

    test('cropping keeps the fraction that was asked for', () {
      final result = decode(
        applyPhotoEdit(
          source(),
          const PhotoEdit(
            crop: CropRect(left: 0, top: 0, width: 0.5, height: 0.5),
          ),
        ),
      );

      expect(result.width, 100);
      expect(result.height, 50);
      // The top-left quarter is the red one, so a correct crop is red
      // throughout rather than red in one corner.
      expect(isRed(result.getPixel(5, 5)), isTrue);
      expect(isRed(result.getPixel(90, 40)), isTrue);
    });

    test('cropping the other half gets the other half', () {
      // The check that the offset is applied at all: a crop that ignored
      // `left` and `top` would still come back the right size.
      final result = decode(
        applyPhotoEdit(
          source(),
          const PhotoEdit(
            crop: CropRect(left: 0.5, top: 0.5, width: 0.5, height: 0.5),
          ),
        ),
      );

      expect(result.width, 100);
      expect(isRed(result.getPixel(5, 5)), isFalse);
    });

    test('a quarter turn swaps the sides', () {
      final result = decode(
        applyPhotoEdit(source(), const PhotoEdit(quarterTurns: 1)),
      );

      expect(result.width, 100);
      expect(result.height, 200);
    });

    test('a quarter turn goes clockwise, like the button says', () {
      // Turned right, the red top-left quarter ends up top-right. Getting
      // this backwards is invisible in the sizes and obvious on screen.
      final result = decode(
        applyPhotoEdit(source(), const PhotoEdit(quarterTurns: 1)),
      );

      expect(isRed(result.getPixel(result.width - 5, 5)), isTrue);
      expect(isRed(result.getPixel(5, 5)), isFalse);
    });

    test('four turns come back to the start', () {
      final result = decode(
        applyPhotoEdit(source(), const PhotoEdit(quarterTurns: 4)),
      );

      expect(result.width, 200);
      expect(result.height, 100);
    });

    test('turning left is turning right three times', () {
      final left = decode(
        applyPhotoEdit(source(), const PhotoEdit(quarterTurns: -1)),
      );
      final right = decode(
        applyPhotoEdit(source(), const PhotoEdit(quarterTurns: 3)),
      );

      expect(left.width, right.width);
      expect(isRed(left.getPixel(5, left.height - 5)), isTrue);
    });

    test('the crop is measured on the turned picture, not the original', () {
      // The rectangle is drawn on what the person is looking at, so the
      // turn has to happen first. Applied the other way round, this would
      // come back 50x100 instead.
      final result = decode(
        applyPhotoEdit(
          source(),
          const PhotoEdit(
            quarterTurns: 1,
            crop: CropRect(left: 0, top: 0, width: 1, height: 0.5),
          ),
        ),
      );

      expect(result.width, 100);
      expect(result.height, 100);
    });

    test('bytes that are not a picture are refused, not mangled', () {
      // The caller keeps the original on null. Returning something
      // plausible instead would replace a readable file with rubbish.
      expect(
        applyPhotoEdit(Uint8List.fromList([1, 2, 3, 4]), const PhotoEdit()),
        isNull,
      );
    });
  });
}

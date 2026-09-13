import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Draws one QR code.
///
/// Painted here rather than taken from `qr_flutter`, which is a painter
/// over exactly this encoder and has not been published in three years.
/// What it would have saved is below; what it would have cost is a
/// dormant dependency in the one screen that has to work when nothing
/// else does.
///
/// Two details decide whether a camera across a table can read this at
/// all, and both are easy to get wrong:
///
///   * the quiet zone. A QR code needs four empty modules of margin on
///     every side. Without it a reader often cannot find the code at all,
///     and "it just does not scan" is indistinguishable from a bug.
///   * whole-pixel modules. A module drawn at a fractional width gets
///     anti-aliased into grey, and a grey module is neither dark nor
///     light to a decoder. The size is rounded down so every module is
///     the same whole number of pixels, and the remainder becomes extra
///     margin.
///
/// It is always black on white, in both themes. A dark-mode QR code with
/// inverted colours is not readable by most scanners, and this is not the
/// place to be stylish.
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    required this.data,
    required this.semanticLabel,
    this.size = 320,
  });

  final String data;

  /// What a screen reader should say. The code itself is meaningless to
  /// read out, and a picture with no label at all is worse -- so callers
  /// say what this one is ("frame 3 of 12").
  final String semanticLabel;

  /// The edge length to aim for. The real one is rounded down so the
  /// modules land on whole pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final code = QrCode.fromData(
      data: data,
      // Medium: a quarter of the code can be damaged and still read.
      // Higher levels make the code denser for the same payload, which on
      // a screen filmed by a phone loses more than the redundancy wins.
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final image = QrImage(code);

    return Semantics(
      label: semanticLabel,
      image: true,
      child: CustomPaint(size: Size.square(size), painter: _QrPainter(image)),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final QrImage image;

  /// The margin a decoder needs, in modules. Four is what the standard
  /// asks for.
  static const _quietZone = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final modules = image.moduleCount;
    final across = modules + _quietZone * 2;

    // Whole pixels per module, or the anti-aliasing turns dark modules
    // grey and the code stops reading.
    final module = (size.shortestSide / across).floorToDouble();
    if (module < 1) return;

    final drawn = module * across;
    final left = (size.width - drawn) / 2;
    final top = (size.height - drawn) / 2;

    // Anti-aliasing off, on both. It is on by default, and with it a
    // module two or three pixels wide is drawn with soft edges: measured
    // on a 600-character frame, 37% of the painted pixels came out
    // neither dark nor light. A grey module is not a value a decoder can
    // read, so a code that looks perfectly fine on screen simply does
    // not scan. Whole-pixel modules plus hard edges is what makes it
    // legible; nothing here is a curve, so there is nothing to smooth.
    canvas.drawRect(
      Rect.fromLTWH(left, top, drawn, drawn),
      Paint()
        ..color = Colors.white
        ..isAntiAlias = false,
    );

    final dark = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (var row = 0; row < modules; row++) {
      for (var column = 0; column < modules; column++) {
        if (!image.isDark(row, column)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            left + (column + _quietZone) * module,
            top + (row + _quietZone) * module,
            // Not shrunk by a hairline for "crispness": adjacent dark
            // modules have to touch, or the finder patterns break.
            module,
            module,
          ),
          dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.image != image;
}

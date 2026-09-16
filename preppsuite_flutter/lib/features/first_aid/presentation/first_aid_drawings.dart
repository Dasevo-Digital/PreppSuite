import 'package:flutter/material.dart';

import '../application/first_aid_guide.dart';

/// The pictures beside the instructions, drawn by the app.
///
/// Line art in code rather than image files, and pictograms rather than
/// illustrations. Three reasons, in order of how much they matter:
///
/// A pictogram is read faster than a photograph. The thing being shown is
/// always one relationship — the hands to the breastbone, the knee to the
/// floor — and a picture that contains only that relationship is legible
/// at arm's length on a floor in bad light, which is where it is used.
///
/// It is correct in both themes. A scanned drawing on white paper is a
/// white rectangle in a dark room at three in the morning.
///
/// And it costs nothing: a few hundred bytes of code each against tens of
/// kilobytes per raster image, times every screen density.
class FirstAidDrawingView extends StatelessWidget {
  const FirstAidDrawingView({
    super.key,
    required this.drawing,
    this.height = 160,
  });

  final FirstAidDrawing drawing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _FirstAidPainter(
          drawing: drawing,
          line: scheme.onSurfaceVariant,
          accent: scheme.primary,
          fill: scheme.primary.withValues(alpha: 0.16),
        ),
        // The drawing repeats what the step already says, so a reader
        // using a screen reader is told nothing new by it.
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FirstAidPainter extends CustomPainter {
  const _FirstAidPainter({
    required this.drawing,
    required this.line,
    required this.accent,
    required this.fill,
  });

  final FirstAidDrawing drawing;
  final Color line;
  final Color accent;
  final Color fill;

  /// Everything below is drawn in a 100 by 100 square and scaled to fit,
  /// centred. Working in real pixels would mean every coordinate changing
  /// whenever the height does.
  static const _side = 100.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _side;
    canvas
      ..save()
      ..translate((size.width - _side * scale) / 2, 0)
      ..scale(scale);

    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final mark = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final wash = Paint()..color = fill;

    switch (drawing) {
      case FirstAidDrawing.compressionPoint:
        _compressionPoint(canvas, stroke, mark, wash);
      case FirstAidDrawing.recoveryPosition:
        _recoveryPosition(canvas, stroke, mark);
      case FirstAidDrawing.choking:
        _choking(canvas, stroke, mark);
      case FirstAidDrawing.bleeding:
        _bleeding(canvas, stroke, mark, wash);
      case FirstAidDrawing.face:
        _face(canvas, stroke, mark);
    }

    canvas.restore();
  }

  /// The chest from the front, with the place the hands go marked.
  ///
  /// Rendered and looked at, twice. The first version drew the ribcage as
  /// a tapering shield with a line through a circle, which read as a crest
  /// with a power button on it. The second put a rounded bar across the
  /// marker, which read as a prohibition sign -- a circle with a diagonal
  /// through it means one thing and it is not "push here".
  ///
  /// What works is a hand: a palm with fingers, the same shape the
  /// bleeding drawing uses, which is legible there for the same reason.
  void _compressionPoint(Canvas canvas, Paint stroke, Paint mark, Paint wash) {
    canvas
      ..drawCircle(const Offset(50, 13), 8, stroke)
      ..drawLine(const Offset(50, 21), const Offset(50, 28), stroke)
      // Shoulders straight and wide: an arc here reads as a helmet brim.
      ..drawLine(const Offset(29, 30), const Offset(71, 30), stroke)
      ..drawPath(
        Path()
          ..moveTo(29, 30)
          ..lineTo(20, 58)
          ..moveTo(71, 30)
          ..lineTo(80, 58),
        stroke,
      )
      // The torso, ending flat rather than in a point.
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(31, 30, 38, 50),
          const Radius.circular(10),
        ),
        stroke,
      )
      // The breastbone, stopping well above the marker so nothing crosses
      // it.
      ..drawLine(const Offset(50, 35), const Offset(50, 46), stroke)
      ..drawCircle(const Offset(50, 62), 13, wash)
      ..drawCircle(const Offset(50, 62), 13, mark)
      // Palm and three fingers, centred on the marker.
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(41, 60, 18, 12),
          const Radius.circular(4),
        ),
        mark,
      )
      ..drawPath(
        Path()
          ..moveTo(44, 60)
          ..lineTo(44, 54)
          ..moveTo(50, 60)
          ..lineTo(50, 53)
          ..moveTo(56, 60)
          ..lineTo(56, 55),
        mark,
      );
  }

  /// Seen from the side: head down, upper arm under the cheek, upper knee
  /// drawn up to stop the roll.
  void _recoveryPosition(Canvas canvas, Paint stroke, Paint mark) {
    // Ground.
    canvas.drawLine(const Offset(8, 80), const Offset(92, 80), stroke);

    // Head, resting on the hand.
    canvas.drawCircle(const Offset(24, 56), 9, stroke);

    // Back, from neck to hip.
    canvas.drawPath(
      Path()
        ..moveTo(33, 60)
        ..quadraticBezierTo(50, 52, 66, 62),
      stroke,
    );

    // The arm that props the head: shoulder, elbow, hand at the cheek.
    canvas.drawPath(
      Path()
        ..moveTo(38, 62)
        ..lineTo(34, 74)
        ..lineTo(23, 68),
      mark,
    );

    // The upper leg, hip and knee both at a right angle.
    canvas.drawPath(
      Path()
        ..moveTo(66, 62)
        ..lineTo(78, 68)
        ..lineTo(76, 80),
      mark,
    );

    // The lower leg, left straight.
    canvas.drawPath(
      Path()
        ..moveTo(66, 66)
        ..lineTo(86, 76),
      stroke,
    );
  }

  /// Bent forward, struck between the shoulder blades.
  void _choking(Canvas canvas, Paint stroke, Paint mark) {
    // Head, leaning well forward.
    canvas.drawCircle(const Offset(30, 42), 10, stroke);

    // Back, curved over.
    canvas.drawPath(
      Path()
        ..moveTo(38, 48)
        ..quadraticBezierTo(58, 38, 66, 60)
        ..lineTo(64, 86),
      stroke,
    );

    // The front of the body and the near leg, so it reads as a person.
    canvas.drawPath(
      Path()
        ..moveTo(36, 54)
        ..quadraticBezierTo(48, 60, 54, 74)
        ..lineTo(52, 86),
      stroke,
    );

    // The helping hand, flat between the shoulder blades. A palm with
    // fingers rather than a blob: a small circle on a stick reads as a
    // key, which is what the first version looked like.
    canvas
      ..save()
      ..translate(63, 49)
      ..rotate(0.5)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -8, 13, 16),
          const Radius.circular(4),
        ),
        mark,
      )
      ..drawPath(
        Path()
          ..moveTo(9, -5)
          ..lineTo(15, -5)
          ..moveTo(9, 0)
          ..lineTo(16, 0)
          ..moveTo(9, 5)
          ..lineTo(15, 5),
        mark,
      )
      ..restore();

    // Two short strokes for the direction of the blow.
    canvas
      ..drawLine(const Offset(86, 36), const Offset(78, 40), mark)
      ..drawLine(const Offset(88, 46), const Offset(80, 47), mark);
  }

  /// A hand pressing a pad onto a forearm, and staying there.
  void _bleeding(Canvas canvas, Paint stroke, Paint mark, Paint wash) {
    // The forearm, across the picture.
    canvas.drawPath(
      Path()
        ..moveTo(10, 56)
        ..lineTo(76, 56)
        ..moveTo(10, 76)
        ..lineTo(76, 76),
      stroke,
    );
    // The hand at the end of it.
    canvas.drawPath(
      Path()
        ..moveTo(76, 56)
        ..quadraticBezierTo(92, 66, 76, 76),
      stroke,
    );

    // The dressing.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 50, 26, 32),
        const Radius.circular(4),
      ),
      wash,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 50, 26, 32),
        const Radius.circular(4),
      ),
      mark,
    );

    // The pressing hand: palm and three fingers.
    canvas.drawPath(
      Path()
        ..moveTo(32, 40)
        ..lineTo(54, 40)
        ..moveTo(36, 40)
        ..lineTo(36, 50)
        ..moveTo(43, 40)
        ..lineTo(43, 50)
        ..moveTo(50, 40)
        ..lineTo(50, 50),
      mark,
    );

    // Downward: keep pressing.
    canvas.drawPath(
      Path()
        ..moveTo(43, 18)
        ..lineTo(43, 34)
        ..moveTo(38, 29)
        ..lineTo(43, 34)
        ..lineTo(48, 29),
      mark,
    );
  }

  /// One side of the mouth and one eyelid down: what to look for when
  /// asking somebody to smile.
  void _face(Canvas canvas, Paint stroke, Paint mark) {
    canvas.drawCircle(const Offset(50, 50), 32, stroke);

    // The sound side.
    canvas.drawCircle(const Offset(38, 42), 3, stroke);
    // The affected side: a lidded eye rather than a dot.
    canvas.drawPath(
      Path()
        ..moveTo(58, 42)
        ..quadraticBezierTo(62, 38, 66, 42),
      mark,
    );

    // The mouth, level on the left and falling away on the right.
    canvas.drawPath(
      Path()
        ..moveTo(36, 62)
        ..quadraticBezierTo(48, 68, 62, 70),
      mark,
    );

    // Which way it is falling.
    canvas.drawPath(
      Path()
        ..moveTo(70, 62)
        ..lineTo(70, 74)
        ..moveTo(66, 70)
        ..lineTo(70, 74)
        ..lineTo(74, 70),
      mark,
    );
  }

  @override
  bool shouldRepaint(_FirstAidPainter old) =>
      old.drawing != drawing || old.line != line || old.accent != accent;
}

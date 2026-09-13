import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/transfer/presentation/qr_code_view.dart';

/// The code has to be readable by a camera, and the two things that decide
/// that are not visible in a screenshot: the quiet zone around it and
/// whether the modules land on whole pixels.
void main() {
  Future<ui.Image> render(
    WidgetTester tester,
    Widget child, {
    required Size size,
  }) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox.fromSize(size: size, child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    // Inside `runAsync`, or it never returns: rasterising is real
    // asynchronous work and the test binding's clock does not move for
    // it. The same trap the screenshot test documents.
    return (await tester.runAsync(boundary.toImage))!;
  }

  Future<Uint8List> pixels(WidgetTester tester, ui.Image image) async {
    final data = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    return Uint8List.view(data.buffer);
  }

  Future<({int dark, int light})> counted(
    WidgetTester tester,
    ui.Image image,
  ) async {
    final bytes = await pixels(tester, image);
    var dark = 0;
    var light = 0;
    for (var at = 0; at < bytes.length; at += 4) {
      final value = bytes[at];
      if (value < 40) dark++;
      if (value > 215) light++;
    }
    return (dark: dark, light: light);
  }

  testWidgets('it draws something with both dark and light in it', (
    tester,
  ) async {
    final image = await render(
      tester,
      const QrCodeView(data: 'PS1:aabbccdd:0:1:test', semanticLabel: 'Bild'),
      size: const Size(320, 320),
    );
    final counts = await counted(tester, image);

    expect(counts.dark, greaterThan(0));
    expect(counts.light, greaterThan(counts.dark), reason: 'mostly quiet');
  });

  testWidgets('the code sits on white, right out to its own edge', (
    tester,
  ) async {
    // Without four empty modules of margin most readers cannot find the
    // code at all, and "it does not scan" looks exactly like a bug. The
    // painted square is found first rather than assumed: what lies
    // outside it is transparent, because the size is rounded down so the
    // modules land on whole pixels.
    final image = await render(
      tester,
      const QrCodeView(data: 'PS1:aabbccdd:0:1:test', semanticLabel: 'Bild'),
      size: const Size(320, 320),
    );
    final bytes = await pixels(tester, image);

    int red(int x, int y) => bytes[(y * image.width + x) * 4];
    int alpha(int x, int y) => bytes[(y * image.width + x) * 4 + 3];

    var left = 0;
    while (left < image.width && alpha(left, image.height ~/ 2) == 0) {
      left++;
    }
    var top = 0;
    while (top < image.height && alpha(image.width ~/ 2, top) == 0) {
      top++;
    }
    final right = image.width - 1 - left;
    final bottom = image.height - 1 - top;

    expect(left, lessThan(image.width ~/ 4), reason: 'something was painted');

    for (final (x, y) in [
      (left + 2, top + 2),
      (right - 2, top + 2),
      (left + 2, bottom - 2),
      (right - 2, bottom - 2),
    ]) {
      expect(red(x, y), greaterThan(215), reason: 'corner ($x, $y) is white');
    }
  });

  testWidgets('no module is drawn grey', (tester) async {
    // The reason the size is rounded down to whole pixels. A module drawn
    // at a fractional width gets anti-aliased, and a grey module is
    // neither dark nor light to a decoder -- a code that looks perfectly
    // fine and does not scan.
    final image = await render(
      tester,
      QrCodeView(data: 'PS1:aabbccdd:3:12:${'A' * 600}', semanticLabel: 'Bild'),
      size: const Size(320, 320),
    );
    final bytes = await pixels(tester, image);

    var grey = 0;
    var painted = 0;
    for (var at = 0; at < bytes.length; at += 4) {
      if (bytes[at + 3] == 0) continue;
      painted++;
      final value = bytes[at];
      if (value >= 40 && value <= 215) grey++;
    }

    expect(painted, greaterThan(0));
    expect(
      grey / painted,
      lessThan(0.01),
      reason: '$grey of $painted painted pixels are neither dark nor light',
    );
  });

  testWidgets('it says what it is to a screen reader', (tester) async {
    // A picture of a QR code read out module by module is useless; read
    // out as nothing at all is worse.
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QrCodeView(
            data: 'PS1:aabbccdd:2:12:test',
            semanticLabel: 'Bild 3 von 12',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Bild 3 von 12'), findsOneWidget);
    handle.dispose();
  });
}

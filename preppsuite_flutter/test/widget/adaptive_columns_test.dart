import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/adaptive_columns.dart';

void main() {
  Future<void> show(WidgetTester tester, Size size, List<Widget> blocks) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveColumns(
            padding: const EdgeInsets.all(16),
            blocks: blocks,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<Widget> numbered(int count) => [
    for (var i = 0; i < count; i++)
      SizedBox(height: 80, child: Text('Block $i')),
  ];

  group('how many columns', () {
    test('a phone gets one', () {
      expect(AdaptiveColumns.columnsFor(400), 1);
      expect(AdaptiveColumns.columnsFor(559), 1);
    });

    test('a second column opens only when a whole one fits', () {
      // 560 + 24 + 560: anything narrower would give two columns that are
      // each too narrow, which is worse than one of the right width.
      expect(AdaptiveColumns.columnsFor(1143), 1);
      expect(AdaptiveColumns.columnsFor(1144), 2);
    });

    test('it stops at three', () {
      expect(AdaptiveColumns.columnsFor(4000), 3);
      expect(AdaptiveColumns.columnsFor(10000), 3);
    });

    test('a width of nothing is still one column', () {
      // Happens for one frame inside an unbounded parent.
      expect(AdaptiveColumns.columnsFor(0), 1);
      expect(AdaptiveColumns.columnsFor(double.infinity), 1);
    });
  });

  testWidgets('narrow stays a lazy ListView', (tester) async {
    await show(tester, const Size(400, 800), numbered(3));

    // Not just "looks the same": the narrow case keeps the widget that
    // only builds what is on screen.
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Block 0'), findsOneWidget);
  });

  testWidgets('a wide window puts the blocks side by side', (tester) async {
    await show(tester, const Size(1500, 900), numbered(4));

    final first = tester.getTopLeft(find.text('Block 0'));
    final second = tester.getTopLeft(find.text('Block 1'));

    expect(second.dx, greaterThan(first.dx), reason: 'beside, not below');
    expect(second.dy, first.dy, reason: 'and level with it');
  });

  testWidgets('a block is not torn in half', (tester) async {
    // The reason blocks exist at all: a heading and the list under it
    // have to stay in the same column.
    await show(tester, const Size(1500, 900), [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text('Giftnotrufzentralen'), Text('030 19240')],
      ),
      const Text('Sirenensignale'),
    ]);

    expect(
      tester.getTopLeft(find.text('030 19240')).dx,
      tester.getTopLeft(find.text('Giftnotrufzentralen')).dx,
    );
  });

  testWidgets('every block is still there', (tester) async {
    await show(tester, const Size(1500, 900), numbered(7));

    for (var i = 0; i < 7; i++) {
      expect(find.text('Block $i'), findsOneWidget);
    }
  });

  testWidgets('columns stretch to fill the window, within reason', (
    tester,
  ) async {
    // 1800 has room for three, which then share it: wider than the 560 a
    // column is measured at, and that is the point -- the space is used.
    await show(tester, const Size(1800, 900), numbered(6));

    final stretched = tester.getSize(find.text('Block 0')).width;
    expect(stretched, greaterThan(560));
    expect(stretched, lessThanOrEqualTo(560 * 1.25));
  });

  testWidgets('a very wide window stops widening and centres', (tester) async {
    // Otherwise the rule eats itself: three columns sharing 4000 px are
    // the same unreadable line the columns were there to prevent.
    await show(tester, const Size(4000, 900), numbered(6));

    final width = tester.getSize(find.text('Block 0')).width;
    expect(width, lessThanOrEqualTo(560 * 1.25));

    // Centred, so the margin falls on both sides rather than all at the
    // right.
    final left = tester.getTopLeft(find.text('Block 0')).dx;
    expect(left, greaterThan(200));
  });
}

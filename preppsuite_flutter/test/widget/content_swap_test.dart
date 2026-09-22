import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/content_swap.dart';

/// The first animation in the app, and the rules it keeps.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ContentSwap(child: child),
        ),
      ),
    );
  }

  testWidgets('a spinner becoming a list is not one frame', (tester) async {
    await pump(tester, const Center(child: CircularProgressIndicator()));
    await pump(tester, const Text('fertig'));

    // Both on screen mid-fade, which is what makes it read as one thing
    // becoming another rather than a jump.
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('fertig'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('fertig'), findsOneWidget);
  });

  testWidgets('it is over quickly enough that nobody waits for it', (
    tester,
  ) async {
    await pump(tester, const Text('eins'));
    await pump(tester, const Placeholder());

    await tester.pump(ContentSwap.duration + const Duration(milliseconds: 20));
    expect(find.text('eins'), findsNothing);
  });

  testWidgets('reduced motion means no motion, not less of it', (
    tester,
  ) async {
    // Somebody who asked their device to stop moving things asked for a
    // reason. They get the frame-to-frame change they had before.
    await pump(
      tester,
      const Center(child: CircularProgressIndicator()),
      reduceMotion: true,
    );
    await pump(tester, const Text('fertig'), reduceMotion: true);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('fertig'), findsOneWidget);
  });

  testWidgets('the same kind of content is left alone', (tester) async {
    // A list that gained a row is not a different thing, and fading it on
    // every tick of the database would fight the scroll position.
    await pump(tester, const Text('eins'));
    await pump(tester, const Text('zwei'));
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('eins'), findsNothing);
    expect(find.text('zwei'), findsOneWidget);
  });
}

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// The four checks Flutter can make on a rendered screen without knowing
/// anything about it, run together so a screen either passes all of them or
/// names the one it fails.
///
/// They are cheap and they are the only thing standing between a new screen
/// and a silent regression: a tappable icon added without a tooltip, a hint
/// coloured `outline` on `surface`, a 32-pixel close button. None of that
/// shows up in a normal widget test, because a test that looks for text
/// finds the text either way.
///
/// What they do not check is whether the screen makes sense read aloud —
/// that is a judgement no matcher makes. Passing these is the floor.
///
/// Call it with the screen already pumped and settled:
///
/// ```dart
/// testWidgets('is accessible', (tester) async {
///   await pumpScreen(tester, []);
///   await expectAccessible(tester);
/// });
/// ```
/// Pass [contrastExemption] to skip the contrast check, naming the reason.
/// There is one legitimate reason and it is WCAG 1.4.3's own: text in an
/// inactive control is exempt, and `textContrastGuideline` does not know
/// that — it reports Material's greyed-out label like any other. The
/// parameter takes a string so the exemption has to be argued at the call
/// site instead of quietly disappearing.
Future<void> expectAccessible(
  WidgetTester tester, {
  String? contrastExemption,
}) async {
  // Semantics are not built unless something asks for them, and the
  // guidelines read the semantics tree, not the widget tree.
  final handle = tester.ensureSemantics();
  try {
    if (contrastExemption == null) {
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  } finally {
    handle.dispose();
  }
}

/// Every node in the rendered tree that asks to be read out as soon as it
/// appears. Used to check that the ones that should announce do, and that
/// the ones rebuilt on a timer do not.
List<SemanticsNode> liveRegions(WidgetTester tester) {
  final found = <SemanticsNode>[];
  void walk(SemanticsNode node) {
    if (node.getSemanticsData().flagsCollection.isLiveRegion) {
      found.add(node);
    }
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(tester.binding.rootElement!.renderObject!.debugSemantics!);
  return found;
}

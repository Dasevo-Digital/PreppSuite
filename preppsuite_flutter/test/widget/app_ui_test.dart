import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_theme.dart';
import 'package:preppsuite_flutter/core/app_ui.dart';

/// The parts that stand in every row of a long list. What is tested is
/// what they are for: they stay smaller than the widgets they replaced.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: appLightTheme,
      home: Scaffold(body: Center(child: child)),
    ),
  );

  int elementsIn(WidgetTester tester, Finder root) {
    var count = 0;
    void visit(Element element) {
      count++;
      element.visitChildren(visit);
    }

    visit(tester.element(root));
    return count;
  }

  testWidgets('a tag costs a fraction of a chip', (tester) async {
    await pump(tester, const Chip(label: Text('abgelaufen')));
    final chip = elementsIn(tester, find.byType(Chip));

    await pump(
      tester,
      const StatusTag(
        label: 'abgelaufen',
        background: Colors.white,
        foreground: Colors.black,
      ),
    );
    final tag = elementsIn(tester, find.byType(StatusTag));

    expect(tag, lessThan(chip / 3));
  });

  testWidgets('a tag is lower than a chip, so the row stays low', (
    tester,
  ) async {
    await pump(tester, const Chip(label: Text('abgelaufen')));
    final chip = tester.getSize(find.byType(Chip)).height;

    await pump(
      tester,
      const StatusTag(
        label: 'abgelaufen',
        background: Colors.white,
        foreground: Colors.black,
      ),
    );

    expect(tester.getSize(find.byType(StatusTag)).height, lessThan(chip));
  });

  testWidgets('a badge costs less than an avatar', (tester) async {
    await pump(tester, const CircleAvatar(child: Icon(Icons.home)));
    final avatar = elementsIn(tester, find.byType(CircleAvatar));

    await pump(tester, const IconBadge(Icons.home));

    expect(elementsIn(tester, find.byType(IconBadge)), lessThan(avatar));
  });

  testWidgets('a meter holds no ticker and no painter', (tester) async {
    await pump(tester, const SizedBox(width: 200, child: ThinMeter(value: .5)));

    expect(
      find.descendant(
        of: find.byType(ThinMeter),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a meter fills as far as its value, and no further', (
    tester,
  ) async {
    Future<double> fill(double value) async {
      await pump(
        tester,
        SizedBox(width: 200, child: ThinMeter(value: value)),
      );
      return tester
          .getSize(
            find
                .descendant(
                  of: find.byType(FractionallySizedBox),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .width;
    }

    expect(await fill(0.25), 50);
    expect(await fill(1.7), 200);
    expect(await fill(0), 0);
  });

  testWidgets('a section heading is announced as one', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const SectionHeading('Wasser'));

    expect(
      tester.getSemantics(find.text('Wasser')),
      matchesSemantics(label: 'Wasser', isHeader: true),
    );
    handle.dispose();
  });

  // Ochre until the value is reached (#322). A green bar at one point of
  // ten says "done" to anybody who only glances at it.
  Color fill(WidgetTester tester) {
    final boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(ThinMeter),
        matching: find.byType(DecoratedBox),
      ),
    );
    return (boxes.last.decoration as BoxDecoration).color!;
  }

  testWidgets('a meter short of its goal is ochre', (tester) async {
    await pump(tester, const SizedBox(width: 200, child: ThinMeter(value: .1)));
    expect(fill(tester), appLightTheme.colorScheme.tertiary);
  });

  testWidgets('a meter at its goal is green', (tester) async {
    await pump(tester, const SizedBox(width: 200, child: ThinMeter(value: 1)));
    expect(fill(tester), appLightTheme.colorScheme.primary);
  });

  // Both styles carry `onSurface`, and a colour in the style wins over the
  // defaults: the chosen tab differed by its weight alone (#322).
  test('the chosen tab has a colour of its own', () {
    for (final theme in [appLightTheme, appDarkTheme]) {
      final tabs = theme.tabBarTheme;
      expect(tabs.labelColor, theme.colorScheme.primary);
      expect(tabs.unselectedLabelColor, theme.colorScheme.onSurfaceVariant);
    }
  });
}

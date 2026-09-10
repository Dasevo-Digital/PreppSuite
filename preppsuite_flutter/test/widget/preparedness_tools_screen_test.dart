import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/drill_progress_store.dart';
import 'package:preppsuite_flutter/features/home/presentation/preparedness_tools_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Working through a drill.
///
/// The ticks used to live in the widget's own state, so leaving the screen
/// lost them. A drill takes twenty minutes with the family, and somebody
/// will step away to check the household plan or the offline map — coming
/// back to an empty list is where a drill gets abandoned.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // An empty tree first, so pumping the screen builds it from nothing.
    // Pumped twice with an identical tree, Flutter updates the elements in
    // place instead: initState never runs again and the expansion tiles
    // keep whatever state they had, which is not what leaving and
    // returning to the screen does.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PreparednessToolsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the first drill and returns its checkboxes.
  Future<Finder> openFirstDrill(WidgetTester tester) async {
    await tester.tap(find.text('72 Stunden ohne Strom'));
    await tester.pumpAndSettle();
    return find.byType(CheckboxListTile);
  }

  testWidgets('the interface is German only because the locale is', (
    tester,
  ) async {
    // The screen title, the section heading and the call button all used
    // to be German string literals, which showed through on an English
    // locale. The drills themselves are still German content on purpose.
    await show(tester);

    expect(find.text('Notfallmodus und Übungen'), findsWidgets);
    expect(find.text('112 anrufen'), findsOneWidget);
    expect(find.text('Übungsmodus'), findsOneWidget);
  });

  testWidgets('a ticked step is still ticked after leaving and coming back', (
    tester,
  ) async {
    await show(tester);
    final boxes = await openFirstDrill(tester);
    await tester.tap(boxes.first);
    await tester.pumpAndSettle();

    expect(tester.widget<CheckboxListTile>(boxes.first).value, isTrue);

    // A fresh tree, as returning to the screen builds.
    await show(tester);
    final again = await openFirstDrill(tester);
    expect(tester.widget<CheckboxListTile>(again.first).value, isTrue);
  });

  testWidgets('unticking it takes it back out again', (tester) async {
    await show(tester);
    final boxes = await openFirstDrill(tester);
    await tester.tap(boxes.first);
    await tester.pumpAndSettle();
    await tester.tap(boxes.first);
    await tester.pumpAndSettle();

    await show(tester);
    final again = await openFirstDrill(tester);
    expect(tester.widget<CheckboxListTile>(again.first).value, isFalse);
  });

  testWidgets('starting over is offered once something is ticked, not before', (
    tester,
  ) async {
    // Ticks outlive the screen now, so without this the second run of a
    // drill would begin already finished.
    await show(tester);
    expect(find.text('Von vorn beginnen'), findsNothing);

    final boxes = await openFirstDrill(tester);
    await tester.tap(boxes.first);
    await tester.pumpAndSettle();
    expect(find.text('Von vorn beginnen'), findsOneWidget);

    await tester.tap(find.text('Von vorn beginnen'));
    await tester.pumpAndSettle();

    expect(find.text('Von vorn beginnen'), findsNothing);
    expect(tester.widget<CheckboxListTile>(boxes.first).value, isFalse);
  });

  testWidgets('starting over also clears what was stored', (tester) async {
    await show(tester);
    final boxes = await openFirstDrill(tester);
    await tester.tap(boxes.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Von vorn beginnen'));
    await tester.pumpAndSettle();

    expect(await const DrillProgressStore().load(), isEmpty);
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('the screen survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}

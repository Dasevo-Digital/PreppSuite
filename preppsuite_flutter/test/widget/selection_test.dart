import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/core/app_theme.dart';
import 'package:preppsuite_flutter/core/selectable_everywhere.dart';

/// Making every label selectable, and the reason it can be done at all.
///
/// A `SelectionArea` around the whole app is only safe because the drag
/// gestures it introduces lose the gesture arena to the ones already
/// there. That is measured rather than assumed: if a Flutter release ever
/// changes it, a map that no longer pans is a far worse bug than text that
/// cannot be copied, and it would otherwise only surface on a device.
void main() {
  testWidgets('a map inside a selection area still pans', (tester) async {
    final controller = MapController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            child: FlutterMap(
              mapController: controller,
              options: const MapOptions(
                initialCenter: LatLng(52.3759, 9.7320),
                initialZoom: 10,
              ),
              children: const [],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.drag(find.byType(FlutterMap), const Offset(-120, -80));
    await tester.pumpAndSettle();

    // Dragged up and to the left, so the centre moves north and east.
    expect(controller.camera.center.longitude, greaterThan(9.7320));
    expect(controller.camera.center.latitude, lessThan(52.3759));
  });

  testWidgets('a list inside a selection area still scrolls', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            child: ListView.builder(
              controller: controller,
              itemCount: 200,
              itemBuilder: (_, i) => ListTile(title: Text('Zeile $i')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(0));
  });

  testWidgets('a slider inside a selection area still drags', (tester) async {
    var value = 0.5;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            child: StatefulBuilder(
              builder: (context, setState) => Slider(
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(value, greaterThan(0.5));
  });

  testWidgets('a plain Text takes part in selection', (tester) async {
    // The whole point: `Text` is not selectable by itself, and this is
    // what changes that. Without the area above it there is no registrar
    // and the label cannot be reached by a copy at all.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SelectionArea(child: Text('Notvorrat'))),
      ),
    );
    await tester.pump();

    expect(
      SelectionContainer.maybeOf(tester.element(find.text('Notvorrat'))),
      isNotNull,
    );
  });

  testWidgets('and does not, without one', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Notvorrat'))),
    );
    await tester.pump();

    expect(
      SelectionContainer.maybeOf(tester.element(find.text('Notvorrat'))),
      isNull,
    );
  });

  group('everywhere in the app (#39)', () {
    // The area used to sit around the start screen only, so every screen
    // opened above it and every dialog could not be copied from. These
    // build the app's own arrangement -- the theme's page transitions
    // and the area around the navigator -- and copy the way a person
    // does, through the clipboard.
    late List<String> copied;

    setUp(() => copied = []);
    final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);

    Future<void> pumpApp(WidgetTester tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: appLightTheme,
          builder: (context, child) => SelectableEverywhere(child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  const Text('Startseite'),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => Scaffold(
                          body: Column(
                            children: [
                              const Text('Noch 12 Liter'),
                              TextButton(
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => const AlertDialog(
                                    content: Text('Schlüssel 03241 Region'),
                                  ),
                                ),
                                child: const Text('Dialog'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Weiter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Weiter'));
      await tester.pumpAndSettle();
    }

    Future<void> rightClickCopy(WidgetTester tester, String text) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(text)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
    }

    Future<void> selectAllAndCopy(WidgetTester tester, String text) async {
      await tester.tapAt(
        tester.getCenter(find.text(text)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();
    }

    testWidgets('a screen opened above the first one can be copied from', (
      tester,
    ) async {
      await pumpApp(tester);
      await rightClickCopy(tester, 'Noch 12 Liter');

      // A right-click takes the word under the pointer, as in a browser.
      expect(copied, ['12']);
    }, variant: macOS);

    testWidgets('and "select all" there leaves the screens beneath it out', (
      tester,
    ) async {
      // The navigator keeps the start screen built under this one. One
      // area around all of them copied its text along.
      await pumpApp(tester);
      await selectAllAndCopy(tester, 'Noch 12 Liter');

      expect(copied.single, contains('Noch 12 Liter'));
      expect(copied.single, isNot(contains('Startseite')));
    }, variant: macOS);

    testWidgets('a dialog can be copied from, and only the dialog', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Dialog'));
      await tester.pumpAndSettle();

      await rightClickCopy(tester, 'Schlüssel 03241 Region');
      expect(copied, ['03241']);

      copied.clear();
      await selectAllAndCopy(tester, 'Schlüssel 03241 Region');
      expect(copied, ['Schlüssel 03241 Region']);
    }, variant: macOS);

    test('every platform\'s page transition brings its area along', () {
      for (final theme in [appLightTheme, appDarkTheme]) {
        final builders = theme.pageTransitionsTheme.builders;
        expect(builders.keys, containsAll(TargetPlatform.values));
        expect(builders.values, everyElement(isA<SelectablePageTransitions>()));
      }
    });
  });
}

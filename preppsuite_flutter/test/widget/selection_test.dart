import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

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
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/road_closure_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/road_closure_store.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/road_closure_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

RoadEvent _event({
  required bool future,
  required bool blocked,
  RoadEventKind kind = RoadEventKind.closure,
  String title = 'A2 | Braunschweig - Königslutter',
}) => RoadEvent(
  road: 'A2',
  kind: kind,
  title: title,
  direction: 'Hannover -> Berlin',
  description: const ['Vollsperrung'],
  startsAt: DateTime(2026, 9, 12, 21),
  future: future,
  blocked: blocked,
);

class _FakeClient implements RoadClosureClient {
  _FakeClient({this.events = const [], this.fails = false});

  final List<RoadEvent> events;
  final bool fails;

  @override
  Future<List<String>> fetchRoads() async => const ['A2', 'A39'];

  @override
  Future<List<RoadEvent>> fetchEvents(String road) async {
    if (fails) throw const RoadClosureException(503);
    return events;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester, _FakeClient client) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RoadClosureScreen(client: client),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing chosen it explains why it has to be chosen', (
    tester,
  ) async {
    await show(tester, _FakeClient());

    expect(find.text('Noch keine Autobahn gewählt'), findsOneWidget);
    // The service answers per road; that is the reason, and it is said.
    expect(find.textContaining('nur je Autobahn'), findsOneWidget);
  });

  testWidgets('what is standing on the road comes before what is announced', (
    tester,
  ) async {
    await const RoadClosureStore().save(['A2']);
    await show(
      tester,
      _FakeClient(
        events: [
          _event(future: true, blocked: true, title: 'A2 | Später gesperrt'),
          _event(future: false, blocked: true, title: 'A2 | Jetzt gesperrt'),
        ],
      ),
    );

    final now = tester.getTopLeft(find.text('A2 | Jetzt gesperrt')).dy;
    final later = tester.getTopLeft(find.text('A2 | Später gesperrt')).dy;
    expect(now, lessThan(later), reason: 'a closure starting Friday is not a reason to turn round today');
    expect(find.text('Jetzt'), findsOneWidget);
    expect(find.text('Angekündigt'), findsOneWidget);
  });

  testWidgets('an open road says so rather than showing nothing', (
    tester,
  ) async {
    await const RoadClosureStore().save(['A2']);
    await show(tester, _FakeClient());

    expect(find.textContaining('keine Sperrung'), findsOneWidget);
  });

  testWidgets('a blocked carriageway is marked as blocked', (tester) async {
    await const RoadClosureStore().save(['A2']);
    await show(
      tester,
      _FakeClient(events: [_event(future: false, blocked: true)]),
    );

    expect(find.text('Gesperrt'), findsOneWidget);
    expect(find.text('Hannover -> Berlin'), findsOneWidget);
  });

  testWidgets('a warning that blocks nothing is shown without the mark', (
    tester,
  ) async {
    await const RoadClosureStore().save(['A2']);
    await show(
      tester,
      _FakeClient(
        events: [
          _event(
            future: false,
            blocked: false,
            kind: RoadEventKind.warning,
            title: 'A2 | Gegenstände auf der Fahrbahn',
          ),
        ],
      ),
    );

    expect(find.text('A2 | Gegenstände auf der Fahrbahn'), findsOneWidget);
    expect(find.text('Gesperrt'), findsNothing);
  });

  testWidgets('a failed fetch is reported, not shown as an open road', (
    tester,
  ) async {
    // The dangerous failure here is the quiet one: "no closures" and
    // "could not ask" must never look the same.
    await const RoadClosureStore().save(['A2']);
    await show(tester, _FakeClient(fails: true));

    expect(find.textContaining('nicht zu erreichen'), findsOneWidget);
    expect(find.textContaining('keine Sperrung'), findsNothing);
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await const RoadClosureStore().save(['A2']);
    await show(
      tester,
      _FakeClient(events: [_event(future: false, blocked: true)]),
    );
    await expectAccessible(tester);
  });

  testWidgets('it survives twice the font size', (tester) async {
    useLargeText(tester);
    await const RoadClosureStore().save(['A2']);
    await show(
      tester,
      _FakeClient(events: [_event(future: false, blocked: true)]),
    );
  });
}

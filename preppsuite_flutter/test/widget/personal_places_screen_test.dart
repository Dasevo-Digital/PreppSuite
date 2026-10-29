import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/personal_place.dart';
import 'package:preppsuite_flutter/features/maps/presentation/personal_places_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

class _RejectedPlaceWrite extends InMemorySharedPreferencesStore {
  _RejectedPlaceWrite(super.data) : super.withData();
  @override
  Future<bool> setValue(String type, String key, Object value) async => false;
}

/// The own places, and the two doors that were missing.
///
/// They used to be a one-way street: typed in here and leaving only when
/// the phone did. A plan that cannot leave the app it was made in is a
/// plan that ends with the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const places = [
    PersonalPlace(
      id: 'a',
      label: 'Treffpunkt Schule',
      latitude: 52.516275,
      longitude: 13.377704,
    ),
  ];

  Future<void> show(
    WidgetTester tester, {
    List<PersonalPlace> given = places,
  }) async {
    await tester.binding.setSurfaceSize(const Size(500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PersonalPlacesScreen(places: given),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('both doors are on the screen', (tester) async {
    await show(tester);

    expect(find.byTooltip('Orte einlesen'), findsOneWidget);
    expect(find.byTooltip('Orte abgeben'), findsOneWidget);
  });

  testWidgets('both formats are offered, because it depends where it goes', (
    tester,
  ) async {
    // GPX is what receivers and hiking software speak, KML what the
    // mapping services do. The app cannot know which is wanted.
    await show(tester);
    await tester.tap(find.byTooltip('Orte abgeben'));
    await tester.pumpAndSettle();

    expect(find.text('Als GPX abgeben'), findsOneWidget);
    expect(find.text('Als KML abgeben'), findsOneWidget);
  });

  testWidgets('nothing to hand over means the button does not pretend', (
    tester,
  ) async {
    await show(tester, given: const []);

    final button = tester.widget<PopupMenuButton<bool>>(
      find.byType(PopupMenuButton<bool>),
    );
    expect(button.enabled, isFalse);
    // Reading in still makes sense with an empty list — that is rather
    // the point of it.
    expect(find.byTooltip('Orte einlesen'), findsOneWidget);
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('it survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
  testWidgets(
    'failed place persistence keeps the confirmed list and reports an error',
    (tester) async {
      await const PersonalPlaceStore().save(places);
      final prefs = await SharedPreferences.getInstance();
      SharedPreferencesStorePlatform.instance = _RejectedPlaceWrite({
        for (final key in prefs.getKeys()) 'flutter.$key': prefs.get(key)!,
      });
      await show(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Neuer Ort');
      await tester.enterText(fields.at(1), '1');
      await tester.enterText(fields.at(2), '2');
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Neuer Ort'), findsNothing);
      expect(find.text(places.single.label), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        (await const PersonalPlaceStore().load()).single.label,
        places.single.label,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a stale editor cannot bring a deleted place back', (
    tester,
  ) async {
    await const PersonalPlaceStore().save(places);
    await show(tester);
    await tester.tap(find.text(places.single.label));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await const PersonalPlaceStore().update((_) => []);
    await tester.enterText(find.byType(TextField).first, 'Veraltete Änderung');
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Veraltete Änderung'), findsNothing);
    expect(await const PersonalPlaceStore().load(), isEmpty);
  });
}

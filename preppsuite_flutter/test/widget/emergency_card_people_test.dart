import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/household/presentation/emergency_card_form_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// More than one doctor, and more than one person to ring.
///
/// Both were a single line each, which suited a household with one GP and
/// one partner and nobody else.
///
/// What this file does **not** do is tap save and read the row back. A
/// `testWidgets` body that writes to the household database never
/// returns here — the write completes, the assertions pass, and the test
/// then hangs before its first teardown. It is nothing to do with this
/// screen: the same thing happens with no screen at all, calling the
/// controller directly against an in-memory database. So what is stored
/// is tested where it is decided, in `card_people_test.dart`, and what is
/// shown is tested here.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  HouseholdMember card({String? doctor, String? contact}) => HouseholdMember(
    clientId: 'lena',
    householdId: 'h',
    name: 'Lena',
    doctor: doctor,
    emergencyContact: contact,
    sortOrder: 0,
    updatedAt: DateTime.utc(2026, 9, 22),
    dirty: false,
  );

  late AppLocalizations l10n;

  Future<void> open(WidgetTester tester, HouseholdMember member) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          navigatorKey: navigator,
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(),
        ),
      ),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              EmergencyCardFormScreen(householdId: 'h', existing: member),
        ),
      ),
    );
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(
      tester.element(find.byType(EmergencyCardFormScreen)),
    )!;
  }

  /// The name fields, in order: the card's own, then one per doctor,
  /// then one per person to ring.
  Finder names() => find.widgetWithText(TextField, 'Name');

  testWidgets('a stored list opens as one row per entry', (tester) async {
    await open(
      tester,
      card(
        doctor:
            'Dr. Sandoval (Hausärztin) · 0531 1\n'
            'Dr. Weller (Kardiologe) · 0531 2',
      ),
    );

    expect(find.text('Dr. Sandoval'), findsOneWidget);
    expect(find.text('Hausärztin'), findsOneWidget);
    expect(find.text('Dr. Weller'), findsOneWidget);
    expect(find.text('0531 2'), findsOneWidget);
  });

  testWidgets('both sections open with a row to fill in', (tester) async {
    // A card that has never named anybody. An empty section with only an
    // "add" button under it reads as a feature to discover, and this is
    // a form to fill in.
    await open(tester, card());

    expect(names(), findsNWidgets(3));
    expect(
      find.widgetWithText(TextField, l10n.emergencyCardSpecialty),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextField, l10n.emergencyCardRelation),
      findsOneWidget,
    );
  });

  testWidgets('adding a doctor adds a row and keeps the one above it', (
    tester,
  ) async {
    await open(tester, card(doctor: 'Dr. Sandoval (Hausärztin) · 0531 1'));

    await tester.tap(find.text(l10n.emergencyCardDoctorAdd));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Sandoval'), findsOneWidget);
    // Card, two doctors, one contact.
    expect(names(), findsNWidgets(4));
  });

  testWidgets('removing one leaves the others where they were', (
    tester,
  ) async {
    // Rows are identified rather than counted, so taking the middle one
    // away must not hand the last one's contents to the middle's fields.
    await open(
      tester,
      card(
        doctor: 'Dr. Eins · 1\nDr. Zwei · 2\nDr. Drei · 3',
      ),
    );

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.close).at(1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dr. Eins'), findsOneWidget);
    expect(find.text('Dr. Zwei'), findsNothing);
    expect(find.text('Dr. Drei'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('the last row is emptied rather than taken away', (
    tester,
  ) async {
    await open(tester, card(contact: 'Anna Weber (Partnerin) · 0170 987'));

    // The contact section's remove button: one doctor row, one contact.
    await tester.tap(find.widgetWithIcon(IconButton, Icons.close).at(1));
    await tester.pumpAndSettle();

    expect(find.text('Anna Weber'), findsNothing);
    expect(names(), findsNWidgets(3));
  });

  testWidgets('a single free-text line opens as a name and nothing else', (
    tester,
  ) async {
    // Everything written before this existed. No migration touches it,
    // so the form has to carry it through as it stands.
    await open(tester, card(doctor: 'Dr. Müller, Praxis am Markt'));

    expect(find.text('Dr. Müller, Praxis am Markt'), findsOneWidget);
  });
}

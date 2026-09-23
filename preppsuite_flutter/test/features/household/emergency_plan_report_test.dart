import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:preppsuite_flutter/features/household/application/emergency_plan_report.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import '../../pdf_text.dart';

/// The paper copy of the household's agreement.
///
/// Read back out of the finished PDF rather than trusted: what this puts on
/// a sheet of paper cannot be taken back, and the emergency cards on it
/// name blood group, allergies and medication. A field that leaks onto the
/// page when nobody asked for it is not a cosmetic bug.
void main() {
  const strings = EmergencyPlanReportStrings(
    title: 'Notfallplan',
    generatedOn: 'Erstellt am 10.09.2026',
    meetingPoints: 'Treffpunkte',
    contact: 'Kontakt',
    contactPoint: 'Anlaufstelle der Gemeinde',
    equipment: 'Ausrüstung',
    notes: 'Notizen',
    empty: 'Nicht eingetragen',
    cards: 'Notfallkarten',
    cardsWarning: 'Auf diesem Blatt stehen Gesundheitsdaten.',
    fields: EmergencyCardFieldStrings(
      birthYear: 'Geburtsjahr',
      bloodType: 'Blutgruppe',
      allergies: 'Allergien',
      medication: 'Medikation',
      conditions: 'Vorerkrankungen',
      insurance: 'Versicherung',
      doctor: 'Arzt',
      doctors: 'Aerzte',
      contact: 'Notfallkontakt',
      contacts: 'Notfallkontakte',
      careNeeds: 'Unterstützungsbedarf',
      notes: 'Notizen',
    ),
  );

  final plan = HouseholdPlan(
    clientId: 'plan-1',
    householdId: 'household-1',
    meetingPointNear: 'Vor der Garage',
    contactName: 'Tante Erna',
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  HouseholdMember member({
    String clientId = 'm1',
    String name = 'Anna Muster',
    int? birthYear,
    String? bloodType,
    String? allergies,
    String? medication,
    String? conditions,
    String? careNeeds,
    String? notes,
  }) => HouseholdMember(
    clientId: clientId,
    householdId: 'household-1',
    name: name,
    birthYear: birthYear,
    bloodType: bloodType,
    allergies: allergies,
    medication: medication,
    conditions: conditions,
    careNeeds: careNeeds,
    notes: notes,
    sortOrder: 0,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  Future<Uint8List> render({List<HouseholdMember> members = const []}) {
    return const EmergencyPlanReport().build(
      plan: plan,
      householdName: 'Familie Muster',
      strings: strings,
      members: members,
      // A built-in font, so the text lands in the stream as literals the
      // assertions below can read. Which fields get printed does not
      // depend on the typeface.
      font: pw.Font.helvetica(),
    );
  }

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  test('the municipality contact point reaches the paper', () async {
    // The one thing on this sheet that is only useful on paper: it is
    // where somebody walks to when the power has been out for two days
    // and the phone is dead, which is exactly when the app cannot be
    // asked.
    final withPoint = plan.copyWith(
      localContactPoint: const Value('Grundschule Nordstadt, Turnhalle'),
    );
    final text = textIn(
      await const EmergencyPlanReport().build(
        plan: withPoint,
        householdName: 'Familie Muster',
        strings: strings,
        font: pw.Font.helvetica(),
      ),
    );

    expect(text, contains('Anlaufstelle'));
    expect(text, contains('Grundschule Nordstadt'));
  });

  test('an unset contact point is headed and marked as unfilled', () async {
    // Unlike the emergency cards, where an empty field is left off: on a
    // plan the gap is the message. Somebody reading it should notice they
    // never found out what their municipality opens.
    final text = textIn(await render());

    expect(text, contains('Anlaufstelle'));
    expect(text, contains('Nicht eingetragen'));
  });

  test('the plan itself is on the sheet', () async {
    final text = textIn(await render());

    expect(text, contains('Familie Muster'));
    expect(text, contains('Vor der Garage'));
    expect(text, contains('Tante Erna'));
  });

  test('without cards asked for, no health data appears', () async {
    // The default, and the one that must never surprise anybody: passing
    // no members has to mean nothing about them on the page.
    final text = textIn(await render());

    expect(text, isNot(contains('Notfallkarten')));
    expect(text, isNot(contains('Blutgruppe')));
  });

  test('with cards asked for, the card is printed', () async {
    final text = textIn(
      await render(
        members: [
          member(
            birthYear: 1984,
            bloodType: '0 negativ',
            allergies: 'Penicillin',
            medication: 'Levothyroxin 50',
          ),
        ],
      ),
    );

    expect(text, contains('Anna Muster'));
    expect(text, contains('0 negativ'));
    expect(text, contains('Penicillin'));
    expect(text, contains('Levothyroxin 50'));
    expect(text, contains('1984'));
  });

  test('the sheet carries the warning itself', () async {
    // Not only the dialog that offered it. The dialog is gone once
    // answered; the paper is what somebody finds in a drawer years later.
    final text = textIn(await render(members: [member(bloodType: 'A+')]));

    expect(text, contains('Gesundheitsdaten'));
  });

  test('a field nobody filled in is left off, not printed empty', () async {
    // "Allergien: —" invites the reader to believe somebody checked, and
    // on a sheet handed to a paramedic that is worse than saying nothing.
    final text = textIn(await render(members: [member(bloodType: 'A+')]));

    expect(text, contains('Blutgruppe'));
    expect(text, isNot(contains('Allergien')));
    expect(text, isNot(contains('Vorerkrankungen')));
  });

  test('whitespace alone counts as unfilled', () async {
    final text = textIn(await render(members: [member(allergies: '   ')]));

    expect(text, isNot(contains('Allergien')));
  });

  test(
    'a practical support dependency reaches an explicitly requested card',
    () async {
      final text = textIn(
        await render(
          members: [
            member(
              careNeeds:
                  'Elektrisches Hilfsmittel und barrierefreier Transport',
            ),
          ],
        ),
      );

      expect(text, contains('Unterstützungsbedarf'));
      expect(text, contains('Elektrisches Hilfsmittel'));
    },
  );

  test('every member of the household gets a card', () async {
    final text = textIn(
      await render(
        members: [
          member(clientId: 'a', name: 'Anna Muster'),
          member(clientId: 'b', name: 'Bert Muster'),
        ],
      ),
    );

    expect(text, contains('Anna Muster'));
    expect(text, contains('Bert Muster'));
  });
}

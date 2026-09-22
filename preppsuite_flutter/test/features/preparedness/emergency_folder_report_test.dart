import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:preppsuite_flutter/features/household/application/emergency_plan_report.dart';
import 'package:preppsuite_flutter/features/preparedness/application/emergency_folder_report.dart';
import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import '../../pdf_text.dart';

/// The folder is the copy that works when the device is gone, which is
/// the assumption the whole app rests on. It is also a loose sheet of
/// paper, so what reaches it is read back out of the finished document
/// rather than trusted.
void main() {
  const strings = EmergencyFolderReportStrings(
    title: 'Notfallordner',
    generatedOn: 'Erstellt am 19.09.2026',
    intro: 'Ausdrucken und ausserhalb der Wohnung aufbewahren.',
    empty: 'Nicht eingetragen',
    meetingPoints: 'Treffpunkte',
    contact: 'Kontakt',
    contactPoint: 'Anlaufstelle',
    equipment: 'Ausruestung',
    notes: 'Notizen',
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
      notes: 'Notizen',
    ),
    evacuation: 'Evakuierungs-Karten',
    evacuationRoute: 'Weg',
    evacuationPlaces: 'Wichtige Orte',
    communication: 'Kommunikationsplan',
    radio: 'Radio-Empfangsplan',
    autonomy: 'Autarkie',
    folder: 'Notfallmappe',
    folderCopiesReady: 'Kopien vorhanden',
    folderTakeAlong: 'Bei Evakuierung mitnehmen',
  );

  final plan = HouseholdPlan(
    clientId: 'plan-1',
    householdId: 'home',
    meetingPointNear: 'Vor der Garage',
    contactName: 'Tante Erna',
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  final hub = PreparednessHubData(
    folder: EmergencyFolderStatus(
      location: 'Abschliessbarer Schrank',
      copiesReady: true,
    ),
    communication: PlanNote(text: 'Erst Oma, dann Nachbarn'),
    radioPlans: [
      RadioReceptionPlan(
        id: 'r1',
        station: 'Regionalradio',
        band: 'UKW',
        frequency: '95,8 MHz',
        receiver: 'Kurbelradio',
        power: 'Kurbel',
        checkedAt: DateTime.utc(2026, 9, 14),
      ),
    ],
    evacuationCards: [
      EvacuationCard(
        id: 'c1',
        label: 'Zuhause',
        start: 'Wohnung',
        destination: 'Sporthalle',
        route: 'Nebenstrassen statt B7',
        locations: 'Apotheke an der Ecke',
        checkedAt: DateTime.utc(2026, 9, 14),
      ),
    ],
  );

  HouseholdMember member() => HouseholdMember(
    clientId: 'm1',
    householdId: 'home',
    name: 'Anna Muster',
    bloodType: '0 negativ',
    allergies: 'Penicillin',
    sortOrder: 0,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  Future<Uint8List> render({
    List<HouseholdMember> members = const [],
    PreparednessHubData? data,
    HouseholdPlan? householdPlan,
  }) => const EmergencyFolderReport().build(
    householdName: 'Familie Muster',
    plan: householdPlan ?? plan,
    hub: data ?? hub,
    members: members,
    autonomy: const [
      (label: 'Wasser', value: '10 Tage'),
      (label: 'Hygiene', value: 'offen'),
    ],
    strings: strings,
    // A built-in font, so the text lands in the stream as literals the
    // assertions can read. Which fields get printed does not depend on
    // the typeface.
    font: pw.Font.helvetica(),
  );

  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  test('one sheet carries what was spread over five exports', () async {
    final text = textIn(await render());

    expect(text, contains('Familie Muster'));
    // The household plan.
    expect(text, contains('Vor der Garage'));
    expect(text, contains('Tante Erna'));
    // The crisis hub.
    expect(text, contains('Abschliessbarer Schrank'));
    expect(text, contains('Erst Oma, dann Nachbarn'));
    expect(text, contains('Regionalradio'));
    expect(text, contains('Sporthalle'));
    // An ASCII arrow: the bundled font is a subset and has no U+2192, so
    // a real arrow reaches the paper as nothing at all.
    expect(text, contains('Wohnung -> Sporthalle'));
    expect(text, isNot(contains('\u2192')));
    expect(text, contains('Nebenstrassen statt B7'));
    // And what the supplies say.
    expect(text, contains('10 Tage'));
  });

  test('health data stays off the paper unless it was asked for', () async {
    final without = textIn(await render());
    expect(without, isNot(contains('Anna Muster')));
    expect(without, isNot(contains('Penicillin')));
    expect(without, isNot(contains('Gesundheitsdaten')));

    final with_ = textIn(await render(members: [member()]));
    expect(with_, contains('Anna Muster'));
    expect(with_, contains('Penicillin'));
    // The warning is on the sheet itself, not only in the dialog that
    // offered it: the dialog is gone once answered.
    expect(with_, contains('Gesundheitsdaten'));
  });

  test('an empty field is left blank, never printed as a dash', () async {
    // The rule `emergencyCardRows` exists for: a card reading
    // "Allergien: -" invites a paramedic to believe somebody checked.
    final text = textIn(await render(members: [member()]));

    expect(text, contains('Blutgruppe'));
    expect(text, isNot(contains('Medikation')));
    expect(text, isNot(contains('Vorerkrankungen')));
  });

  test('a section with nothing in it says so rather than vanishing', () async {
    // A folder that shows its own gaps is one somebody can finish.
    final text = textIn(
      await render(
        data: const PreparednessHubData(),
        householdPlan: null,
      ),
    );

    expect(text, contains('Evakuierungs-Karten'));
    expect(text, contains('Radio-Empfangsplan'));
    expect(text, contains('Nicht eingetragen'));
  });

  test('it says where it belongs', () async {
    // The whole point of paper here is that it is not on the device.
    expect(
      textIn(await render()),
      contains('ausserhalb der Wohnung'),
    );
  });
}

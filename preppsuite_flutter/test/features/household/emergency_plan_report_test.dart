import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart' show PdfException;
import 'package:pdf/widgets.dart' as pw;
import 'package:preppsuite_flutter/core/pdf_blocks.dart';
import 'package:preppsuite_flutter/features/household/application/emergency_plan_report.dart';
import 'package:preppsuite_flutter/features/household/application/meeting_point_places.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import '../../pdf_text.dart';

import 'package:preppsuite_flutter/features/household/application/card_species.dart';

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
      kind: 'Karte für',
      speciesName: _speciesName,
      chipNumber: 'Chipnummer',
      vet: 'Tierarzt',
      vets: 'Tierärzte',
      shelters: 'Wer es aufnimmt',
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

  group('long entries (#351)', () {
    final pasted = [
      for (var i = 1; i <= 60; i++) 'Mittel $i 5 mg morgens und abends',
    ].join('\n');

    test('a pasted medication plan prints instead of failing', () async {
      final pdf = await render(
        members: [
          member(medication: pasted),
          member(clientId: 'm2', name: 'Ben Muster'),
        ],
      );
      final text = textIn(pdf);
      expect(text, contains('Mittel 60'));
      // Too long for one page: every line says whose it is.
      expect(RegExp('Medikation').allMatches(text).length, greaterThan(0));
      expect(
        RegExp('Anna Muster').allMatches(text).length,
        greaterThanOrEqualTo(2),
        reason: 'the name goes with every line of a card this long',
      );
    });

    test('so do notes of a page and more', () async {
      final notes = List.filled(900, 'Wasser').join(' ');
      final pdf = await const EmergencyPlanReport().build(
        plan: plan.copyWith(notes: Value(notes)),
        householdName: 'Familie Muster',
        strings: strings,
        font: pw.Font.helvetica(),
      );
      expect(textIn(pdf), contains('Wasser'));
    });

    test('a card of medium lines prints with the bundled font', () async {
      // Measured in the review of 11 November: 2.9.6 guessed 27 lines and
      // kept this card together, and it was 812 points of a 728-point page.
      const line =
          'Metoprololsuccinat 47,5 mg Retardtablette, 1-0-1, morgens und '
          'abends nach dem Essen';
      final pdf = await const EmergencyPlanReport().build(
        plan: plan,
        householdName: 'Familie Muster',
        strings: strings,
        members: [
          member(
            medication: List.filled(12, line).join('\n'),
            conditions: List.filled(12, line).join('\n'),
          ),
        ],
      );
      expect(pdf, isNotEmpty);
    });

    test('a card the guess takes for short runs on where it is not', () async {
      // Wide letters: each line is one by the count of its characters and
      // two on the page, so a card guessed to fit is taller than a sheet.
      final wide = ['W' * 48, ...List.filled(28, 'W' * 59)].join('\n');
      final rows = [(label: 'Medikation', value: wide)];
      expect(
        rows.fold(1, (n, r) => n + pdfEstimatedLines('${r.label}: ${r.value}')),
        lessThanOrEqualTo(pdfCardLinesTogether),
        reason: 'guessed short enough to keep together',
      );
      final together = pw.Document(
        theme: pw.ThemeData.withFont(base: pw.Font.helvetica()),
      );
      expect(
        () => together.addPage(
          pw.MultiPage(build: (_) => pdfCard('Anna Muster', rows)),
        ),
        throwsA(isA<PdfException>()),
        reason: 'and taller than a page',
      );

      final pdf = await render(members: [member(medication: wide)]);
      expect(
        RegExp('Anna Muster').allMatches(textIn(pdf)).length,
        greaterThanOrEqualTo(2),
        reason: 'set again with the card running on, the name on each line',
      );
    });

    test('thirty short cards each stay under their name', () async {
      final pdf = await render(
        members: [
          for (var i = 0; i < 30; i++)
            member(
              clientId: 'm$i',
              name: 'Person $i',
              bloodType: 'A+',
              allergies: 'Penicillin',
              medication: 'Ramipril 5 mg',
              conditions: 'Bluthochdruck',
            ),
        ],
      );
      expect(textIn(pdf), contains('Person 29'));
    });
  });

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

  test(
    'a meeting point on the map is on the paper with its coordinates',
    () async {
      // #204: the point stays on the device, but the sheet printed from it
      // carries it -- the copy that still finds the place when nobody there
      // knows what "vor der Garage" means.
      final text = textIn(
        await const EmergencyPlanReport().build(
          plan: plan,
          householdName: 'Familie Muster',
          strings: strings,
          meetingPlaces: const {
            MeetingPoint.near: '52.26890, 10.52680',
            MeetingPoint.far: '52.30000, 10.60000',
          },
          font: pw.Font.helvetica(),
        ),
      );

      expect(text, contains('Vor der Garage'));
      expect(text, contains('52.26890, 10.52680'));
      // A far point with no text of its own still reaches the paper.
      expect(text, contains('52.30000, 10.60000'));
    },
  );

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

  test('an animal\'s card says what it is, its chip and its vet', () {
    // Built from the rows rather than the PDF: the PDF font folds
    // umlauts, and the rows are what both reports print.
    final rows = emergencyCardRows(
      HouseholdMember(
        clientId: 'bello',
        householdId: 'household-1',
        name: 'Bello',
        species: 'dog',
        chipNumber: '276098100000001',
        doctor: 'Praxis Feld|Tierarzt|0511 123',
        sortOrder: 0,
        updatedAt: DateTime.utc(2026),
        dirty: false,
      ),
      strings.fields,
    );
    final labels = [for (final row in rows) row.label];

    expect(labels, containsAllInOrder(['Karte für', 'Chipnummer', 'Tierarzt']));
    expect(rows.first.value, 'dog');
    expect(labels, isNot(contains('Arzt')));
  });
}

String _speciesName(CardSpecies species) => species.name;

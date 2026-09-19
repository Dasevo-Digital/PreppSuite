import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keeps crisis planning data locally and restores it', () async {
    const store = PreparednessHubStore();
    final savedAt = DateTime(2026, 9, 17, 8);
    final data = PreparednessHubData(
      radioPlans: [
        RadioReceptionPlan(
          id: 'radio',
          station: 'Regionalradio',
          band: 'DAB+',
          frequency: 'Kanal 7B',
          receiver: 'Kurbelradio',
          power: 'Akku',
          checkedAt: DateTime(2026, 9, 17),
        ),
      ],
      folder: EmergencyFolderStatus(
        location: 'Schrank',
        copiesReady: true,
        lastChecked: savedAt,
      ),
      maintenance: {'batteries': savedAt},
      evacuationCards: [
        EvacuationCard(
          id: 'route',
          label: 'Zuhause',
          start: 'Start',
          destination: 'Treffpunkt',
          route: 'Nebenstraßen',
          locations: 'Apotheke',
          checkedAt: DateTime(2026, 9, 17),
        ),
      ],
      events: [
        IncidentEntry(
          id: 'event',
          at: DateTime(2026, 9, 17),
          kind: 'Stromausfall',
          note: 'Beginn',
          action: 'Radio eingeschaltet',
        ),
      ],
      communication: PlanNote(text: 'Kontaktkette', checkedAt: savedAt),
      support: PlanNote(text: 'Hilfsmittel', checkedAt: savedAt),
      pets: PlanNote(text: 'Transportbox', checkedAt: savedAt),
      mobility: PlanNote(text: 'Fahrzeug', checkedAt: savedAt),
      utilities: PlanNote(text: 'Absperrort', checkedAt: savedAt),
      actionDone: {'now': savedAt},
      crisisMode: true,
      autonomy: AutonomySnapshot(
        waterDays: 8,
        foodDays: 12,
        medicineDays: 5,
        energyDays: 7,
        hygieneDays: 10,
        checkedAt: savedAt,
      ),
      waterHygiene: PlanNote(text: 'Kanisterrotation', checkedAt: savedAt),
      powerOutage: PlanNote(text: 'Kühlkette', checkedAt: savedAt),
      cooking: PlanNote(text: 'Ein-Topf-Gericht', checkedAt: savedAt),
      redundancy: PlanNote(text: 'Zweites Radio', checkedAt: savedAt),
      climateRoom: PlanNote(text: 'Innenraum', checkedAt: savedAt),
      analogFallback: PlanNote(text: 'Papierkarte', checkedAt: savedAt),
      mutualAid: PlanNote(text: 'Hilfeangebot', checkedAt: savedAt),
      practice: PlanNote(text: 'Filtertest', checkedAt: savedAt),
    );

    await store.save(data);
    final restored = await store.load();

    expect(restored.radioPlans.single.station, 'Regionalradio');
    expect(restored.folder.location, 'Schrank');
    expect(restored.maintenance['batteries'], savedAt);
    expect(restored.evacuationCards.single.route, 'Nebenstraßen');
    expect(restored.events.single.action, 'Radio eingeschaltet');
    expect(restored.communication.text, 'Kontaktkette');
    expect(restored.pets.text, 'Transportbox');
    expect(restored.actionDone['now'], savedAt);
    expect(restored.crisisMode, isTrue);
    expect(restored.autonomy.limitingDays, 5);
    expect(restored.autonomy.bottleneck, 'Medikamente');
    expect(restored.waterHygiene.text, 'Kanisterrotation');
    expect(restored.analogFallback.text, 'Papierkarte');
  });

  test('invalid stored content falls back to an empty plan', () {
    expect(
      PreparednessHubData.fromJson({
        'events': ['broken'],
      }),
      isA<PreparednessHubData>(),
    );
    expect(PreparednessHubData.fromJson(null).events, isEmpty);
  });

  test('does not hide a missing resource behind the other ranges', () {
    const snapshot = AutonomySnapshot(
      waterDays: 8,
      foodDays: 12,
      medicineDays: 5,
      energyDays: 0,
      hygieneDays: 10,
    );

    expect(snapshot.limitingDays, 0);
    expect(snapshot.bottleneck, 'Energie');
  });

  group('merging a restored plan into the one on the device', () {
    PlanNote note(String text, DateTime at) =>
        PlanNote(text: text, checkedAt: at);

    test('the later check wins, in both directions', () {
      final held = PreparednessHubData(
        utilities: note('alt', DateTime(2026, 3, 1)),
        pets: note('neu', DateTime(2026, 9, 14)),
      );
      final incoming = PreparednessHubData(
        utilities: note('neu', DateTime(2026, 9, 14)),
        pets: note('alt', DateTime(2026, 3, 1)),
      );

      final merged = held.mergeWith(incoming);

      expect(merged.utilities.text, 'neu');
      expect(merged.pets.text, 'neu');
    });

    test('a note nobody has touched yields to one that was written', () {
      final merged = const PreparednessHubData().mergeWith(
        PreparednessHubData(
          communication: note('Kontaktkette', DateTime(2026, 9, 14)),
        ),
      );

      expect(merged.communication.text, 'Kontaktkette');
    });

    test('cards are joined by id, held order first', () {
      EvacuationCard card(String id, String destination, DateTime at) =>
          EvacuationCard(
            id: id,
            label: id,
            start: 'Wohnung',
            destination: destination,
            route: 'Nebenstrassen',
            locations: '',
            checkedAt: at,
          );
      final held = PreparednessHubData(
        evacuationCards: [
          card('a', 'Sporthalle', DateTime(2026, 9, 14)),
          card('b', 'Schule', DateTime(2026, 3, 1)),
        ],
      );
      final incoming = PreparednessHubData(
        evacuationCards: [
          card('b', 'Gemeindehaus', DateTime(2026, 9, 16)),
          card('c', 'Bahnhof', DateTime(2026, 3, 1)),
          card('a', 'Feuerwache', DateTime(2026, 3, 1)),
        ],
      );

      final merged = held.mergeWith(incoming);

      expect(
        merged.evacuationCards.map((item) => item.id),
        ['a', 'b', 'c'],
      );
      // 'a' keeps the newer local destination, 'b' takes the newer one
      // from the backup, 'c' is added.
      expect(
        merged.evacuationCards.map((item) => item.destination),
        ['Sporthalle', 'Gemeindehaus', 'Bahnhof'],
      );
    });

    test('an incident log only ever grows', () {
      IncidentEntry event(String id, DateTime at) => IncidentEntry(
        id: id,
        at: at,
        kind: 'Stromausfall',
        note: '',
        action: '',
      );
      final merged =
          PreparednessHubData(
            events: [event('one', DateTime(2026, 9, 14))],
          ).mergeWith(
            PreparednessHubData(events: [event('two', DateTime(2026, 3, 1))]),
          );

      expect(merged.events.map((item) => item.id), ['one', 'two']);
    });

    test('a check date is kept when the backup only has an older one', () {
      final merged =
          PreparednessHubData(
            maintenance: {'batteries': DateTime(2026, 9, 14)},
            actionDone: {'now': DateTime(2026, 3, 1)},
          ).mergeWith(
            PreparednessHubData(
              maintenance: {
                'batteries': DateTime(2026, 3, 1),
                'filter': DateTime(2026, 3, 1),
              },
              actionDone: {'now': DateTime(2026, 9, 14)},
            ),
          );

      expect(merged.maintenance['batteries'], DateTime(2026, 9, 14));
      expect(merged.maintenance['filter'], DateTime(2026, 3, 1));
      expect(merged.actionDone['now'], DateTime(2026, 9, 14));
    });

    test('a restore never switches crisis mode on or off', () {
      expect(
        const PreparednessHubData(
          crisisMode: false,
        ).mergeWith(const PreparednessHubData(crisisMode: true)).crisisMode,
        isFalse,
      );
      expect(
        const PreparednessHubData(
          crisisMode: true,
        ).mergeWith(const PreparednessHubData(crisisMode: false)).crisisMode,
        isTrue,
      );
    });

    test('the store folds a restored plan into what it holds', () async {
      const store = PreparednessHubStore();
      await store.save(
        PreparednessHubData(cooking: note('Gaskocher', DateTime(2026, 9, 14))),
      );

      await store.mergeFrom(
        PreparednessHubData(
          cooking: note('Campingkocher', DateTime(2026, 3, 1)),
          practice: note('Filtertest', DateTime(2026, 9, 16)),
        ),
      );

      final merged = await store.load();
      expect(merged.cooking.text, 'Gaskocher');
      expect(merged.practice.text, 'Filtertest');
    });
  });
}

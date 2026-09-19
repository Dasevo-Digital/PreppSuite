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
}

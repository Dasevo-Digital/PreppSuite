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
    );

    await store.save(data);
    final restored = await store.load();

    expect(restored.radioPlans.single.station, 'Regionalradio');
    expect(restored.folder.location, 'Schrank');
    expect(restored.maintenance['batteries'], savedAt);
    expect(restored.evacuationCards.single.route, 'Nebenstraßen');
    expect(restored.events.single.action, 'Radio eingeschaltet');
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

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/drill_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'completed drills are recorded independently from current ticks',
    () async {
      const store = DrillProgressStore();
      final completed = DateTime.utc(2026, 9, 16, 10, 30);

      await store.save({'power-outage:Radio prüfen'});
      await store.markCompleted('power-outage', completed);
      await store.clear();

      expect(await store.load(), isEmpty);
      expect(
        (await store.loadCompleted())['power-outage'],
        completed.toLocal(),
      );
    },
  );

  test('malformed rehearsal history behaves as empty', () async {
    SharedPreferences.setMockInitialValues({'drillLastCompleted': '{bad'});

    expect(await const DrillProgressStore().loadCompleted(), isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_range.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a plan written out comes back the same', () async {
    const store = EnergyPlanStore();
    await store.save(
      const EnergyPlan(
        reserves: [
          EnergyReserve(
            id: 'a',
            kind: EnergyKind.solidFuel,
            label: 'Brennholz',
            amount: 400,
          ),
        ],
        draws: [
          EnergyDraw(
            id: 'b',
            kind: EnergyKind.solidFuel,
            label: 'Ofen',
            perHour: 3,
            hoursPerDay: 8,
          ),
        ],
      ),
    );

    final read = await store.load();
    expect(read.reserves.single.label, 'Brennholz');
    expect(read.draws.single.perDay, 24);
  });

  test('nothing stored is an empty plan, not a failure', () async {
    final read = await const EnergyPlanStore().load();
    expect(read.isEmpty, isTrue);
  });

  test('a damaged file loses the entries, not the screen', () async {
    // Two hand-typed lists are cheap to type again; a screen that
    // refuses to open because of one bad character is not.
    SharedPreferences.setMockInitialValues({
      'energyReserves': 'not json at all',
      'energyDraws': '{"not":"a list"}',
    });
    final read = await const EnergyPlanStore().load();
    expect(read.isEmpty, isTrue);
  });

  test('one unreadable entry does not take the others with it', () async {
    SharedPreferences.setMockInitialValues({
      'energyReserves':
          '[{"id":"a","kind":"gas","label":"gut","amount":460},'
          '{"id":"b","kind":"antimatter","label":"schlecht","amount":1}]',
    });
    final read = await const EnergyPlanStore().load();
    expect(read.reserves.map((r) => r.label), ['gut']);
  });
}

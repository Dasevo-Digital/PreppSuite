import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_range.dart';

EnergyReserve reserve(EnergyKind kind, double amount, [String label = 'x']) =>
    EnergyReserve(
      id: '$kind-$amount-$label',
      kind: kind,
      label: label,
      amount: amount,
    );

EnergyDraw draw(
  EnergyKind kind,
  double perHour,
  double hoursPerDay, [
  String label = 'y',
]) => EnergyDraw(
  id: '$kind-$perHour-$hoursPerDay-$label',
  kind: kind,
  label: label,
  perHour: perHour,
  hoursPerDay: hoursPerDay,
);

void main() {
  test('a stove and two cartridges come to a number of days', () {
    // Two 230 g cartridges, a stove rated at 160 g/h, on for an hour a
    // day: 460 / 160 = 2.875.
    final ranges = energyRanges(
      reserves: [reserve(EnergyKind.gas, 460, 'Kartuschen')],
      draws: [draw(EnergyKind.gas, 160, 1, 'Gaskocher')],
    );

    expect(ranges, hasLength(1));
    expect(ranges.single.stored, 460);
    expect(ranges.single.perDay, 160);
    // Two, not three: a reserve that lasts two days and twenty-one hours
    // lasts two days.
    expect(ranges.single.days, 2);
  });

  test('a reserve that just runs out is not rounded up into another day', () {
    final ranges = energyRanges(
      reserves: [reserve(EnergyKind.liquidFuel, 2.99)],
      draws: [draw(EnergyKind.liquidFuel, 1, 1)],
    );
    expect(ranges.single.days, 2);
  });

  test('several things drawing on the same kind are added', () {
    final ranges = energyRanges(
      reserves: [
        reserve(EnergyKind.electricity, 200, 'Powerbank'),
        reserve(EnergyKind.electricity, 300, 'Autobatterie'),
      ],
      draws: [
        draw(EnergyKind.electricity, 2, 5, 'Radio'),
        draw(EnergyKind.electricity, 10, 4, 'Lampe'),
      ],
    );

    expect(ranges.single.stored, 500);
    expect(ranges.single.perDay, 50);
    expect(ranges.single.days, 10);
  });

  test('hours a day are part of the sum, not a decoration', () {
    // The same stove, on for twenty minutes instead of an hour.
    final full = energyRanges(
      reserves: [reserve(EnergyKind.gas, 460)],
      draws: [draw(EnergyKind.gas, 160, 1)],
    ).single;
    final brief = energyRanges(
      reserves: [reserve(EnergyKind.gas, 460)],
      draws: [draw(EnergyKind.gas, 160, 1 / 3)],
    ).single;

    expect(full.days, 2);
    expect(brief.days, 8);
  });

  test('kinds nobody has and nobody uses are left out', () {
    final ranges = energyRanges(
      reserves: [reserve(EnergyKind.solidFuel, 500)],
      draws: [draw(EnergyKind.solidFuel, 3, 8)],
    );

    expect(ranges.map((r) => r.kind), [EnergyKind.solidFuel]);
  });

  test('stocked but unused is not the same as lasting for ever', () {
    final range = energyRanges(
      reserves: [reserve(EnergyKind.gas, 460)],
      draws: const [],
    ).single;

    expect(range.days, isNull);
    expect(range.unused, isTrue);
    expect(range.empty, isFalse);
  });

  test('used but not stocked is nought days, not no answer', () {
    final range = energyRanges(
      reserves: const [],
      draws: [draw(EnergyKind.candles, 1, 4)],
    ).single;

    expect(range.days, 0);
    expect(range.empty, isTrue);
    expect(range.unused, isFalse);
  });

  test('the shortest reserve is the household range', () {
    // Three comfortable-looking numbers and one that is not. Nobody
    // works this out by reading a list.
    final ranges = energyRanges(
      reserves: [
        reserve(EnergyKind.gas, 1380, 'sechs Kartuschen'),
        reserve(EnergyKind.electricity, 500, 'Powerbanks'),
        reserve(EnergyKind.candles, 40, 'Teelichter'),
      ],
      draws: [
        draw(EnergyKind.gas, 160, 1, 'Kocher'),
        draw(EnergyKind.electricity, 5, 5, 'Radio'),
        draw(EnergyKind.candles, 1, 6, 'Abendlicht'),
      ],
    );

    expect(firstToRunOut(ranges)!.kind, EnergyKind.candles);
    expect(firstToRunOut(ranges)!.days, 6);
  });

  test('a kind nothing draws on never becomes the shortest', () {
    final ranges = energyRanges(
      reserves: [
        reserve(EnergyKind.solidFuel, 1),
        reserve(EnergyKind.gas, 1000),
      ],
      draws: [draw(EnergyKind.gas, 100, 1)],
    );

    expect(firstToRunOut(ranges)!.kind, EnergyKind.gas);
  });

  test('with nothing entered there is nothing to say', () {
    expect(energyRanges(reserves: const [], draws: const []), isEmpty);
    expect(firstToRunOut(const []), isNull);
  });

  test('every kind carries the unit it is actually counted in', () {
    expect(EnergyKind.gas.unit, EnergyUnit.grams);
    expect(EnergyKind.electricity.unit, EnergyUnit.wattHours);
    expect(EnergyKind.liquidFuel.unit, EnergyUnit.liters);
    expect(EnergyKind.solidFuel.unit, EnergyUnit.kilograms);
    expect(EnergyKind.candles.unit, EnergyUnit.hours);
  });

  test('a power bank in milliamp hours becomes watt-hours', () {
    // 20000 mAh at the cell's 3.7 volts is 74 Wh. The figure printed on
    // the case is the cell's, not what leaves the socket, and the screen
    // says so rather than applying a made-up efficiency.
    expect(wattHoursFromMilliampHours(20000), closeTo(74, 0.001));
    expect(wattHoursFromMilliampHours(10000, volts: 3.6), closeTo(36, 0.001));
  });

  group('what is stored survives being written down and read back', () {
    test('a reserve', () {
      final original = reserve(EnergyKind.gas, 460, 'Kartuschen');
      final copy = EnergyReserve.fromJson(original.toJson())!;
      expect(copy.id, original.id);
      expect(copy.kind, EnergyKind.gas);
      expect(copy.label, 'Kartuschen');
      expect(copy.amount, 460);
    });

    test('a draw', () {
      final original = draw(EnergyKind.electricity, 5, 4.5, 'Radio');
      final copy = EnergyDraw.fromJson(original.toJson())!;
      expect(copy.kind, EnergyKind.electricity);
      expect(copy.perHour, 5);
      expect(copy.hoursPerDay, 4.5);
      expect(copy.perDay, closeTo(22.5, 1e-9));
    });

    test('a kind this version does not know is dropped, not guessed', () {
      expect(
        EnergyReserve.fromJson({
          'id': 'a',
          'kind': 'nuclear',
          'label': 'x',
          'amount': 1,
        }),
        isNull,
      );
    });

    test('a half-written entry is dropped rather than read as a zero', () {
      expect(
        EnergyDraw.fromJson({'id': 'a', 'kind': 'gas', 'label': 'x'}),
        isNull,
      );
      expect(EnergyReserve.fromJson('nonsense'), isNull);
    });
  });
}

/// How long the stored energy lasts.
///
/// The counterpart to `supply_calculator.dart`: that one answers how long
/// the food and water last, this one how long the light, the cooking and
/// the radio do. Same arithmetic, and the same rule about figures —
/// **nothing here is estimated on the household's behalf.** How much a
/// stove burns is written on the stove, and how much a lamp draws is
/// written on the lamp; the one thing this app would have to invent to
/// fill those in is the one thing it will not.
///
/// So what it contributes is the division, the unit handling and the
/// question nobody asks themselves: which of the four reserves runs out
/// first.
library;

/// What a reserve is counted in.
enum EnergyUnit { wattHours, grams, liters, kilograms, hours }

/// A kind of stored energy.
///
/// Five, because five is how a cupboard is actually organised — and
/// because they do not convert into one another in any way a household
/// can act on. A kilogram of firewood and a watt-hour of battery are not
/// exchangeable at any rate, so pretending they are one pool would turn
/// a real answer into an arithmetical one.
enum EnergyKind {
  /// Power banks, batteries, a solar panel's day's work. In watt-hours,
  /// which is what a label states once it says anything meaningful.
  electricity(EnergyUnit.wattHours),

  /// Cartridges and bottles. Counted in grams, because a stove's
  /// consumption is printed in grams an hour and a cartridge's contents
  /// in grams — so the division needs no constant from anywhere.
  gas(EnergyUnit.grams),

  /// Petrol, diesel, paraffin, lamp oil, spirit.
  liquidFuel(EnergyUnit.liters),

  /// Firewood, briquettes, coal, pellets.
  solidFuel(EnergyUnit.kilograms),

  /// Candles and tea lights, counted as burning hours: a packet states
  /// how long one burns, and the number of hours is the only thing that
  /// divides into anything.
  candles(EnergyUnit.hours);

  const EnergyKind(this.unit);

  final EnergyUnit unit;
}

/// Something in the cupboard.
class EnergyReserve {
  const EnergyReserve({
    required this.id,
    required this.kind,
    required this.label,
    required this.amount,
  });

  final String id;
  final EnergyKind kind;

  /// What it is: "Gaskartuschen", "Powerbank", "Brennholz".
  final String label;

  /// In [EnergyKind.unit].
  final double amount;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'label': label,
    'amount': amount,
  };

  static EnergyReserve? fromJson(Object? value) {
    if (value is! Map) return null;
    final kind = _kindNamed(value['kind']);
    final amount = (value['amount'] as num?)?.toDouble();
    if (kind == null || amount == null || value['id'] is! String) return null;
    return EnergyReserve(
      id: value['id'] as String,
      kind: kind,
      label: value['label'] as String? ?? '',
      amount: amount,
    );
  }
}

/// Something that uses it.
class EnergyDraw {
  const EnergyDraw({
    required this.id,
    required this.kind,
    required this.label,
    required this.perHour,
    required this.hoursPerDay,
  });

  final String id;
  final EnergyKind kind;

  /// What uses it: "Gaskocher", "Radio", "Petroleumlampe".
  final String label;

  /// What the label on the thing says it uses in an hour, in the kind's
  /// own unit. A candle uses one hour of candle an hour, which is why
  /// that kind's figure is always 1.
  final double perHour;

  /// How long it is on in a day. The honest half of the calculation:
  /// a stove rated at 160 g/h used for twenty minutes is not a stove
  /// rated at 160 g/h.
  final double hoursPerDay;

  double get perDay => perHour * hoursPerDay;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'label': label,
    'perHour': perHour,
    'hoursPerDay': hoursPerDay,
  };

  static EnergyDraw? fromJson(Object? value) {
    if (value is! Map) return null;
    final kind = _kindNamed(value['kind']);
    final perHour = (value['perHour'] as num?)?.toDouble();
    final hoursPerDay = (value['hoursPerDay'] as num?)?.toDouble();
    if (kind == null ||
        perHour == null ||
        hoursPerDay == null ||
        value['id'] is! String) {
      return null;
    }
    return EnergyDraw(
      id: value['id'] as String,
      kind: kind,
      label: value['label'] as String? ?? '',
      perHour: perHour,
      hoursPerDay: hoursPerDay,
    );
  }
}

/// The kind by its stored name, or null where a stored file names one
/// this version does not have.
EnergyKind? _kindNamed(Object? name) {
  for (final kind in EnergyKind.values) {
    if (kind.name == name) return kind;
  }
  return null;
}

/// How one kind stands.
class EnergyRange {
  const EnergyRange({
    required this.kind,
    required this.stored,
    required this.perDay,
  });

  final EnergyKind kind;

  /// Everything of this kind, added up.
  final double stored;

  /// What everything of this kind uses in a day.
  final double perDay;

  /// Whole days it lasts, or null where nothing draws on it.
  ///
  /// Whole days, and rounded **down**: a reserve that lasts three days
  /// and twenty hours lasts three days. Rounding that up is how a plan
  /// ends a day early.
  int? get days => perDay > 0 ? (stored / perDay).floor() : null;

  /// Stocked but nothing uses it. Not a fault — a spare cylinder for a
  /// stove that was never entered is the commonest case — but it is why
  /// "no answer" and "runs for ever" must not look the same.
  bool get unused => perDay <= 0 && stored > 0;

  /// Something uses it and there is none.
  bool get empty => perDay > 0 && stored <= 0;
}

/// Every kind that is either stored or drawn on, and how long it lasts.
///
/// Kinds nobody has and nobody uses are left out entirely: a household
/// that heats with wood should not have to read past four empty rows to
/// find out about its wood.
List<EnergyRange> energyRanges({
  required List<EnergyReserve> reserves,
  required List<EnergyDraw> draws,
}) {
  final ranges = <EnergyRange>[];
  for (final kind in EnergyKind.values) {
    var stored = 0.0;
    for (final reserve in reserves) {
      if (reserve.kind == kind) stored += reserve.amount;
    }
    var perDay = 0.0;
    for (final draw in draws) {
      if (draw.kind == kind) perDay += draw.perDay;
    }
    if (stored <= 0 && perDay <= 0) continue;
    ranges.add(EnergyRange(kind: kind, stored: stored, perDay: perDay));
  }
  return ranges;
}

/// The kind that runs out first.
///
/// The whole point of the screen. Four reserves each lasting a
/// comfortable-sounding number of days are not four answers: the
/// household's range is the smallest of them, and that is a figure
/// nobody works out by looking at a list.
EnergyRange? firstToRunOut(List<EnergyRange> ranges) {
  EnergyRange? shortest;
  for (final range in ranges) {
    final days = range.days;
    if (days == null) continue;
    if (shortest == null || days < shortest.days!) shortest = range;
  }
  return shortest;
}

/// A power bank's rating in mAh, as watt-hours.
///
/// Pure arithmetic — capacity times cell voltage — and it is here because
/// the figure printed on a power bank is the one number in this whole
/// feature that cannot be used as it stands. What it does **not** do is
/// apply an efficiency: converting 3.7 volts up to 5 loses something, and
/// how much depends on the device. Inventing a percentage would be worse
/// than leaving the figure optimistic and saying so.
double wattHoursFromMilliampHours(double milliampHours, {double volts = 3.7}) =>
    milliampHours * volts / 1000;

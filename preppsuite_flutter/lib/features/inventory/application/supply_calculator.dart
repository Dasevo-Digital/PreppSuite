import '../../../model/categories.dart';

import '../../../local_db/database.dart';
import 'inventory_category_l10n.dart';

/// What one head costs a day.
///
/// Every figure here is either official or plainly labelled as this app's
/// own, and keeping them in one enum is what makes that checkable. The
/// BBK's own page states a figure for adults and, for children and
/// animals, only the reminder that they exist — "Haben Sie Vorräte für
/// (Klein-)Kinder oder Haustiere, die Sie in einem Notfall auch versorgen
/// müssen?" — and then points at the BLE. The BLE's *Vorratstabelle* does
/// carry a children's figure, in its footnotes, and that is where the
/// number below comes from. Dressing an invented number up as an official
/// one would be the worst thing this screen could do.
enum SupplyHead {
  /// BBK: at least 1.5 litres of fluid a day, plus 0.5 litres for
  /// cooking, and around 2200 kcal.
  adult(litersPerDay: 2.0, kcalPerDay: 2200),

  /// 1 litre of drinking plus the same 0.5 litres for cooking.
  ///
  /// The litre is official after all: the BLE's stockpiling table cites
  /// the DGE and the Max Rubner-Institut for "Kinder (nicht Säuglinge) im
  /// Alter von bis zu 12 Jahren haben einen durchschnittlichen
  /// Getränkebedarf in Höhe von 1 Liter pro Person und Tag". This was 2.0
  /// as the app's own cautious guess, which overstated the water target
  /// for every household with children.
  ///
  /// The same footnote recommends 2 litres of drinking a day from 65, i.e.
  /// 2.5 with cooking. There is no head for that: age is not in the
  /// household profile, and asking for it to adjust one number would be a
  /// poor trade. The screen says so instead.
  ///
  /// The energy figure is still this app's own conservative estimate —
  /// nobody official publishes one.
  child(litersPerDay: 1.5, kcalPerDay: 1400),

  /// Water only, at the veterinary rule of thumb of roughly 60 ml per
  /// kilogram a day, taken at 20 kg. Pet food is not counted in the
  /// calories — those are human ones, and a dog cannot live on them.
  dog(litersPerDay: 1.2, kcalPerDay: 0),

  /// The same rule of thumb at 4 kg.
  cat(litersPerDay: 0.25, kcalPerDay: 0);

  const SupplyHead({required this.litersPerDay, required this.kcalPerDay});

  final double litersPerDay;
  final int kcalPerDay;

  /// Whether this head's food has to be stocked separately rather than
  /// counted in the calorie target.
  bool get eatsPetFood => this == SupplyHead.dog || this == SupplyHead.cat;
}

/// Kept for the tests and callers that predate [SupplyHead].
const litersPerPersonPerDay = 2.0;
const kcalPerPersonPerDay = 2200;

/// How many of each kind of head a household feeds.
class SupplyHousehold {
  const SupplyHousehold({
    this.adults = 1,
    this.children = 0,
    this.dogs = 0,
    this.cats = 0,
  });

  final int adults;
  final int children;
  final int dogs;
  final int cats;

  int countOf(SupplyHead head) => switch (head) {
    SupplyHead.adult => adults,
    SupplyHead.child => children,
    SupplyHead.dog => dogs,
    SupplyHead.cat => cats,
  };

  /// The kinds actually present, so the breakdown shows only what this
  /// household has.
  Iterable<SupplyHead> get present =>
      SupplyHead.values.where((head) => countOf(head) > 0);

  bool get hasPets => dogs > 0 || cats > 0;

  double get litersPerDay => SupplyHead.values.fold(
    0,
    (total, head) => total + countOf(head) * head.litersPerDay,
  );

  int get kcalPerDay => SupplyHead.values.fold(
    0,
    (total, head) => total + countOf(head) * head.kcalPerDay,
  );
}

/// Target vs. current stock for the "Vorräte für X Tage" calculator.
/// Deliberately covers only drinking water and calories — the reference
/// this is modeled on also tracks "Brauchwasser" (service/hygiene water),
/// but there's no official BBK figure for that and [InventoryItemCategory]
/// doesn't distinguish drinking from service water, so faking a number
/// there would be dishonest. See `supply_calculator.dart`'s test suite for
/// the exact rounding/unit-normalization rules.
class SupplyCalculatorResult {
  const SupplyCalculatorResult({
    required this.waterTargetLiters,
    required this.waterCurrentLiters,
    required this.caloriesTarget,
    required this.caloriesCurrent,
  });

  final double waterTargetLiters;
  final double waterCurrentLiters;
  final int caloriesTarget;
  final int caloriesCurrent;
}

SupplyCalculatorResult calculateSupply({
  required List<InventoryItem> items,
  required int days,
  SupplyHousehold household = const SupplyHousehold(),
}) {
  var waterCurrent = 0.0;
  var caloriesCurrent = 0;

  for (final item in items) {
    final category = InventoryItemCategoryX.fromName(item.category);
    if (category == InventoryItemCategory.water) {
      final liters = _normalizeToLiters(item.quantity, item.unit);
      if (liters != null) waterCurrent += liters;
    } else if (category == InventoryItemCategory.food &&
        item.calories != null) {
      caloriesCurrent += item.calories!;
    }
  }

  return SupplyCalculatorResult(
    waterTargetLiters: household.litersPerDay * days,
    waterCurrentLiters: waterCurrent,
    caloriesTarget: household.kcalPerDay * days,
    caloriesCurrent: caloriesCurrent,
  );
}

/// Only counts units that unambiguously mean a liquid volume — "Flasche"
/// (bottle), "Kiste" (crate) etc. can't be reliably converted without a
/// separate per-unit volume, so those items are simply not counted rather
/// than guessed at.
double? _normalizeToLiters(double quantity, String unit) {
  final normalized = unit.trim().toLowerCase();
  switch (normalized) {
    case 'l':
    case 'liter':
    case 'litre':
      return quantity;
    case 'ml':
    case 'milliliter':
      return quantity / 1000;
    default:
      return null;
  }
}

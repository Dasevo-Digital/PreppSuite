/// What the stores say is in the refrigerator and the freezer (#276).
///
/// The blackout clock answers how long the cold lasts. What it did not
/// answer is the next question -- what is in there -- and that was left
/// to memory, with the door kept shut. The stores already know: every
/// row has a storage location, and a household that wrote "Kühlschrank"
/// or "Gefriertruhe" there has said where it is.
///
/// **Read from the words, not from a setting.** The location is the
/// household's own text, travels with every row and reads the same on
/// every device; a separate list of "which location is the fridge" would
/// be one more thing to keep in step. A location that names neither is
/// not guessed at: "Küche" is the cupboard as often as the fridge, and a
/// tin listed for throwing out because it stood in the kitchen would be
/// worse than a fridge the screen does not know about.
library;

import '../../../core/name_order.dart';
import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../inventory/application/stock_today.dart';
import 'outage_food_safety.dart';

// First, so a "Gefrierfach im Kühlschrank" is the freezer it names. Not
// "Truhe" alone, which is as often for toys or tools, and not "kühl",
// which is also a cool cellar.
final _freezerWords = RegExp(
  r'gefrier|tiefk(ü|ue)hl|k(ü|ue)hltruhe|eisfach|\btk\b|freezer|congelador',
  caseSensitive: false,
  unicode: true,
);

final _refrigeratorWords = RegExp(
  r'k(ü|ue)hlschrank|k(ü|ue)hlfach|fridge|refrigera|nevera|frigor(í|i)fico|'
  r'heladera',
  caseSensitive: false,
  unicode: true,
);

/// The cold store [storageLocation] names, or null where it names none.
ColdStore? coldStoreOf(String storageLocation) {
  if (_freezerWords.hasMatch(storageLocation)) return ColdStore.freezer;
  if (_refrigeratorWords.hasMatch(storageLocation)) {
    return ColdStore.refrigerator;
  }
  return null;
}

/// What is in each cold store today.
class ColdStoreContents {
  const ColdStoreContents({
    this.refrigerator = const [],
    this.freezer = const [],
  });

  final List<InventoryItem> refrigerator;
  final List<InventoryItem> freezer;

  List<InventoryItem> of(ColdStore store) => switch (store) {
    ColdStore.refrigerator => refrigerator,
    ColdStore.freezer => freezer,
  };

  /// Nothing in the stores is kept in either.
  bool get isEmpty => refrigerator.isEmpty && freezer.isEmpty;
}

/// [items] sorted into the two cold stores by where they are kept.
///
/// Only what is there today: a row at nothing -- or a pack in daily use
/// taken down to nothing since it was counted -- has nothing to throw
/// out.
ColdStoreContents coldStoreContents(
  Iterable<InventoryItem> items, {
  DateTime? now,
}) {
  final refrigerator = <InventoryItem>[];
  final freezer = <InventoryItem>[];
  for (final item in items) {
    if (item.deletedAt != null) continue;
    final store = coldStoreOf(item.storageLocation);
    if (store == null || !(stockToday(item, now: now) > 0)) continue;
    (store == ColdStore.freezer ? freezer : refrigerator).add(item);
  }
  int byName(InventoryItem a, InventoryItem b) => compareNames(a.name, b.name);
  return ColdStoreContents(
    refrigerator: refrigerator..sort(byName),
    freezer: freezer..sort(byName),
  );
}

/// Whether [item] is put forward for throwing out once its store's time
/// is up: food, for the household or its animals. The rest is offered
/// and left for the household to tick -- a bottle of water does not
/// spoil, and a medicine has a rule of its own ([isColdMedicine]).
bool proposedForDiscard(InventoryItem item) =>
    switch (InventoryItemCategory.fromName(item.category)) {
      InventoryItemCategory.food || InventoryItemCategory.petFood => true,
      _ => false,
    };

/// A medicine kept cold. ready.gov: one that should be refrigerated is
/// discarded once the power has been out for more than a day, unless its
/// label says otherwise -- a different clock from the food's, so it is
/// never ticked for the household.
bool isColdMedicine(InventoryItem item) =>
    InventoryItemCategory.fromName(item.category) ==
    InventoryItemCategory.medical;

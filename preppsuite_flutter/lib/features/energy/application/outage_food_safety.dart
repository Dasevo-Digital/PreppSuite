/// How long the cold in a fridge and a freezer lasts once the power is off.
///
/// The one question a household actually asks during a blackout, and the
/// one it cannot look up while the network is down.
///
/// **Where the figures come from.** FEMA's Ready.gov and the USDA's Food
/// Safety and Inspection Service, because no German authority publishes
/// comparable numbers — the BZfE, the BfR and the Verbraucherzentrale all
/// describe the principle and none of them states hours. So this is the
/// first place in the app that quotes a foreign authority, and the screen
/// says so rather than presenting the figures as the app's own. A cold
/// chain is not a national quantity; what would be wrong is inventing one.
///
/// - refrigerator, door kept shut: about **4 hours**
/// - full freezer: about **48 hours**
/// - half-full freezer: about **24 hours**
/// - the threshold itself: **40 °F**, which is 4 °C
/// - perishables that spent **2 hours** above it are discarded
/// - never taste food to decide; refreezing is allowed while ice crystals
///   remain
///
/// Sources: <https://www.ready.gov/power-outages>, <https://www.ready.gov/food>
/// and the FSIS "Keep Your Food Safe During Emergencies" fact sheet.
///
/// Everything here is pure arithmetic over a start time, so the screen can
/// be tested without a clock and the numbers live in exactly one place.
library;

/// How full the freezer is. The only thing the household has to answer,
/// and it doubles the answer either way — which is why it is asked
/// instead of assumed.
enum FreezerFill { full, half }

/// The two cold stores a household has. Kept apart because their
/// answers differ by a factor of twelve and they fail in different ways:
/// a warm fridge is a decision about tonight's food, a thawed freezer is
/// a decision about a month's.
enum ColdStore { refrigerator, freezer }

/// Door shut, no power: how long the contents stay safe.
const refrigeratorWindow = Duration(hours: 4);
const fullFreezerWindow = Duration(hours: 48);
const halfFreezerWindow = Duration(hours: 24);

/// How long a perishable may sit above [safeTemperatureCelsius] before it
/// is thrown out. Starts when the store's own window has run out, not
/// when the power went.
const perishableGrace = Duration(hours: 2);

/// 40 °F, stated in the unit the app speaks.
const safeTemperatureCelsius = 4;

/// One store's standing at a moment in time.
class ColdStoreStatus {
  const ColdStoreStatus({
    required this.store,
    required this.window,
    required this.elapsed,
  });

  final ColdStore store;

  /// How long this store is expected to hold, from the moment the power
  /// went.
  final Duration window;

  /// How long the power has been off. May exceed [window].
  final Duration elapsed;

  /// What is left of [window], never negative.
  Duration get remaining {
    final left = window - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// The window has run out. Not the same as "the food is spoilt" — it
  /// means the figure no longer answers, and [graceRemaining] takes over.
  bool get isOver => elapsed >= window;

  /// After the window, the two-hour rule. Zero once that is gone too,
  /// which is the point at which perishables are discarded.
  Duration get graceRemaining {
    if (!isOver) return perishableGrace;
    final left = window + perishableGrace - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// Perishables in this store are to be thrown out.
  bool get isSpoilt => graceRemaining == Duration.zero;

  /// How much of the window is used up, 0..1 — for a progress bar.
  double get fraction {
    if (window == Duration.zero) return 1;
    final used = elapsed.inSeconds / window.inSeconds;
    return used.clamp(0.0, 1.0);
  }
}

/// Both stores, at [now], for a blackout that began at [startedAt].
///
/// A [startedAt] in the future reads as "just now" rather than as a
/// negative age: clocks get corrected, and a countdown that runs backwards
/// is worse than one that restarts.
List<ColdStoreStatus> coldStoreStatuses({
  required DateTime startedAt,
  required DateTime now,
  required FreezerFill freezerFill,
}) {
  var elapsed = now.difference(startedAt);
  if (elapsed.isNegative) elapsed = Duration.zero;

  return [
    ColdStoreStatus(
      store: ColdStore.refrigerator,
      window: refrigeratorWindow,
      elapsed: elapsed,
    ),
    ColdStoreStatus(
      store: ColdStore.freezer,
      window: switch (freezerFill) {
        FreezerFill.full => fullFreezerWindow,
        FreezerFill.half => halfFreezerWindow,
      },
      elapsed: elapsed,
    ),
  ];
}

/// When [status] runs out, as a wall-clock instant.
///
/// The countdown answers "how long still"; this answers "until when",
/// which is the form somebody writes on a note and sticks to the door.
DateTime windowEndsAt(DateTime startedAt, ColdStoreStatus status) =>
    startedAt.add(status.window);

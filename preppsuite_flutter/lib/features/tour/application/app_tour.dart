import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../home/application/shell_layout.dart';

/// The stops of the guided tour (#173), in the order it takes them.
///
/// Each one is a real destination of the shell, not a picture of it: the
/// tour opens the screen itself and lays a band over its foot, so what is
/// shown is what is there, and whatever the screen offers can be used on
/// the spot. A tour of screenshots goes stale with the first redesign, and
/// one of spotlights over single buttons breaks under large text, in a
/// landscape window and in front of a screen reader.
///
/// Ordered by what matters when something happens: help and warnings
/// first, then what is set up beforehand. Warnings come earlier here than
/// in the bar, because the bar is ordered for use and this is ordered for
/// learning — and whoever learns only two stops should learn those two.
enum TourStop {
  emergency,
  warnings,
  inventory,
  checklists,
  map,
  knowledge,
  household,
  settings;

  ShellDestination get destination => switch (this) {
    TourStop.emergency => ShellDestination.emergency,
    TourStop.warnings => ShellDestination.warnings,
    TourStop.inventory => ShellDestination.inventory,
    TourStop.checklists => ShellDestination.checklists,
    TourStop.map => ShellDestination.map,
    TourStop.knowledge => ShellDestination.knowledge,
    TourStop.household => ShellDestination.household,
    TourStop.settings => ShellDestination.settings,
  };

  bool get isFirst => index == 0;
  bool get isLast => index == TourStop.values.length - 1;
}

/// Where the tour is, or null while it is not running.
///
/// Held in memory only. A tour interrupted by closing the app is not
/// picked up again on the next start: whoever opens it then came for
/// something else.
class AppTourController extends Notifier<TourStop?> {
  @override
  TourStop? build() => null;

  /// Starting it from anywhere answers the offer as well — whoever found
  /// the button has no use for the card that points at it.
  void start() {
    state = TourStop.values.first;
    unawaited(ref.read(tourOfferProvider.notifier).answer());
  }

  void next() {
    final stop = state;
    if (stop == null) return;
    state = stop.isLast ? null : TourStop.values[stop.index + 1];
  }

  void back() {
    final stop = state;
    if (stop == null || stop.isFirst) return;
    state = TourStop.values[stop.index - 1];
  }

  void end() => state = null;
}

final appTourProvider = NotifierProvider<AppTourController, TourStop?>(
  AppTourController.new,
);

const _tourOfferAnsweredKey = 'appTourOfferAnswered';

/// Whether the overview should still offer the tour.
///
/// Offered until it is either taken or declined, once per device: to a
/// new household after its setup, and once to every household that was
/// already there when the tour arrived, because both have the same gap.
/// The answer belongs to this device and to whoever holds it, so it does
/// not travel with the household's settings and is in no backup — a
/// second phone in the same household has a second person in front of it.
///
/// False until the stored answer has been read, so that a card is never
/// shown for one frame and then taken away.
class TourOfferController extends Notifier<bool> {
  @override
  bool build() {
    unawaited(_load());
    return false;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (ref.mounted) {
        state = !(prefs.getBool(_tourOfferAnsweredKey) ?? false);
      }
    } on Object {
      // A store that cannot be read offers nothing: an offer is the one
      // thing here that may safely be missing.
    }
  }

  Future<void> answer() async {
    state = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tourOfferAnsweredKey, true);
    } on Object {
      // Offered again on the next start, which is the lesser nuisance.
    }
  }
}

final tourOfferProvider = NotifierProvider<TourOfferController, bool>(
  TourOfferController.new,
);

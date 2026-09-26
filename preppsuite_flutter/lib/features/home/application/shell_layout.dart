/// How the top-level navigation should be drawn at a given width.
///
/// PreppSuite runs on phones and on desktops, and the same destinations
/// have to work at both ends. A bar across the bottom of a thirteen-inch
/// iPad is a phone layout that happens to fit.
enum ShellNavigation {
  /// A bar along the bottom. The only one that works one-handed.
  bar,

  /// A rail down the side, icons above short labels.
  rail,

  /// The same rail, wide enough to put the labels beside the icons.
  extendedRail,
}

/// Material's own window size classes, with one departure: the extended
/// rail waits for the *large* class rather than starting at expanded.
/// Extended costs about 256 of the 840 an expanded window has, and the
/// content is what people came for.
ShellNavigation shellNavigationFor(double width) {
  if (width < 600) return ShellNavigation.bar;
  if (width < 1200) return ShellNavigation.rail;
  return ShellNavigation.extendedRail;
}

/// Everywhere the shell can go, in the order it is offered.
///
/// The order is the priority order, and the bar cuts from the end of it:
/// the first four are what someone opens during an actual emergency, the
/// rest are what they set up beforehand.
enum ShellDestination {
  overview,
  emergency,
  inventory,
  checklists,
  warnings,
  shelters,
  map,
  knowledge,
  household,
  settings,
}

/// How many slots a bottom bar gets before the rest move behind "more".
///
/// Material's own limit. Ten destinations across a phone leaves about
/// forty pixels each, which is neither readable nor tappable — and the
/// rail, which has the room, still shows all ten.
const barSlotLimit = 5;

/// Which destinations a bar shows, and which are behind the "more" button.
class ShellSlots {
  const ShellSlots({
    required this.visible,
    required this.overflow,
    this.selectedIsBehindMore = false,
  });

  /// In bar order, left to right. Never longer than [barSlotLimit].
  final List<ShellDestination> visible;

  /// What the "more" sheet lists. Empty when everything fits, and the bar
  /// then has no "more" button at all.
  final List<ShellDestination> overflow;

  /// Whether the open screen is one of the [overflow] ones, in which case
  /// the bar marks the "more" button itself as the place you are.
  final bool selectedIsBehindMore;

  bool get hasOverflow => overflow.isNotEmpty;
}

/// Splits [destinations] into what the bar shows and what it hides.
///
/// A rail hides nothing — it scrolls, and a desktop window has the height.
/// A bar keeps the first few and puts the rest behind one more button.
///
/// **The bar never rearranges itself.** The same five things stand in the
/// same places whatever screen is open, because in an emergency a thumb
/// goes where it went last time. When the open screen is one of the
/// hidden ones, the "more" button is marked as the place you are — see
/// [selectedIsBehindMore]. That answers the one objection to a fixed bar,
/// which is that it would otherwise show nothing selected at all and read
/// as "you are nowhere".
///
/// The earlier answer was to give the open screen the last slot. It cost
/// more than it looked: the slot then has to hold any of the ten labels,
/// and two German ones do not fit a fifth of a phone — "Einstellungen"
/// wrapped, and the bar's fixed height cut the second line off. A bar of
/// five fixed words can be measured once and kept short; a slot that
/// takes any word cannot.
ShellSlots shellSlotsFor({
  required ShellNavigation navigation,
  required ShellDestination selected,
  List<ShellDestination> destinations = ShellDestination.values,
}) {
  if (navigation != ShellNavigation.bar ||
      destinations.length <= barSlotLimit) {
    return ShellSlots(visible: destinations, overflow: const []);
  }

  // One slot goes to the "more" button itself.
  final kept = destinations.take(barSlotLimit - 1).toList();
  final hidden = [
    for (final destination in destinations)
      if (!kept.contains(destination)) destination,
  ];

  return ShellSlots(
    visible: kept,
    overflow: hidden,
    selectedIsBehindMore: hidden.contains(selected),
  );
}

/// How the top-level navigation should be drawn at a given width.
///
/// PreppSuite runs on phones and on desktops, and the same seven
/// destinations have to work at both ends. A bar across the bottom of a
/// thirteen-inch iPad is a phone layout that happens to fit.
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

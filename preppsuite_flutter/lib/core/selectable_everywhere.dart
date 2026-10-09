import 'package:flutter/material.dart';

/// Makes every text in the app selectable, on every screen and in every
/// dialog (#39).
///
/// The app's `SelectionArea` used to sit around the start screen only,
/// inside the navigator. Every screen opened on top of it -- most of the
/// app -- and every dialog is a route of its own beside that one, not
/// under it, so right-click-copy worked on the first screen and nowhere
/// past it: "it often does not work".
///
/// One area around the navigator would reach all of them, and was
/// measured not to do: "select all" then takes in every screen the
/// navigator keeps beneath the visible one, and a copy brings their text
/// along. So each screen gets an area of its own, through the page
/// transition every screen is built with ([SelectablePageTransitions]),
/// and this one, around the navigator, is left with what is not a screen:
/// dialogs and sheets. A screen's own area is the nearer one for its text,
/// so none of it reaches this one.
///
/// Above the navigator there is no overlay for the selection handles and
/// the copy menu to sit in, so this brings its own. The entry rebuilds
/// with the app, so a theme or language change reaches what is inside.
class SelectableEverywhere extends StatefulWidget {
  const SelectableEverywhere({super.key, required this.child});

  final Widget child;

  @override
  State<SelectableEverywhere> createState() => _SelectableEverywhereState();
}

class _SelectableEverywhereState extends State<SelectableEverywhere> {
  late final OverlayEntry _entry = OverlayEntry(
    builder: (_) => SelectionArea(child: widget.child),
  );

  @override
  void didUpdateWidget(SelectableEverywhere oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  void dispose() {
    _entry
      ..remove()
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}

/// A platform's page transition, with the screen inside it made
/// selectable on its own. See [SelectableEverywhere].
class SelectablePageTransitions extends PageTransitionsBuilder {
  const SelectablePageTransitions(this._transition);

  final PageTransitionsBuilder _transition;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _transition.delegatedTransition;

  @override
  Duration get transitionDuration => _transition.transitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      _transition.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _transition.buildTransitions(
    route,
    context,
    animation,
    secondaryAnimation,
    SelectionArea(child: child),
  );
}

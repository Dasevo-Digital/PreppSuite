import 'package:flutter/material.dart';

/// One piece of content becoming another, rather than being replaced
/// between two frames.
///
/// Until this existed there was not a single animation in the app —
/// sixteen kinds were searched for and none was found. Every screen that
/// waits for something therefore showed a spinner and then, in one
/// frame, the finished page. That is not a small thing: a hard cut reads
/// as a jump, and a jump is what an app does when something went wrong.
/// The work is the same either way; what changes is whether somebody can
/// see that it finished.
///
/// **Deliberately only at the seams.** It switches when the *kind* of
/// content changes — a spinner for a list, a list for an empty state —
/// because [AnimatedSwitcher] compares widgets the way the framework
/// does. A list that gains a row is the same kind of thing and is left
/// alone, which is the point: fading a list on every tick of the
/// database would be motion for its own sake, and it would fight the
/// scroll position.
///
/// **It obeys the system.** Somebody who has asked their phone to reduce
/// motion has asked for a reason, and gets the frame-to-frame change
/// they had before rather than a shorter version of this one.
class ContentSwap extends StatelessWidget {
  const ContentSwap({super.key, required this.child});

  final Widget child;

  /// Long enough to be seen, short enough that nobody waits for it.
  ///
  /// Material's own medium duration. Below about 150 ms a fade reads as a
  /// flicker; above about 250 ms it reads as the app being slow, which is
  /// the opposite of what this is for.
  static const duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);

    return AnimatedSwitcher(
      duration: still ? Duration.zero : duration,
      // The way out is quicker than the way in, so the two never overlap
      // into a moment where both are half visible and neither readable.
      reverseDuration: still ? Duration.zero : const Duration(milliseconds: 90),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: still
            ? child
            : SlideTransition(
                // Four pixels, from below. Enough to read as arriving;
                // not enough to read as sliding.
                position: Tween(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
      ),
      child: child,
    );
  }
}

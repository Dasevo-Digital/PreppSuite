/// What just happened, said through the case of the phone.
///
/// The app had haptics in exactly two places, and both were rhythm: the
/// distress signal's flash and the compression pacer's beat. Nothing
/// else in it could be felt — a delete that could not be undone, a save
/// that failed, and a barcode that finally read all landed the same way,
/// which is to say silently.
///
/// **Intents, not vibrations.** Callers say what happened and this file
/// decides what that feels like. Sprinkling `HapticFeedback` through
/// fifty screens is how an app ends up buzzing differently for the same
/// kind of event in two places, and how it ends up buzzing for
/// everything.
///
/// **Only where the screen's own answer is weak, or where it is too
/// late to take back.** Four rules, and anything outside them stays
/// silent:
///
///  * the eyes are somewhere else — a camera pointed at a barcode, a
///    phone held up against another phone;
///  * the hands are busy and the list is long — ticking off a Notgepäck
///    while packing it;
///  * it cannot be undone;
///  * it failed, and the only sign is a message that slides away by
///    itself.
///
/// Everything else already says so on screen, and a buzz that adds
/// nothing is a buzz that teaches people to stop noticing them.
library;

import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class Feel {
  /// Whether this device has anything to say with.
  ///
  /// A desktop has no haptics, and every call would still be a platform
  /// channel round trip for nothing. Asked here once rather than at each
  /// of the call sites, which is how the pacer's guard came to be copied
  /// and the distress signal's came to be missing.
  static bool get _possible =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// A choice was made where the screen barely moves — a checklist line
  /// ticked, one of a row of chips chosen.
  static void chose() {
    if (_possible) unawaited(HapticFeedback.selectionClick());
  }

  /// Something the app was waiting for arrived: a barcode read, a
  /// transfer finished. Often while nobody is looking at the screen.
  static void arrived() {
    if (_possible) unawaited(HapticFeedback.mediumImpact());
  }

  /// Something is gone and is not coming back.
  ///
  /// The heaviest of the three on purpose. It is the one that should
  /// register even through a pocket, and the one somebody should feel
  /// they did rather than notice afterwards.
  static void removed() {
    if (_possible) unawaited(HapticFeedback.heavyImpact());
  }

  /// It did not work, and the only sign otherwise is a message that
  /// slides away by itself.
  static void failed() {
    if (_possible) unawaited(HapticFeedback.vibrate());
  }

  /// One beat of a rhythm somebody is following without watching: the
  /// compression pacer, the distress signal's flash.
  ///
  /// The exception to "only where the screen's answer is weak", and the
  /// oldest use in the app. Here the buzz **is** the answer — a
  /// hundred-and-ten-a-minute chest compression is counted through the
  /// hand, not read off a phone lying on the floor.
  static void beat() {
    if (_possible) unawaited(HapticFeedback.heavyImpact());
  }

  /// Something changed within that rhythm and must be noticed: the
  /// pacer's changeover to the other person.
  ///
  /// Deliberately unlike [beat], because it has to stand out from the
  /// beat it interrupts.
  static void beatChange() {
    if (_possible) unawaited(HapticFeedback.vibrate());
  }
}

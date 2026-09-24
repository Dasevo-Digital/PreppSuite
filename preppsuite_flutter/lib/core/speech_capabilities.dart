import 'package:flutter/foundation.dart';

/// Whether this platform can read a text out loud.
///
/// The same shape as `notification_capabilities.dart`, and for the same
/// reason: one of the five targets cannot, and a button that does nothing
/// is worse than no button. `flutter_tts` ships implementations for
/// Android, iOS, macOS and Windows; Linux is not among them, and there is
/// no freedesktop equivalent it could fall back to.
///
/// That the plugin *exists* for a platform is not the same as a voice
/// being installed on the device. This only answers the first question;
/// the second is asked of the engine itself, at runtime, by
/// `StepSpeech.isAvailable`.
bool get supportsSpeech => !kIsWeb && supportsSpeechOn(defaultTargetPlatform);

/// Split out so the mapping can be tested; the platform itself cannot be.
bool supportsSpeechOn(TargetPlatform platform) => switch (platform) {
  TargetPlatform.android ||
  TargetPlatform.iOS ||
  TargetPlatform.macOS ||
  TargetPlatform.windows => true,
  TargetPlatform.linux || TargetPlatform.fuchsia => false,
};

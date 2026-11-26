import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/speech_capabilities.dart';

/// Reads a first aid guide out loud, one step at a time.
///
/// The situation this exists for: both hands on somebody's chest, eyes on
/// their face, and the next step on a screen nobody can look at. The app
/// already keeps the rhythm with a metronome; this is the same idea one
/// step further.
///
/// Two gates before a word is spoken, and both are needed. The platform
/// has to have an implementation at all (`supportsSpeech` — Linux does
/// not), and the device has to have a voice for the language. A phone
/// that has never downloaded a German voice reports none, and the button
/// stays away rather than producing English vowels over German words.
abstract interface class StepSpeech {
  /// Whether this device can speak [languageCode] right now.
  Future<bool> isAvailable(String languageCode);

  /// Speaks [text], interrupting whatever was being said.
  ///
  /// Completes when the text has been said to the end, when it is cut
  /// off by [stop] or by the next [speak], or when it fails -- not when
  /// the engine merely begins. A button that offers "stop" while this
  /// runs goes back to "read aloud" when it completes (#412).
  Future<void> speak(String text, {required String languageCode});

  Future<void> stop();
}

class PlatformStepSpeech implements StepSpeech {
  PlatformStepSpeech([FlutterTts? engine]) : _engine = engine ?? FlutterTts();

  final FlutterTts _engine;

  /// Completed when what is being said now is cut off.
  ///
  /// The engine does not say so on every platform: with
  /// `awaitSpeakCompletion`, Android answers a stopped utterance, iOS and
  /// macOS answer only one that was said to its end, and the future of
  /// a stopped one never completes there.
  Completer<void>? _cut;

  void _cutOff() {
    final cut = _cut;
    _cut = null;
    if (cut != null && !cut.isCompleted) cut.complete();
  }

  @override
  Future<bool> isAvailable(String languageCode) async {
    if (!supportsSpeech) return false;
    try {
      // `isLanguageAvailable` is the question that matters: a plugin can
      // be present and the device still have nothing to say it with.
      final available = await _engine.isLanguageAvailable(languageCode);
      return available == true;
    } on Object {
      // A missing engine reports itself as a platform exception rather
      // than as an absent plugin on some versions of Android. Either way
      // the answer to "can this device speak" is no.
      return false;
    }
  }

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    if (text.trim().isEmpty) return;
    _cutOff();
    final cut = _cut = Completer<void>();
    try {
      await _engine.stop();
      await _engine.setLanguage(languageCode);
      // Slower than the default. These are instructions somebody is
      // acting on while they hear them, not a paragraph being read.
      await _engine.setSpeechRate(0.45);
      // Without it the engine answers `speak` as soon as it begins, and
      // a caller had no way of knowing when the voice ended (#412).
      await _engine.awaitSpeakCompletion(true);
      // Stopped while it was being set up: not a word after that.
      if (cut.isCompleted) return;
      await Future.any([_engine.speak(text), cut.future]);
    } on Object {
      // Silence is the failure mode, and it is an acceptable one: the
      // steps are on the screen either way.
    } finally {
      if (identical(_cut, cut)) _cut = null;
    }
  }

  @override
  Future<void> stop() async {
    _cutOff();
    try {
      await _engine.stop();
    } on Object {
      // Nothing to stop.
    }
  }
}

/// The voice of the first aid guides.
///
/// A provider rather than an engine per button, so a test can stand in
/// for a device that speaks.
final firstAidSpeechProvider = Provider<StepSpeech>(
  (ref) => PlatformStepSpeech(),
);

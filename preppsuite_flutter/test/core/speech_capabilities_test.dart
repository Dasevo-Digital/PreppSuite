import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preppsuite_flutter/core/speech_capabilities.dart';

void main() {
  test('every platform is decided, and Linux is a no', () {
    // `flutter_tts` ships no Linux implementation and there is no
    // freedesktop equivalent to fall back to. Saying so here is what
    // keeps a button that does nothing off that build.
    expect(supportsSpeechOn(TargetPlatform.android), isTrue);
    expect(supportsSpeechOn(TargetPlatform.iOS), isTrue);
    expect(supportsSpeechOn(TargetPlatform.macOS), isTrue);
    expect(supportsSpeechOn(TargetPlatform.windows), isTrue);
    expect(supportsSpeechOn(TargetPlatform.linux), isFalse);
    expect(supportsSpeechOn(TargetPlatform.fuchsia), isFalse);
  });

  test('the switch covers every platform there is', () {
    // A new TargetPlatform would be a compile error rather than a
    // surprise at runtime; this holds that the list stays exhaustive.
    for (final platform in TargetPlatform.values) {
      expect(() => supportsSpeechOn(platform), returnsNormally);
    }
  });
}

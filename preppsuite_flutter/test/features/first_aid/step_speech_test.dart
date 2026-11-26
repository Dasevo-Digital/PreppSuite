import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/step_speech.dart';

/// When reading aloud is over (#412).
///
/// `speak` used to return as soon as the engine began, so the button
/// beside a guide stayed on "stop" after the last step had been said.
/// It returns when the voice ends now, however it ends.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');

  late List<String> calls;
  // The platform's answer to `speak`, which with awaitSpeakCompletion
  // arrives when the utterance is over -- or, on iOS and macOS after a
  // stop, never.
  late Completer<int> said;

  setUp(() {
    calls = [];
    said = Completer<int>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call.method);
          if (call.method == 'speak') return said.future;
          return Future.value(1);
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('it waits for the end of what is said', () async {
    final speech = PlatformStepSpeech();
    var over = false;
    unawaited(
      speech
          .speak('1. Notruf 112', languageCode: 'de-DE')
          .then((_) => over = true),
    );
    await pumpEventQueue();

    expect(calls, contains('awaitSpeakCompletion'));
    expect(calls.last, 'speak');
    expect(over, isFalse, reason: 'still speaking');

    said.complete(1);
    await pumpEventQueue();
    expect(over, isTrue);
  });

  test('a stop ends it, even where the engine never answers', () async {
    final speech = PlatformStepSpeech();
    var over = false;
    unawaited(
      speech
          .speak('1. Notruf 112', languageCode: 'de-DE')
          .then((_) => over = true),
    );
    await pumpEventQueue();

    await speech.stop();
    await pumpEventQueue();
    expect(over, isTrue);
    expect(calls.last, 'stop');
  });

  test('the next reading ends the one before', () async {
    final speech = PlatformStepSpeech();
    var first = false;
    unawaited(
      speech.speak('erste', languageCode: 'de-DE').then((_) => first = true),
    );
    await pumpEventQueue();

    unawaited(speech.speak('zweite', languageCode: 'de-DE'));
    await pumpEventQueue();
    expect(first, isTrue);
  });

  test('stopped while it is set up, it says nothing', () async {
    final speech = PlatformStepSpeech();
    final reading = speech.speak('1. Notruf 112', languageCode: 'de-DE');
    await speech.stop();
    await reading;

    expect(calls, isNot(contains('speak')));
  });
}

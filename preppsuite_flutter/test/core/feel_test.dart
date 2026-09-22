import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/feel.dart';

/// What the app says through the case of the phone.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final asked = <String?>[];

  setUp(() {
    asked.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          asked.add(call.arguments as String?);
        }
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  Future<List<String?>> after(void Function() act, TargetPlatform on) async {
    debugDefaultTargetPlatformOverride = on;
    act();
    // The calls are deliberately not awaited by their callers — nothing
    // should wait on a buzz — so the channel is given its turn here.
    await Future<void>.delayed(Duration.zero);
    return List.of(asked);
  }

  test('a phone is told, and told different things', () async {
    expect(await after(Feel.chose, TargetPlatform.android), hasLength(1));

    asked.clear();
    final removed = await after(Feel.removed, TargetPlatform.iOS);
    asked.clear();
    final chose = await after(Feel.chose, TargetPlatform.iOS);

    // Four intents that all felt the same would be one intent.
    expect(removed, isNot(chose));
  });

  test('a desktop is not asked at all', () async {
    // There is nothing there to feel it, and every call would still be a
    // platform channel round trip for nothing. Asked once in `Feel`
    // rather than at each of the call sites, which is how one guard came
    // to be copied and another came to be missing.
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ]) {
      asked.clear();
      expect(
        await after(() {
          Feel.chose();
          Feel.arrived();
          Feel.removed();
          Feel.failed();
          Feel.beat();
          Feel.beatChange();
        }, platform),
        isEmpty,
        reason: '$platform',
      );
    }
  });

  test('the rhythm intents differ from each other', () async {
    // The pacer's changeover has to stand out from the beat it
    // interrupts, or it is not a changeover.
    asked.clear();
    final beat = await after(Feel.beat, TargetPlatform.android);
    asked.clear();
    final change = await after(Feel.beatChange, TargetPlatform.android);

    expect(beat, isNot(change));
  });
}

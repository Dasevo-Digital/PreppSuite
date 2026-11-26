import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_screen.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/first_aid_video_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// The icon buttons of the first aid screens (#412): named for a screen
/// reader, and the video's following the player.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget app(Widget home) => ProviderScope(
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  testWidgets('the button that clears the search is named', (tester) async {
    await tester.pumpWidget(app(const FirstAidScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Brand');
    await tester.pump();

    final clear = find.byTooltip('Suche leeren');
    expect(clear, findsOneWidget);
    await tester.tap(clear);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  group('the video controls', () {
    // Never initialised, so nothing reaches a platform player: play and
    // pause only change the value, which is what the controls draw from.
    late VideoPlayerController controller;

    setUp(() => controller = VideoPlayerController.file(File('clip.mp4')));
    tearDown(() => controller.dispose());

    Future<void> show(WidgetTester tester) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Center(child: FirstAidVideoControls(controller: controller)),
          ),
        ),
      );
    }

    testWidgets('both buttons say what they do', (tester) async {
      await show(tester);

      expect(find.byTooltip('Abspielen'), findsOneWidget);
      expect(find.byTooltip('Von vorn'), findsOneWidget);
    });

    testWidgets('a tap plays and pauses', (tester) async {
      await show(tester);

      await tester.tap(find.byTooltip('Abspielen'));
      await tester.pump();
      expect(controller.value.isPlaying, isTrue);
      expect(find.byTooltip('Anhalten'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.byTooltip('Anhalten'));
      await tester.pump();
      expect(controller.value.isPlaying, isFalse);
      expect(find.byTooltip('Abspielen'), findsOneWidget);
    });

    testWidgets('a clip that ends on its own offers play again', (
      tester,
    ) async {
      // Nothing on the screen rebuilds when a clip ends. The button used
      // to go on showing "pause" until something else did.
      await show(tester);
      await tester.tap(find.byTooltip('Abspielen'));
      await tester.pump();

      controller.value = controller.value.copyWith(
        isPlaying: false,
        isCompleted: true,
      );
      await tester.pump();

      expect(find.byTooltip('Abspielen'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}

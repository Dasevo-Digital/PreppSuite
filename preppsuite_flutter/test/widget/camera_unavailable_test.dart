import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:preppsuite_flutter/core/camera_unavailable.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// What stands where the viewfinder does not come.
///
/// The package's own fallback prints an English sentence into a German
/// app and says only what went wrong. These tests hold the replacement to
/// the two things that make it worth having: it is in the reader's
/// language, and it names the way to do the job without a camera.
void main() {
  late AppLocalizations l10n;

  Future<void> pump(WidgetTester tester, MobileScannerErrorCode code) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: CameraUnavailable(
                error: MobileScannerException(errorCode: code),
                alternative: l10n.cameraAlternativeBarcode,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a refused camera says how to allow it again', (tester) async {
    await pump(tester, MobileScannerErrorCode.permissionDenied);

    expect(find.text(l10n.cameraDeniedTitle), findsOneWidget);
    expect(find.text(l10n.cameraDeniedBody), findsOneWidget);
    // The package's own wording must not be what the reader gets.
    expect(find.text('Camera permission denied.'), findsNothing);
  });

  testWidgets('a device without a camera is told apart from a refusal', (
    tester,
  ) async {
    await pump(tester, MobileScannerErrorCode.unsupported);

    expect(find.text(l10n.cameraUnsupportedTitle), findsOneWidget);
    // Telling somebody to allow the camera in the settings, on a machine
    // that has none, is worse than saying nothing.
    expect(find.text(l10n.cameraDeniedBody), findsNothing);
  });

  testWidgets('our own mistakes get the plain message, not advice', (
    tester,
  ) async {
    await pump(tester, MobileScannerErrorCode.controllerDisposed);

    expect(find.text(l10n.cameraFailedTitle), findsOneWidget);
    expect(find.text(l10n.cameraDeniedBody), findsNothing);
  });

  testWidgets('every case names the way out without a camera', (tester) async {
    for (final code in MobileScannerErrorCode.values) {
      await pump(tester, code);
      expect(
        find.text(l10n.cameraAlternativeBarcode),
        findsOneWidget,
        reason: '$code',
      );
    }
  });

  testWidgets('is accessible', (tester) async {
    await pump(tester, MobileScannerErrorCode.permissionDenied);
    await expectAccessible(tester);
  });
}

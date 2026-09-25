import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/generated/app_localizations.dart';

/// What to show in place of the viewfinder when the camera does not come.
///
/// `mobile_scanner` has a default for this and it is the wrong thing twice
/// over: it prints its own English sentence into a German app, and the
/// sentence it prints — "Camera permission denied." — tells somebody what
/// happened without telling them what to do about it. Refusing the camera
/// is a perfectly reasonable thing to have done, and the screen that
/// results should say how to undo it and how to get on without it.
///
/// [alternative] is the part worth having. Every screen in this app that
/// asks for a camera can be done without one — a barcode can be typed, a
/// household can travel through a folder or a file — and naming that way
/// out is more use than any amount of explaining the error.
class CameraUnavailable extends StatelessWidget {
  const CameraUnavailable({
    super.key,
    required this.error,
    required this.alternative,
  });

  final MobileScannerException error;

  /// One sentence: how to do the same thing without the camera.
  final String alternative;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Only the three the person can act on are told apart. The rest —
    // a controller started twice, used after disposal — are this app's
    // own mistakes, and dressing them up in advice would be a lie about
    // whose fault they are.
    final (title, body) = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => (
        l10n.cameraDeniedTitle,
        l10n.cameraDeniedBody,
      ),
      MobileScannerErrorCode.unsupported => (
        l10n.cameraUnsupportedTitle,
        l10n.cameraUnsupportedBody,
      ),
      _ => (l10n.cameraFailedTitle, l10n.cameraFailedBody),
    };

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                alternative,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

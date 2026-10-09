import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'emergency_access.dart';

/// What takes the place of a widget that failed to build (#141).
///
/// Flutter's own is a grey patch in a release build: no word of what
/// happened, and on a whole screen no way anywhere. This says it in a
/// sentence, points at the error log, and where there is a navigator
/// offers the way to the emergency help -- which does not depend on the
/// part that broke. Small and unstyled on purpose: it can be asked to fill
/// a list tile as well as a screen, under any constraints, and must not
/// itself be the next thing to fail.
Widget friendlyErrorWidget(FlutterErrorDetails details) => Builder(
  builder: (context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final text =
        l10n?.errorWidgetText ??
        'Dieser Teil der App konnte nicht angezeigt werden.';
    final canNavigate =
        l10n != null &&
        Navigator.maybeOf(context) != null &&
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) !=
            null;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0x14B00020),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB00020), fontSize: 14),
              ),
              if (canNavigate)
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EmergencyAccessScreen(),
                    ),
                  ),
                  child: Text(l10n.emergencyAccessButton),
                ),
            ],
          ),
        ),
      ),
    );
  },
);

import '../../../l10n/generated/app_localizations.dart';
import 'sun_moon.dart';

String localizeMoonPhase(AppLocalizations l10n, MoonPhase phase) =>
    switch (phase) {
      MoonPhase.newMoon => l10n.moonPhaseNew,
      MoonPhase.waxingCrescent => l10n.moonPhaseWaxingCrescent,
      MoonPhase.firstQuarter => l10n.moonPhaseFirstQuarter,
      MoonPhase.waxingGibbous => l10n.moonPhaseWaxingGibbous,
      MoonPhase.fullMoon => l10n.moonPhaseFull,
      MoonPhase.waningGibbous => l10n.moonPhaseWaningGibbous,
      MoonPhase.lastQuarter => l10n.moonPhaseLastQuarter,
      MoonPhase.waningCrescent => l10n.moonPhaseWaningCrescent,
    };

/// A span in hours and minutes, or minutes alone below an hour.
///
/// "0 h 41 min" is a clumsy way of writing three quarters of an hour, and
/// this figure — how long there is still light after sunset — is often
/// under one.
String formatSpan(AppLocalizations l10n, Duration duration) {
  final minutes = duration.inMinutes;
  if (minutes < 60) return l10n.durationMinutes(minutes);
  return l10n.durationHoursMinutes(minutes ~/ 60, minutes % 60);
}

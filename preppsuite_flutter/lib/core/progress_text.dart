import '../l10n/generated/app_localizations.dart';

/// What a progress bar announces to a screen reader.
///
/// The bar itself carries no text, so without this a screen reader reaches
/// it and says nothing useful — the numbers are in the sibling label, and
/// finding out how far along a download is means navigating back to it.
/// A percentage on the bar is short enough to be worth hearing in passing.
///
/// Returns null for an indeterminate bar, which is the honest answer: a
/// mirror behind a redirect does not always give a total, and there is no
/// percentage to report.
String? percentValue(AppLocalizations l10n, double? fraction) {
  if (fraction == null) return null;
  return l10n.progressPercent((fraction.clamp(0.0, 1.0) * 100).round());
}

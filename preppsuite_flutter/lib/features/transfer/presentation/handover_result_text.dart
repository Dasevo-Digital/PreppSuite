import '../../../l10n/generated/app_localizations.dart';
import '../application/local_handover.dart';

/// What one side of a local handover says when it is over: what arrived
/// here, and nothing about the other device (#399).
///
/// Each side only knows what it took in itself. The host of a device
/// being set up hands over the whole household and takes in nothing, and
/// it used to say that both devices had already been at the same point;
/// the guest said the same whenever nothing new came back, even after
/// sending rows the host had never had. Shared by both screens so that
/// the two sides keep saying it the same way.
String handoverResultText(AppLocalizations l10n, LocalHandoverResult result) {
  final rows = result.received == 0
      ? l10n.transferHandoverNothing
      : l10n.transferHandoverDone(result.received);
  return result.photos == 0
      ? rows
      : '$rows ${l10n.transferHandoverPhotos(result.photos)}';
}

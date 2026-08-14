import 'package:preppsuite_client/preppsuite_client.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Maps a caught error from a household endpoint call to a localized
/// message, falling back to a generic message for anything unexpected
/// (network errors, etc).
String localizeHouseholdError(AppLocalizations l10n, Object error) {
  if (error is HouseholdException) {
    return switch (error.reason) {
      HouseholdExceptionReason.invalidInviteCode =>
        l10n.errorInvalidInviteCode,
      HouseholdExceptionReason.notAMember => l10n.errorNotAMember,
      HouseholdExceptionReason.notOwner => l10n.errorNotOwner,
      HouseholdExceptionReason.alreadyInHousehold =>
        l10n.errorAlreadyInHousehold,
    };
  }
  return l10n.errorGeneric(error.toString());
}

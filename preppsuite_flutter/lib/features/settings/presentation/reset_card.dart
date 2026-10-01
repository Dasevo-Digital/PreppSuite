import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/locale_provider.dart';
import '../../../core/notifications_provider.dart';
import '../../../core/theme_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../household/application/household_providers.dart';
import '../../inventory/application/inventory_photo_service.dart';
import '../../maps/application/map_source_preference.dart';
import '../../sharing/application/folder_key_store.dart';
import '../../sharing/application/shared_folder_store.dart';

class ResetCard extends ConsumerWidget {
  const ResetCard({super.key, required this.profile, required this.l10n});

  final HouseholdProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Column(
      children: [
        ListTile(
          leading: const Icon(Icons.settings_backup_restore),
          title: Text(l10n.resetSettings),
          subtitle: Text(l10n.resetSettingsHint),
          onTap: () => _resetSettings(context, ref),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(
            Icons.delete_forever_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(l10n.resetHousehold),
          subtitle: Text(l10n.resetHouseholdHint),
          onTap: () => _resetHousehold(context, ref),
        ),
      ],
    ),
  );

  Future<bool> _confirm(BuildContext context, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.resetConfirmTitle),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.resetTitle),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _resetSettings(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(context, l10n.resetSettingsHint)) return;
    final prefs = await SharedPreferences.getInstance();
    for (final key in const [
      'localeOverride',
      'themeModeOverride',
      'notificationsEnabled',
      'expiryLeadDays',
      'chargeReminderDays',
      'mapTileProvider',
      'mapTilerApiKey',
      'mapSourcePreference',
      'warningExtraRegions',
    ]) {
      await prefs.remove(key);
    }
    // The additional regions are mirrored into preferences for the
    // background worker, but the profile is their source of truth. Clear
    // both, otherwise the next profile save would restore them.
    await ref
        .read(householdProfileProvider.notifier)
        .save(profile.copyWith(extraRegions: const []));
    ref.invalidate(localeOverrideProvider);
    ref.invalidate(themeModeProvider);
    ref.invalidate(notificationsEnabledProvider);
    ref.invalidate(mapSourceProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.resetDone)),
      );
    }
  }

  Future<void> _resetHousehold(BuildContext context, WidgetRef ref) async {
    if (!await _confirm(context, l10n.resetConfirmHousehold)) return;
    final db = ref.read(appDatabaseProvider);
    // Pictures first: the rows are the only record of which files were
    // this household's.
    await deleteHouseholdPhotos(db, householdId: profile.id);
    await db.deleteHouseholdData(profile.id);
    await const SharedFolderStore().clearLocation();
    await const FolderKeyStore().clear(profile.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nearbyEmergencyContacts');
    await ref.read(householdProfileProvider.notifier).clear();
  }
}

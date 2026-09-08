import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale_provider.dart';
import '../../../core/notification_capabilities.dart';
import '../../../core/notifications_provider.dart';
import '../../../core/theme_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../downloads/presentation/download_folder_card.dart';
import '../../inventory/presentation/expiry_reminders_card.dart';
import '../../maps/presentation/offline_map_card.dart';
import '../../sharing/presentation/shared_folder_card.dart';
import 'additional_regions_card.dart';
import 'my_region_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.profile});

  final HouseholdProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.languageLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(l10n.languageLabel),
              trailing: _LanguagePicker(l10n: l10n),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.settingsAppearanceTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(child: _ThemeModePicker(l10n: l10n)),
          const SizedBox(height: 24),
          Text(
            l10n.settingsMyRegionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          MyRegionCard(profile: profile, l10n: l10n),
          const SizedBox(height: 24),
          Text(
            l10n.settingsAdditionalRegionsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          AdditionalRegionsCard(profile: profile, l10n: l10n),
          const SizedBox(height: 24),
          Text(
            l10n.settingsNotificationsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(child: _NotificationsToggle(l10n: l10n)),
          const SizedBox(height: 24),
          Text(
            l10n.settingsExpiryRemindersTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          // A switch that cannot do anything is worse than an
          // explanation. Linux has no scheduled notifications at all.
          if (supportsScheduledNotifications)
            ExpiryRemindersCard(l10n: l10n)
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.settingsExpiryRemindersUnsupported),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            l10n.settingsSharingTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SharedFolderCard(profile: profile, l10n: l10n),
          const SizedBox(height: 24),
          Text(
            l10n.settingsOfflineMapTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          OfflineMapCard(l10n: l10n),
          const SizedBox(height: 24),
          Text(
            l10n.downloadFolderTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DownloadFolderCard(l10n: l10n),
        ],
      ),
    );
  }
}

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeOverrideProvider);

    // No `isExpanded` here, unlike the form fields: this one sits in a
    // ListTile's trailing slot, which offers unbounded width, and asking
    // to fill unbounded width is an assertion rather than a wide button.
    // It sizes to its longest option instead, which for three language
    // names is short enough to survive a large font.
    return DropdownButton<Locale?>(
      value: current,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.languageSystemOption)),
        DropdownMenuItem(
          value: const Locale('de'),
          child: Text(l10n.languageGermanOption),
        ),
        DropdownMenuItem(
          value: const Locale('en'),
          child: Text(l10n.languageEnglishOption),
        ),
      ],
      onChanged: (locale) =>
          ref.read(localeOverrideProvider.notifier).setLocale(locale),
    );
  }
}

class _ThemeModePicker extends ConsumerWidget {
  const _ThemeModePicker({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(
            value: ThemeMode.system,
            label: Text(l10n.themeSystemOption),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            label: Text(l10n.themeLightOption),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text(l10n.themeDarkOption),
          ),
        ],
        selected: {current},
        onSelectionChanged: (selection) =>
            ref.read(themeModeProvider.notifier).setThemeMode(selection.first),
      ),
    );
  }
}

class _NotificationsToggle extends ConsumerWidget {
  const _NotificationsToggle({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationsEnabledProvider);

    return SwitchListTile(
      title: Text(l10n.settingsNotificationsToggleLabel),
      subtitle: Text(l10n.settingsNotificationsToggleHint),
      value: enabled,
      onChanged: (value) =>
          ref.read(notificationsEnabledProvider.notifier).setEnabled(value),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale_provider.dart';
import '../../../core/notification_capabilities.dart';
import '../../../core/notifications_provider.dart';
import '../../../core/theme_provider.dart';
import '../../../core/crisis_mode_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../downloads/presentation/download_folder_card.dart';
import '../../knowledge/application/article_viewer_choice.dart';
import 'article_viewer_card.dart';
import 'portable_data_card.dart';
import '../../inventory/presentation/expiry_reminders_card.dart';
import '../../inventory/presentation/charge_reminder_card.dart';
import '../../maps/presentation/offline_map_card.dart';
import '../../sharing/presentation/shared_folder_card.dart';
import '../../transfer/presentation/transfer_card.dart';
import 'app_lock_card.dart';
import 'backup_card.dart';
import 'local_encryption_card.dart';
import 'reset_card.dart';
import 'version_info_card.dart';
import 'warning_readiness_card.dart';
import 'followed_places_screen.dart';
import 'error_log_card.dart';
import '../../../core/adaptive_columns.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.profile});

  final HouseholdProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      // In columns on a wide window (#47), like the pages behind them.
      body: AdaptiveColumns(
        padding: const EdgeInsets.all(16),
        columnWidth: 420,
        spacing: 12,
        blocks: [
          _CategoryTile(
            icon: Icons.notifications_active_outlined,
            title: l10n.settingsCategoryWarnings,
            subtitle: l10n.settingsCategoryWarningsBody,
            onTap: () => _open(
              context,
              (l10n) => l10n.settingsCategoryWarnings,
              (l10n) => [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(l10n.followedPlacesOpen),
                    subtitle: Text(l10n.followedPlacesIntro),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FollowedPlacesScreen(profile: profile),
                      ),
                    ),
                  ),
                ),
                Card(child: _NotificationsToggle(l10n: l10n)),
                WarningReadinessCard(
                  profile: profile,
                  l10n: l10n,
                  onManagePlaces: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FollowedPlacesScreen(profile: profile),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _CategoryTile(
            icon: Icons.schedule_outlined,
            title: l10n.settingsCategoryReminders,
            subtitle: l10n.settingsCategoryRemindersBody,
            onTap: () => _open(
              context,
              (l10n) => l10n.settingsCategoryReminders,
              (l10n) => [
                if (supportsScheduledNotifications) ...[
                  ChargeReminderCard(l10n: l10n),
                  ExpiryRemindersCard(l10n: l10n),
                ] else
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(l10n.settingsScheduledRemindersUnsupported),
                    ),
                  ),
              ],
            ),
          ),
          _CategoryTile(
            icon: Icons.palette_outlined,
            title: l10n.settingsCategoryAppearance,
            subtitle: l10n.settingsCategoryAppearanceBody,
            onTap: () => _open(
              context,
              (l10n) => l10n.settingsCategoryAppearance,
              (l10n) => [
                Card(
                  child: ListTile(
                    title: Text(l10n.languageLabel),
                    trailing: _LanguagePicker(l10n: l10n),
                  ),
                ),
                Card(child: _ThemeModePicker(l10n: l10n)),
                Card(child: _CrisisModeToggle(l10n: l10n)),
              ],
            ),
          ),
          _CategoryTile(
            icon: Icons.security_outlined,
            title: l10n.settingsCategoryData,
            subtitle: l10n.settingsCategoryDataBody,
            onTap: () => _open(
              context,
              (l10n) => l10n.settingsCategoryData,
              (l10n) => [
                AppLockCard(l10n: l10n),
                SharedFolderCard(profile: profile, l10n: l10n),
                TransferCard(householdId: profile.id, l10n: l10n),
                BackupCard(householdId: profile.id, l10n: l10n),
                LocalEncryptionCard(householdId: profile.id, l10n: l10n),
                ResetCard(profile: profile, l10n: l10n),
              ],
            ),
          ),
          _CategoryTile(
            icon: Icons.offline_pin_outlined,
            title: l10n.settingsCategoryOffline,
            subtitle: l10n.settingsCategoryOfflineBody,
            onTap: () => _open(
              context,
              (l10n) => l10n.settingsCategoryOffline,
              (l10n) => [
                OfflineMapCard(l10n: l10n),
                if (offersArticleViewerChoice) ArticleViewerCard(l10n: l10n),
                DownloadFolderCard(l10n: l10n),
                PortableDataCard(l10n: l10n),
              ],
            ),
          ),
          _CategoryTile(
            icon: Icons.info_outline,
            title: l10n.settingsCategoryAbout,
            subtitle: l10n.settingsCategoryAboutBody,
            onTap: () => _open(
              context,
              (l10n) => l10n.settingsCategoryAbout,
              (l10n) => const [
                VersionInfoCard(),
                ErrorLogCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(
    BuildContext context,
    String Function(AppLocalizations l10n) title,
    List<Widget> Function(AppLocalizations l10n) children,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _SettingsCategoryScreen(title: title, children: children),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

/// A category, built fresh on every frame.
///
/// It used to be handed a finished list of widgets, made with the
/// `l10n` of the moment the tile was tapped. The language picker lives on
/// one of these pages: switching to English there left the page one was
/// looking at in German until it was popped, which reads exactly like the
/// setting did not work.
class _SettingsCategoryScreen extends StatelessWidget {
  const _SettingsCategoryScreen({required this.title, required this.children});

  final String Function(AppLocalizations l10n) title;
  final List<Widget> Function(AppLocalizations l10n) children;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = children(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(title(l10n))),
      // Each card is a block: on a wide window they share the width
      // instead of one stretched column with nothing beside it (#47).
      body: AdaptiveColumns(
        padding: const EdgeInsets.all(16),
        spacing: 12,
        blocks: items,
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
        DropdownMenuItem(
          value: const Locale('es'),
          child: Text(l10n.languageSpanishOption),
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

class _CrisisModeToggle extends ConsumerWidget {
  const _CrisisModeToggle({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(crisisModeProvider);
    return SwitchListTile(
      secondary: const Icon(Icons.emergency_outlined),
      title: Text(l10n.settingsCrisisModeTitle),
      subtitle: Text(l10n.settingsCrisisModeHint),
      value: enabled,
      onChanged: (value) =>
          ref.read(crisisModeProvider.notifier).setEnabled(value),
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

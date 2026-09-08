import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/geolocation_service.dart';
import '../../../core/location_capabilities.dart';
import '../../../core/locale_provider.dart';
import '../../../core/notification_capabilities.dart';
import '../../../core/notifications_provider.dart';
import '../../../core/theme_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../model/household_profile.dart';
import '../../household/application/german_states.dart';
import '../../household/application/household_providers.dart';
import '../../household/application/warning_feed_countries.dart';
import '../../downloads/presentation/download_folder_card.dart';
import '../../inventory/presentation/expiry_reminders_card.dart';
import '../../maps/presentation/offline_map_card.dart';
import '../../sharing/presentation/shared_folder_card.dart';
import '../../warnings/application/warning_region_filter.dart';

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
          _MyRegionCard(profile: profile, l10n: l10n),
          const SizedBox(height: 24),
          Text(
            l10n.settingsAdditionalRegionsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _AdditionalRegionsCard(profile: profile, l10n: l10n),
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

/// The household's own country and region.
///
/// Every "is the caller the owner" check is gone: there is one user, on one
/// device, and nobody to ask permission from.
class _MyRegionCard extends StatelessWidget {
  const _MyRegionCard({required this.profile, required this.l10n});

  final HouseholdProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final country = warningFeedCountries.firstWhere(
      (c) => c.code == profile.countryCode,
      orElse: () => WarningFeedCountry(
        profile.countryCode,
        profile.countryCode,
        profile.countryCode,
      ),
    );
    final countryName = Localizations.localeOf(context).languageCode == 'de'
        ? country.nameDe
        : country.nameEn;

    return Card(
      child: ListTile(
        title: Text(countryName),
        subtitle: Text(profile.regionKey ?? l10n.settingsNoRegionSet),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: l10n.csvImportEditRowTooltip,
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) => _EditRegionDialog(profile: profile),
          ),
        ),
      ),
    );
  }
}

class _EditRegionDialog extends ConsumerStatefulWidget {
  const _EditRegionDialog({required this.profile});

  final HouseholdProfile profile;

  @override
  ConsumerState<_EditRegionDialog> createState() => _EditRegionDialogState();
}

class _EditRegionDialogState extends ConsumerState<_EditRegionDialog> {
  late final TextEditingController _regionKeyController = TextEditingController(
    text: widget.profile.regionKey ?? '',
  );
  late String _countryCode = widget.profile.countryCode;
  @override
  void dispose() {
    _regionKeyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final region = _regionKeyController.text.trim();
    await ref
        .read(householdProfileProvider.notifier)
        .save(
          widget.profile.copyWith(
            countryCode: _countryCode,
            regionKey: region.isEmpty ? null : region,
            clearRegionKey: region.isEmpty,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.settingsMyRegionTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _countryCode,
              decoration: InputDecoration(labelText: l10n.countryLabel),
              items: [
                for (final country in warningFeedCountries)
                  DropdownMenuItem(
                    value: country.code,
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'de'
                          ? country.nameDe
                          : country.nameEn,
                    ),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _countryCode = value ?? _countryCode),
            ),
            if (_countryCode == 'DE') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _regionKeyController,
                decoration: InputDecoration(
                  labelText: l10n.regionKeyLabel,
                  helperText: l10n.regionKeyHelper,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }
}

/// Regions followed beyond the household's own.
class _AdditionalRegionsCard extends ConsumerWidget {
  const _AdditionalRegionsCard({required this.profile, required this.l10n});

  final HouseholdProfile profile;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          if (profile.extraRegions.isEmpty)
            ListTile(subtitle: Text(l10n.settingsNoAdditionalRegions))
          else
            for (final region in profile.extraRegions)
              ListTile(
                leading: Icon(
                  region.kind == WarningRegionKind.kreis
                      ? Icons.location_city
                      : Icons.map_outlined,
                ),
                title: Text(_regionTitle(region)),
                subtitle: Text(
                  region.kind == WarningRegionKind.kreis
                      ? l10n.settingsRegionTypeKreis
                      : l10n.settingsRegionTypeBundesland,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.csvImportRemoveRowTooltip,
                  onPressed: () => ref
                      .read(householdProfileProvider.notifier)
                      .removeRegion(region),
                ),
              ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => const _AddRegionDialog(),
                ),
                icon: const Icon(Icons.add),
                label: Text(l10n.settingsAddRegionButton),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "NI" is what gets stored and what the BBK feed says; it is not what
/// anyone calls the place they live.
String _regionTitle(WarningRegion region) {
  if (region.kind == WarningRegionKind.kreis) return region.value;
  return germanStateByBbkCode(region.value)?.nameDe ?? region.value;
}

class _AddRegionDialog extends ConsumerStatefulWidget {
  const _AddRegionDialog();

  @override
  ConsumerState<_AddRegionDialog> createState() => _AddRegionDialogState();
}

class _AddRegionDialogState extends ConsumerState<_AddRegionDialog> {
  final _kreisController = TextEditingController();
  WarningRegionKind _kind = WarningRegionKind.kreis;

  /// Picked from a list rather than typed. There are sixteen of them and
  /// what gets stored is a two-letter code nobody knows by heart — asking
  /// for it in a text field only ever produced a rejected form.
  GermanState? _state;

  String? _error;
  bool _locating = false;

  @override
  void dispose() {
    _kreisController.dispose();
    super.dispose();
  }

  Future<void> _add(AppLocalizations l10n) async {
    final WarningRegion region;

    switch (_kind) {
      case WarningRegionKind.kreis:
        final value = _kreisController.text.trim();
        // A Kreisschlüssel is exactly five digits; anything else silently
        // matches nothing, which looks like the feature being broken
        // rather than the input being wrong.
        if (!RegExp(r'^\d{5}$').hasMatch(value)) {
          setState(() => _error = l10n.settingsKreisSchluesselInvalid);
          return;
        }
        region = WarningRegion(kind: _kind, value: value);

      case WarningRegionKind.bundesland:
        final state = _state;
        if (state == null) {
          setState(() => _error = l10n.settingsBundeslandRequired);
          return;
        }
        region = WarningRegion(kind: _kind, value: state.bbkCode);
    }

    await ref.read(householdProfileProvider.notifier).addRegion(region);
    if (mounted) Navigator.of(context).pop();
  }

  /// Fills in the Bundesland the device is currently in. Kreis-level
  /// precision is not available this way — Nominatim answers with a state
  /// name, which is what the original server-side version used too.
  Future<void> _useLocation(AppLocalizations l10n) async {
    setState(() {
      _locating = true;
      _error = null;
    });

    try {
      final state = await GeolocationService().determineBundesland();
      if (!mounted) return;
      setState(() {
        _locating = false;
        if (state == null) {
          _error = l10n.settingsLocationNoMatchMessage;
        } else {
          _kind = WarningRegionKind.bundesland;
          _state = state;
        }
      });
    } on LocationUnavailableException catch (refusal) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _error = switch (refusal.reason) {
          LocationRefusal.servicesOff => l10n.settingsLocationServicesOff,
          LocationRefusal.deniedForever => l10n.settingsLocationDeniedForever,
          LocationRefusal.denied => l10n.settingsLocationDenied,
          LocationRefusal.unavailable => l10n.settingsLocationUnavailable(
            refusal.detail ?? '',
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.settingsAddRegionDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<WarningRegionKind>(
            segments: [
              ButtonSegment(
                value: WarningRegionKind.kreis,
                label: Text(l10n.settingsRegionTypeKreis),
              ),
              ButtonSegment(
                value: WarningRegionKind.bundesland,
                label: Text(l10n.settingsRegionTypeBundesland),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (selection) => setState(() {
              _kind = selection.first;
              // The old error belongs to the other kind of input.
              _error = null;
            }),
          ),
          const SizedBox(height: 16),
          if (_kind == WarningRegionKind.kreis)
            TextField(
              controller: _kreisController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.settingsKreisSchluesselLabel,
                helperText: l10n.settingsKreisSchluesselHelper,
                errorText: _error,
              ),
            )
          else
            DropdownButtonFormField<GermanState>(
              // A FormField reads `initialValue` once and never again, so
              // the state the location button finds would not show up
              // without rebuilding the field around it.
              key: ValueKey(_state?.bbkCode),
              initialValue: _state,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.settingsBundeslandLabel,
                errorText: _error,
              ),
              items: [
                for (final state in germanStates)
                  DropdownMenuItem(value: state, child: Text(state.nameDe)),
              ],
              onChanged: (value) => setState(() {
                _state = value;
                _error = null;
              }),
            ),
          // Linux has no location implementation at all, so the button
          // would only ever produce an error.
          if (supportsDeviceLocation) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _locating ? null : () => _useLocation(l10n),
                icon: const Icon(Icons.my_location),
                label: Text(l10n.settingsUseLocationButton),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => _add(l10n),
          child: Text(l10n.settingsAddRegionButton),
        ),
      ],
    );
  }
}

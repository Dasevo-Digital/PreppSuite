import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart';

import '../../../core/geolocation_service.dart';
import '../../../core/locale_provider.dart';
import '../../../core/notifications_provider.dart';
import '../../../core/theme_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../main.dart';
import '../../household/application/german_states.dart';
import '../../household/application/household_exception_l10n.dart';
import '../../household/application/household_providers.dart';
import '../../household/application/warning_feed_countries.dart';
import '../../inventory/application/expiry_reminder_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.membership});

  final HouseholdMembershipInfo membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isOwner = membership.member.role == HouseholdRole.owner;
    final household = membership.household;

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
          _MyRegionCard(household: household, isOwner: isOwner, l10n: l10n),
          const SizedBox(height: 24),
          Text(
            l10n.settingsAdditionalRegionsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _AdditionalRegionsCard(
            householdId: household.id!,
            isOwner: isOwner,
            l10n: l10n,
          ),
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
          Card(child: _ExpiryRemindersCard(l10n: l10n)),
          const SizedBox(height: 24),
          Text(
            l10n.serverAddressLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(l10n.serverAddressLabel),
              subtitle: SelectableText(serverUrl),
            ),
          ),
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

/// Lead-time picker for expiry reminders. Deliberately shows the chips
/// even when notifications are off — hiding them would leave no hint that
/// the feature exists — but says plainly that nothing will be scheduled
/// until the switch above is on.
class _ExpiryRemindersCard extends ConsumerWidget {
  const _ExpiryRemindersCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(expiryLeadDaysProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    final hint = !notificationsEnabled
        ? l10n.settingsExpiryRemindersDisabledHint
        : selected.isEmpty
        ? l10n.settingsExpiryRemindersNoneHint
        : l10n.settingsExpiryRemindersHint;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final days in selectableExpiryLeadDays)
                FilterChip(
                  label: Text(
                    days == 1
                        ? l10n.expiryLeadDayOneLabel
                        : l10n.expiryLeadDaysLabel(days),
                  ),
                  selected: selected.contains(days),
                  onSelected: (_) =>
                      ref.read(expiryLeadDaysProvider.notifier).toggle(days),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyRegionCard extends StatelessWidget {
  const _MyRegionCard({
    required this.household,
    required this.isOwner,
    required this.l10n,
  });

  final Household household;
  final bool isOwner;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final country = warningFeedCountries.firstWhere(
      (c) => c.code == household.countryCode,
      orElse: () => WarningFeedCountry(
        household.countryCode,
        household.countryCode,
        household.countryCode,
      ),
    );
    final countryName = Localizations.localeOf(context).languageCode == 'de'
        ? country.nameDe
        : country.nameEn;

    return Card(
      child: ListTile(
        title: Text(countryName),
        subtitle: Text(household.regionKey ?? l10n.settingsNoRegionSet),
        trailing: isOwner
            ? IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.csvImportEditRowTooltip,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => _EditRegionDialog(household: household),
                ),
              )
            : null,
      ),
    );
  }
}

class _EditRegionDialog extends ConsumerStatefulWidget {
  const _EditRegionDialog({required this.household});

  final Household household;

  @override
  ConsumerState<_EditRegionDialog> createState() => _EditRegionDialogState();
}

class _EditRegionDialogState extends ConsumerState<_EditRegionDialog> {
  late final TextEditingController _regionKeyController;
  late String _countryCode;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _countryCode = widget.household.countryCode;
    _regionKeyController = TextEditingController(
      text: widget.household.regionKey ?? '',
    );
  }

  @override
  void dispose() {
    _regionKeyController.dispose();
    super.dispose();
  }

  Future<void> _showRegionKeyExplanation(AppLocalizations l10n) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.regionKeyExplanationTitle),
        content: SingleChildScrollView(
          child: Text(l10n.regionKeyExplanationBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.regionKeyExplanationClose),
          ),
        ],
      ),
    );
  }

  Future<void> _save(AppLocalizations l10n) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await client.household.updateRegion(
        widget.household.id!,
        countryCode: _countryCode,
        regionKey: _regionKeyController.text.trim().isEmpty
            ? null
            : _regionKeyController.text.trim(),
      );
      ref.invalidate(myHouseholdProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      setState(() => _errorMessage = localizeHouseholdError(l10n, error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.settingsMyRegionTitle),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
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
                    setState(() => _countryCode = value ?? 'DE'),
              ),
              if (_countryCode == 'DE') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _regionKeyController,
                  decoration: InputDecoration(
                    labelText: l10n.regionKeyLabel,
                    helperText: l10n.regionKeyHelper,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: l10n.regionKeyExplanationTooltip,
                      onPressed: () => _showRegionKeyExplanation(l10n),
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : () => _save(l10n),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.saveButton),
        ),
      ],
    );
  }
}

class _AdditionalRegionsCard extends ConsumerWidget {
  const _AdditionalRegionsCard({
    required this.householdId,
    required this.isOwner,
    required this.l10n,
  });

  final UuidValue householdId;
  final bool isOwner;
  final AppLocalizations l10n;

  Future<void> _removeRegion(
    WidgetRef ref,
    WarningRegionSubscription subscription,
  ) async {
    await client.household.removeWarningRegion(householdId, subscription.id!);
    ref.invalidate(householdWarningRegionsProvider(householdId));
  }

  Future<void> _useLocation(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final state = await GeolocationService().determineBundesland();
      if (state == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsLocationNoMatchMessage)),
        );
        return;
      }
      await client.household.addWarningRegion(
        householdId,
        kind: WarningRegionKind.bundesland,
        value: state.bbkCode,
        label: state.nameDe,
      );
      ref.invalidate(householdWarningRegionsProvider(householdId));
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.settingsLocationSuccessMessage(state.nameDe)),
        ),
      );
    } on LocationUnavailableException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsLocationErrorMessage('$error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionsAsync = ref.watch(
      householdWarningRegionsProvider(householdId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: regionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.errorGeneric(error.toString())),
            ),
            data: (regions) => regions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.settingsNoAdditionalRegions),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < regions.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          title: Text(regions[i].label),
                          trailing: isOwner
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: l10n.csvImportRemoveRowTooltip,
                                  onPressed: () =>
                                      _removeRegion(ref, regions[i]),
                                )
                              : null,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        if (isOwner) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => _AddRegionDialog(householdId: householdId),
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.settingsAddRegionButton),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _useLocation(context, ref),
            icon: const Icon(Icons.my_location),
            label: Text(l10n.settingsUseLocationButton),
          ),
        ],
      ],
    );
  }
}

class _AddRegionDialog extends ConsumerStatefulWidget {
  const _AddRegionDialog({required this.householdId});

  final UuidValue householdId;

  @override
  ConsumerState<_AddRegionDialog> createState() => _AddRegionDialogState();
}

class _AddRegionDialogState extends ConsumerState<_AddRegionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _kreisController = TextEditingController();
  final _labelController = TextEditingController();
  WarningRegionKind _kind = WarningRegionKind.bundesland;
  GermanState _selectedState = germanStates.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _kreisController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_kind == WarningRegionKind.kreis &&
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await client.household.addWarningRegion(
        widget.householdId,
        kind: _kind,
        value: _kind == WarningRegionKind.kreis
            ? _kreisController.text.trim()
            : _selectedState.bbkCode,
        label: _kind == WarningRegionKind.kreis
            ? _labelController.text.trim()
            : _selectedState.nameDe,
      );
      ref.invalidate(householdWarningRegionsProvider(widget.householdId));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.settingsAddRegionDialogTitle),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<WarningRegionKind>(
                segments: [
                  ButtonSegment(
                    value: WarningRegionKind.bundesland,
                    label: Text(l10n.settingsRegionTypeBundesland),
                  ),
                  ButtonSegment(
                    value: WarningRegionKind.kreis,
                    label: Text(l10n.settingsRegionTypeKreis),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) =>
                    setState(() => _kind = selection.first),
              ),
              const SizedBox(height: 16),
              if (_kind == WarningRegionKind.bundesland)
                DropdownButtonFormField<GermanState>(
                  initialValue: _selectedState,
                  decoration: InputDecoration(
                    labelText: l10n.settingsRegionTypeBundesland,
                  ),
                  items: [
                    for (final state in germanStates)
                      DropdownMenuItem(value: state, child: Text(state.nameDe)),
                  ],
                  onChanged: (value) => setState(
                    () => _selectedState = value ?? germanStates.first,
                  ),
                )
              else ...[
                TextFormField(
                  controller: _kreisController,
                  decoration: InputDecoration(
                    labelText: l10n.settingsKreisSchluesselLabel,
                  ),
                  validator: (value) =>
                      (value == null || value.trim().length != 5)
                      ? l10n.settingsKreisSchluesselInvalid
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: l10n.settingsRegionLabelLabel,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.fieldRequired
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _save,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.saveButton),
        ),
      ],
    );
  }
}

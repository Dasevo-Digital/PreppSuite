import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/crisis_mode_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../energy/application/energy_store.dart';
import '../../energy/application/outage_store.dart';
import '../../warnings/application/warning_providers.dart';
import '../../household/application/card_species.dart';
import '../../household/application/emergency_plan_report.dart';
import '../../household/application/household_member_controller.dart';
import '../../household/application/household_plan_controller.dart';
import '../../household/application/household_providers.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/application/supply_calculator.dart';
import '../../inventory/presentation/prepper_recipes_screen.dart';
import '../../kids_comic/presentation/kids_comic_screen.dart';
import '../application/autonomy_overview.dart';
import '../application/current_situation.dart';
import '../application/emergency_folder_report.dart';
import '../application/preparedness_hub_store.dart';
import 'resilience_plan_panel.dart';
import 'scenario_screen.dart';

/// Private, offline planning tools. The screen intentionally has no map or
/// cloud action: routes and sensitive document locations stay on this device.
class PreparednessHubScreen extends ConsumerStatefulWidget {
  const PreparednessHubScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<PreparednessHubScreen> createState() =>
      _PreparednessHubScreenState();
}

class _PreparednessHubScreenState extends ConsumerState<PreparednessHubScreen> {
  static const _store = PreparednessHubStore();

  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  static const _energyStore = EnergyPlanStore();
  static const _outageStore = OutageClockStore();
  PreparednessHubData _data = const PreparednessHubData();
  // The stored energy is kept by its own screen, not here. This screen
  // only divides it, the same as it does the inventory.
  EnergyPlan _energy = const EnergyPlan();
  OutageClock? _outage;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final data = await _store.load();
    final energy = await _energyStore.load();
    final outage = await _outageStore.load();
    if (mounted) {
      setState(() {
        _data = data;
        _energy = energy;
        _outage = outage;
        _loading = false;
      });
    }
  }

  /// What is actually going on, as far as the records say.
  CurrentSituation _situation() => currentSituation(
    warnings: ref.watch(activeWarningsProvider).value ?? const [],
    profile: ref.watch(householdProfileProvider).value,
    outage: _outage,
  );

  /// What the household is on its own for, resource by resource.
  ///
  /// Four of the five come out of records the app already holds. This
  /// screen used to ask for all five by hand, beside an inventory that
  /// answered four of them — the same second, silently disagreeing
  /// number the supply calculator had and removed.
  List<AutonomyReach> _reaches() {
    final items =
        ref.watch(inventoryItemsProvider(widget.householdId)).value ?? const [];
    final profile = ref.watch(householdProfileProvider).value;
    return autonomyReaches(
      items: items,
      household: SupplyHousehold(
        adults: profile?.personCount ?? 1,
        children: profile?.children ?? 0,
        dogs: profile?.dogs ?? 0,
        cats: profile?.cats ?? 0,
      ),
      energy: _energy,
      entered: _data.autonomy,
    );
  }

  Future<void> _change(PreparednessHubData value) async {
    setState(() => _data = value);
    await _store.save(value);
  }

  String _date(DateTime? value) => value == null
      ? _l10n.hubNotCheckedYet
      : MaterialLocalizations.of(context).formatMediumDate(value);

  @override
  Widget build(BuildContext context) {
    final reaches = _reaches();
    final situation = _situation();
    return Scaffold(
      appBar: AppBar(title: Text(_l10n.hubTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!situation.isQuiet) ...[
                  _situationCard(situation),
                  const SizedBox(height: 16),
                ],
                Text(
                  _l10n.hubPrivacyNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _section(
                  _l10n.hubAutonomyTitle,
                  Icons.monitor_heart_outlined,
                  _l10n.hubAutonomyHint,
                  _autonomy(reaches),
                ),
                _section(
                  _l10n.hubWaterHygieneTitle,
                  Icons.water_drop_outlined,
                  _l10n.hubWaterHygieneHint,
                  _planNote(
                    note: _data.waterHygiene,
                    label: _l10n.hubWaterHygieneLabel,
                    hint: _l10n.hubWaterHygieneTemplate,
                    onSave: (value) =>
                        _change(_data.copyWith(waterHygiene: value)),
                  ),
                ),
                _section(
                  _l10n.hubPowerOutageTitle,
                  Icons.power_outlined,
                  _l10n.hubPowerOutageHint,
                  _planNote(
                    note: _data.powerOutage,
                    label: _l10n.hubPowerOutageTitle,
                    hint: _l10n.hubPowerOutageTemplate,
                    onSave: (value) =>
                        _change(_data.copyWith(powerOutage: value)),
                  ),
                ),
                _section(
                  _l10n.hubCookingTitle,
                  Icons.soup_kitchen_outlined,
                  _l10n.hubCookingHint,
                  _cookingPlan(),
                ),
                _section(
                  _l10n.hubRedundancyTitle,
                  Icons.account_tree_outlined,
                  _l10n.hubRedundancyHint,
                  _planNote(
                    note: _data.redundancy,
                    label: _l10n.hubRedundancyTitle,
                    hint: _l10n.hubRedundancyTemplate,
                    onSave: (value) =>
                        _change(_data.copyWith(redundancy: value)),
                  ),
                ),
                _section(
                  _l10n.hubClimateRoomTitle,
                  Icons.thermostat_outlined,
                  _l10n.hubClimateRoomHint,
                  _planNote(
                    note: _data.climateRoom,
                    label: _l10n.hubClimateRoomLabel,
                    hint: _l10n.hubClimateRoomTemplate,
                    onSave: (value) =>
                        _change(_data.copyWith(climateRoom: value)),
                  ),
                ),
                _section(
                  _l10n.hubRadioTitle,
                  Icons.radio_outlined,
                  _l10n.hubRadioHint,
                  _radioPlan(),
                ),
                _section(
                  _l10n.hubFolderTitle,
                  Icons.folder_copy_outlined,
                  _l10n.hubFolderHint,
                  _folder(reaches),
                ),
                _section(
                  _l10n.hubCommunicationTitle,
                  Icons.forum_outlined,
                  _l10n.hubCommunicationHint,
                  _planNote(
                    note: _data.communication,
                    label: _l10n.hubCommunicationTitle,
                    hint: _l10n.hubCommunicationTemplate,
                    onSave: (value) =>
                        _change(_data.copyWith(communication: value)),
                    templates: [
                      _l10n.hubStatusSafe,
                      _l10n.hubStatusHelp,
                    ],
                  ),
                ),
                _section(
                  _l10n.hubSupportTitle,
                  Icons.accessible_forward_outlined,
                  _l10n.hubSupportHint,
                  _planNote(
                    note: _data.support,
                    label: _l10n.hubSupportTitle,
                    hint: _l10n.hubSupportTemplate,
                    onSave: (value) => _change(_data.copyWith(support: value)),
                  ),
                ),
                _section(
                  _l10n.hubPetsTitle,
                  Icons.pets_outlined,
                  _l10n.hubPetsHint,
                  _planNote(
                    note: _data.pets,
                    label: _l10n.hubPetsTitle,
                    hint: _l10n.hubPetsTemplate,
                    onSave: (value) => _change(_data.copyWith(pets: value)),
                  ),
                ),
                _section(
                  _l10n.hubMobilityTitle,
                  Icons.directions_car_outlined,
                  _l10n.hubMobilityHint,
                  _planNote(
                    note: _data.mobility,
                    label: _l10n.hubMobilityLabel,
                    hint: _l10n.hubMobilityTemplate,
                    onSave: (value) => _change(_data.copyWith(mobility: value)),
                  ),
                ),
                _section(
                  _l10n.hubUtilitiesTitle,
                  Icons.power_off_outlined,
                  _l10n.hubUtilitiesHint,
                  _planNote(
                    note: _data.utilities,
                    label: _l10n.hubUtilitiesLabel,
                    hint: _l10n.hubUtilitiesTemplate,
                    onSave: (value) =>
                        _change(_data.copyWith(utilities: value)),
                  ),
                ),
                _section(
                  _l10n.hubMaintenanceTitle,
                  Icons.build_outlined,
                  _l10n.hubMaintenanceHint,
                  _maintenance(),
                ),
                _section(
                  _l10n.hubEvacuationTitle,
                  Icons.route_outlined,
                  _l10n.hubEvacuationHint,
                  _evacuation(),
                ),
                _section(
                  _l10n.hubEventsTitle,
                  Icons.history_edu_outlined,
                  _l10n.hubEventsHint,
                  _events(),
                ),
                _section(
                  _l10n.hubActionsTitle,
                  Icons.timer_outlined,
                  _l10n.hubActionsHint,
                  _actionCards(),
                ),
                _section(
                  _l10n.hubCrisisTitle,
                  Icons.visibility_outlined,
                  _l10n.hubCrisisHint,
                  _crisisTools(),
                ),
                _section(
                  _l10n.hubComicTitle,
                  Icons.auto_stories_outlined,
                  _l10n.hubComicHint,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const KidsComicScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(_l10n.hubComicOpen),
                    ),
                  ),
                ),
                _section(
                  _l10n.hubAnalogTitle,
                  Icons.print_outlined,
                  _l10n.hubAnalogHint,
                  _planNote(
                    note: _data.analogFallback,
                    label: _l10n.hubAnalogTitle,
                    hint: _l10n.hubAnalogTemplate,
                    onSave: (value) =>
                        _change(_data.copyWith(analogFallback: value)),
                  ),
                ),
                _section(
                  _l10n.hubMutualAidTitle,
                  Icons.volunteer_activism_outlined,
                  _l10n.hubMutualAidHint,
                  _planNote(
                    note: _data.mutualAid,
                    label: _l10n.hubMutualAidLabel,
                    hint: _l10n.hubMutualAidTemplate,
                    onSave: (value) =>
                        _change(_data.copyWith(mutualAid: value)),
                  ),
                ),
                _section(
                  _l10n.hubPracticeTitle,
                  Icons.event_repeat_outlined,
                  _l10n.hubPracticeHint,
                  _planNote(
                    note: _data.practice,
                    label: _l10n.hubPracticeLabel,
                    hint: _l10n.hubPracticeTemplate,
                    onSave: (value) => _change(_data.copyWith(practice: value)),
                  ),
                ),
                _section(
                  _l10n.hubResilienceTitle,
                  Icons.hub_outlined,
                  _l10n.hubResilienceHint,
                  ResiliencePlanPanel(
                    plan: _data.resilience,
                    maintenance: _data.maintenance,
                    onPlanChanged: (value) =>
                        _change(_data.copyWith(resilience: value)),
                    onMaintenanceIntervalChanged: (task, everyDays) => _change(
                      _data.copyWith(
                        resilience: _data.resilience.copyWith(
                          maintenanceEveryDays: {
                            ..._data.resilience.maintenanceEveryDays,
                            task: everyDays,
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// What is happening, at the top of the page where the plans are.
  ///
  /// The two things the app can actually know: a severe warning over this
  /// household's own region, and a blackout somebody started the clock
  /// on. Both were already in the app; neither reached this screen, where
  /// "crisis mode" meant a quarter more text and nothing else.
  ///
  /// It offers, it does not act. The larger display stays a choice — a
  /// screen that rearranges itself because a feed said so is one nobody
  /// can rely on — and the log button opens the ordinary dialog with the
  /// details filled in, so what is written down is still somebody's own
  /// words.
  Widget _situationCard(CurrentSituation situation) {
    final theme = Theme.of(context);
    final warning = situation.leadWarning;
    final hours = outageHours(situation.outage, DateTime.now());
    final onColor = theme.colorScheme.onErrorContainer;
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: onColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _l10n.hubSituationTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: onColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (warning != null)
              Text(warning.headline, style: TextStyle(color: onColor)),
            if (situation.warnings.length > 1)
              Text(
                _l10n.hubSituationMoreWarnings(situation.warnings.length - 1),
                style: TextStyle(color: onColor),
              ),
            if (hours != null)
              Text(
                _l10n.hubSituationOutage(hours),
                style: TextStyle(color: onColor),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // The app-wide mode, not one for this page: in a crisis
                // the first aid steps and the emergency numbers need the
                // larger display more than the plans do. Still an offer —
                // the app reports, the household decides.
                if (!ref.watch(crisisModeProvider))
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(crisisModeProvider.notifier).setEnabled(true),
                    icon: const Icon(Icons.format_size),
                    label: Text(_l10n.hubSituationCrisisMode),
                  ),
                FilledButton.icon(
                  onPressed: () => _addEvent(
                    kindPrefill:
                        warning?.eventType ?? _l10n.hubSituationOutageKind,
                    notePrefill: warning?.headline,
                  ),
                  icon: const Icon(Icons.edit_note),
                  label: Text(_l10n.hubSituationLog),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    String title,
    IconData icon,
    String description,
    Widget content,
  ) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 12),
          content,
        ],
      ),
    ),
  );

  Widget _autonomy(List<AutonomyReach> reaches) {
    final limiting = limitingReach(reaches);
    final open = openQuestions(reaches);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A range that leaves a resource out is not this household's
        // range, so an unanswered question outranks the number.
        if (open.isNotEmpty) ...[
          Text(
            _l10n.hubAutonomyIncomplete(
              open.map((reach) => _resourceName(reach.resource)).join(', '),
            ),
            style: theme.textTheme.titleMedium,
          ),
          if (limiting != null)
            Text(
              _l10n.hubAutonomyKnownSoFar(
                limiting.days!,
                _resourceName(limiting.resource),
              ),
            ),
        ] else if (limiting != null)
          Text(
            _l10n.hubAutonomyRange(
              limiting.days!,
              _resourceName(limiting.resource),
            ),
            style: theme.textTheme.titleMedium,
          ),
        const SizedBox(height: 8),
        for (final reach in reaches)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              identical(reach, limiting)
                  ? Icons.priority_high
                  : reach.answered
                  ? Icons.check_circle_outline
                  : Icons.help_outline,
            ),
            title: Text(_resourceName(reach.resource)),
            subtitle: switch (_reachDetail(reach)) {
              final detail? => Text(detail),
              _ => null,
            },
            trailing: Text(
              switch (reach.days) {
                final days? => _l10n.hubAutonomyDays(days),
                _ => _l10n.hubAutonomyOpen,
              },
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _editAutonomy(reaches),
              icon: const Icon(Icons.edit_outlined),
              label: Text(_l10n.hubAutonomyAddByHand),
            ),
            // The same records, asked the other way round: not how long
            // they last, but what is missing for a given stretch (#149).
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ScenarioScreen(householdId: widget.householdId),
                ),
              ),
              icon: const Icon(Icons.calculate_outlined),
              label: Text(_l10n.scenarioOpen),
            ),
          ],
        ),
      ],
    );
  }

  String _actionTitle(_ActionTask task) => switch (task) {
    _ActionTask.now => _l10n.hubActionNowTitle,
    _ActionTask.twoDays => _l10n.hubActionTwoDaysTitle,
    _ActionTask.days => _l10n.hubActionDaysTitle,
  };

  String _actionBody(_ActionTask task) => switch (task) {
    _ActionTask.now => _l10n.hubActionNowBody,
    _ActionTask.twoDays => _l10n.hubActionTwoDaysBody,
    _ActionTask.days => _l10n.hubActionDaysBody,
  };

  String _taskTitle(_MaintenanceTask task) => switch (task) {
    _MaintenanceTask.batteries => _l10n.hubTaskBatteriesTitle,
    _MaintenanceTask.radio => _l10n.hubTaskRadioTitle,
    _MaintenanceTask.waterFilter => _l10n.hubTaskWaterFilterTitle,
    _MaintenanceTask.kit => _l10n.hubTaskKitTitle,
    _MaintenanceTask.medicine => _l10n.hubTaskMedicineTitle,
    _MaintenanceTask.extinguisher => _l10n.hubTaskExtinguisherTitle,
    _MaintenanceTask.vehicle => _l10n.hubTaskVehicleTitle,
  };

  String _taskHint(_MaintenanceTask task) => switch (task) {
    _MaintenanceTask.batteries => _l10n.hubTaskBatteriesHint,
    _MaintenanceTask.radio => _l10n.hubTaskRadioHint,
    _MaintenanceTask.waterFilter => _l10n.hubTaskWaterFilterHint,
    _MaintenanceTask.kit => _l10n.hubTaskKitHint,
    _MaintenanceTask.medicine => _l10n.hubTaskMedicineHint,
    _MaintenanceTask.extinguisher => _l10n.hubTaskExtinguisherHint,
    _MaintenanceTask.vehicle => _l10n.hubTaskVehicleHint,
  };

  String _resourceName(AutonomyResource resource) => switch (resource) {
    AutonomyResource.water => _l10n.hubResourceWater,
    AutonomyResource.food => _l10n.hubResourceFood,
    AutonomyResource.medicine => _l10n.hubResourceMedicine,
    AutonomyResource.energy => _l10n.hubResourceEnergy,
    AutonomyResource.hygiene => _l10n.hubResourceHygiene,
  };

  /// Why a figure is what it is — or why there is none.
  ///
  /// Never silent: a household that reads "8 Tage" has to be able to see
  /// whether that covers the crates of water in the cellar.
  String? _reachDetail(AutonomyReach reach) {
    final missed = reach.unmeasured > 0
        ? _l10n.hubAutonomyNotCounted(reach.unmeasured, _gapReason(reach))
        : null;
    return switch (reach.basis) {
      AutonomyBasis.stock => missed ?? _l10n.hubAutonomyFromStock,
      AutonomyBasis.entered => _l10n.hubAutonomyByHandWith(_gapReason(reach)),
      null => _gapReason(reach),
    };
  }

  String _gapReason(AutonomyReach reach) => switch (reach.gap) {
    AutonomyGap.onlyByHand => _l10n.hubGapOnlyByHand,
    AutonomyGap.nothingRecorded => switch (reach.resource) {
      AutonomyResource.energy => _l10n.hubGapNoEnergyPlan,
      _ => _l10n.hubGapNothingRecorded,
    },
    AutonomyGap.notDivisible => switch (reach.resource) {
      AutonomyResource.water => _l10n.hubGapNoLiters,
      AutonomyResource.food => _l10n.hubGapNoCalories,
      AutonomyResource.medicine => _l10n.hubGapNoDose,
      AutonomyResource.energy => _l10n.hubGapNoDraw,
      AutonomyResource.hygiene => _l10n.hubGapOnlyByHand,
    },
    null => _l10n.hubGapNoLiters,
  };

  /// Only what the records cannot answer.
  ///
  /// Water, food, medicines and energy are asked for here only while the
  /// inventory or the energy plan cannot divide them; hygiene always,
  /// because nothing in this app counts soap.
  Future<void> _editAutonomy(List<AutonomyReach> reaches) async {
    final snapshot = _data.autonomy;
    final byHand = [
      for (final reach in reaches)
        if (reach.basis != AutonomyBasis.stock) reach,
    ];
    final fields = {
      for (final reach in byHand)
        reach.resource: TextEditingController(
          text: '${_enteredFor(snapshot, reach.resource)}',
        ),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.hubAutonomyDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_l10n.hubAutonomyDialogHint),
              const SizedBox(height: 12),
              for (final reach in byHand)
                _daysField(
                  fields[reach.resource]!,
                  '${_resourceName(reach.resource)} (${_gapReason(reach)})',
                ),
            ],
          ),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved != true) return;
    int read(AutonomyResource resource) {
      final controller = fields[resource];
      if (controller == null) return _enteredFor(snapshot, resource);
      return (int.tryParse(controller.text.trim())?.clamp(0, 3650) ?? 0)
          .toInt();
    }

    await _change(
      _data.copyWith(
        autonomy: snapshot.copyWith(
          waterDays: read(AutonomyResource.water),
          foodDays: read(AutonomyResource.food),
          medicineDays: read(AutonomyResource.medicine),
          energyDays: read(AutonomyResource.energy),
          hygieneDays: read(AutonomyResource.hygiene),
        ),
      ),
    );
  }

  int _enteredFor(AutonomySnapshot snapshot, AutonomyResource resource) =>
      switch (resource) {
        AutonomyResource.water => snapshot.waterDays,
        AutonomyResource.food => snapshot.foodDays,
        AutonomyResource.medicine => snapshot.medicineDays,
        AutonomyResource.energy => snapshot.energyDays,
        AutonomyResource.hygiene => snapshot.hygieneDays,
      };

  Widget _daysField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: _l10n.hubAutonomyDaysField(label),
        ),
      );

  Widget _cookingPlan() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _planNote(
        note: _data.cooking,
        label: _l10n.hubCookingLabel,
        hint: _l10n.hubCookingTemplate,
        onSave: (value) => _change(_data.copyWith(cooking: value)),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PrepperRecipesScreen(householdId: widget.householdId),
          ),
        ),
        icon: const Icon(Icons.menu_book_outlined),
        label: Text(_l10n.hubCookingRecipes),
      ),
    ],
  );

  Widget _planNote({
    required PlanNote note,
    required String label,
    required String hint,
    required ValueChanged<PlanNote> onSave,
    List<String> templates = const [],
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(note.text.isEmpty ? _l10n.hubNoteEmpty : note.text),
      if (note.checkedAt != null) ...[
        const SizedBox(height: 4),
        Text(
          _l10n.hubNoteUpdated(_date(note.checkedAt)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _editPlanNote(
              title: label,
              current: note,
              hint: hint,
              onSave: onSave,
            ),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              note.text.isEmpty ? _l10n.hubNoteCreate : _l10n.hubNoteEdit,
            ),
          ),
          for (final template in templates)
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: template)),
              icon: const Icon(Icons.copy_outlined),
              label: Text(_l10n.hubNoteCopyTemplate),
            ),
        ],
      ),
    ],
  );

  Future<void> _editPlanNote({
    required String title,
    required PlanNote current,
    required String hint,
    required ValueChanged<PlanNote> onSave,
  }) async {
    final controller = TextEditingController(text: current.text);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 5,
          maxLines: 12,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved == true) onSave(current.update(controller.text.trim()));
  }

  Widget _actionCards() => Column(
    children: [
      for (final action in _ActionTask.values)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _data.actionDone.containsKey(action.id),
          title: Text(_actionTitle(action)),
          subtitle: Text(
            _data.actionDone[action.id] == null
                ? _actionBody(action)
                : _l10n.hubActionDone(_date(_data.actionDone[action.id])),
          ),
          onChanged: (value) {
            final updated = {..._data.actionDone};
            if (value == true) {
              updated[action.id] = DateTime.now();
            } else {
              updated.remove(action.id);
            }
            unawaited(_change(_data.copyWith(actionDone: updated)));
          },
        ),
    ],
  );

  Widget _crisisTools() => Column(
    children: [
      // The same switch as in the settings. There used to be a second
      // crisis mode here, for this page only, kept in the plan — which
      // the shared folder carries, so switching it on one device switched
      // it on every other.
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: ref.watch(crisisModeProvider),
        title: Text(_l10n.hubCrisisSwitch),
        subtitle: Text(
          _l10n.hubCrisisSwitchHint,
        ),
        onChanged: (value) =>
            ref.read(crisisModeProvider.notifier).setEnabled(value),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: _exportBriefing,
          icon: const Icon(Icons.print_outlined),
          label: Text(_l10n.hubBriefingButton),
        ),
      ),
    ],
  );

  Widget _radioPlan() => Column(
    children: [
      for (final plan in _data.radioPlans)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(plan.station),
          subtitle: Text(
            _l10n.hubRadioDetails(
              plan.band,
              plan.frequency,
              plan.receiver,
              plan.power,
              _date(plan.checkedAt),
            ),
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: _l10n.hubEntryRemove,
            onPressed: () => _change(
              _data.copyWith(
                radioPlans: [
                  for (final item in _data.radioPlans)
                    if (item.id != plan.id) item,
                ],
              ),
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _addRadio,
          icon: const Icon(Icons.add),
          label: Text(_l10n.hubRadioAdd),
        ),
      ),
    ],
  );

  Widget _folder(List<AutonomyReach> reaches) {
    final folder = _data.folder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: Text(_l10n.hubFolderLocation),
          subtitle: Text(
            folder.location.isEmpty ? _l10n.hubFolderNotSet : folder.location,
          ),
          trailing: const Icon(Icons.edit_outlined),
          onTap: _editFolderLocation,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: folder.copiesReady,
          title: Text(_l10n.hubFolderCopies),
          onChanged: (value) => _change(
            _data.copyWith(folder: folder.copyWith(copiesReady: value == true)),
          ),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: folder.takeWhenLeaving,
          title: Text(_l10n.hubFolderTakeAlong),
          onChanged: (value) => _change(
            _data.copyWith(
              folder: folder.copyWith(takeWhenLeaving: value == true),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _change(
              _data.copyWith(
                folder: folder.copyWith(lastChecked: DateTime.now()),
              ),
            ),
            icon: const Icon(Icons.verified_outlined),
            label: Text(
              folder.lastChecked == null
                  ? _l10n.hubFolderCheckedToday
                  : _l10n.hubFolderCheckedTodayWith(
                      _date(folder.lastChecked),
                    ),
            ),
          ),
        ),
        // The question above is "are the copies ready?". Until now the
        // app asked it and gave no help answering: the material was
        // spread over five separate exports on five separate screens.
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _exportFolder(reaches),
            icon: const Icon(Icons.folder_special_outlined),
            label: Text(_l10n.hubFolderReportButton),
          ),
        ),
      ],
    );
  }

  /// The folder, as one document.
  ///
  /// The emergency cards are asked about every time, never remembered —
  /// the same trade `EmergencyPlanReport` spells out: a printed card is
  /// the copy that still works when the phone is dead, and it is a loose
  /// sheet naming somebody's blood group and medication.
  Future<void> _exportFolder(List<AutonomyReach> reaches) async {
    final members =
        ref.read(householdMembersProvider(widget.householdId)).value ??
        const [];
    var withCards = false;
    if (members.isNotEmpty) {
      final answer = await _askAboutCards(members.length);
      if (answer == null) return;
      withCards = answer;
    }
    if (!mounted) return;
    final locale = _l10n.localeName;
    final plan = ref.read(householdPlanProvider(widget.householdId)).value;
    final profile = ref.read(householdProfileProvider).value;
    final l10n = _l10n;
    final autonomy = [
      for (final reach in reaches)
        (
          label: _resourceName(reach.resource),
          value: switch (reach.days) {
            final days? => l10n.hubAutonomyDays(days),
            _ => l10n.hubAutonomyOpen,
          },
        ),
    ];
    await Printing.layoutPdf(
      name: l10n.hubFolderReportFile,
      onLayout: (_) => const EmergencyFolderReport().build(
        householdName: profile?.name ?? '',
        plan: plan,
        members: withCards ? members : const [],
        hub: _data,
        autonomy: autonomy,
        strings: EmergencyFolderReportStrings(
          title: l10n.hubFolderReportTitle,
          generatedOn: l10n.pdfGeneratedOn(
            DateFormat.yMMMMd(locale).add_Hm().format(DateTime.now()),
          ),
          intro: l10n.hubFolderReportIntro,
          empty: l10n.emergencyPlanPdfEmpty,
          meetingPoints: l10n.emergencyPlanPdfMeetingPoints,
          contact: l10n.emergencyPlanPdfContact,
          contactPoint: l10n.householdPlanContactPoint,
          equipment: l10n.emergencyPlanPdfEquipment,
          notes: l10n.notesLabel,
          cards: l10n.emergencyPlanPdfCards,
          cardsWarning: l10n.emergencyPlanPdfCardsWarning,
          fields: EmergencyCardFieldStrings(
            birthYear: l10n.emergencyCardBirthYear,
            bloodType: l10n.emergencyCardBloodType,
            allergies: l10n.emergencyCardAllergies,
            medication: l10n.emergencyCardMedication,
            conditions: l10n.emergencyCardConditions,
            insurance: l10n.emergencyCardInsurance,
            doctor: l10n.emergencyCardDoctor,
            doctors: l10n.emergencyCardDoctors,
            contact: l10n.emergencyCardContact,
            contacts: l10n.emergencyCardContacts,
            notes: l10n.emergencyCardNotes,
            careNeeds: l10n.emergencyCardCareTitle,
            kind: l10n.cardSpeciesLabel,
            speciesName: (species) => localizeCardSpecies(l10n, species),
            chipNumber: l10n.cardChipNumber,
            vet: l10n.cardVet,
            vets: l10n.cardVets,
            shelters: l10n.cardShelters,
          ),
          evacuation: l10n.hubEvacuationTitle,
          evacuationRoute: l10n.hubFolderReportRoute,
          evacuationPlaces: l10n.hubFolderReportPlaces,
          communication: l10n.hubCommunicationTitle,
          radio: l10n.hubRadioTitle,
          autonomy: l10n.hubFolderReportAutonomy,
          folder: l10n.hubFolderTitle,
          folderCopiesReady: l10n.hubFolderCopies,
          folderTakeAlong: l10n.hubFolderTakeAlong,
        ),
      ),
    );
  }

  /// True to include the cards, false for the folder alone, null to
  /// abandon the export.
  Future<bool?> _askAboutCards(int count) => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.warning_amber_outlined),
      title: Text(_l10n.emergencyPlanCardsAskTitle),
      content: Text(_l10n.emergencyPlanCardsAskBody(count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            MaterialLocalizations.of(dialogContext).cancelButtonLabel,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(_l10n.emergencyPlanCardsAskWithout),
        ),
        // Not emphasised: including them is the more consequential of
        // the two, and the emphasised button is the one people press
        // without reading.
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(_l10n.emergencyPlanCardsAskWith),
        ),
      ],
    ),
  );

  Widget _maintenance() => Column(
    children: [
      for (final task in _MaintenanceTask.values)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _data.maintenance.containsKey(task.id),
          title: Text(_taskTitle(task)),
          subtitle: Text(
            _data.maintenance[task.id] == null
                ? _taskHint(task)
                : _l10n.hubMaintenanceLastChecked(
                    _date(_data.maintenance[task.id]),
                  ),
          ),
          onChanged: (value) {
            final updated = {..._data.maintenance};
            if (value == true) {
              updated[task.id] = DateTime.now();
            } else {
              updated.remove(task.id);
            }
            unawaited(_change(_data.copyWith(maintenance: updated)));
          },
        ),
    ],
  );

  Widget _evacuation() => Column(
    children: [
      for (final card in _data.evacuationCards)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.map_outlined),
          title: Text(card.label),
          subtitle: Text(
            _l10n.hubEvacuationSummary(
              card.start.isEmpty ? _l10n.hubEvacuationStartOpen : card.start,
              card.destination.isEmpty
                  ? _l10n.hubEvacuationDestinationOpen
                  : card.destination,
              _date(card.checkedAt),
            ),
          ),
          isThreeLine: true,
          onTap: () => _showEvacuation(card),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: _l10n.hubEvacuationRemove,
            onPressed: () => _change(
              _data.copyWith(
                evacuationCards: [
                  for (final item in _data.evacuationCards)
                    if (item.id != card.id) item,
                ],
              ),
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _editEvacuation(),
          icon: const Icon(Icons.add),
          label: Text(_l10n.hubEvacuationAdd),
        ),
      ),
    ],
  );

  Widget _events() => Column(
    children: [
      for (final event in _data.events.take(5))
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notes_outlined),
          title: Text(event.kind),
          subtitle: Text(
            _l10n.hubEventSummary(
              _dateTime(event.at),
              event.note.isEmpty ? event.action : event.note,
            ),
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: _l10n.hubEntryRemove,
            onPressed: () => _change(
              _data.copyWith(
                events: [
                  for (final item in _data.events)
                    if (item.id != event.id) item,
                ],
              ),
            ),
          ),
        ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _addEvent,
            icon: const Icon(Icons.add),
            label: Text(_l10n.hubEventsAdd),
          ),
          if (_data.events.isNotEmpty)
            FilledButton.icon(
              onPressed: _exportEvents,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_l10n.hubEventsExport),
            ),
        ],
      ),
    ],
  );

  String _dateTime(DateTime date) => _l10n.hubDateTime(
    _date(date),
    MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(date)),
  );

  Future<void> _addRadio() async {
    final station = TextEditingController();
    final frequency = TextEditingController();
    final receiver = TextEditingController();
    final power = TextEditingController(text: _l10n.hubRadioPowerExample);
    var band = 'UKW';
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(_l10n.hubRadioDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: station,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: _l10n.hubRadioStation,
                  ),
                ),
                DropdownButtonFormField(
                  initialValue: band,
                  decoration: InputDecoration(
                    labelText: _l10n.hubRadioBand,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'UKW', child: Text('UKW')),
                    DropdownMenuItem(value: 'DAB+', child: Text('DAB+')),
                  ],
                  onChanged: (value) => setDialogState(() => band = value!),
                ),
                TextField(
                  controller: frequency,
                  decoration: InputDecoration(
                    labelText: _l10n.hubRadioFrequency,
                  ),
                ),
                TextField(
                  controller: receiver,
                  decoration: InputDecoration(
                    labelText: _l10n.hubRadioReceiver,
                  ),
                ),
                TextField(
                  controller: power,
                  decoration: InputDecoration(
                    labelText: _l10n.hubRadioPower,
                  ),
                ),
              ],
            ),
          ),
          actions: _dialogActions(context, () => Navigator.pop(context, true)),
        ),
      ),
    );
    if (saved == true && station.text.trim().isNotEmpty) {
      await _change(
        _data.copyWith(
          radioPlans: [
            ..._data.radioPlans,
            RadioReceptionPlan.create(
              station: station.text.trim(),
              band: band,
              frequency: frequency.text.trim(),
              receiver: receiver.text.trim(),
              power: power.text.trim(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _editFolderLocation() async {
    final location = TextEditingController(text: _data.folder.location);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.hubFolderLocation),
        content: TextField(
          controller: location,
          autofocus: true,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: _l10n.hubFolderLocationHint,
          ),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved == true) {
      await _change(
        _data.copyWith(
          folder: _data.folder.copyWith(location: location.text.trim()),
        ),
      );
    }
  }

  Future<void> _editEvacuation([EvacuationCard? current]) async {
    final label = TextEditingController(text: current?.label ?? '');
    final start = TextEditingController(text: current?.start ?? '');
    final destination = TextEditingController(text: current?.destination ?? '');
    final route = TextEditingController(text: current?.route ?? '');
    final locations = TextEditingController(text: current?.locations ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          current == null ? _l10n.hubEvacuationDialogTitle : current.label,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: _l10n.hubEvacuationLabel,
                ),
              ),
              TextField(
                controller: start,
                decoration: InputDecoration(
                  labelText: _l10n.hubEvacuationStart,
                ),
              ),
              TextField(
                controller: destination,
                decoration: InputDecoration(
                  labelText: _l10n.hubEvacuationDestination,
                ),
              ),
              TextField(
                controller: route,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _l10n.hubEvacuationRoute,
                ),
              ),
              TextField(
                controller: locations,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: _l10n.hubEvacuationPlaces,
                ),
              ),
            ],
          ),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved != true || label.text.trim().isEmpty) return;
    final edited = EvacuationCard.create(
      label: label.text.trim(),
      start: start.text.trim(),
      destination: destination.text.trim(),
      route: route.text.trim(),
      locations: locations.text.trim(),
    );
    await _change(
      _data.copyWith(
        evacuationCards: current == null
            ? [..._data.evacuationCards, edited]
            : [
                for (final item in _data.evacuationCards)
                  if (item.id == current.id) edited else item,
              ],
      ),
    );
  }

  Future<void> _showEvacuation(EvacuationCard card) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(card.label),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _l10n.hubEvacuationStartLine(
                card.start.isEmpty ? '–' : card.start,
              ),
            ),
            Text(
              _l10n.hubEvacuationDestinationLine(
                card.destination.isEmpty ? '–' : card.destination,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _l10n.hubEvacuationRoute,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(card.route.isEmpty ? '–' : card.route),
            const SizedBox(height: 12),
            Text(
              _l10n.hubEvacuationPlacesLine,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(card.locations.isEmpty ? '–' : card.locations),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_l10n.hubClose),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            _editEvacuation(card);
          },
          child: Text(_l10n.hubNoteEdit),
        ),
      ],
    ),
  );

  Future<void> _addEvent({String? kindPrefill, String? notePrefill}) async {
    final kind = TextEditingController(
      text: kindPrefill ?? _l10n.hubEventsNoteHint,
    );
    final note = TextEditingController(text: notePrefill ?? '');
    final action = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.hubEventsDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: kind,
                decoration: InputDecoration(
                  labelText: _l10n.hubEventsKind,
                ),
              ),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _l10n.hubEventsNote,
                ),
              ),
              TextField(
                controller: action,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _l10n.hubEventsAction,
                ),
              ),
            ],
          ),
        ),
        actions: _dialogActions(context, () => Navigator.pop(context, true)),
      ),
    );
    if (saved == true &&
        (note.text.trim().isNotEmpty || action.text.trim().isNotEmpty)) {
      await _change(
        _data.copyWith(
          events: [
            IncidentEntry.create(
              kind: kind.text.trim().isEmpty
                  ? _l10n.hubEventsKindHint
                  : kind.text.trim(),
              note: note.text.trim(),
              action: action.text.trim(),
            ),
            ..._data.events,
          ],
        ),
      );
    }
  }

  List<Widget> _dialogActions(BuildContext context, VoidCallback save) => [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(_l10n.hubCancel),
    ),
    FilledButton(onPressed: save, child: Text(_l10n.hubSave)),
  ];

  Future<void> _exportEvents() async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(level: 0, child: pw.Text(_l10n.hubEventsPdfTitle)),
          for (final event in _data.events)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    event.kind,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(event.at.toLocal().toString()),
                  if (event.note.isNotEmpty)
                    pw.Text(_l10n.hubEventsObservationLine(event.note)),
                  if (event.action.isNotEmpty)
                    pw.Text(_l10n.hubEventsActionLine(event.action)),
                ],
              ),
            ),
        ],
      ),
    );
    final bytes = await document.save();
    if (mounted) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: _l10n.hubEventsPdfFile,
      );
    }
  }

  String _resilienceSupportBriefing() {
    final support = _data.resilience.support;
    final lines = <String>[
      if (support.powerReviewed) _l10n.resilienceSupportPower,
      if (support.evacuationReviewed) _l10n.resilienceSupportEvacuation,
      if (support.transportReviewed) _l10n.resilienceSupportTransport,
      if (support.medicineReviewed) _l10n.resilienceSupportMedicine,
      if (support.assistanceReviewed) _l10n.resilienceSupportAssistance,
      if (support.note.isNotEmpty) support.note,
    ];
    return lines.join('\n');
  }

  String _resilienceSourcesBriefing() => _data.resilience.sources
      .map(
        (source) =>
            '${source.label}: ${source.channel} · ${source.offlineFallback}',
      )
      .join('\n');

  String _resilienceNeighborhoodBriefing() => _data.resilience.neighborhood
      .map(
        (entry) =>
            '${entry.alias}: ${entry.skill} · ${entry.contactMethod} · ${entry.meetingPoint}',
      )
      .join('\n');

  Future<void> _exportBriefing() async {
    final document = pw.Document();
    final plans = [
      (_l10n.hubBriefingCommunication, _data.communication.text),
      (_l10n.hubBriefingSupport, _data.support.text),
      (_l10n.hubBriefingPets, _data.pets.text),
      (_l10n.hubBriefingMobility, _data.mobility.text),
      (_l10n.hubBriefingUtilities, _data.utilities.text),
      (_l10n.hubFolderTitle, _data.folder.location),
      (_l10n.hubWaterHygieneTitle, _data.waterHygiene.text),
      (_l10n.hubBriefingPowerOutage, _data.powerOutage.text),
      (_l10n.hubCookingTitle, _data.cooking.text),
      (_l10n.hubBriefingRedundancy, _data.redundancy.text),
      (_l10n.hubBriefingClimate, _data.climateRoom.text),
      (_l10n.hubAnalogTitle, _data.analogFallback.text),
      (_l10n.hubMutualAidTitle, _data.mutualAid.text),
      (_l10n.hubPracticeTitle, _data.practice.text),
      (_l10n.resilienceSupportTitle, _resilienceSupportBriefing()),
      (_l10n.resilienceSourcesTitle, _resilienceSourcesBriefing()),
      (_l10n.resilienceNeighborhoodTitle, _resilienceNeighborhoodBriefing()),
    ];
    document.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(level: 0, child: pw.Text(_l10n.hubBriefingPdfTitle)),
          pw.Text(_l10n.hubBriefingCreated('${DateTime.now().toLocal()}')),
          pw.SizedBox(height: 12),
          for (final plan in plans)
            if (plan.$2.isNotEmpty)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      plan.$1,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(plan.$2),
                  ],
                ),
              ),
          if (_data.radioPlans.isNotEmpty) ...[
            pw.Text(
              _l10n.hubBriefingRadio,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            for (final radio in _data.radioPlans)
              pw.Text(
                _l10n.hubBriefingRadioLine(
                  radio.station,
                  radio.band,
                  radio.frequency,
                  radio.receiver,
                ),
              ),
          ],
          if (_data.evacuationCards.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              _l10n.hubBriefingEvacuation,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            for (final card in _data.evacuationCards)
              pw.Text(
                _l10n.hubBriefingEvacuationLine(
                  card.label,
                  card.start,
                  card.destination,
                ),
              ),
          ],
        ],
      ),
    );
    final bytes = await document.save();
    if (mounted) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: _l10n.hubBriefingPdfFile,
      );
    }
  }
}

/// The ids are what is stored against a check date, so they are fixed
/// strings and not translated. What a person reads comes out of the
/// translations beside them — the two used to be the same value, which
/// meant a German sentence sat in a const list at the bottom of this
/// file and no English reader ever saw anything else.
enum _MaintenanceTask {
  batteries,
  radio,
  waterFilter('water_filter'),
  kit,
  medicine,
  extinguisher,
  vehicle;

  const _MaintenanceTask([this._id]);

  final String? _id;

  String get id => _id ?? name;
}

enum _ActionTask {
  now,
  twoDays('two_days'),
  days;

  const _ActionTask([this._id]);

  final String? _id;

  String get id => _id ?? name;
}

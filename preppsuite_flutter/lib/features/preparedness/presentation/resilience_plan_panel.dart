import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../knowledge/presentation/apollo_library_screen.dart';
import '../application/resilience_plan.dart';

/// Small, testable resilience plans beside the operational crisis plan.
///
/// Nothing here reaches a server, an address book, or the current location.
/// The entries are only as precise as their owner deliberately makes them.
class ResiliencePlanPanel extends StatelessWidget {
  const ResiliencePlanPanel({
    super.key,
    required this.plan,
    required this.maintenance,
    required this.onPlanChanged,
    required this.onMaintenanceIntervalChanged,
  });

  final ResiliencePlan plan;
  final Map<String, DateTime> maintenance;
  final ValueChanged<ResiliencePlan> onPlanChanged;
  final void Function(String taskId, int everyDays)
  onMaintenanceIntervalChanged;

  static const _warningPaths = <({String id, IconData icon})>[
    (id: 'nina', icon: Icons.notifications_active_outlined),
    (id: 'cell', icon: Icons.cell_tower_outlined),
    (id: 'siren', icon: Icons.campaign_outlined),
    (id: 'radio', icon: Icons.radio_outlined),
  ];

  static const _learningPaths = <({String id, IconData icon})>[
    (id: 'medical', icon: Icons.health_and_safety_outlined),
    (id: 'water', icon: Icons.water_drop_outlined),
    (id: 'repair', icon: Icons.handyman_outlined),
    (id: 'navigation', icon: Icons.explore_outlined),
    (id: 'school', icon: Icons.school_outlined),
  ];

  static const _maintenanceTasks = <String>[
    'batteries',
    'radio',
    'waterFilter',
    'kit',
    'medicine',
    'extinguisher',
    'vehicle',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subheading(context, l10n.resilienceWarningTitle),
        Text(l10n.resilienceWarningHint),
        const SizedBox(height: 8),
        for (final route in _warningPaths)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: plan.warningChecks.containsKey(route.id),
            secondary: Icon(route.icon),
            title: Text(_warningLabel(l10n, route.id)),
            subtitle: plan.warningChecks[route.id] == null
                ? null
                : Text(_checked(context, plan.warningChecks[route.id]!)),
            onChanged: (checked) => _toggleWarning(route.id, checked == true),
          ),
        const Divider(height: 28),
        _subheading(context, l10n.resilienceSupportTitle),
        Text(l10n.resilienceSupportHint),
        const SizedBox(height: 8),
        _supportCheck(
          context,
          l10n.resilienceSupportPower,
          plan.support.powerReviewed,
          (value) => _changeSupport(powerReviewed: value),
        ),
        _supportCheck(
          context,
          l10n.resilienceSupportEvacuation,
          plan.support.evacuationReviewed,
          (value) => _changeSupport(evacuationReviewed: value),
        ),
        _supportCheck(
          context,
          l10n.resilienceSupportTransport,
          plan.support.transportReviewed,
          (value) => _changeSupport(transportReviewed: value),
        ),
        _supportCheck(
          context,
          l10n.resilienceSupportMedicine,
          plan.support.medicineReviewed,
          (value) => _changeSupport(medicineReviewed: value),
        ),
        _supportCheck(
          context,
          l10n.resilienceSupportAssistance,
          plan.support.assistanceReviewed,
          (value) => _changeSupport(assistanceReviewed: value),
        ),
        OutlinedButton.icon(
          onPressed: () => _editSupport(context, l10n),
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.resilienceSupportNote),
        ),
        if (plan.support.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(plan.support.note),
        ],
        const Divider(height: 28),
        _subheading(context, l10n.resilienceMaintenanceSchedule),
        for (final task in _maintenanceTasks)
          _MaintenanceScheduleRow(
            task: task,
            lastChecked: maintenance[task],
            everyDays: plan.maintenanceEveryDays[task] ?? 0,
            label: _maintenanceLabel(l10n, task),
            l10n: l10n,
            onChanged: (days) => onMaintenanceIntervalChanged(task, days),
          ),
        const Divider(height: 28),
        _subheading(context, l10n.resilienceSourcesTitle),
        Text(l10n.resilienceSourcesHint),
        const SizedBox(height: 8),
        if (plan.sources.isEmpty)
          Text(l10n.resilienceSourcesEmpty)
        else
          for (final source in plan.sources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(source.label),
              subtitle: Text(
                '${source.channel}\n${source.offlineFallback}\n'
                '${_checked(context, source.checkedAt)}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onPlanChanged(
                  plan.copyWith(
                    sources: [
                      for (final item in plan.sources)
                        if (item.id != source.id) item,
                    ],
                  ),
                ),
              ),
            ),
        OutlinedButton.icon(
          onPressed: () => _addSource(context, l10n),
          icon: const Icon(Icons.add),
          label: Text(l10n.resilienceSourceAdd),
        ),
        const Divider(height: 28),
        _subheading(context, l10n.resilienceLearningTitle),
        Text(l10n.resilienceLearningHint),
        const SizedBox(height: 8),
        for (final path in _learningPaths)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: plan.learningChecks.containsKey(path.id),
            secondary: Icon(path.icon),
            title: Text(_learningLabel(l10n, path.id)),
            subtitle: plan.learningChecks[path.id] == null
                ? null
                : Text(_checked(context, plan.learningChecks[path.id]!)),
            onChanged: (checked) => _toggleLearning(path.id, checked == true),
          ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ApolloLibraryScreen(),
            ),
          ),
          icon: const Icon(Icons.auto_stories_outlined),
          label: Text(l10n.resilienceLearningOpen),
        ),
        const Divider(height: 28),
        _subheading(context, l10n.resilienceNeighborhoodTitle),
        Text(l10n.resilienceNeighborhoodHint),
        const SizedBox(height: 8),
        if (plan.neighborhood.isEmpty)
          Text(l10n.resilienceNeighborhoodEmpty)
        else
          for (final entry in plan.neighborhood)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: Text(entry.alias),
              subtitle: Text(
                '${entry.skill}\n${entry.contactMethod} · ${entry.meetingPoint}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onPlanChanged(
                  plan.copyWith(
                    neighborhood: [
                      for (final item in plan.neighborhood)
                        if (item.id != entry.id) item,
                    ],
                  ),
                ),
              ),
            ),
        OutlinedButton.icon(
          onPressed: () => _addNeighbor(context, l10n),
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(l10n.resilienceNeighborhoodAdd),
        ),
      ],
    );
  }

  Widget _subheading(BuildContext context, String title) => Text(
    title,
    style: Theme.of(context).textTheme.titleMedium,
  );

  Widget _supportCheck(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) => CheckboxListTile(
    contentPadding: EdgeInsets.zero,
    value: value,
    title: Text(title),
    onChanged: (next) => onChanged(next == true),
  );

  void _toggleWarning(String id, bool checked) {
    final updated = {...plan.warningChecks};
    if (checked) {
      updated[id] = DateTime.now();
    } else {
      updated.remove(id);
    }
    onPlanChanged(plan.copyWith(warningChecks: updated));
  }

  void _toggleLearning(String id, bool checked) {
    final updated = {...plan.learningChecks};
    if (checked) {
      updated[id] = DateTime.now();
    } else {
      updated.remove(id);
    }
    onPlanChanged(plan.copyWith(learningChecks: updated));
  }

  void _changeSupport({
    bool? powerReviewed,
    bool? evacuationReviewed,
    bool? transportReviewed,
    bool? medicineReviewed,
    bool? assistanceReviewed,
  }) => onPlanChanged(
    plan.copyWith(
      support: plan.support.copyWith(
        powerReviewed: powerReviewed,
        evacuationReviewed: evacuationReviewed,
        transportReviewed: transportReviewed,
        medicineReviewed: medicineReviewed,
        assistanceReviewed: assistanceReviewed,
      ),
    ),
  );

  Future<void> _editSupport(BuildContext context, AppLocalizations l10n) async {
    final controller = TextEditingController(text: plan.support.note);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resilienceSupportNote),
        content: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          decoration: InputDecoration(hintText: l10n.resilienceSupportHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              MaterialLocalizations.of(dialogContext).saveButtonLabel,
            ),
          ),
        ],
      ),
    );
    if (saved == true) {
      onPlanChanged(
        plan.copyWith(
          support: plan.support.copyWith(note: controller.text.trim()),
        ),
      );
    }
  }

  Future<void> _addSource(BuildContext context, AppLocalizations l10n) async {
    final label = TextEditingController();
    final channel = TextEditingController();
    final fallback = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resilienceSourceAdd),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.resilienceSourceLabel,
                ),
              ),
              TextField(
                controller: channel,
                decoration: InputDecoration(
                  labelText: l10n.resilienceSourceChannel,
                ),
              ),
              TextField(
                controller: fallback,
                decoration: InputDecoration(
                  labelText: l10n.resilienceSourceFallback,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              MaterialLocalizations.of(dialogContext).saveButtonLabel,
            ),
          ),
        ],
      ),
    );
    if (saved == true && label.text.trim().isNotEmpty) {
      onPlanChanged(
        plan.copyWith(
          sources: [
            ...plan.sources,
            TrustedSource.create(
              label: label.text.trim(),
              channel: channel.text.trim(),
              offlineFallback: fallback.text.trim(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _addNeighbor(BuildContext context, AppLocalizations l10n) async {
    final alias = TextEditingController();
    final skill = TextEditingController();
    final contact = TextEditingController();
    final meeting = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resilienceNeighborhoodAdd),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: alias,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.resilienceNeighborAlias,
                ),
              ),
              TextField(
                controller: skill,
                decoration: InputDecoration(
                  labelText: l10n.resilienceNeighborSkill,
                ),
              ),
              TextField(
                controller: contact,
                decoration: InputDecoration(
                  labelText: l10n.resilienceNeighborContact,
                ),
              ),
              TextField(
                controller: meeting,
                decoration: InputDecoration(
                  labelText: l10n.resilienceNeighborMeeting,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              MaterialLocalizations.of(dialogContext).saveButtonLabel,
            ),
          ),
        ],
      ),
    );
    if (saved == true && alias.text.trim().isNotEmpty) {
      onPlanChanged(
        plan.copyWith(
          neighborhood: [
            ...plan.neighborhood,
            NeighborhoodCapability.create(
              alias: alias.text.trim(),
              skill: skill.text.trim(),
              contactMethod: contact.text.trim(),
              meetingPoint: meeting.text.trim(),
            ),
          ],
        ),
      );
    }
  }

  String _checked(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatMediumDate(value);

  String _warningLabel(AppLocalizations l10n, String id) => switch (id) {
    'nina' => l10n.resilienceWarningNina,
    'cell' => l10n.resilienceWarningCell,
    'siren' => l10n.resilienceWarningSiren,
    _ => l10n.resilienceWarningRadio,
  };

  String _learningLabel(AppLocalizations l10n, String id) => switch (id) {
    'medical' => l10n.resilienceLearningMedical,
    'water' => l10n.resilienceLearningWater,
    'repair' => l10n.resilienceLearningRepair,
    'navigation' => l10n.resilienceLearningNavigation,
    _ => l10n.resilienceLearningSchool,
  };

  String _maintenanceLabel(AppLocalizations l10n, String id) => switch (id) {
    'batteries' => l10n.hubTaskBatteriesTitle,
    'radio' => l10n.hubTaskRadioTitle,
    'waterFilter' => l10n.hubTaskWaterFilterTitle,
    'kit' => l10n.hubTaskKitTitle,
    'medicine' => l10n.hubTaskMedicineTitle,
    'extinguisher' => l10n.hubTaskExtinguisherTitle,
    _ => l10n.hubTaskVehicleTitle,
  };
}

class _MaintenanceScheduleRow extends StatelessWidget {
  const _MaintenanceScheduleRow({
    required this.task,
    required this.lastChecked,
    required this.everyDays,
    required this.label,
    required this.l10n,
    required this.onChanged,
  });

  final String task;
  final DateTime? lastChecked;
  final int everyDays;
  final String label;
  final AppLocalizations l10n;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final due =
        everyDays > 0 &&
        (lastChecked == null ||
            !DateTime.now().isBefore(
              lastChecked!.add(Duration(days: everyDays)),
            ));
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        due ? Icons.event_busy_outlined : Icons.event_available_outlined,
      ),
      title: Text(label),
      subtitle: Text(
        everyDays == 0
            ? l10n.resilienceMaintenanceOff
            : due
            ? l10n.resilienceMaintenanceDue
            : l10n.resilienceMaintenanceEveryDays(everyDays),
      ),
      trailing: PopupMenuButton<int>(
        tooltip: l10n.resilienceMaintenanceSchedule,
        onSelected: onChanged,
        itemBuilder: (context) => [
          PopupMenuItem(value: 0, child: Text(l10n.resilienceMaintenanceOff)),
          for (final days in [30, 90, 180, 365])
            PopupMenuItem(
              value: days,
              child: Text(l10n.resilienceMaintenanceEveryDays(days)),
            ),
        ],
        child: const Icon(Icons.more_horiz),
      ),
    );
  }
}

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../preparedness/presentation/preparedness_hub_screen.dart';
import '../application/drill_progress_store.dart';

/// A deliberately small, offline exercise and incident guide. It does not
/// create a cloud account or transmit a "safe" status; contacts remain under
/// the user's control in the emergency directory.
class PreparednessToolsScreen extends StatefulWidget {
  const PreparednessToolsScreen({super.key, required this.householdId});

  /// Passed through to the crisis hub, which divides the household's own
  /// inventory into days rather than asking for the figure again.
  final String householdId;

  @override
  State<PreparednessToolsScreen> createState() =>
      _PreparednessToolsScreenState();
}

class _PreparednessToolsScreenState extends State<PreparednessToolsScreen> {
  static const _store = DrillProgressStore();

  Set<String> _checked = {};
  Map<String, DateTime> _completed = {};
  final Map<String, bool> _learningAnswers = {};

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final result = await Future.wait([_store.load(), _store.loadCompleted()]);
    if (mounted) {
      setState(() {
        _checked = result[0] as Set<String>;
        _completed = result[1] as Map<String, DateTime>;
      });
    }
  }

  void _toggle(_Scenario scenario, String step, {required bool on}) {
    final key = '${scenario.id}:$step';
    final updated = {..._checked};
    if (on) {
      updated.add(key);
    } else {
      updated.remove(key);
    }
    setState(() {
      _checked = updated;
    });
    unawaited(_store.save(updated));
    if (on &&
        scenario.steps.every(
          (item) => updated.contains('${scenario.id}:$item'),
        )) {
      final completedAt = DateTime.now();
      setState(() => _completed = {..._completed, scenario.id: completedAt});
      unawaited(_store.markCompleted(scenario.id, completedAt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.drillsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.drillsEmergencyMode,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.drillsImmediateDanger),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: '112')),
                    icon: const Icon(Icons.call),
                    label: Text(l10n.drillsCallEmergency),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_special_outlined),
              title: Text(l10n.toolsHubTitle),
              subtitle: Text(
                l10n.toolsHubBody,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PreparednessHubScreen(householdId: widget.householdId),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.toolsLearnTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.toolsLearnBody,
          ),
          const SizedBox(height: 8),
          for (final lesson in _Lesson.values)
            Card(
              child: ExpansionTile(
                leading: Icon(lesson.icon),
                title: Text(_lessonTitle(l10n, lesson)),
                subtitle: Text(_lessonSummary(l10n, lesson)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(_lessonQuestion(l10n, lesson)),
                  const SizedBox(height: 8),
                  for (final answer in _lessonAnswers(l10n, lesson))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: OutlinedButton(
                        onPressed: () => setState(
                          () => _learningAnswers[lesson.id] =
                              _lessonAnswers(
                                l10n,
                                lesson,
                              ).indexOf(answer) ==
                              lesson.correctAnswer,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(answer),
                        ),
                      ),
                    ),
                  if (_learningAnswers.containsKey(lesson.id))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _learningAnswers[lesson.id] == true
                            ? l10n.toolsAnswerRight(
                                _lessonExplanation(l10n, lesson),
                              )
                            : l10n.toolsAnswerWrong(
                                _lessonExplanation(l10n, lesson),
                              ),
                        style: TextStyle(
                          color: _learningAnswers[lesson.id] == true
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.drillsSectionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              // Ticks outlive the screen now, so there has to be a way
              // back to zero — otherwise the second run of a drill starts
              // already finished.
              if (_checked.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(_checked.clear);
                    unawaited(_store.clear());
                  },
                  child: Text(l10n.drillsReset),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.drillsHarmless),
          const SizedBox(height: 8),
          for (final scenario in _Scenario.values)
            Card(
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                  child: Icon(scenario.icon),
                ),
                title: Text(_drillTitle(l10n, scenario)),
                subtitle: Text(
                  switch (_completed[scenario.id]) {
                    final DateTime completed => l10n.toolsDrillMeta(
                      l10n.toolsDrillDuration(scenario.minutes),
                      l10n.drillsLastCompleted(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(completed),
                      ),
                    ),
                    null => l10n.toolsDrillDuration(scenario.minutes),
                  },
                ),
                children: [
                  for (final (index, text) in _drillSteps(
                    l10n,
                    scenario,
                  ).indexed)
                    CheckboxListTile(
                      value: _checked.contains('${scenario.id}:$index'),
                      title: Text(text),
                      onChanged: (value) =>
                          _toggle(scenario, '$index', on: value == true),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The text of a lesson, by id.
///
/// Switches rather than a map, so adding a lesson without translating it
/// does not compile.
String _lessonTitle(AppLocalizations l10n, _Lesson lesson) => switch (lesson) {
  _Lesson.communication => l10n.toolsLessonCommunicationTitle,
  _Lesson.evacuation => l10n.toolsLessonEvacuationTitle,
  _Lesson.power => l10n.toolsLessonPowerTitle,
};

String _lessonSummary(AppLocalizations l10n, _Lesson lesson) =>
    switch (lesson) {
      _Lesson.communication => l10n.toolsLessonCommunicationSummary,
      _Lesson.evacuation => l10n.toolsLessonEvacuationSummary,
      _Lesson.power => l10n.toolsLessonPowerSummary,
    };

String _lessonQuestion(AppLocalizations l10n, _Lesson lesson) =>
    switch (lesson) {
      _Lesson.communication => l10n.toolsLessonCommunicationQuestion,
      _Lesson.evacuation => l10n.toolsLessonEvacuationQuestion,
      _Lesson.power => l10n.toolsLessonPowerQuestion,
    };

/// In the order the answers are shown, which is what `correctAnswer`
/// indexes into.
List<String> _lessonAnswers(AppLocalizations l10n, _Lesson lesson) =>
    switch (lesson) {
      _Lesson.communication => [
        l10n.toolsLessonCommunicationAnswerA,
        l10n.toolsLessonCommunicationAnswerB,
        l10n.toolsLessonCommunicationAnswerC,
      ],
      _Lesson.evacuation => [
        l10n.toolsLessonEvacuationAnswerA,
        l10n.toolsLessonEvacuationAnswerB,
        l10n.toolsLessonEvacuationAnswerC,
      ],
      _Lesson.power => [
        l10n.toolsLessonPowerAnswerA,
        l10n.toolsLessonPowerAnswerB,
        l10n.toolsLessonPowerAnswerC,
      ],
    };

String _lessonExplanation(AppLocalizations l10n, _Lesson lesson) =>
    switch (lesson) {
      _Lesson.communication => l10n.toolsLessonCommunicationExplanation,
      _Lesson.evacuation => l10n.toolsLessonEvacuationExplanation,
      _Lesson.power => l10n.toolsLessonPowerExplanation,
    };

String _drillTitle(AppLocalizations l10n, _Scenario drill) => switch (drill) {
  _Scenario.powerOutage => l10n.toolsDrillPowerTitle,
  _Scenario.evacuation => l10n.toolsDrillEvacuationTitle,
  _Scenario.communication => l10n.toolsDrillCommunicationTitle,
  _Scenario.equipment => l10n.toolsDrillEquipmentTitle,
  _Scenario.radio => l10n.toolsDrillRadioTitle,
};

/// The steps, in the order they are ticked off.
List<String> _drillSteps(AppLocalizations l10n, _Scenario drill) =>
    switch (drill) {
      _Scenario.powerOutage => [
        l10n.toolsDrillPowerStepA,
        l10n.toolsDrillPowerStepB,
        l10n.toolsDrillPowerStepC,
      ],
      _Scenario.evacuation => [
        l10n.toolsDrillEvacuationStepA,
        l10n.toolsDrillEvacuationStepB,
        l10n.toolsDrillEvacuationStepC,
      ],
      _Scenario.communication => [
        l10n.toolsDrillCommunicationStepA,
        l10n.toolsDrillCommunicationStepB,
        l10n.toolsDrillCommunicationStepC,
      ],
      _Scenario.equipment => [
        l10n.toolsDrillEquipmentStepA,
        l10n.toolsDrillEquipmentStepB,
        l10n.toolsDrillEquipmentStepC,
      ],
      _Scenario.radio => [
        l10n.toolsDrillRadioStepA,
        l10n.toolsDrillRadioStepB,
        l10n.toolsDrillRadioStepC,
      ],
    };

/// The drills, as ids and nothing else.
///
/// What is stored against a person's progress is the id, and the id used
/// to be the same string as the heading they read — so translating the
/// heading would have orphaned every tick they had made. The text lives
/// in the translations now; only the structure lives here.
enum _Scenario {
  powerOutage('power-outage', 20, 3, Icons.power_outlined),
  evacuation('evacuation', 15, 3, Icons.route_outlined),
  communication('communication', 10, 3, Icons.forum_outlined),
  equipment('equipment', 15, 3, Icons.battery_charging_full_outlined),
  radio('radio', 10, 3, Icons.radio_outlined);

  const _Scenario(this.id, this.minutes, this.stepCount, this.icon);

  final String id;
  final int minutes;
  final int stepCount;
  final IconData icon;

  /// What a tick is stored against, one per step.
  ///
  /// A number, and it used to be the German sentence itself — which made
  /// translating the sentence the same thing as losing the tick. The
  /// scenario id is untouched, so the log of finished runs survives; a
  /// drill that happens to be half-ticked while the app updates starts
  /// over, which is what `DrillProgressStore` says a rehearsal does
  /// anyway.
  Iterable<String> get steps => [
    for (var index = 0; index < stepCount; index++) '$index',
  ];
}

enum _Lesson {
  communication('communication', Icons.forum_outlined, 1),
  evacuation('evacuation', Icons.route_outlined, 0),
  power('power', Icons.flash_on_outlined, 1);

  const _Lesson(this.id, this.icon, this.correctAnswer);

  final String id;
  final IconData icon;
  final int correctAnswer;
}

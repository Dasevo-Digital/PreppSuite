import 'package:flutter/material.dart';

import '../../../core/adaptive_columns.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/knowledge_check.dart';
import '../application/knowledge_check_store.dart';
import 'first_aid_guide_screen.dart';

/// Asking back, because reading a guide again does not find out what you
/// have forgotten.
///
/// One question at a time, answered before the next appears, and the
/// reason shown straight away in the words of the guide it came from —
/// with the guide one tap behind it. Being told "wrong" and moved along
/// teaches nothing; being told *why*, while the question is still in mind,
/// is the whole point.
///
/// No score is kept beyond which questions sit. There is no badge and no
/// streak: the thing being encouraged is coming back in a year, not coming
/// back tomorrow.
class KnowledgeCheckScreen extends StatefulWidget {
  const KnowledgeCheckScreen({
    super.key,
    this.store = const KnowledgeCheckStore(),
  });

  final KnowledgeCheckStore store;

  @override
  State<KnowledgeCheckScreen> createState() => _KnowledgeCheckScreenState();
}

class _KnowledgeCheckScreenState extends State<KnowledgeCheckScreen> {
  List<KnowledgeQuestion>? _round;
  Set<String> _passed = const {};
  DateTime? _lastRound;

  var _at = 0;
  int? _chosen;
  final _right = <String>{};
  final _wrong = <String>{};
  var _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_round == null) _begin();
  }

  /// Reads what already sits, then picks a round around it.
  void _begin() {
    final language = Localizations.localeOf(context).languageCode;
    widget.store.passed().then((passed) async {
      final last = await widget.store.lastRound();
      if (!mounted) return;
      setState(() {
        _passed = passed;
        _lastRound = last;
        _round = knowledgeRound(
          knowledgeQuestionsFor(language),
          passed: passed,
        );
      });
    });
  }

  void _answer(int index) {
    final round = _round;
    if (round == null || _chosen != null) return;
    final question = round[_at];
    setState(() {
      _chosen = index;
      (index == question.correct ? _right : _wrong).add(question.id);
    });
  }

  Future<void> _next() async {
    final round = _round!;
    if (_at + 1 < round.length) {
      setState(() {
        _at++;
        _chosen = null;
      });
      return;
    }
    await widget.store.record(right: _right, wrong: _wrong);
    final passed = await widget.store.passed();
    if (!mounted) return;
    setState(() {
      _passed = passed;
      _finished = true;
    });
  }

  void _again() {
    final language = Localizations.localeOf(context).languageCode;
    setState(() {
      _round = knowledgeRound(
        knowledgeQuestionsFor(language),
        passed: _passed,
      );
      _at = 0;
      _chosen = null;
      _finished = false;
      _right.clear();
      _wrong.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final round = _round;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.knowledgeCheckTitle)),
      body: round == null
          ? const Center(child: CircularProgressIndicator())
          : _finished
          ? _summary(l10n)
          : _question(l10n, round),
    );
  }

  Widget _question(AppLocalizations l10n, List<KnowledgeQuestion> round) {
    final theme = Theme.of(context);
    final question = round[_at];
    final chosen = _chosen;
    final correct = chosen == question.correct;

    return AdaptiveColumns(
      padding: const EdgeInsets.all(16),
      blocks: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.knowledgeCheckProgress(_at + 1, round.length),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: (_at + 1) / round.length),
            const SizedBox(height: 16),
            Text(question.question, style: theme.textTheme.headlineSmall),
          ],
        ),
        Column(
          children: [
            for (var i = 0; i < question.answers.length; i++)
              Card(
                // Only the two that matter get a colour: the one chosen
                // and the right one. Painting the rest red would say that
                // they were considered and rejected, which they were not.
                color: chosen == null
                    ? null
                    : i == question.correct
                    ? theme.colorScheme.primaryContainer
                    : i == chosen
                    ? theme.colorScheme.errorContainer
                    : null,
                child: ListTile(
                  title: Text(question.answers[i]),
                  onTap: chosen == null ? () => _answer(i) : null,
                ),
              ),
          ],
        ),
        if (chosen != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct
                        ? l10n.knowledgeCheckRight
                        : l10n.knowledgeCheckWrong,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(question.because),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                FirstAidGuideScreen(guideId: question.guideId),
                          ),
                        ),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text(l10n.knowledgeCheckReadGuide),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _next,
                        child: Text(
                          _at + 1 < round.length
                              ? l10n.knowledgeCheckNext
                              : l10n.knowledgeCheckFinish,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _summary(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final total = knowledgeQuestionsFor(
      Localizations.localeOf(context).languageCode,
    ).length;

    return AdaptiveColumns(
      padding: const EdgeInsets.all(16),
      blocks: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.knowledgeCheckResult(
                _right.length,
                _right.length + _wrong.length,
              ),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(l10n.knowledgeCheckHeld(_passed.length, total)),
            if (_lastRound != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.knowledgeCheckComeBack,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
        if (_wrong.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.knowledgeCheckReview,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final question in _round!)
                if (_wrong.contains(question.id))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(question.question),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              FirstAidGuideScreen(guideId: question.guideId),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _again,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.knowledgeCheckAgain),
          ),
        ),
      ],
    );
  }
}

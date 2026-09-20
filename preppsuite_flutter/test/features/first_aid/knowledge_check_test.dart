import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides_de.dart';
import 'package:preppsuite_flutter/features/first_aid/application/first_aid_guides_en.dart';
import 'package:preppsuite_flutter/features/first_aid/application/knowledge_check.dart';
import 'package:preppsuite_flutter/features/first_aid/application/knowledge_check_de.dart';
import 'package:preppsuite_flutter/features/first_aid/application/knowledge_check_en.dart';
import 'package:preppsuite_flutter/features/first_aid/application/knowledge_check_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asking back about first aid.
///
/// The rule this file exists to enforce: **a quiz must not know anything
/// the guides do not.** A question whose answer is not in a shipped guide
/// would be a second source of medical advice, arrived at by whoever wrote
/// the question, and this app does not have one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every question points at a guide that exists', () {
    for (final question in [...knowledgeQuestionsDe, ...knowledgeQuestionsEn]) {
      expect(
        firstAidGuideIds,
        contains(question.guideId),
        reason: '${question.id} names ${question.guideId}',
      );
    }
  });

  test('every explanation is the guide\'s own wording, word for word', () {
    // The rule, enforced rather than trusted: an explanation is a
    // sentence lifted out of the guide it names, not a paraphrase and not
    // an addition. The moment somebody may add "because…", the quiz has
    // started giving medical advice of its own.
    for (final pair in [
      (knowledgeQuestionsDe, firstAidGuidesDe),
      (knowledgeQuestionsEn, firstAidGuidesEn),
    ]) {
      for (final question in pair.$1) {
        final guide = pair.$2.firstWhere((g) => g.id == question.guideId);
        final wording = [
          for (final step in guide.steps) ...[step.text, ?step.detail],
          ...guide.cautions,
        ].join(' ').replaceAll(RegExp(r'\s+'), ' ');
        final claim = question.because.replaceAll(RegExp(r'\s+'), ' ').trim();

        expect(
          wording.contains(claim),
          isTrue,
          reason: '${question.id}: "$claim" is not in ${guide.id}',
        );
      }
    }
  });

  test('both languages ask the same questions', () {
    expect(
      knowledgeQuestionsEn.map((q) => q.id).toList(),
      knowledgeQuestionsDe.map((q) => q.id).toList(),
    );
    for (var i = 0; i < knowledgeQuestionsDe.length; i++) {
      expect(
        knowledgeQuestionsEn[i].correct,
        knowledgeQuestionsDe[i].correct,
        reason: knowledgeQuestionsDe[i].id,
      );
      expect(
        knowledgeQuestionsEn[i].guideId,
        knowledgeQuestionsDe[i].guideId,
      );
    }
  });

  test('nothing is empty and every answer index is real', () {
    for (final question in [...knowledgeQuestionsDe, ...knowledgeQuestionsEn]) {
      expect(question.question.trim(), isNotEmpty, reason: question.id);
      expect(question.because.trim(), isNotEmpty, reason: question.id);
      expect(question.answers.length, greaterThanOrEqualTo(2));
      expect(
        question.correct,
        inInclusiveRange(0, question.answers.length - 1),
      );
      for (final answer in question.answers) {
        expect(answer.trim(), isNotEmpty, reason: question.id);
      }
    }
  });

  test('ids are unique', () {
    final ids = knowledgeQuestionsDe.map((q) => q.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('a language nobody wrote for is asked in English', () {
    expect(knowledgeQuestionsFor('nl'), same(knowledgeQuestionsEn));
    expect(knowledgeQuestionsFor('de'), same(knowledgeQuestionsDe));
  });

  group('picking a round', () {
    test('it is short enough to finish', () {
      final round = knowledgeRound(knowledgeQuestionsDe, random: Random(1));
      expect(round, hasLength(knowledgeRoundLength));
      expect(knowledgeRoundLength, lessThan(knowledgeQuestionsDe.length));
    });

    test('what is still open comes first', () {
      // A round that keeps asking what somebody knows never reaches what
      // they do not.
      final passed = knowledgeQuestionsDe
          .take(knowledgeQuestionsDe.length - 2)
          .map((q) => q.id)
          .toSet();
      final round = knowledgeRound(
        knowledgeQuestionsDe,
        passed: passed,
        random: Random(2),
      );

      expect(passed.contains(round[0].id), isFalse);
      expect(passed.contains(round[1].id), isFalse);
    });

    test('a household that knows everything still gets asked', () {
      final all = knowledgeQuestionsDe.map((q) => q.id).toSet();
      expect(
        knowledgeRound(knowledgeQuestionsDe, passed: all, random: Random(3)),
        hasLength(knowledgeRoundLength),
      );
    });

    test('no question is asked twice in one round', () {
      final round = knowledgeRound(knowledgeQuestionsDe, random: Random(4));
      expect(round.map((q) => q.id).toSet().length, round.length);
    });
  });

  group('what is remembered', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    const store = KnowledgeCheckStore();

    test('a right answer is held and a wrong one is taken back', () async {
      await store.record(right: {'a', 'b'}, wrong: {});
      expect(await store.passed(), {'a', 'b'});

      // Getting it wrong after getting it right is exactly what this is
      // looking for. Leaving it marked would hide it.
      await store.record(right: {'c'}, wrong: {'a'});
      expect(await store.passed(), {'b', 'c'});
    });

    test('the date of the last round is kept', () async {
      expect(await store.lastRound(), isNull);
      await store.record(
        right: {'a'},
        wrong: {},
        at: DateTime.utc(2026, 9, 20, 12),
      );
      expect(await store.lastRound(), DateTime.utc(2026, 9, 20, 12));
    });

    test('forgetting really forgets', () async {
      await store.record(right: {'a'}, wrong: {});
      await store.forget();
      expect(await store.passed(), isEmpty);
      expect(await store.lastRound(), isNull);
    });
  });
}

import 'dart:math';

import 'knowledge_check_de.dart';
import 'knowledge_check_en.dart';

/// Asking back, because first aid is knowledge that goes quiet.
///
/// The app has thirty guides and a pacer, and both assume somebody
/// opens them. In the moment they are needed, most people do not: they do
/// what they remember, and what they remember is a course from years ago
/// with the wrong half worn away. Reading a guide again does not find that
/// out. Being asked does.
///
/// So every question here aims at a **belief somebody actually holds**,
/// not at a fact worth memorising. Something into the mouth during a fit,
/// rubbing cold limbs warm, ice on a burn, making somebody sick after
/// swallowing something: each of those is a thing people do, meaning to
/// help, that the guides say plainly not to.
///
/// Nothing here is new content. Every question is answerable from a guide
/// this app already ships, [KnowledgeQuestion.guideId] names it, and the
/// explanation is that guide's own wording — which the tests hold it to.
/// A quiz that knows something the guides do not would be a second source
/// of medical advice, and this app does not have one.
class KnowledgeQuestion {
  const KnowledgeQuestion({
    required this.id,
    required this.guideId,
    required this.question,
    required this.answers,
    required this.correct,
    required this.because,
  });

  /// Stable across languages, and never shown.
  final String id;

  /// The guide this is answerable from, and the one to read afterwards.
  final String guideId;

  final String question;

  /// Kept short and few: this is checking what somebody would do, not
  /// their reading speed.
  final List<String> answers;

  /// Index into [answers].
  final int correct;

  /// Why — in the words of the guide it came from.
  final String because;
}

/// The questions in [languageCode], English for anything not German.
List<KnowledgeQuestion> knowledgeQuestionsFor(String languageCode) =>
    languageCode == 'de' ? knowledgeQuestionsDe : knowledgeQuestionsEn;

/// How many questions one round asks.
///
/// Short on purpose. A round somebody finishes tells them something; one
/// they abandon halfway tells them nothing, and the whole set every time
/// would be the same seventeen in the same order until they are answered
/// from memory rather than from knowledge.
const knowledgeRoundLength = 8;

/// One round, preferring what has not been answered correctly yet.
///
/// Not simply random: a round that keeps asking what somebody already
/// knows is a round that never reaches what they do not. The ones still
/// open come first, shuffled among themselves; the rest fill up behind
/// them, so a household that knows everything still gets asked.
List<KnowledgeQuestion> knowledgeRound(
  List<KnowledgeQuestion> questions, {
  Set<String> passed = const {},
  int length = knowledgeRoundLength,
  Random? random,
}) {
  final shuffle = random ?? Random();
  final open = [
    for (final question in questions)
      if (!passed.contains(question.id)) question,
  ]..shuffle(shuffle);
  final known = [
    for (final question in questions)
      if (passed.contains(question.id)) question,
  ]..shuffle(shuffle);
  return [...open, ...known].take(length).toList();
}

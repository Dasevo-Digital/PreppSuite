import 'knowledge_check.dart';

/// What people actually believe, and what the guides say about it.
const knowledgeQuestionsEn = <KnowledgeQuestion>[
  KnowledgeQuestion(
    id: 'seizure-mouth',
    guideId: 'seizure',
    question:
        'Somebody is having a seizure. What do you put between the teeth?',
    answers: ['Nothing', 'A rolled-up cloth', 'A spoon'],
    correct: 0,
    because:
        'Put nothing in the mouth. Nothing. The tongue cannot be '
        'swallowed; broken teeth and broken fingers can happen.',
  ),
  KnowledgeQuestion(
    id: 'poisoning-vomit',
    guideId: 'poisoning',
    question: 'A child has swallowed something. Make them sick?',
    answers: [
      'No, and call the poison centre',
      'Yes, the sooner the better',
      'Only with salt water',
    ],
    correct: 0,
    because:
        'Do not make them vomit. With acids, alkalis and foaming '
        'agents the way back up does more harm than the way down.',
  ),
  KnowledgeQuestion(
    id: 'poisoning-milk',
    guideId: 'poisoning',
    question: 'Does a glass of milk help after a poisoning?',
    answers: [
      'No, it speeds the uptake of many poisons',
      'Yes, it lines the stomach',
      'Only for cleaning products',
    ],
    correct: 0,
    because: 'No milk. It speeds up the uptake of many poisons.',
  ),
  KnowledgeQuestion(
    id: 'hypothermia-rub',
    guideId: 'hypothermia',
    question: 'A chilled person: rub the arms and legs warm?',
    answers: [
      'No, warm the trunk, neck and head only',
      'Yes, rubbing hard gets the circulation going',
      'Only the hands',
    ],
    correct: 0,
    because:
        'Do not rub arms and legs and do not warm them actively. That '
        'drives cold blood to the heart.',
  ),
  KnowledgeQuestion(
    id: 'burns-ice',
    guideId: 'burns',
    question: 'What do you cool a small burn with?',
    answers: [
      'Hand-warm water, 10 to 20 minutes',
      'Ice cubes from the freezer',
      'Nothing, air is enough',
    ],
    correct: 0,
    because: 'No ice, no iced water. That does further damage.',
  ),
  KnowledgeQuestion(
    id: 'burns-large',
    guideId: 'burns',
    question: 'And with a large burnt area?',
    answers: [
      'Do not cool it — cover it and keep the person warm',
      'Cool it the same way, only for longer',
      'Put them in cold water',
    ],
    correct: 0,
    because:
        'Do not cool large areas — cover them and keep the person '
        'warm.',
  ),
  KnowledgeQuestion(
    id: 'cpr-no-breaths',
    guideId: 'cpr-adult',
    question: 'You cannot or will not give rescue breaths. What then?',
    answers: [
      'Keep pushing without interruption',
      'Wait for the ambulance',
      'Pause after every 30 compressions',
    ],
    correct: 0,
    because:
        'If you cannot or will not give breaths, keep pushing without '
        'stopping. Compression-only is markedly better than nothing.',
  ),
  KnowledgeQuestion(
    id: 'cpr-child-start',
    guideId: 'cpr-child',
    question: 'Resuscitating a child — what do you start with?',
    answers: [
      'Five rescue breaths',
      '30 compressions, as with an adult',
      'The defibrillator',
    ],
    correct: 0,
    because: 'Start with 5 rescue breaths, not with compressions.',
  ),
  KnowledgeQuestion(
    id: 'choking-infant',
    guideId: 'choking',
    question: 'An infant under one is choking. Abdominal thrusts?',
    answers: [
      'No — back blows, face down along the forearm',
      'Yes, but more gently',
      'Yes, the same as for an adult',
    ],
    correct: 0,
    because:
        'No abdominal thrusts on an infant under one year. Instead 5 '
        'back blows face-down along your forearm, then 5 chest '
        'thrusts face-up.',
  ),
  KnowledgeQuestion(
    id: 'shock-drink',
    guideId: 'shock',
    question: 'Somebody in shock asks for water. Do you give it?',
    answers: [
      'No, nothing to eat and nothing to drink',
      'Yes, small sips',
      'Only if they are fully awake',
    ],
    correct: 0,
    because:
        'Nothing to eat and nothing to drink, however firmly they '
        'ask. Surgery may be ahead.',
  ),
  KnowledgeQuestion(
    id: 'stroke-time',
    guideId: 'stroke',
    question: 'A suspected stroke. What must you remember?',
    answers: [
      'The time it started',
      'The blood pressure',
      'When they last ate',
    ],
    correct: 0,
    because: 'Note the time it started.',
  ),
  KnowledgeQuestion(
    id: 'unresponsive-gasping',
    guideId: 'unresponsive',
    question:
        'An unresponsive person takes occasional gasping breaths. Is that '
        'normal breathing?',
    answers: [
      'No — it is a sign of cardiac arrest',
      'Yes, as long as the chest moves',
      'Yes, but keep watching them',
    ],
    correct: 0,
    because:
        'Occasional gasps are not normal breathing. This agonal '
        'breathing is common in the first minutes of a cardiac arrest '
        'and is regularly mistaken for breathing — in doubt, treat it '
        'as no breathing.',
  ),
  KnowledgeQuestion(
    id: 'bleeding-tourniquet',
    guideId: 'severe-bleeding',
    question: 'A tourniquet is on. Loosen it now and then?',
    answers: [
      'No, it stays until medical staff take it off',
      'Yes, briefly every 20 minutes',
      'Yes, once the bleeding has stopped',
    ],
    correct: 0,
    because:
        'A tourniquet once applied stays on until medical staff '
        'remove it. Loosening and retightening is more dangerous than '
        'leaving it.',
  ),
  KnowledgeQuestion(
    id: 'anaphylaxis-after',
    guideId: 'anaphylaxis',
    question:
        'After the auto-injector things improve quickly. Does the person '
        'still need hospital?',
    answers: [
      'Yes, always',
      'No, not once the symptoms are gone',
      'Only if they still feel unwell',
    ],
    correct: 0,
    because:
        'Even if it improves quickly: always go to hospital. In a '
        'proportion of cases the reaction returns hours later.',
  ),
  KnowledgeQuestion(
    id: 'emergency-call-hangup',
    guideId: 'emergency-call',
    question: 'When do you hang up on an emergency call?',
    answers: [
      'When the control room says so',
      'When you have said everything',
      'As soon as the ambulance is on its way',
    ],
    correct: 0,
    because: 'Do not hang up until the dispatcher says so.',
  ),
  KnowledgeQuestion(
    id: 'aed-safe',
    guideId: 'aed',
    question: 'Can a defibrillator harm somebody who needs no shock?',
    answers: [
      'No, it analyses by itself and only then allows one',
      'Yes, which is why only trained people should use it',
      'Yes, if the pads are stuck on wrongly',
    ],
    correct: 0,
    because:
        'An AED never shocks somebody who does not need it. It '
        'analyses by itself and only then releases the button.',
  ),
  KnowledgeQuestion(
    id: 'recovery-turn',
    guideId: 'recovery-position',
    question: 'How long does somebody stay in the recovery position?',
    answers: [
      'At most 30 minutes, then turn them to the other side',
      'Until the ambulance arrives, without turning',
      'As long as it looks comfortable',
    ],
    correct: 0,
    because:
        'Turn them onto the other side after 30 minutes at the '
        'latest.',
  ),
];

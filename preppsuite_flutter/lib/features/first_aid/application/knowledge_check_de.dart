import 'knowledge_check.dart';

/// Was Menschen wirklich glauben, und was die Anleitungen dazu sagen.
const knowledgeQuestionsDe = <KnowledgeQuestion>[
  KnowledgeQuestion(
    id: 'seizure-mouth',
    guideId: 'seizure',
    question:
        'Jemand hat einen Krampfanfall. Was schiebst du zwischen die '
        'Zähne?',
    answers: ['Nichts', 'Ein zusammengerolltes Tuch', 'Einen Löffel'],
    correct: 0,
    because:
        'Nichts in den Mund schieben. Nichts. Die Zunge kann nicht '
        'verschluckt werden, abgebrochene Zähne und gebrochene Finger '
        'dagegen schon.',
  ),
  KnowledgeQuestion(
    id: 'poisoning-vomit',
    guideId: 'poisoning',
    question: 'Ein Kind hat etwas geschluckt. Erbrechen auslösen?',
    answers: [
      'Nein, und den Giftnotruf anrufen',
      'Ja, je schneller desto besser',
      'Nur mit Salzwasser',
    ],
    correct: 0,
    because:
        'Kein Erbrechen auslösen. Bei Säuren, Laugen und Schäumern '
        'richtet der Weg zurück mehr Schaden an als der Weg hinunter.',
  ),
  KnowledgeQuestion(
    id: 'poisoning-milk',
    guideId: 'poisoning',
    question: 'Hilft ein Glas Milch nach einer Vergiftung?',
    answers: [
      'Nein, sie beschleunigt die Aufnahme vieler Gifte',
      'Ja, sie legt sich schützend an',
      'Nur bei Reinigungsmitteln',
    ],
    correct: 0,
    because: 'Keine Milch. Sie beschleunigt die Aufnahme vieler Gifte.',
  ),
  KnowledgeQuestion(
    id: 'hypothermia-rub',
    guideId: 'hypothermia',
    question: 'Unterkühlte Person: Arme und Beine warm reiben?',
    answers: [
      'Nein, wärmen nur Rumpf, Hals und Kopf',
      'Ja, kräftig reiben bringt den Kreislauf in Gang',
      'Nur die Hände',
    ],
    correct: 0,
    because:
        'Arme und Beine nicht reiben und nicht aktiv erwärmen. Das '
        'treibt kaltes Blut zum Herzen.',
  ),
  KnowledgeQuestion(
    id: 'burns-ice',
    guideId: 'burns',
    question: 'Womit kühlst du eine kleine Verbrennung?',
    answers: [
      'Handwarmem Wasser, 10 bis 20 Minuten',
      'Eiswürfeln aus dem Gefrierfach',
      'Gar nicht, Luft reicht',
    ],
    correct: 0,
    because: 'Kein Eis, kein Eiswasser. Das schädigt zusätzlich.',
  ),
  KnowledgeQuestion(
    id: 'burns-large',
    guideId: 'burns',
    question: 'Und bei einer großen verbrannten Fläche?',
    answers: [
      'Nicht kühlen, zudecken und warm halten',
      'Genauso kühlen, nur länger',
      'In kaltes Wasser legen',
    ],
    correct: 0,
    because:
        'Große Flächen nicht kühlen, sondern zudecken und warm '
        'halten.',
  ),
  KnowledgeQuestion(
    id: 'cpr-no-breaths',
    guideId: 'cpr-adult',
    question: 'Du kannst oder willst nicht beatmen. Was dann?',
    answers: [
      'Ohne Unterbrechung weiterdrücken',
      'Auf den Rettungsdienst warten',
      'Alle 30 Kompressionen eine Pause machen',
    ],
    correct: 0,
    because:
        'Kannst oder willst du nicht beatmen, drücke ohne Unterbrechung '
        'weiter. Nur zu drücken ist deutlich besser als nichts zu tun.',
  ),
  KnowledgeQuestion(
    id: 'cpr-child-start',
    guideId: 'cpr-child',
    question: 'Wiederbelebung bei einem Kind — womit fängst du an?',
    answers: [
      'Mit 5 Beatmungen',
      'Mit 30-mal Drücken wie beim Erwachsenen',
      'Mit dem Defibrillator',
    ],
    correct: 0,
    because: 'Mit 5 Beatmungen beginnen, nicht mit dem Drücken.',
  ),
  KnowledgeQuestion(
    id: 'choking-infant',
    guideId: 'choking',
    question: 'Säugling unter einem Jahr verschluckt sich. Heimlich-Griff?',
    answers: [
      'Nein, Rückenschläge in Bauchlage über dem Unterarm',
      'Ja, aber vorsichtiger',
      'Ja, genauso wie beim Erwachsenen',
    ],
    correct: 0,
    because:
        'Bei Säuglingen unter einem Jahr keine '
        'Oberbauchkompressionen. Stattdessen 5 Rückenschläge in '
        'Bauchlage über dem Unterarm, dann 5 Brustkompressionen in '
        'Rückenlage.',
  ),
  KnowledgeQuestion(
    id: 'shock-drink',
    guideId: 'shock',
    question: 'Eine Person im Schock bittet um Wasser. Gibst du es?',
    answers: [
      'Nein, nichts zu essen und nichts zu trinken',
      'Ja, kleine Schlucke',
      'Nur, wenn sie ganz wach ist',
    ],
    correct: 0,
    because:
        'Nichts zu essen und nichts zu trinken geben, auch wenn '
        'ausdrücklich darum gebeten wird. Eine Operation könnte '
        'bevorstehen.',
  ),
  KnowledgeQuestion(
    id: 'stroke-time',
    guideId: 'stroke',
    question: 'Verdacht auf Schlaganfall. Was merkst du dir unbedingt?',
    answers: [
      'Die Uhrzeit, zu der es angefangen hat',
      'Den Blutdruck',
      'Wann die Person zuletzt gegessen hat',
    ],
    correct: 0,
    because: 'Die Uhrzeit merken, zu der es angefangen hat.',
  ),
  KnowledgeQuestion(
    id: 'unresponsive-gasping',
    guideId: 'unresponsive',
    question:
        'Bewusstlose Person macht einzelne schnappende Atemzüge. Atmet '
        'sie normal?',
    answers: [
      'Nein — das ist ein Zeichen für Kreislaufstillstand',
      'Ja, solange sich der Brustkorb bewegt',
      'Ja, aber man sollte sie beobachten',
    ],
    correct: 0,
    because:
        'Einzelne schnappende Atemzüge sind keine normale Atmung. '
        'Diese Schnappatmung ist in den ersten Minuten nach einem '
        'Herzstillstand häufig und wird regelmäßig für Atmung '
        'gehalten – im Zweifel gilt sie als Atemstillstand.',
  ),
  KnowledgeQuestion(
    id: 'bleeding-tourniquet',
    guideId: 'severe-bleeding',
    question: 'Ein Tourniquet sitzt. Zwischendurch lockern?',
    answers: [
      'Nein, es bleibt bis medizinisches Personal es abnimmt',
      'Ja, alle 20 Minuten kurz',
      'Ja, sobald die Blutung steht',
    ],
    correct: 0,
    because:
        'Ein einmal angelegtes Tourniquet bleibt, bis medizinisches '
        'Personal es abnimmt. Lösen und wieder festziehen ist '
        'gefährlicher als es zu lassen.',
  ),
  KnowledgeQuestion(
    id: 'anaphylaxis-after',
    guideId: 'anaphylaxis',
    question:
        'Nach dem Autoinjektor geht es rasch besser. Muss die Person '
        'trotzdem in die Klinik?',
    answers: [
      'Ja, immer',
      'Nein, wenn die Beschwerden weg sind',
      'Nur wenn sie sich noch schlecht fühlt',
    ],
    correct: 0,
    because:
        'Auch wenn es rasch besser wird: immer in die Klinik. Die '
        'Beschwerden kommen in einem Teil der Fälle nach Stunden '
        'zurück.',
  ),
  KnowledgeQuestion(
    id: 'emergency-call-hangup',
    guideId: 'emergency-call',
    question: 'Wann legst du beim Notruf auf?',
    answers: [
      'Wenn die Leitstelle es sagt',
      'Wenn du alles gesagt hast',
      'Sobald der Rettungswagen unterwegs ist',
    ],
    correct: 0,
    because: 'Nicht auflegen, bevor die Leitstelle es sagt.',
  ),
  KnowledgeQuestion(
    id: 'aed-safe',
    guideId: 'aed',
    question:
        'Kann ein Defibrillator jemandem schaden, der keinen Schock '
        'braucht?',
    answers: [
      'Nein, er analysiert selbst und gibt nur dann frei',
      'Ja, deshalb nur mit Ausbildung benutzen',
      'Ja, wenn die Elektroden falsch kleben',
    ],
    correct: 0,
    because:
        'Ein AED schockt nie jemanden, der keinen Schock braucht. Er '
        'analysiert selbst und gibt nur dann frei.',
  ),
  KnowledgeQuestion(
    id: 'recovery-turn',
    guideId: 'recovery-position',
    question: 'Wie lange bleibt jemand in der stabilen Seitenlage liegen?',
    answers: [
      'Höchstens 30 Minuten, dann auf die andere Seite',
      'Bis der Rettungsdienst da ist, ohne zu drehen',
      'So lange wie es bequem aussieht',
    ],
    correct: 0,
    because: 'Nach spätestens 30 Minuten auf die andere Seite drehen.',
  ),
  KnowledgeQuestion(
    id: 'suicide-asking',
    guideId: 'suicidal-ideation',
    question:
        'Jemand deutet an, nicht mehr leben zu wollen. Direkt danach '
        'fragen?',
    answers: [
      'Ja, direkt fragen',
      'Nein, das bringt ihn erst auf den Gedanken',
      'Nur andeuten und abwarten',
    ],
    correct: 0,
    because:
        'Darüber zu sprechen erhöht die Wahrscheinlichkeit nicht, dass '
        'jemand es tut.',
  ),
  KnowledgeQuestion(
    id: 'panic-bag',
    guideId: 'anxiety-panic',
    question: 'Hilft eine Tüte vor dem Mund bei einer Panikattacke?',
    answers: [
      'Nein, vor- und mitatmen',
      'Ja, das gleicht die Atmung wieder aus',
      'Nur wenn jemand hyperventiliert',
    ],
    correct: 0,
    because:
        'Keine Tüte vor den Mund. Die Leitlinien 2025 sprechen für '
        'dieses und ähnliche Hausmittel keine Empfehlung aus; empfohlen '
        'ist das Vor- und Mitatmen.',
  ),
  KnowledgeQuestion(
    id: 'drowning-breaths',
    guideId: 'drowning',
    question:
        'Jemand wurde aus dem Wasser geholt und atmet nicht. Nur drücken '
        'oder auch beatmen?',
    answers: [
      'Auch beatmen, 30 zu 2',
      'Nur drücken, wie beim Herzstillstand',
      'Erst das Wasser herausdrücken',
    ],
    correct: 0,
    because:
        'Beim Ertrinken gehören die Beatmungen dazu – anders als beim '
        'Herzstillstand. Angefangen wird trotzdem mit dem Drücken.',
  ),
  KnowledgeQuestion(
    id: 'hypo-diet-drink',
    guideId: 'hypoglycaemia',
    question: 'Unterzuckerung, und im Kühlschrank steht Cola light. Hilft die?',
    answers: [
      'Nein, da ist kein Zucker drin',
      'Ja, Cola ist Cola',
      'Ja, aber nur in größerer Menge',
    ],
    correct: 0,
    because: 'Keine Diät- oder Light-Getränke. Da ist kein Zucker drin.',
  ),
  KnowledgeQuestion(
    id: 'frostbite-heater',
    guideId: 'frostbite',
    question: 'Erfrorene Finger an den Heizlüfter halten?',
    answers: [
      'Nein, körperwarmes Wasser',
      'Ja, Hauptsache schnell warm',
      'Ja, aber nur kurz',
    ],
    correct: 0,
    because: 'Nicht an direkte Hitze wie Heizlüfter oder Herd.',
  ),
  KnowledgeQuestion(
    id: 'nosebleed-head',
    guideId: 'nosebleed',
    question: 'Nasenbluten. Kopf in den Nacken?',
    answers: [
      'Nein, leicht nach vorn',
      'Ja, dann hört es schneller auf',
      'Egal, Hauptsache zudrücken',
    ],
    correct: 0,
    because:
        'Den Kopf nicht in den Nacken legen. Das Blut läuft dann in den '
        'Rachen.',
  ),
  KnowledgeQuestion(
    id: 'snakebite-suck',
    guideId: 'snakebite',
    question: 'Kreuzotterbiss. Abbinden und Gift aussaugen?',
    answers: [
      'Nein, beides schadet',
      'Abbinden ja, aussaugen nein',
      'Beides, so schnell wie möglich',
    ],
    correct: 0,
    because:
        'Nichts davon hilft, und alles davon kann schaden: abbinden, Gift '
        'aussaugen, kühlen, die Stelle reiben, die Wunde aufschneiden.',
  ),
  KnowledgeQuestion(
    id: 'tick-oil',
    guideId: 'tick',
    question: 'Zecke mit Öl oder einem Streichholz lösen?',
    answers: [
      'Nein, einfach herausziehen',
      'Ja, dann lässt sie von selbst los',
      'Nur Öl, keine Hitze',
    ],
    correct: 0,
    because:
        'Keine Chemie und keine Hitze, um die Zecke zu betäuben oder zu '
        'töten.',
  ),
  KnowledgeQuestion(
    id: 'amputation-ice',
    guideId: 'amputation',
    question: 'Abgetrennter Finger – direkt auf Eis legen?',
    answers: [
      'Nein, erst in einen Beutel, dann in Eiswasser',
      'Ja, je kälter desto besser',
      'Nein, in Wasser legen',
    ],
    correct: 0,
    because:
        'Das Körperteil nicht direkt ins Wasser und nicht direkt auf Eis. '
        'Das schädigt das Gewebe und kann das Wiederannähen unmöglich '
        'machen.',
  ),
  KnowledgeQuestion(
    id: 'jellyfish-water',
    guideId: 'jellyfish',
    question: 'Quallenstrieme mit Leitungswasser abspülen?',
    answers: [
      'Nein, mit Meerwasser',
      'Ja, Hauptsache sauber',
      'Ja, und danach kühlen',
    ],
    correct: 0,
    because: 'Nicht mit Süßwasser abspülen – Meerwasser.',
  ),
];

import 'first_aid_guide.dart';
import 'poison_centres.dart';

/// Die Erste-Hilfe-Anleitungen auf Deutsch.
///
/// Die Reihenfolge ist die Reihenfolge auf dem Bildschirm und sie ist
/// nach Dringlichkeit sortiert, nicht alphabetisch.
///
/// Der Inhalt folgt den Reanimationsleitlinien 2025 des European
/// Resuscitation Council in der deutschen Fassung des German Resuscitation
/// Council sowie deren Erste-Hilfe-Kapitel. Die Zahlen sind deren Zahlen;
/// die Worte sind die dieser App. Jede Anleitung nennt ihre Quelle auf dem
/// Bildschirm.
///
/// Zum Schritt von 2021 auf 2025: die Zahlen für Laien haben sich nicht
/// geändert — 30:2, 5 bis 6 cm, 100 bis 120 in der Minute. Geändert hat
/// sich die Reihenfolge. Der Notruf kommt vor die Atemkontrolle und wird
/// mit der Leitstelle am Lautsprecher weitergeführt, damit früher gedrückt
/// wird; Schnappatmung ist ausdrücklich keine normale Atmung; und es wird
/// nicht mehr erst umgelagert und ausgezogen, bevor jemand anfängt.
///
/// Was hier bewusst **nicht** behauptet wird: dass die deutschen
/// Lehraussagen für Erste-Hilfe-Kurse schon umgestellt sind. Die stimmen
/// die Hilfsorganisationen gemeinsam über die Bundesarbeitsgemeinschaft
/// Erste Hilfe ab, zu einem festgelegten Zeitpunkt und nicht jede für
/// sich. Wer einen Kurs besucht, lernt, was dort gilt — diese Anleitungen
/// widersprechen dem in keiner Zahl.
///
/// Was hier bewusst fehlt: alles, was ohne Ausbildung nicht sicher
/// anzuwenden ist, und jede Dosierung eines Medikaments, das nicht dem
/// Verletzten selbst verordnet wurde.
const firstAidGuidesDe = <FirstAidGuide>[
  FirstAidGuide(
    id: 'emergency-call',
    group: FirstAidGroup.basics,
    title: 'Notruf absetzen',
    when: 'Immer zuerst, sobald jemand ernsthaft in Gefahr ist.',
    steps: [
      FirstAidStep(
        'Wo ist es passiert?',
        detail:
            'Ort, Straße, Hausnummer, Stockwerk. Auf dem Land: '
            'Gemeinde und was in der Nähe steht.',
      ),
      FirstAidStep(
        'Was ist passiert?',
        detail:
            'Ein Satz genügt: Sturz vom Dach, Person atmet nicht, '
            'Auto gegen Baum.',
      ),
      FirstAidStep('Wie viele Verletzte?'),
      FirstAidStep(
        'Welche Verletzungen?',
        detail: 'Was du siehst, nicht was du vermutest.',
      ),
      FirstAidStep(
        'Warten auf Rückfragen.',
        detail:
            'Die Leitstelle beendet das Gespräch, nicht du. Sie '
            'leitet dich am Telefon an, bis der Rettungsdienst da ist.',
      ),
    ],
    facts: [
      FirstAidFact('Rettungsdienst und Feuerwehr', '112'),
      FirstAidFact('Polizei', '110'),
      FirstAidFact('Ärztlicher Bereitschaftsdienst', '116 117'),
      FirstAidFact('Europaweit', '112'),
    ],
    cautions: [
      'Nicht auflegen, bevor die Leitstelle es sagt.',
      'Kein Netz heißt nicht kein Notruf: 112 geht auch ohne Guthaben '
          'und in vielen Fällen über ein fremdes Netz.',
    ],
    source: 'Bundesamt für Bevölkerungsschutz und Katastrophenhilfe',
  ),
  FirstAidGuide(
    id: 'unresponsive',
    group: FirstAidGroup.basics,
    title: 'Bewusstlose Person prüfen',
    when:
        'Jemand liegt da und reagiert nicht. Das ist der Anfang von '
        'allem, was danach kommt.',
    steps: [
      FirstAidStep(
        'Eigene Sicherheit zuerst.',
        detail:
            'Verkehr, Strom, Rauch, Gas. Ein zweiter Verletzter '
            'hilft niemandem.',
      ),
      FirstAidStep(
        'Laut ansprechen und an den Schultern rütteln.',
      ),
      FirstAidStep(
        'Keine Reaktion? Um Hilfe rufen und 112 wählen.',
        detail: 'Telefon auf Lautsprecher, damit die Hände frei bleiben.',
      ),
      FirstAidStep(
        'Atemwege frei machen.',
        detail:
            'Eine Hand auf die Stirn, zwei Finger der anderen unter '
            'das Kinn, Kopf vorsichtig nach hinten neigen.',
      ),
      FirstAidStep(
        'Höchstens 10 Sekunden auf die Atmung achten.',
        detail:
            'Hebt sich der Brustkorb? Hörst du Atemgeräusche? '
            'Spürst du die Luft an deiner Wange?',
      ),
      FirstAidStep(
        'Atmet normal: stabile Seitenlage, Atmung weiter beobachten.',
      ),
      FirstAidStep(
        'Atmet nicht normal: sofort mit der Wiederbelebung beginnen.',
      ),
    ],
    cautions: [
      'Einzelne schnappende Atemzüge sind keine normale Atmung. Diese '
          'Schnappatmung ist in den ersten Minuten nach einem '
          'Herzstillstand häufig und wird regelmäßig für Atmung '
          'gehalten – im Zweifel gilt sie als Atemstillstand.',
      'Im Zweifel drücken. Herzdruckmassage bei jemandem, dessen Herz '
          'noch schlägt, richtet weit weniger Schaden an als unterlassene '
          'Wiederbelebung bei jemandem, dessen Herz steht.',
    ],
    source:
        'Reanimationsleitlinien 2025 des European Resuscitation '
        'Council (ERC), deutsche Fassung des German Resuscitation Council',
  ),
  FirstAidGuide(
    id: 'cpr-adult',
    group: FirstAidGroup.lifeThreatening,
    title: 'Wiederbelebung – Erwachsener',
    when: 'Die Person reagiert nicht und atmet nicht normal.',
    callFirst: true,
    drawing: FirstAidDrawing.compressionPoint,
    hasPacer: true,
    steps: [
      FirstAidStep(
        '112 anrufen und einen Defibrillator holen lassen.',
        detail:
            'Bist du allein: erst anrufen, Lautsprecher an, dann '
            'drücken. Ist jemand bei dir: er ruft an und holt den AED, '
            'du drückst.',
      ),
      FirstAidStep(
        'Sofort anfangen, wo die Person liegt.',
        detail:
            'Kleidung nur öffnen, wenn du sonst den Druckpunkt nicht '
            'findest. Auf eine harte Unterlage umlagern nur, wenn es '
            'in Sekunden geht — jede Verzögerung kostet mehr, als die '
            'weiche Unterlage.',
      ),
      FirstAidStep(
        'Einen Handballen auf die Mitte des Brustkorbs setzen, '
        'die zweite Hand darüber, Finger verschränken.',
        detail:
            'Mitte des Brustkorbs heißt untere Hälfte des '
            'Brustbeins.',
      ),
      FirstAidStep(
        '30-mal drücken.',
        detail:
            '5 bis 6 cm tief, 100 bis 120 Mal in der Minute, Arme '
            'gestreckt, senkrecht von oben. Den Brustkorb nach jedem '
            'Druck vollständig hochkommen lassen.',
      ),
      FirstAidStep(
        '2-mal beatmen.',
        detail:
            'Kopf überstrecken, Nase zuhalten, eine Sekunde lang '
            'gleichmäßig einblasen, bis sich der Brustkorb sichtbar hebt. '
            'Zusammen höchstens 10 Sekunden.',
      ),
      FirstAidStep(
        'Weiter im Wechsel 30:2, ohne Pause.',
        detail:
            'Bis der Rettungsdienst übernimmt, ein AED anweist '
            'abzusetzen, oder die Person normal zu atmen beginnt.',
      ),
      FirstAidStep(
        'Zu zweit alle zwei Minuten wechseln.',
        detail:
            'Der Wechsel dauert Sekunden. Müde Hände drücken zu '
            'flach, ohne dass man es merkt.',
      ),
    ],
    facts: [
      FirstAidFact('Takt', '100–120 pro Minute'),
      FirstAidFact('Tiefe', '5–6 cm'),
      FirstAidFact('Verhältnis', '30 Kompressionen : 2 Beatmungen'),
    ],
    cautions: [
      'Kannst oder willst du nicht beatmen, drücke ohne Unterbrechung '
          'weiter. Nur zu drücken ist deutlich besser als nichts zu tun.',
      'Nicht aufhören, um zu prüfen, ob es wirkt. Jede Unterbrechung '
          'lässt den Druck im Kreislauf zusammenfallen.',
      'Knackende Geräusche sind normal und kein Grund aufzuhören.',
    ],
    source:
        'Reanimationsleitlinien 2025 des European Resuscitation '
        'Council (ERC), deutsche Fassung des German Resuscitation Council',
  ),
  FirstAidGuide(
    id: 'cpr-child',
    group: FirstAidGroup.lifeThreatening,
    title: 'Wiederbelebung – Kind und Säugling',
    when:
        'Ein Kind unter der Pubertät oder ein Säugling reagiert nicht '
        'und atmet nicht normal.',
    callFirst: true,
    hasPacer: true,
    steps: [
      FirstAidStep(
        '112 anrufen, sobald das Kind nicht reagiert und nicht normal '
        'atmet.',
        detail:
            'Telefon auf Lautsprecher und liegen lassen — so bleibst du '
            'beim Kind und hast die Hände frei. Bis 2021 galt hier noch: '
            'erst eine Minute wiederbeleben, dann anrufen. Seit den '
            'Leitlinien 2025 ist die Reihenfolge dieselbe wie beim '
            'Erwachsenen.',
      ),
      FirstAidStep(
        'Mit 5 Beatmungen beginnen, nicht mit dem Drücken.',
        detail:
            'Bei Kindern steht das Herz fast immer wegen '
            'Sauerstoffmangel still, nicht umgekehrt. Beim Säugling Mund '
            'und Nase zugleich umschließen.',
      ),
      FirstAidStep(
        '15-mal drücken, dann 2-mal beatmen.',
        detail:
            'Kind: ein oder zwei Handballen. Säugling: zwei Finger '
            'oder beide Daumen bei umfassten Händen.',
      ),
      FirstAidStep(
        'Ein Drittel des Brustkorbdurchmessers tief drücken.',
        detail:
            'Etwa 5 cm beim Kind, etwa 4 cm beim Säugling. Takt wie '
            'beim Erwachsenen: 100 bis 120 in der Minute.',
      ),
      FirstAidStep(
        'Weiter 15:2, bis Hilfe da ist.',
      ),
    ],
    facts: [
      FirstAidFact('Erst', '5 Beatmungen'),
      FirstAidFact('Dann', '15 Kompressionen : 2 Beatmungen'),
      FirstAidFact('Tiefe Kind', 'etwa 5 cm'),
      FirstAidFact('Tiefe Säugling', 'etwa 4 cm'),
      FirstAidFact('Takt', '100–120 pro Minute'),
    ],
    cautions: [
      'Traust du dir das Verhältnis 15:2 nicht zu, nimm 30:2 wie beim '
          'Erwachsenen. Das ist ausdrücklich erlaubt und weit besser als '
          'zu zögern.',
      'Zu vorsichtig zu drücken ist der häufigste Fehler. Ein Kind, '
          'dessen Herz steht, kann durch zu zaghaftes Drücken nicht '
          'gerettet werden.',
    ],
    source:
        'Reanimationsleitlinien 2025 des European Resuscitation '
        'Council (ERC), deutsche Fassung des German Resuscitation Council',
  ),
  FirstAidGuide(
    id: 'aed',
    group: FirstAidGroup.lifeThreatening,
    title: 'Defibrillator (AED)',
    when: 'Ein Gerät ist erreichbar, während wiederbelebt wird.',
    steps: [
      FirstAidStep(
        'Einschalten. Das Gerät sagt ab jetzt alles an.',
      ),
      FirstAidStep(
        'Weiter drücken, während die Elektroden aufgeklebt werden.',
        detail: 'Nur wenn du allein bist, unterbrich dafür kurz.',
      ),
      FirstAidStep(
        'Elektroden auf den nackten Brustkorb kleben, wie aufgedruckt.',
        detail:
            'Eine unter das rechte Schlüsselbein, eine seitlich '
            'unter die linke Achsel. Brust nass? Vorher abtrocknen.',
      ),
      FirstAidStep(
        'Während der Analyse niemanden berühren.',
      ),
      FirstAidStep(
        'Schock empfohlen: sicherstellen, dass niemand die Person '
        'berührt, dann auslösen.',
      ),
      FirstAidStep(
        'Sofort danach weiter drücken.',
        detail:
            'Ohne auf eine Reaktion zu warten. Das Gerät meldet sich '
            'nach zwei Minuten von selbst wieder.',
      ),
    ],
    cautions: [
      'Ein AED schockt nie jemanden, der keinen Schock braucht. Er '
          'analysiert selbst und gibt nur dann frei.',
      'Kinder unter acht Jahren: Kinderelektroden verwenden, wenn '
          'vorhanden. Sind keine da, nimm die für Erwachsene – das ist '
          'besser als kein Schock.',
      'Elektroden nicht auf einen Herzschrittmacher kleben; ein paar '
          'Zentimeter daneben genügen. Medikamentenpflaster vorher '
          'abziehen.',
    ],
    source:
        'Reanimationsleitlinien 2025 des European Resuscitation '
        'Council (ERC), deutsche Fassung des German Resuscitation Council',
  ),
  FirstAidGuide(
    id: 'recovery-position',
    group: FirstAidGroup.lifeThreatening,
    title: 'Stabile Seitenlage',
    when: 'Die Person ist bewusstlos und atmet normal.',
    drawing: FirstAidDrawing.recoveryPosition,
    steps: [
      FirstAidStep(
        'Neben der Person knien, Beine gerade legen.',
      ),
      FirstAidStep(
        'Den nahen Arm im rechten Winkel nach oben legen, Handfläche '
        'nach oben.',
      ),
      FirstAidStep(
        'Den fernen Arm über die Brust ziehen, den Handrücken an die '
        'nahe Wange legen und dort festhalten.',
      ),
      FirstAidStep(
        'Das ferne Knie anwinkeln und die Person am Knie zu dir '
        'herüberziehen.',
      ),
      FirstAidStep(
        'Das obenliegende Bein so ausrichten, dass Hüfte und Knie im '
        'rechten Winkel liegen.',
      ),
      FirstAidStep(
        'Den Kopf nach hinten neigen, damit die Atemwege frei bleiben '
        'und der Mund der tiefste Punkt ist.',
      ),
      FirstAidStep(
        'Die Atmung weiter beobachten.',
        detail:
            'Hört sie auf oder wird sie unnormal: auf den Rücken '
            'drehen und mit der Wiederbelebung beginnen.',
      ),
    ],
    cautions: [
      'Nach spätestens 30 Minuten auf die andere Seite drehen.',
      'Bei Verdacht auf eine Wirbelsäulenverletzung nur dann drehen, '
          'wenn die Atemwege anders nicht frei zu halten sind. Freie '
          'Atemwege haben Vorrang.',
    ],
    source:
        'Reanimationsleitlinien 2025 des European Resuscitation '
        'Council (ERC), deutsche Fassung des German Resuscitation Council',
  ),
  FirstAidGuide(
    id: 'choking',
    group: FirstAidGroup.lifeThreatening,
    title: 'Ersticken',
    when:
        'Jemand greift sich an den Hals, kann nicht sprechen, nicht '
        'husten, nicht atmen.',
    drawing: FirstAidDrawing.choking,
    steps: [
      FirstAidStep(
        'Hustet die Person noch kräftig: zum Weiterhusten auffordern '
        'und dabeibleiben.',
        detail: 'Husten ist stärker als alles, was du tun kannst.',
      ),
      FirstAidStep(
        'Wird das Husten schwach: 5 Schläge zwischen die '
        'Schulterblätter.',
        detail:
            'Oberkörper nach vorn beugen, mit dem Handballen kräftig '
            'schlagen, nach jedem Schlag prüfen.',
      ),
      FirstAidStep(
        'Bleibt es stecken: 5 Oberbauchkompressionen.',
        detail:
            'Von hinten umfassen, eine Faust zwischen Nabel und '
            'Brustbeinende, mit der anderen Hand umgreifen, kräftig nach '
            'hinten und oben ziehen.',
      ),
      FirstAidStep(
        'Im Wechsel weiter: 5 Schläge, 5 Kompressionen.',
      ),
      FirstAidStep(
        'Wird die Person bewusstlos: 112 und sofort Wiederbelebung.',
      ),
    ],
    facts: [
      FirstAidFact('Wechsel', '5 Rückenschläge, 5 Oberbauchkompressionen'),
      FirstAidFact('Säugling', '5 Rückenschläge, 5 Brustkompressionen'),
    ],
    cautions: [
      'Bei Säuglingen unter einem Jahr keine Oberbauchkompressionen. '
          'Stattdessen 5 Rückenschläge in Bauchlage über dem Unterarm, '
          'dann 5 Brustkompressionen in Rückenlage.',
      'Nicht mit den Fingern blind im Mund nachfassen. Das schiebt den '
          'Fremdkörper meist tiefer.',
      'Nach Oberbauchkompressionen immer ärztlich untersuchen lassen, '
          'auch wenn alles gut aussieht – innere Verletzungen sind '
          'möglich.',
    ],
    source:
        'Reanimationsleitlinien 2025 des European Resuscitation '
        'Council (ERC), deutsche Fassung des German Resuscitation Council',
  ),
  FirstAidGuide(
    id: 'severe-bleeding',
    group: FirstAidGroup.injury,
    title: 'Starke Blutung',
    when: 'Blut fließt kräftig, spritzt oder durchtränkt die Kleidung.',
    callFirst: true,
    drawing: FirstAidDrawing.bleeding,
    steps: [
      FirstAidStep(
        'Sofort direkt auf die Wunde drücken.',
        detail:
            'Mit der Hand, mit einem Tuch, mit dem, was da ist. '
            'Handschuhe nur, wenn sie in Reichweite liegen.',
      ),
      FirstAidStep('112 anrufen oder anrufen lassen.'),
      FirstAidStep(
        'Die blutende Stelle hochhalten, wenn es geht.',
      ),
      FirstAidStep(
        'Druckverband anlegen und den Druck halten.',
        detail:
            'Blutet es durch: nicht abnehmen, sondern eine weitere '
            'Lage darüber und weiter drücken.',
      ),
      FirstAidStep(
        'Lässt sich eine Blutung an Arm oder Bein so nicht stillen: '
        'Tourniquet.',
        detail:
            '5 bis 7 cm oberhalb der Wunde, nie über einem Gelenk. '
            'So fest, bis es nicht mehr blutet. Uhrzeit auf die Haut '
            'schreiben.',
      ),
      FirstAidStep(
        'Die Person flach hinlegen und warm halten.',
        detail: 'Auf Zeichen eines Schocks achten.',
      ),
    ],
    cautions: [
      'Ein einmal angelegtes Tourniquet bleibt, bis medizinisches '
          'Personal es abnimmt. Lösen und wieder festziehen ist '
          'gefährlicher als es zu lassen.',
      'Den Verband nicht anheben, um nachzusehen. Jedes Nachschauen '
          'reißt die gerade entstandene Gerinnung wieder auf.',
      'Einen tief steckenden Fremdkörper nicht herausziehen. Er '
          'verschließt die Wunde, die er gemacht hat. Ringsherum '
          'abpolstern.',
    ],
    source:
        'Erste-Hilfe-Leitlinien 2025 des European Resuscitation '
        'Council (ERC)',
  ),
  FirstAidGuide(
    id: 'shock',
    group: FirstAidGroup.injury,
    title: 'Schock',
    when:
        'Blass, kalte feuchte Haut, schneller flacher Puls, unruhig '
        'oder auffallend teilnahmslos – nach Blutverlust, Verbrennung '
        'oder starken Schmerzen.',
    callFirst: true,
    steps: [
      FirstAidStep('112 anrufen.'),
      FirstAidStep(
        'Die Ursache beheben, soweit möglich.',
        detail:
            'Eine Blutung zuerst stillen. Ohne das hilft die '
            'Lagerung wenig.',
      ),
      FirstAidStep(
        'Flach hinlegen und die Beine etwa 30 cm hochlegen.',
        detail:
            'Nicht bei Verdacht auf Verletzungen von Wirbelsäule, '
            'Becken oder Beinen und nicht bei Atemnot.',
      ),
      FirstAidStep(
        'Warm halten.',
        detail:
            'Eine Decke auch unter die Person, nicht nur darüber. '
            'Der Boden zieht mehr Wärme als die Luft.',
      ),
      FirstAidStep(
        'Bleiben, ansprechen, Atmung beobachten.',
      ),
    ],
    cautions: [
      'Nichts zu essen und nichts zu trinken geben, auch wenn '
          'ausdrücklich darum gebeten wird. Eine Operation könnte '
          'bevorstehen.',
      'Wird die Person bewusstlos und atmet normal: stabile Seitenlage. '
          'Atmet sie nicht normal: Wiederbelebung.',
    ],
    source:
        'Erste-Hilfe-Leitlinien 2025 des European Resuscitation '
        'Council (ERC)',
  ),
  FirstAidGuide(
    id: 'burns',
    group: FirstAidGroup.injury,
    title: 'Verbrennung und Verbrühung',
    when:
        'Hitze, Feuer, heiße Flüssigkeit, Strom oder Chemie haben die '
        'Haut verletzt.',
    steps: [
      FirstAidStep(
        'Die Ursache beenden.',
        detail:
            'Flammen ersticken, Strom abschalten, durchnässte heiße '
            'Kleidung entfernen, solange sie nicht festklebt.',
      ),
      FirstAidStep(
        'Kleine Flächen 10 bis 20 Minuten kühlen.',
        detail:
            'Fließendes lauwarmes Wasser, etwa 20 °C. Nur Hände, '
            'Füße, Gesicht oder einzelne Stellen.',
      ),
      FirstAidStep(
        'Ringe, Uhren und Armbänder sofort abnehmen.',
        detail: 'Bevor es anschwillt. Danach geht es nicht mehr.',
      ),
      FirstAidStep(
        'Locker und keimarm abdecken.',
        detail:
            'Brandwundenauflage oder ein sauberes Tuch. Nichts, was '
            'fasert.',
      ),
      FirstAidStep(
        'Große Flächen nicht kühlen, sondern zudecken und warm halten.',
        detail:
            'Mehr als eine Handfläche des Verletzten. Kühlen führt '
            'dann zu Unterkühlung, die gefährlicher ist als die '
            'Verbrennung.',
      ),
      FirstAidStep(
        '112 bei großer Fläche, bei Gesicht, Händen, Genitalien oder '
        'Gelenken, bei Kindern, bei Strom und bei Chemie.',
      ),
    ],
    cautions: [
      'Kein Eis, kein Eiswasser. Das schädigt zusätzlich.',
      'Blasen nicht öffnen.',
      'Keine Salbe, kein Öl, kein Mehl, kein Puder, kein Hausmittel.',
      'Festgeklebte Kleidung nicht abziehen. Herumschneiden statt '
          'abreißen.',
    ],
    source:
        'Erste-Hilfe-Leitlinien 2025 des European Resuscitation '
        'Council (ERC)',
  ),
  FirstAidGuide(
    id: 'stroke',
    group: FirstAidGroup.illness,
    title: 'Schlaganfall',
    when:
        'Plötzlich: hängender Mundwinkel, kraftloser Arm, verwaschene '
        'Sprache, Sehstörung oder stärkster Kopfschmerz aus dem Nichts.',
    callFirst: true,
    drawing: FirstAidDrawing.face,
    steps: [
      FirstAidStep(
        'Lächeln lassen.',
        detail: 'Hängt eine Gesichtshälfte?',
      ),
      FirstAidStep(
        'Beide Arme nach vorn heben lassen, Handflächen nach oben.',
        detail: 'Sinkt einer ab oder dreht sich?',
      ),
      FirstAidStep(
        'Einen einfachen Satz nachsprechen lassen.',
        detail: 'Klingt es verwaschen, oder werden Worte vertauscht?',
      ),
      FirstAidStep(
        'Eines davon auffällig: sofort 112.',
        detail: 'Und sagen, dass es ein Schlaganfall sein könnte.',
      ),
      FirstAidStep(
        'Die Uhrzeit merken, zu der es angefangen hat.',
        detail:
            'Das ist die wichtigste Auskunft, die du geben kannst – '
            'sie entscheidet über die Behandlung. War die Person beim '
            'Aufwachen schon betroffen, gilt der Zeitpunkt, zu dem sie '
            'zuletzt gesund gesehen wurde.',
      ),
      FirstAidStep(
        'Oberkörper leicht erhöht lagern, bei Bewusstsein.',
      ),
    ],
    facts: [
      FirstAidFact('F – Face', 'Gesicht hängt'),
      FirstAidFact('A – Arms', 'Arm sinkt ab'),
      FirstAidFact('S – Speech', 'Sprache verwaschen'),
      FirstAidFact('T – Time', 'Sofort 112, Uhrzeit merken'),
    ],
    cautions: [
      'Nichts zu essen und nichts zu trinken geben. Das Schlucken kann '
          'gestört sein, ohne dass man es sieht.',
      'Nicht abwarten, ob es besser wird. Auch wenn die Zeichen wieder '
          'verschwinden, ist es ein Notfall.',
      'Nicht selbst fahren und nicht fahren lassen.',
    ],
    source:
        'Erste-Hilfe-Leitlinien 2025 des European Resuscitation '
        'Council (ERC)',
  ),
  FirstAidGuide(
    id: 'heart-attack',
    group: FirstAidGroup.illness,
    title: 'Herzinfarkt',
    when:
        'Druck, Enge oder Schmerz in der Brust, länger als ein paar '
        'Minuten – oft mit Atemnot, Übelkeit, kaltem Schweiß und Angst.',
    callFirst: true,
    steps: [
      FirstAidStep(
        'Sofort 112. Nicht abwarten.',
      ),
      FirstAidStep(
        'Oberkörper hoch lagern, halb sitzend.',
      ),
      FirstAidStep(
        'Beengende Kleidung öffnen, Fenster auf.',
      ),
      FirstAidStep(
        'Bei der Person bleiben und ruhig mit ihr sprechen.',
        detail:
            'Angst treibt den Puls und damit den Sauerstoffbedarf '
            'des Herzens.',
      ),
      FirstAidStep(
        'Jede Anstrengung vermeiden.',
        detail: 'Nicht laufen lassen, nicht Treppen steigen lassen.',
      ),
      FirstAidStep(
        'Bewusstlos und keine normale Atmung: sofort Wiederbelebung.',
      ),
    ],
    cautions: [
      'Bei Frauen, älteren Menschen und Diabetikern fehlt der typische '
          'Brustschmerz oft. Dann stehen Atemnot, Übelkeit, '
          'Oberbauchschmerz oder plötzliche Erschöpfung im Vordergrund.',
      'Nicht selbst ins Krankenhaus fahren. Im Rettungswagen beginnt '
          'die Behandlung, im eigenen Auto nicht.',
      'Kein Medikament geben, das nicht dieser Person verordnet wurde.',
    ],
    source:
        'Erste-Hilfe-Leitlinien 2025 des European Resuscitation '
        'Council (ERC)',
  ),
  FirstAidGuide(
    id: 'seizure',
    group: FirstAidGroup.illness,
    title: 'Krampfanfall',
    when:
        'Jemand stürzt, wird steif und zuckt, oft mit verdrehten '
        'Augen und Speichel am Mund.',
    steps: [
      FirstAidStep(
        'Platz schaffen und Gefährliches wegräumen.',
      ),
      FirstAidStep(
        'Etwas Weiches unter den Kopf legen.',
      ),
      FirstAidStep(
        'Auf die Uhr sehen.',
        detail:
            'Wie lange der Anfall dauert, ist die Auskunft, nach der '
            'als Erstes gefragt wird.',
      ),
      FirstAidStep(
        'Warten, bis es vorbei ist.',
        detail:
            'Die meisten Anfälle enden nach ein bis zwei Minuten von '
            'selbst.',
      ),
      FirstAidStep(
        'Danach stabile Seitenlage und dabeibleiben.',
        detail: 'Die Verwirrung danach dauert oft länger als der Anfall.',
      ),
    ],
    facts: [
      FirstAidFact('112 rufen, wenn', 'der Anfall länger als 5 Minuten dauert'),
      FirstAidFact('Ebenso, wenn', 'es der erste Anfall ist'),
      FirstAidFact(
        'Ebenso, wenn',
        'ein zweiter folgt, ohne dass die Person '
            'zwischendurch zu sich kommt',
      ),
      FirstAidFact('Ebenso bei', 'Verletzung, Schwangerschaft, Wasser'),
    ],
    cautions: [
      'Nichts in den Mund schieben. Nichts. Die Zunge kann nicht '
          'verschluckt werden, abgebrochene Zähne und gebrochene Finger '
          'dagegen schon.',
      'Nicht festhalten und die Zuckungen nicht unterdrücken.',
      'Nichts zu trinken geben, solange die Person nicht wieder klar '
          'ist.',
    ],
    source:
        'Erste-Hilfe-Leitlinien 2025 des European Resuscitation '
        'Council (ERC)',
  ),
  FirstAidGuide(
    id: 'anaphylaxis',
    group: FirstAidGroup.illness,
    title: 'Allergischer Schock',
    when:
        'Nach Stich, Nuss, Medikament oder Lebensmittel: Quaddeln, '
        'schwellendes Gesicht, pfeifende Atmung, Engegefühl im Hals, '
        'Kreislaufzusammenbruch.',
    callFirst: true,
    steps: [
      FirstAidStep('Sofort 112 und sagen, dass es eine Allergie ist.'),
      FirstAidStep(
        'Nach dem Notfallset der Person fragen oder danach suchen.',
        detail: 'Wer das weiß, trägt meist einen Autoinjektor bei sich.',
      ),
      FirstAidStep(
        'Den Autoinjektor in die Außenseite des Oberschenkels drücken.',
        detail:
            'Durch die Kleidung hindurch möglich. Die Anleitung '
            'steht auf dem Gerät und ist in Sekunden gelesen.',
      ),
      FirstAidStep(
        'Flach hinlegen, Beine hoch.',
        detail:
            'Bei Atemnot dagegen aufrecht sitzen lassen. Nicht '
            'plötzlich aufstehen lassen.',
      ),
      FirstAidStep(
        'Keine Besserung nach 5 bis 15 Minuten: zweite Dosis, wenn '
        'eine zweite da ist.',
      ),
      FirstAidStep(
        'Bewusstlos und keine normale Atmung: Wiederbelebung.',
      ),
    ],
    cautions: [
      'Auch wenn es rasch besser wird: immer in die Klinik. Die '
          'Beschwerden kommen in einem Teil der Fälle nach Stunden '
          'zurück.',
      'Ein Autoinjektor darf nur bei der Person angewendet werden, für '
          'die er verordnet ist – oder auf Anweisung der Leitstelle.',
    ],
    source:
        'Erste-Hilfe-Leitlinien 2025 des European Resuscitation '
        'Council (ERC)',
  ),
  FirstAidGuide(
    id: 'hypothermia',
    group: FirstAidGroup.environment,
    title: 'Unterkühlung',
    when:
        'Zittern, kalte blasse Haut, Verlangsamung, Verwirrung – nach '
        'Kälte, Nässe oder Wind. Hört das Zittern auf, wird es '
        'gefährlich.',
    steps: [
      FirstAidStep(
        'Aus der Kälte holen, vor Wind und Nässe schützen.',
      ),
      FirstAidStep(
        'Nasse Kleidung entfernen, notfalls aufschneiden.',
      ),
      FirstAidStep(
        'In Decken einpacken, auch unter der Person.',
        detail: 'Kopf mit einpacken. Der Boden zieht die meiste Wärme.',
      ),
      FirstAidStep(
        'Wach und schluckfähig: warme, gezuckerte Getränke.',
      ),
      FirstAidStep(
        'Wärme auf Rumpf, Hals und Kopf, nicht auf Arme und Beine.',
        detail:
            'Wärmflasche oder Wärmepad, immer mit einem Tuch '
            'dazwischen.',
      ),
      FirstAidStep(
        '112 bei Verwirrung, aufhörendem Zittern oder Schläfrigkeit.',
      ),
    ],
    cautions: [
      'Arme und Beine nicht reiben und nicht aktiv erwärmen. Das treibt '
          'kaltes Blut zum Herzen.',
      'So wenig wie möglich bewegen. Ein stark unterkühltes Herz kann '
          'durch Erschütterung stehenbleiben.',
      'Kein Alkohol. Er fühlt sich warm an und kühlt aus.',
      'Bei schwerer Unterkühlung Atmung und Puls bis zu einer Minute '
          'prüfen – beides kann kaum wahrnehmbar sein. Niemand ist tot, '
          'bevor er nicht warm und tot ist.',
    ],
    source:
        'Erste-Hilfe-Leitlinien 2025 des European Resuscitation '
        'Council (ERC)',
  ),
  FirstAidGuide(
    id: 'heat',
    group: FirstAidGroup.environment,
    title: 'Hitzeerschöpfung und Hitzschlag',
    when:
        'Nach Hitze oder Anstrengung: Schwäche, Kopfschmerz, Übelkeit. '
        'Kommt heiße trockene Haut, Verwirrung oder Bewusstlosigkeit '
        'dazu, ist es ein Hitzschlag und lebensbedrohlich.',
    steps: [
      FirstAidStep(
        'In den Schatten oder in einen kühlen Raum bringen.',
      ),
      FirstAidStep(
        'Hinlegen, Beine hoch, Kleidung öffnen.',
      ),
      FirstAidStep(
        'Bei Bewusstsein: in kleinen Schlucken Wasser trinken lassen.',
      ),
      FirstAidStep(
        'Kühlen: feuchte Tücher, Luft zufächeln, kaltes Wasser auf '
        'Nacken, Achseln und Leisten.',
      ),
      FirstAidStep(
        '112 bei Verwirrung, heißer trockener Haut, Erbrechen oder '
        'Bewusstlosigkeit.',
        detail:
            'Das ist ein Hitzschlag. Weiterkühlen, bis der '
            'Rettungsdienst da ist.',
      ),
    ],
    cautions: [
      'Nichts zu trinken geben, wenn die Person verwirrt oder nicht '
          'ganz wach ist.',
      'Kein Alkohol und nichts Koffeinhaltiges.',
      'Ein Hitzschlag ist kein stärkerer Sonnenbrand. Ohne Behandlung '
          'endet er tödlich.',
    ],
    source:
        'Bundeszentrale für gesundheitliche Aufklärung und '
        'Erste-Hilfe-Leitlinien 2025 des ERC',
  ),
  FirstAidGuide(
    id: 'poisoning',
    group: FirstAidGroup.environment,
    title: 'Vergiftung',
    when:
        'Etwas wurde geschluckt, eingeatmet, verschüttet oder in die '
        'Augen bekommen, das dort nicht hingehört.',
    steps: [
      FirstAidStep(
        'Eigene Sicherheit: bei Gas und Rauch nicht hineingehen.',
      ),
      FirstAidStep(
        'Beim Giftnotruf anrufen. Bei Bewusstlosigkeit oder Atemnot '
        'zuerst 112.',
      ),
      FirstAidStep(
        'Bereitlegen, was gefragt wird.',
        detail:
            'Was, wie viel, wann, wie alt und wie schwer ist die '
            'Person, welche Beschwerden.',
      ),
      FirstAidStep(
        'Die Verpackung, den Rest und gegebenenfalls Erbrochenes '
        'aufheben.',
      ),
      FirstAidStep(
        'Haut oder Augen betroffen: 10 bis 15 Minuten mit fließendem '
        'Wasser spülen.',
        detail:
            'Beim Auge vom inneren zum äußeren Winkel, damit nichts '
            'ins gesunde Auge läuft.',
      ),
      FirstAidStep(
        'Bewusstlos und normale Atmung: stabile Seitenlage.',
      ),
    ],
    facts: poisonCentres,
    cautions: [
      'Kein Erbrechen auslösen. Bei Säuren, Laugen und Schäumern '
          'richtet der Weg zurück mehr Schaden an als der Weg hinunter.',
      'Keine Milch. Sie beschleunigt die Aufnahme vieler Gifte.',
      'Kein Salzwasser.',
      'Die Nummern sind ein gespeicherter Stand. Prüfe sie, solange du '
          'Netz hast, und trage die für dich zuständige in die '
          'Notfallkontakte ein.',
    ],
    source:
        'Giftinformationszentren der Länder, Bundesinstitut für '
        'Risikobewertung',
  ),
];

import 'kids_comic.dart';

const _mila = ComicSpeaker.mila;
const _nuss = ComicSpeaker.nuss;
const _papa = ComicSpeaker.papa;
const _nachbarin = ComicSpeaker.neighbour;

const kidsComicDe = KidsComic(
  title: 'Mila und Nuss',
  subtitle: 'Ein Notfall-Comic für Kinder',
  intro:
      'Nuss ist ein Eichhörnchen und legt jeden Herbst Vorräte an. Mila '
      'lernt von ihm und von Papa, was man tut, wenn plötzlich etwas anders '
      'ist als sonst: wenn der Strom weg ist, die Sirene heult, ein Sturm '
      'kommt, es brennt oder die Großen von Krieg reden.',
  coverDescription:
      'Mila und das Eichhörnchen Nuss unter einem Baum mit einem Haufen Nüsse',
  speakers: {
    ComicSpeaker.mila: 'Mila',
    ComicSpeaker.nuss: 'Nuss',
    ComicSpeaker.papa: 'Papa',
    ComicSpeaker.neighbour: 'Frau Yilmaz',
  },
  numbers: [
    (number: '112', label: 'Feuerwehr und Rettungsdienst'),
    (number: '110', label: 'Polizei'),
  ],
  chapters: [
    ComicChapter(
      id: 'vorrat',
      title: 'Nuss legt Vorräte an',
      lede:
          'Wer vorbereitet ist, hat weniger Angst. Darum fängt alles hier '
          'an, an einem ganz normalen Tag.',
      rulesTitle: 'Vorräte',
      rules: [
        'Wasser und Essen für ein paar Tage',
        'Notgepäck für jeden',
        'Telefonnummern auf Papier',
        'Treffpunkt ausmachen',
      ],
      panels: [
        ComicPanel(
          image: 'vorrat-1',
          description:
              'Nuss sitzt unter einem Baum neben einem Haufen Nüsse, Mila '
              'schaut zu',
          lines: [
            ComicLine(
              _nuss,
              'Ich sammle Nüsse für den Winter. Dann habe ich genug, auch '
              'wenn draußen alles zugeschneit ist.',
            ),
            ComicLine(
              _mila,
              'Schlau! Brauchen wir Menschen auch so einen Vorrat?',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-2',
          description: 'Papa zeigt Mila ein Regal mit Wasserflaschen und Dosen',
          lines: [
            ComicLine(
              _papa,
              'Ja. Wir haben Wasser und Essen für ein paar Tage. Falls die '
              'Geschäfte mal zu sind, kommen wir trotzdem zurecht.',
            ),
            ComicLine.caption(
              'Rund 2 Liter pro Mensch und Tag, zum Trinken und Kochen.',
              lead: 'Wie viel Wasser?',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-3',
          description:
              'Mila packt einen Rucksack mit Taschenlampe, Trinkflasche und '
              'Kuschelhase',
          lines: [
            ComicLine(
              _mila,
              'In mein Notgepäck kommen: Taschenlampe, Trinkflasche, warme '
              'Jacke und mein Kuschelhase Momo!',
            ),
            ComicLine(
              _nuss,
              'Und ein Zettel mit den Telefonnummern von Mama und Papa. Wenn '
              'das Handy leer ist, hilft Papier.',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-4',
          description:
              'Ein grünes Sammelplatz-Schild vor dem Haus, Papa und Mila '
              'daneben',
          lines: [
            ComicLine(
              _papa,
              'Wenn wir uns einmal verlieren, treffen wir uns hier am Schild '
              'vor dem Haus.',
            ),
            ComicLine(
              _mila,
              'Und meine Adresse weiß ich auswendig: Lindenweg 4!',
            ),
            ComicLine.caption(
              '112 für Feuerwehr und Rettungsdienst, 110 für die Polizei. '
              'Beide Nummern kosten nichts.',
              lead: 'Notruf:',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'strom',
      title: 'Plötzlich ist es dunkel',
      lede:
          'Ein Stromausfall kommt ohne Vorwarnung. Licht, Fernseher und '
          'Heizung gehen aus, und das Handy lädt nicht mehr.',
      rulesTitle: 'Stromausfall',
      rules: [
        'Ruhig bleiben',
        'Taschenlampe statt Kerze',
        'Kühlschrank zu lassen',
        'Radio hören, Nachbarn fragen',
      ],
      panels: [
        ComicPanel(
          image: 'strom-1',
          description:
              'Dunkles Zimmer bei Nacht, Mila erschrocken, Papa neben ihr',
          lines: [
            ComicLine(_mila, 'Papa! Das Licht ist aus und der Fernseher auch!'),
            ComicLine(
              _papa,
              'Das ist ein Stromausfall. Zuerst bleiben wir ruhig. Ich bin da.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-2',
          description:
              'Nuss leuchtet mit einer Taschenlampe, daneben eine '
              'durchgestrichene Kerze',
          lines: [
            ComicLine(
              _nuss,
              'Taschenlampe statt Kerze! Eine Kerze kann umfallen, und dann '
              'brennt es.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-3',
          description: 'Papa hält den Kühlschrank zu, Mila schaut',
          lines: [
            ComicLine(
              _papa,
              'Den Kühlschrank lassen wir zu. Dann bleibt es drinnen länger '
              'kalt.',
            ),
            ComicLine(_mila, 'Und der Aufzug im Haus?'),
            ComicLine(
              _papa,
              'Der fährt ohne Strom nicht. Wir nehmen die Treppe.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-4',
          description: 'Papa kurbelt an einem Radio, Mila und Nuss hören zu',
          lines: [
            ComicLine(
              _papa,
              'Dieses Radio läuft mit Batterien oder mit der Kurbel. Im Radio '
              'sagen sie, was los ist und wie lange es dauert.',
            ),
            ComicLine.caption(
              'Warm anziehen, zusammenrücken und mit der Taschenlampe '
              'Schattentheater spielen. So vergeht die Zeit schneller.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-5',
          wide: true,
          description:
              'Mila und Papa klopfen bei der Nachbarin, die freundlich die '
              'Tür öffnet',
          lines: [
            ComicLine(
              _mila,
              'Frau Yilmaz von nebenan wohnt allein. Sollen wir fragen, ob '
              'sie etwas braucht?',
            ),
            ComicLine(
              _nachbarin,
              'Wie lieb von euch! Eine Decke hätte ich gern.',
            ),
            ComicLine(
              _papa,
              'Gute Idee, Mila. Wenn Nachbarn sich helfen, ist es für alle '
              'leichter.',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'sirene',
      title: 'Die Sirene heult',
      lede:
          'Sirenen warnen alle Menschen gleichzeitig. Wichtig ist, wie sie '
          'klingen.',
      rulesTitle: 'Sirene',
      rules: [
        'Auf und ab: Warnung, ins Haus',
        'Fenster und Türen zu',
        'Radio oder Warn-App an',
        'Langer Ton: Entwarnung',
      ],
      panels: [
        ComicPanel(
          image: 'sirene-1',
          description:
              'Eine Sirene auf einem Mast mit roten Schallwellen, Mila '
              'erschrocken',
          lines: [
            ComicLine.caption(
              'Das ist eine Warnung.',
              lead: 'Ein Heulton, der eine Minute lang auf und ab geht:',
            ),
            ComicLine(_mila, 'Was bedeutet das?'),
            ComicLine(
              _nuss,
              'Achtung! Etwas ist passiert. Jetzt hören wir gut hin.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-2',
          description: 'Mila geht mit Nuss auf ein Haus zu',
          lines: [
            ComicLine(
              _nuss,
              'Geh ins nächste Haus. Bist du unterwegs, bleib bei deiner '
              'Lehrerin oder einem Erwachsenen, den du kennst.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-3',
          description:
              'Drinnen: Papa schließt das Fenster, das Radio steht auf dem '
              'Tisch',
          lines: [
            ComicLine(
              _papa,
              'Fenster und Türen zu, Radio an. Im Radio und in der Warn-App '
              'sagen sie, was wir jetzt tun sollen.',
            ),
            ComicLine(_mila, 'Ich bleibe bei dir.'),
          ],
        ),
        ComicPanel(
          image: 'sirene-4',
          description:
              'Die Sirene mit einem ruhigen grünen Ton, Mila atmet auf',
          lines: [
            ComicLine.caption(
              'Entwarnung. Die Gefahr ist vorbei.',
              lead: 'Ein langer Ton, ohne Auf und Ab:',
            ),
            ComicLine(_mila, 'Puh!'),
            ComicLine(
              _nuss,
              'Einmal im Jahr, am Warntag im September, üben alle Sirenen '
              'zugleich. Dann musst du dich nicht erschrecken.',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'sturm',
      title: 'Sturm und Hochwasser',
      lede:
          'Gewitter, Sturm und viel Regen kommen bei uns am häufigsten vor. '
          'Dagegen hilft fast immer dasselbe: rein ins Haus.',
      rulesTitle: 'Sturm und Hochwasser',
      rules: [
        'Bei Gewitter ins Haus, weg von Bäumen',
        'Drinnen weg vom Fenster',
        'Nie durch Wasser laufen',
        'Bei Hochwasser nach oben, nicht in den Keller',
      ],
      panels: [
        ComicPanel(
          image: 'sturm-1',
          description:
              'Gewitterwolke mit Blitz über einem Baum, Mila läuft weg vom '
              'Baum',
          lines: [
            ComicLine(
              _nuss,
              'Bei Gewitter schnell ins Haus. Stell dich nicht unter einen '
              'Baum!',
            ),
            ComicLine(_mila, 'Und drinnen?'),
            ComicLine(
              _nuss,
              'Weg vom Fenster. Draußen kann der Sturm Äste und Ziegel '
              'herumwirbeln.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-2',
          description:
              'Papa und Mila bleiben auf dem trockenen Gehweg stehen, vor '
              'ihnen ist die Straße überflutet',
          lines: [
            ComicLine.caption(
              'Wasser ist oft stärker und tiefer, als es aussieht.',
              lead: 'Hochwasser:',
            ),
            ComicLine(
              _papa,
              'Wir gehen nie durch Wasser auf der Straße. Und bei Hochwasser '
              'auch nicht in den Keller!',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-3',
          description:
              'Mila und Nuss oben im Haus mit Rucksack, unten ist Wasser',
          lines: [
            ComicLine(
              _mila,
              'Wir gehen nach oben und warten, bis die Feuerwehr sagt, dass es '
              'wieder sicher ist.',
            ),
            ComicLine(_nuss, 'Das Notgepäck und das Radio nehmen wir mit.'),
          ],
        ),
        ComicPanel(
          image: 'sturm-4',
          description: 'Heißer Sommertag, Mila trinkt im Schatten eines Baums',
          lines: [
            ComicLine.caption('ist auch eine Gefahr.', lead: 'Große Hitze'),
            ComicLine(
              _nuss,
              'Viel trinken, im Schatten bleiben und mittags lieber drinnen '
              'spielen.',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'feuer',
      title: 'Es piept und riecht nach Rauch',
      lede:
          'Feuer in der Wohnung ist die Gefahr, die Kinder am ehesten selbst '
          'erleben. Hier zählt jede Sekunde.',
      rulesTitle: 'Feuer',
      rules: [
        'Raus und laut „Feuer!“ rufen',
        'Bücken oder krabbeln',
        'Nie verstecken, nie zurückgehen',
        '112: Wo? Was? Dann warten',
      ],
      panels: [
        ComicPanel(
          image: 'feuer-1',
          description:
              'Ein piepender Rauchmelder an der Decke, darunter Rauch, Mila '
              'erschrocken',
          lines: [
            ComicLine(_mila, 'Der Rauchmelder piept!'),
            ComicLine(
              _nuss,
              'Sofort raus aus der Wohnung! Und laut „Feuer!“ rufen, damit '
              'alle es hören.',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-2',
          description: 'Mila krabbelt auf allen vieren unter dem Rauch zur Tür',
          lines: [
            ComicLine.caption(
              'Unten am Boden ist weniger Rauch. Darum: bücken oder krabbeln.',
            ),
            ComicLine(
              _nuss,
              'Versteck dich nie, nicht unterm Bett und nicht im Schrank! Die '
              'Feuerwehr muss dich finden können.',
            ),
            ComicLine(_mila, 'Und die Tür mache ich hinter mir zu.'),
          ],
        ),
        ComicPanel(
          image: 'feuer-3',
          description:
              'Draußen am Sammelplatz: Papa ruft mit dem Handy 112 an, Mila '
              'hält sich an ihm fest',
          lines: [
            ComicLine(_mila, 'Momo ist noch drinnen!'),
            ComicLine(
              _papa,
              'Wir gehen niemals zurück ins Haus. Das macht die Feuerwehr. '
              'Sachen kann man ersetzen, dich nicht.',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-4',
          description: 'Großes Handy mit der Nummer 112, Nuss zeigt darauf',
          lines: [
            ComicLine(_mila, 'Und wenn ich allein bin?'),
            ComicLine(
              _nuss,
              'Dann rufst du selbst die 112 an. Das kostet nichts und geht '
              'auch ohne Guthaben.',
            ),
            ComicLine.caption(
              'Wo ist es? Was ist passiert? Dann wartest du. Die Leitstelle '
              'stellt Fragen und legt als Erste auf.',
              lead: 'Am Telefon sagst du:',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'krieg',
      title: 'Wenn die Großen von Krieg reden',
      lede:
          'Manchmal hören Kinder Nachrichten, die ihnen Angst machen. '
          'Darüber zu reden hilft mehr als Schweigen.',
      rulesTitle: 'Wenn ich Angst habe',
      rules: [
        'Darüber reden',
        'Erwachsene fragen, nicht dem Internet glauben',
        'Bei Warnung: Raum ohne Fenster, zusammen bleiben',
        'Seltsame Dinge nicht anfassen',
      ],
      panels: [
        ComicPanel(
          image: 'krieg-1',
          description: 'Mila steht bedrückt neben dem Radio, Papa ist bei ihr',
          lines: [
            ComicLine(
              _mila,
              'Im Radio reden sie von Krieg. Kommt der auch zu uns?',
            ),
            ComicLine(
              _papa,
              'Gut, dass du fragst. Hier bei uns ist es gerade sicher. Und '
              'sehr viele Menschen arbeiten jeden Tag dafür, dass das so '
              'bleibt.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-2',
          description: 'Mila malt ein Bild mit einem Herz, Nuss sitzt bei ihr',
          lines: [
            ComicLine(
              _nuss,
              'Angst zu haben ist in Ordnung. Erzähl jemandem davon: Papa, '
              'deiner Lehrerin oder Oma.',
            ),
            ComicLine(_mila, 'Mir hilft auch Malen. Und Kuscheln mit Momo.'),
          ],
        ),
        ComicPanel(
          image: 'krieg-3',
          description:
              'Die Familie in einem Raum ohne Fenster mit Rucksack, Radio und '
              'Kuschelhase',
          lines: [
            ComicLine.caption(
              '',
              lead: 'Falls es doch einmal eine Warnung gibt:',
            ),
            ComicLine(
              _papa,
              'Dann gehen wir in einen Raum ohne Fenster, zum Beispiel in den '
              'Flur oder in den Keller. Notgepäck, Radio und Taschenlampe '
              'nehmen wir mit.',
            ),
            ComicLine(_mila, 'Und wir bleiben zusammen.'),
          ],
        ),
        ComicPanel(
          image: 'krieg-4',
          description:
              'Ein Handy mit Fragezeichen, daneben im Gras ein seltsamer '
              'Gegenstand, den niemand anfasst',
          lines: [
            ComicLine(
              _nuss,
              'Nicht alles, was im Internet steht, stimmt. Frag lieber '
              'Erwachsene oder hör die Nachrichten im Radio.',
            ),
            ComicLine(
              _mila,
              'Und wenn ich draußen etwas Seltsames finde, fasse ich es nicht '
              'an und sage einem Erwachsenen Bescheid.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-5',
          wide: true,
          description:
              'Mila, Papa und Nuss stehen zufrieden unter dem großen Baum',
          lines: [
            ComicLine(
              _mila,
              'Jetzt weiß ich, was ich tun kann. Das fühlt sich viel besser an.',
            ),
            ComicLine(
              _nuss,
              'Siehst du? Wer vorbereitet ist, hat weniger Angst.',
            ),
          ],
        ),
      ],
    ),
  ],
  parentsIntro:
      'Der Comic eignet sich zum gemeinsamen Lesen ab etwa fünf Jahren. Ein '
      'Kapitel pro Abend reicht. Das letzte Kapitel ist bewusst ruhig '
      'gehalten. Lesen Sie es, wenn Ihr Kind Fragen zu Nachrichten stellt, '
      'und nicht als Einstieg.',
  parentsTips: [
    'Fragen ehrlich und kurz beantworten. Kinder brauchen keine '
        'Einzelheiten, aber sie merken, wenn etwas verschwiegen wird.',
    'Das Notgepäck gemeinsam packen. Wer selbst etwas tun kann, fühlt sich '
        'weniger ausgeliefert.',
    'Treffpunkt, Adresse und die Nummern 112 und 110 zusammen üben, am '
        'besten draußen vor der Tür.',
    'Den Warntag im September als Anlass nehmen, über die Sirenensignale '
        'zu sprechen.',
    'Rauchmelder gemeinsam testen, damit das Piepen bekannt ist und nicht '
        'erschreckt.',
  ],
  source:
      'Die Verhaltensregeln folgen den Empfehlungen des Bundesamts für '
      'Bevölkerungsschutz und Katastrophenhilfe zur Notfallvorsorge. Mila, '
      'Nuss und ihre Geschichte sind eigene Figuren und keine '
      'Veröffentlichung des BBK.',
);

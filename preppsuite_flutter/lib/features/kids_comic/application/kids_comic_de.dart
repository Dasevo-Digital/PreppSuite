import 'kids_comic.dart';

const _mila = ComicSpeaker.mila;
const _nuss = ComicSpeaker.nuss;
const _papa = ComicSpeaker.papa;

const kidsComicDe = KidsComic(
  title: 'Mila und Nuss',
  subtitle: 'Unser Notfall-Comic',
  intro:
      'Sechs spannende Geschichten für kluge Kinder: vorsorgen, ruhig '
      'bleiben, Warnungen verstehen, zusammenhalten. Mila lernt mit dem '
      'Eichhörnchen Nuss und mit Papa, was man tut, wenn der Strom weg ist, '
      'die Sirene heult, ein Unwetter kommt, es brennt oder die Großen von '
      'Krieg reden.',
  coverDescription:
      'Mila und das Eichhörnchen Nuss sammeln im Garten Nüsse, daneben steht '
      'eine offene Kiste mit Vorräten',
  speakers: {
    ComicSpeaker.mila: 'Mila',
    ComicSpeaker.nuss: 'Nuss',
    ComicSpeaker.papa: 'Papa',
  },
  numbers: [
    (number: '112', label: 'Feuerwehr und Rettungsdienst'),
    (number: '110', label: 'Polizei'),
  ],
  numbersNote: 'Kinder: immer Erwachsene dazuholen.',
  chapters: [
    ComicChapter(
      id: 'vorrat',
      title: 'Nuss legt Vorräte an',
      lede: 'Was hilft, wenn einmal etwas ausfällt?',
      panels: [
        ComicPanel(
          image: 'vorrat-1',
          description:
              'Mila und Nuss sammeln im Garten Nüsse in einen Korb, daneben '
              'eine offene Kiste mit Dosen, Gläsern und Wasserflaschen',
          lines: [
            ComicLine(_nuss, 'Ich sammle Nüsse. Was sammeln wir für Notfälle?'),
          ],
        ),
        ComicPanel(
          image: 'vorrat-2',
          description:
              'Papa und Mila räumen ein Regal mit Wasserflaschen, Dosen und '
              'Gläsern ein, Nuss schaut zu',
          lines: [
            ComicLine(
              _papa,
              'Wasser und haltbares Essen – erst für 3, besser für 10 Tage.',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-3',
          description:
              'Mila packt ihren Teddy in einen roten Rucksack, auf dem Tisch '
              'liegen Verbandskasten, Taschenlampe und eine Packliste',
          lines: [
            ComicLine(
              _mila,
              'Unser Rucksack braucht Licht, Radio, Medizin und mein '
              'Kuscheltier!',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-4',
          description:
              'Papa zeigt Mila im Park ein grünes Sammelplatz-Schild, Nuss '
              'sitzt auf seiner Schulter',
          lines: [
            ComicLine(
              _papa,
              'Wir kennen unseren Treffpunkt und wichtige Telefonnummern.',
            ),
          ],
        ),
      ],
      note:
          'Ungefähr 2 Liter Wasser pro Person und Tag für Trinken und '
          'Kochen. Haustiere mitdenken.',
      rulesTitle: 'Vorrat',
      rules: ['3 Tage sind ein guter Anfang', 'Möglichst 10 Tage planen'],
    ),
    ComicChapter(
      id: 'strom',
      title: 'Plötzlich ist es dunkel',
      lede: 'Strom ist weg – was nun?',
      panels: [
        ComicPanel(
          image: 'strom-1',
          description:
              'Dunkles Wohnzimmer am Abend, Papa drückt den Lichtschalter, '
              'Mila und Nuss schauen zur Lampe',
          lines: [ComicLine(_mila, 'Das Licht ist aus! Ist das schlimm?')],
        ),
        ComicPanel(
          image: 'strom-2',
          description:
              'Mila leuchtet mit einer Taschenlampe, daneben ein '
              'durchgestrichenes Kerzen-Zeichen, Nuss sitzt bei einer Laterne',
          lines: [
            ComicLine(
              _papa,
              'Wir bleiben ruhig. Unsere Taschenlampe ist sicherer als eine '
              'Kerze.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-3',
          description:
              'Papa schließt den Kühlschrank und zeigt zur Treppe, am Aufzug '
              'hängt ein Verbotsschild',
          lines: [
            ComicLine(
              _nuss,
              'Kühlschrank schnell schließen! Und nie den Aufzug nehmen.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-4',
          description:
              'Mila, Papa und Nuss hören ein Kurbelradio, in der Tür steht '
              'lächelnd Oma',
          lines: [
            ComicLine(
              _mila,
              'Das Kurbelradio informiert uns. Und fragen wir, ob Oma Hilfe '
              'braucht!',
            ),
          ],
        ),
      ],
      note:
          'Bereithalten: Taschenlampe, Ersatzbatterien, Powerbank und '
          'Batterie- oder Kurbelradio.',
      rulesTitle: 'Strom',
      rules: ['Taschenlampe und Radio', 'Kühlschrank geschlossen halten'],
    ),
    ComicChapter(
      id: 'sirene',
      title: 'Die Sirene heult',
      lede: 'Ein Geräusch sagt: Pass jetzt auf!',
      panels: [
        ComicPanel(
          image: 'sirene-1',
          description:
              'Mila, Papa und Nuss schauen zu einer heulenden Sirene auf '
              'einem Mast über den Dächern',
          lines: [
            ComicLine(
              _nuss,
              'Hörst du das Auf und Ab? Das kann ein Warnsignal sein!',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-2',
          description:
              'Papa führt Mila an der Hand durch die Haustür ins Haus, Nuss '
              'läuft mit',
          lines: [
            ComicLine(
              _papa,
              'Wir suchen erst Schutz und gehen zusammen hinein.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-3',
          description:
              'Am Küchentisch schaltet Papa das Radio ein und hält ein Handy '
              'mit einem Warnzeichen, Mila und Nuss hören zu',
          lines: [
            ComicLine(
              _mila,
              'Was ist passiert? Wir hören Radio und prüfen offizielle '
              'Warnungen.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-4',
          description:
              'Papa erklärt Mila und Nuss die Warnmeldung, im Fenster ein '
              'grüner Haken',
          lines: [
            ComicLine(
              _papa,
              'Die Warnmeldung sagt uns, was wir bei dieser Gefahr tun '
              'sollen.',
            ),
          ],
        ),
      ],
      note:
          'Sirene: 1 Minute auf und ab = Warnung; 1 Minute gleichbleibend = '
          'Entwarnung. Örtliche Signale beachten.',
      rulesTitle: 'Sirene',
      rules: [
        'Warnung hören',
        'Offizielle Meldung prüfen',
        'Passend handeln',
      ],
    ),
    ComicChapter(
      id: 'sturm',
      title: 'Sturm, Hochwasser und Hitze',
      lede: 'Das Wetter kann gefährlich werden.',
      panels: [
        ComicPanel(
          image: 'sturm-1',
          description:
              'Mila, Nuss und Papa sitzen drinnen auf dem Sofa, draußen '
              'tobt ein Sturm mit Regen',
          lines: [
            ComicLine(
              _mila,
              'Bei Sturm bleiben wir drinnen und weg von den Fenstern.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-2',
          description:
              'Papa und Mila mit Nuss im Arm gehen die Treppe hinauf, '
              'draußen steht die Straße unter Wasser',
          lines: [
            ComicLine(
              _papa,
              'Bei Hochwasser geht es nach oben – niemals in den Keller!',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-3',
          description:
              'Papa legt Notrucksack, Radio, Wasser und Taschenlampe bereit, '
              'draußen stehen Häuser im Wasser',
          lines: [
            ComicLine(
              _nuss,
              'Notrucksack und Radio liegen bereit. Wir befolgen die Warnung.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-4',
          description:
              'Papa, Mila mit Sonnenhut und Nuss trinken Wasser im Schatten '
              'eines Baumes',
          lines: [
            ComicLine(
              _mila,
              'Wenn es sehr heiß ist: Schatten, Pausen und genug trinken!',
            ),
          ],
        ),
      ],
      note:
          'Nicht durch Hochwasser gehen oder fahren. Bei Gewitter nicht unter '
          'Bäumen Schutz suchen.',
      rulesTitle: 'Unwetter',
      rules: ['Drinnen Schutz suchen', 'Bei Hochwasser niemals in den Keller'],
    ),
    ComicChapter(
      id: 'feuer',
      title: 'Es piept und riecht nach Rauch',
      lede: 'Ein Rauchmelder warnt vor Feuer.',
      panels: [
        ComicPanel(
          image: 'feuer-1',
          description:
              'Im Flur piept ein Rauchmelder an der Decke, Rauch zieht '
              'herein, Mila zeigt nach oben',
          lines: [ComicLine(_mila, 'Der Rauchmelder piept! Feuer!')],
        ),
        ComicPanel(
          image: 'feuer-2',
          description:
              'Papa, Mila und Nuss krabbeln unter dem Rauch zur offenen '
              'Haustür',
          lines: [
            ComicLine(
              _papa,
              'Schnell zum sicheren Ausgang. Bei Rauch bleiben wir möglichst '
              'tief.',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-3',
          description:
              'Draußen zieht Papa die Haustür zu, Mila hält Nuss im Arm',
          lines: [
            ComicLine(
              _mila,
              'Tür hinter uns schließen – und nicht wieder hineingehen!',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-4',
          description:
              'Papa telefoniert, Mila hält Nuss im Arm, hinter ihnen kommt '
              'die Feuerwehr',
          lines: [
            ComicLine(_papa, 'Draußen rufe ich 112 und sage, ob jemand fehlt.'),
          ],
        ),
      ],
      note:
          'Nie in verqualmte Fluchtwege laufen. Ist der Weg blockiert: Tür '
          'schließen und am Fenster Hilfe rufen.',
      rulesTitle: 'Feuer',
      rules: ['Raus, Tür zu, 112', 'Nicht verstecken und nicht zurückgehen'],
    ),
    ComicChapter(
      id: 'krieg',
      title: 'Wenn die Großen von Krieg reden',
      lede: 'Auch schwierige Fragen dürfen gestellt werden.',
      panels: [
        ComicPanel(
          image: 'krieg-1',
          description:
              'Mila sitzt bedrückt auf dem Sofa und drückt ihr Kuscheltier, '
              'Nuss sitzt bei ihr, auf dem Tisch steht ein Radio',
          lines: [
            ComicLine(
              _mila,
              'Im Radio reden sie über Krieg. Das macht mir Angst.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-2',
          description:
              'Papa sitzt bei Mila auf dem Sofa und spricht freundlich mit '
              'ihr, Nuss hört zu',
          lines: [
            ComicLine(
              _papa,
              'Das verstehe ich. Du darfst fragen – ich höre dir zu.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-3',
          description: 'Mila malt ein Herz, Nuss kuschelt sich an sie',
          lines: [
            ComicLine(
              _nuss,
              'Reden, malen und zusammen kuscheln können helfen.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-4',
          description:
              'Papa, Mila und Nuss sitzen ruhig bei Rucksack, Radio, '
              'Taschenlampe und Verbandskasten',
          lines: [
            ComicLine(
              _papa,
              'Wir prüfen Nachrichten und überlegen ruhig, was wir tun '
              'können.',
            ),
          ],
        ),
      ],
      note:
          'Kinderfragen ehrlich und altersgerecht beantworten, Gefühle ernst '
          'nehmen, Nachrichtenpausen machen.',
      rulesTitle: 'Gefühle',
      rules: ['Fragen stellen', 'Sorgen teilen', 'Verlässliche Infos nutzen'],
    ),
  ],
  parentsIntro:
      'Der Comic eignet sich zum gemeinsamen Lesen ab etwa fünf Jahren. Ein '
      'Kapitel pro Abend reicht. Das letzte Kapitel ist bewusst ruhig '
      'gehalten. Lesen Sie es, wenn Ihr Kind Fragen zu Nachrichten stellt, '
      'und nicht als Einstieg. Was die Kapitel raten, hier für Erwachsene:',
  parentsTips: [
    'Notvorrat: möglichst zehn Tage selbst versorgen, drei Tage sind ein '
        'guter Anfang. Wasser: etwa zwei Liter pro Person und Tag.',
    'Stromausfall: Licht, Radio und Vorräte vorbereiten. Bei einem Ausfall '
        'an Kühlung, Heizung, Aufzug und Kommunikation denken.',
    'Warnung: Die Sirene heult bundesweit eine Minute auf- und '
        'abschwellend zur Warnung und eine Minute gleichbleibend zur '
        'Entwarnung. Immer die konkrete Warnmeldung prüfen.',
    'Naturgefahren: Bei Sturm Schutz im Gebäude suchen. Bei Hochwasser in '
        'höher gelegene Stockwerke gehen, niemals in Keller, Unterführungen '
        'oder Tiefgaragen.',
    'Brand: nur sichere Fluchtwege nutzen, Rauch meiden, Türen nach dem '
        'Verlassen schließen und draußen 112 rufen. Nie zurück ins brennende '
        'Haus.',
    'Mit Kindern reden: Sorgen ernst nehmen, ehrlich und altersgerecht '
        'erklären, nicht mit Krisennachrichten überfluten und keine absolute '
        'Sicherheit versprechen.',
  ],
  source:
      'Die Verhaltensregeln sind im Oktober 2026 redaktionell mit den '
      'öffentlich zugänglichen Empfehlungen des Bundesamts für '
      'Bevölkerungsschutz und Katastrophenhilfe abgeglichen: Vorsorgen für '
      'Krisen und Katastrophen, Sirenen und Warnung in Deutschland, Schutz '
      'suchen, Hochwasser, Brandschutz und Mit Ängsten und Sorgen umgehen. '
      'Keine amtliche Freigabe oder fachmedizinische Zertifizierung. Mila, '
      'Nuss und ihre Geschichte sind eigene Figuren und keine '
      'Veröffentlichung des BBK.',
);

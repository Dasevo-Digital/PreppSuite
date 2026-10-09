import 'kids_comic.dart';

const _mila = ComicSpeaker.mila;
const _nuss = ComicSpeaker.nuss;
const _papa = ComicSpeaker.papa;
const _neighbour = ComicSpeaker.neighbour;

const kidsComicEn = KidsComic(
  title: 'Mila and Nuss',
  subtitle: 'An emergency comic for children',
  intro:
      'Nuss is a squirrel who puts food by every autumn. Mila learns from '
      'him and from her dad what to do when suddenly things are not the '
      'way they usually are: when the power goes out, the siren wails, a '
      'storm comes, there is a fire, or the grown-ups talk about war.',
  coverDescription:
      'Mila and Nuss the squirrel under a tree with a pile of nuts',
  speakers: {
    ComicSpeaker.mila: 'Mila',
    ComicSpeaker.nuss: 'Nuss',
    ComicSpeaker.papa: 'Dad',
    ComicSpeaker.neighbour: 'Mrs Yilmaz',
  },
  numbers: [
    (number: '112', label: 'Fire brigade and ambulance'),
    (number: '110', label: 'Police'),
  ],
  chapters: [
    ComicChapter(
      id: 'vorrat',
      title: 'Nuss puts food by',
      lede:
          'Being prepared makes you less afraid. That is why it all starts '
          'here, on a perfectly ordinary day.',
      rulesTitle: 'Supplies',
      rules: [
        'Water and food for a few days',
        'An emergency bag for everyone',
        'Phone numbers on paper',
        'Agree on a meeting point',
      ],
      panels: [
        ComicPanel(
          image: 'vorrat-1',
          description:
              'Nuss sits under a tree beside a pile of nuts, Mila watches',
          lines: [
            ComicLine(
              _nuss,
              'I collect nuts for the winter. Then I have enough, even when '
              'everything outside is snowed in.',
            ),
            ComicLine(_mila, 'Clever! Do people need a store like that too?'),
          ],
        ),
        ComicPanel(
          image: 'vorrat-2',
          description: 'Dad shows Mila a shelf with water bottles and tins',
          lines: [
            ComicLine(
              _papa,
              'Yes. We have water and food for a few days. If the shops are '
              'ever closed, we will still manage.',
            ),
            ComicLine.caption(
              'About 2 litres per person per day, for drinking and cooking.',
              lead: 'How much water?',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-3',
          description:
              'Mila packs a backpack with a torch, a water bottle and a toy '
              'rabbit',
          lines: [
            ComicLine(
              _mila,
              'My emergency bag gets a torch, a water bottle, a warm jacket '
              'and my rabbit Momo!',
            ),
            ComicLine(
              _nuss,
              'And a note with Mum’s and Dad’s phone numbers. When the phone '
              'is flat, paper still works.',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-4',
          description:
              'A green assembly point sign in front of the house, Dad and '
              'Mila beside it',
          lines: [
            ComicLine(
              _papa,
              'If we ever lose each other, we meet here at the sign in front '
              'of the house.',
            ),
            ComicLine(_mila, 'And I know my address by heart: Lindenweg 4!'),
            ComicLine.caption(
              '112 for the fire brigade and ambulance, 110 for the police. '
              'Both numbers are free.',
              lead: 'Emergency calls:',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'strom',
      title: 'Suddenly it is dark',
      lede:
          'A power cut comes without warning. The lights, the television and '
          'the heating go off, and the phone stops charging.',
      rulesTitle: 'Power cut',
      rules: [
        'Stay calm',
        'A torch, not a candle',
        'Keep the fridge shut',
        'Listen to the radio, check on the neighbours',
      ],
      panels: [
        ComicPanel(
          image: 'strom-1',
          description: 'A dark room at night, Mila startled, Dad beside her',
          lines: [
            ComicLine(_mila, 'Dad! The light’s gone off and so has the TV!'),
            ComicLine(
              _papa,
              'That’s a power cut. First of all, we stay calm. I’m here.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-2',
          description:
              'Nuss shines a torch, next to it a candle that is crossed out',
          lines: [
            ComicLine(
              _nuss,
              'A torch, not a candle! A candle can fall over, and then there’s '
              'a fire.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-3',
          description: 'Dad keeps the fridge shut, Mila watches',
          lines: [
            ComicLine(
              _papa,
              'We keep the fridge shut. That way it stays cold inside for '
              'longer.',
            ),
            ComicLine(_mila, 'And the lift in our building?'),
            ComicLine(
              _papa,
              'It doesn’t work without power. We take the stairs.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-4',
          description: 'Dad winds up a radio, Mila and Nuss listen',
          lines: [
            ComicLine(
              _papa,
              'This radio runs on batteries or with the crank. On the radio '
              'they tell us what is going on and how long it will last.',
            ),
            ComicLine.caption(
              'Dress warmly, snuggle up and play shadow theatre with the '
              'torch. The time goes by faster that way.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-5',
          wide: true,
          description:
              'Mila and Dad knock at the neighbour’s, who opens the door with '
              'a smile',
          lines: [
            ComicLine(
              _mila,
              'Mrs Yilmaz next door lives on her own. Shall we ask if she '
              'needs anything?',
            ),
            ComicLine(_neighbour, 'How kind of you! I’d love a blanket.'),
            ComicLine(
              _papa,
              'Good idea, Mila. When neighbours help each other, it’s easier '
              'for everyone.',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'sirene',
      title: 'The siren wails',
      lede:
          'Sirens warn everybody at the same time. What matters is how they '
          'sound.',
      rulesTitle: 'Siren',
      rules: [
        'Up and down: a warning, go inside',
        'Close windows and doors',
        'Turn on the radio or the warning app',
        'One long tone: all clear',
      ],
      panels: [
        ComicPanel(
          image: 'sirene-1',
          description: 'A siren on a pole with red sound waves, Mila startled',
          lines: [
            ComicLine.caption(
              'That is a warning.',
              lead: 'A wailing tone that rises and falls for one minute:',
            ),
            ComicLine(_mila, 'What does that mean?'),
            ComicLine(
              _nuss,
              'Watch out! Something has happened. Now we listen carefully.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-2',
          description: 'Mila walks towards a house with Nuss',
          lines: [
            ComicLine(
              _nuss,
              'Go into the nearest building. If you are out and about, stay '
              'with your teacher or a grown-up you know.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-3',
          description:
              'Indoors: Dad closes the window, the radio is on the table',
          lines: [
            ComicLine(
              _papa,
              'Windows and doors shut, radio on. The radio and the warning '
              'app tell us what to do now.',
            ),
            ComicLine(_mila, 'I’m staying with you.'),
          ],
        ),
        ComicPanel(
          image: 'sirene-4',
          description:
              'The siren with a calm green tone, Mila breathes a sigh of '
              'relief',
          lines: [
            ComicLine.caption(
              'All clear. The danger is over.',
              lead: 'One long tone that does not rise and fall:',
            ),
            ComicLine(_mila, 'Phew!'),
            ComicLine(
              _nuss,
              'Once a year, on warning day in September, all the sirens are '
              'tested together. Then you don’t need to be scared.',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'sturm',
      title: 'Storms and floods',
      lede:
          'Thunderstorms, gales and heavy rain are what happens most often '
          'here. Nearly always the same thing helps: get inside.',
      rulesTitle: 'Storms and floods',
      rules: [
        'In a thunderstorm go inside, away from trees',
        'Indoors, keep away from windows',
        'Never walk through water',
        'In a flood go upstairs, not into the cellar',
      ],
      panels: [
        ComicPanel(
          image: 'sturm-1',
          description:
              'A thundercloud with lightning over a tree, Mila runs away from '
              'the tree',
          lines: [
            ComicLine(
              _nuss,
              'In a thunderstorm get inside quickly. Don’t stand under a tree!',
            ),
            ComicLine(_mila, 'And indoors?'),
            ComicLine(
              _nuss,
              'Away from the window. Outside, the storm can blow branches and '
              'roof tiles around.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-2',
          description:
              'Dad and Mila stay on the dry pavement, the street in front of '
              'them is flooded',
          lines: [
            ComicLine.caption(
              'Water is often stronger and deeper than it looks.',
              lead: 'Floods:',
            ),
            ComicLine(
              _papa,
              'We never walk through water in the street. And in a flood we '
              'don’t go into the cellar either!',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-3',
          description: 'Mila and Nuss upstairs with a backpack, there is water downstairs',
          lines: [
            ComicLine(
              _mila,
              'We go upstairs and wait until the fire brigade says it’s safe '
              'again.',
            ),
            ComicLine(
              _nuss,
              'We take the emergency bag and the radio with us.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-4',
          description: 'A hot summer day, Mila drinks in the shade of a tree',
          lines: [
            ComicLine.caption('is dangerous too.', lead: 'Great heat'),
            ComicLine(
              _nuss,
              'Drink lots, stay in the shade and play indoors at midday.',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'feuer',
      title: 'Beeping and the smell of smoke',
      lede:
          'A fire at home is the danger children are most likely to face '
          'themselves. Every second counts.',
      rulesTitle: 'Fire',
      rules: [
        'Get out and shout “Fire!”',
        'Bend down or crawl',
        'Never hide, never go back',
        '112: Where? What? Then wait',
      ],
      panels: [
        ComicPanel(
          image: 'feuer-1',
          description:
              'A beeping smoke alarm on the ceiling, smoke below it, Mila '
              'startled',
          lines: [
            ComicLine(_mila, 'The smoke alarm is beeping!'),
            ComicLine(
              _nuss,
              'Get out of the flat right away! And shout “Fire!” loudly so '
              'everyone hears it.',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-2',
          description:
              'Mila crawls on all fours under the smoke towards the door',
          lines: [
            ComicLine.caption(
              'There is less smoke down near the floor. So: bend down or crawl.',
            ),
            ComicLine(
              _nuss,
              'Never hide, not under the bed and not in the wardrobe! The fire '
              'brigade has to be able to find you.',
            ),
            ComicLine(_mila, 'And I close the door behind me.'),
          ],
        ),
        ComicPanel(
          image: 'feuer-3',
          description:
              'Outside at the assembly point: Dad calls 112 on his phone, Mila '
              'holds on to him',
          lines: [
            ComicLine(_mila, 'Momo is still inside!'),
            ComicLine(
              _papa,
              'We never go back into the house. The fire brigade does that. '
              'Things can be replaced, you can’t.',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-4',
          description: 'A big phone showing 112, Nuss points at it',
          lines: [
            ComicLine(_mila, 'And if I’m on my own?'),
            ComicLine(
              _nuss,
              'Then you call 112 yourself. It is free and works even with no '
              'credit on the phone.',
            ),
            ComicLine.caption(
              'Where is it? What has happened? Then you wait. The control '
              'centre asks questions and hangs up first.',
              lead: 'On the phone you say:',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'krieg',
      title: 'When grown-ups talk about war',
      lede:
          'Sometimes children hear news that frightens them. Talking about '
          'it helps more than keeping quiet.',
      rulesTitle: 'When I’m scared',
      rules: [
        'Talk about it',
        'Ask grown-ups, don’t believe the internet',
        'If there is a warning: a room without windows, stay together',
        'Don’t touch strange objects',
      ],
      panels: [
        ComicPanel(
          image: 'krieg-1',
          description: 'Mila stands sadly beside the radio, Dad is with her',
          lines: [
            ComicLine(
              _mila,
              'On the radio they’re talking about war. Will it come here too?',
            ),
            ComicLine(
              _papa,
              'I’m glad you asked. Here where we live it is safe right now. '
              'And lots of people work every day to keep it that way.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-2',
          description: 'Mila draws a picture with a heart, Nuss sits with her',
          lines: [
            ComicLine(
              _nuss,
              'Being scared is all right. Tell someone about it: your dad, '
              'your teacher or your grandma.',
            ),
            ComicLine(_mila, 'Drawing helps me too. And cuddling Momo.'),
          ],
        ),
        ComicPanel(
          image: 'krieg-3',
          description:
              'The family in a room without windows with a backpack, a radio '
              'and the toy rabbit',
          lines: [
            ComicLine.caption('', lead: 'If there ever is a warning:'),
            ComicLine(
              _papa,
              'Then we go into a room without windows, like the hallway or the '
              'cellar. We take the emergency bags, the radio and a torch.',
            ),
            ComicLine(_mila, 'And we stay together.'),
          ],
        ),
        ComicPanel(
          image: 'krieg-4',
          description:
              'A phone with a question mark, and in the grass a strange '
              'object nobody touches',
          lines: [
            ComicLine(
              _nuss,
              'Not everything on the internet is true. Better ask a grown-up '
              'or listen to the news on the radio.',
            ),
            ComicLine(
              _mila,
              'And if I find something strange outside, I don’t touch it and '
              'I tell a grown-up.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-5',
          wide: true,
          description: 'Mila, Dad and Nuss stand happily under the big tree',
          lines: [
            ComicLine(
              _mila,
              'Now I know what I can do. That feels much better.',
            ),
            ComicLine(_nuss, 'You see? Being prepared makes you less afraid.'),
          ],
        ),
      ],
    ),
  ],
  parentsIntro:
      'The comic is meant to be read together, from about five years old. '
      'One chapter an evening is plenty. The last chapter is deliberately '
      'calm. Read it when your child asks about the news, not as the '
      'starting point.',
  parentsTips: [
    'Answer questions honestly and briefly. Children do not need details, '
        'but they notice when something is being kept from them.',
    'Pack the emergency bag together. Being able to do something yourself '
        'makes you feel less helpless.',
    'Practise the meeting point, your address and the numbers 112 and 110 '
        'together, ideally outside the front door.',
    'Use warning day in September as a reason to talk about the siren '
        'signals.',
    'Test the smoke alarms together, so the beeping is familiar and not '
        'frightening.',
  ],
  source:
      'The safety rules follow the emergency preparedness advice of the '
      'German Federal Office of Civil Protection and Disaster Assistance '
      '(BBK). Mila, Nuss and their story are this app’s own characters and '
      'not a BBK publication.',
);

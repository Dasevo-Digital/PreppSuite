import 'kids_comic.dart';

const _mila = ComicSpeaker.mila;
const _nuss = ComicSpeaker.nuss;
const _papa = ComicSpeaker.papa;

const kidsComicEn = KidsComic(
  title: 'Mila and Nuss',
  subtitle: 'Our emergency comic',
  intro:
      'Six exciting stories for curious kids: prepare, stay calm, understand '
      'warnings, stick together. With Nuss the squirrel and with her dad, '
      'Mila learns what to do when the lights go out, the siren sounds, a '
      'storm comes, there is a fire, or adults talk about war.',
  coverDescription:
      'Mila and Nuss the squirrel gathering nuts in the garden, next to an '
      'open box of supplies',
  speakers: {
    ComicSpeaker.mila: 'Mila',
    ComicSpeaker.nuss: 'Nuss',
    ComicSpeaker.papa: 'Dad',
  },
  numbers: [
    (number: '112', label: 'Fire and ambulance'),
    (number: '110', label: 'Police (Germany)'),
  ],
  numbersNote: 'Children: always ask an adult for help.',
  chapters: [
    ComicChapter(
      id: 'vorrat',
      title: 'Nuss stocks up',
      lede: 'What if something important stops working?',
      panels: [
        ComicPanel(
          image: 'vorrat-1',
          description:
              'Mila and Nuss gather nuts into a basket in the garden, next to '
              'an open box of tins, jars and water bottles',
          lines: [
            ComicLine(
              _nuss,
              'I collect nuts. What should our family store for emergencies?',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-2',
          description:
              'Dad and Mila fill a shelf with water bottles, tins and jars, '
              'Nuss watches',
          lines: [
            ComicLine(
              _papa,
              'Water and long-lasting food: start with 3 days, aim for 10.',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-3',
          description:
              'Mila packs her teddy into a red backpack, on the table are a '
              'first aid kit, a flashlight and a packing list',
          lines: [
            ComicLine(
              _mila,
              'Our go-bag needs a flashlight, radio, medicine and my teddy!',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-4',
          description:
              'In the park Dad shows Mila a green assembly point sign, Nuss '
              'sits on his shoulder',
          lines: [
            ComicLine(
              _papa,
              'We also know where to meet and which numbers to call.',
            ),
          ],
        ),
      ],
      note:
          'Plan roughly 2 litres of water per person per day for drinking and '
          'cooking. Remember pets.',
      rulesTitle: 'Supplies',
      rules: ['3 days is a good start', 'Plan for 10 days if possible'],
    ),
    ComicChapter(
      id: 'strom',
      title: 'Suddenly, the lights go out',
      lede: 'No electricity: what do we do?',
      panels: [
        ComicPanel(
          image: 'strom-1',
          description:
              'A dark living room in the evening, Dad presses the light '
              'switch, Mila and Nuss look up at the lamp',
          lines: [ComicLine(_mila, 'The lights went out! Is something wrong?')],
        ),
        ComicPanel(
          image: 'strom-2',
          description:
              'Mila shines a flashlight, next to her a crossed-out candle '
              'sign, Nuss sits by a lantern',
          lines: [
            ComicLine(
              _papa,
              'We stay calm. A flashlight is safer than candles.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-3',
          description:
              'Dad closes the fridge and points to the stairs, there is a '
              'no-entry sign on the lift',
          lines: [
            ComicLine(_nuss, 'Keep the fridge shut! And never use the lift.'),
          ],
        ),
        ComicPanel(
          image: 'strom-4',
          description:
              'Mila, Dad and Nuss listen to a crank radio, Grandma stands '
              'smiling in the doorway',
          lines: [
            ComicLine(
              _mila,
              'We can listen to the crank radio and see if Grandma needs help.',
            ),
          ],
        ),
      ],
      note:
          'Keep handy: a flashlight, spare batteries, power bank and a '
          'battery-powered or crank radio.',
      rulesTitle: 'Power',
      rules: ['Flashlight and radio', 'Keep the fridge closed'],
    ),
    ComicChapter(
      id: 'sirene',
      title: 'The siren sounds',
      lede: 'That loud sound means: pay attention!',
      panels: [
        ComicPanel(
          image: 'sirene-1',
          description:
              'Mila, Dad and Nuss look up at a wailing siren on a mast above '
              'the rooftops',
          lines: [
            ComicLine(
              _nuss,
              'Hear the rising and falling sound? It may be a warning!',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-2',
          description:
              'Dad leads Mila by the hand through the front door into the '
              'house, Nuss runs along',
          lines: [
            ComicLine(_papa, 'We find a safe place and go inside together.'),
          ],
        ),
        ComicPanel(
          image: 'sirene-3',
          description:
              'At the kitchen table Dad switches on the radio and holds a '
              'phone with a warning sign, Mila and Nuss listen',
          lines: [
            ComicLine(
              _mila,
              'What happened? Let’s check the radio and official alerts.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-4',
          description:
              'Dad explains the alert to Mila and Nuss, a green tick in the '
              'window',
          lines: [
            ComicLine(
              _papa,
              'The alert tells us what to do for this particular danger.',
            ),
          ],
        ),
      ],
      note:
          'In Germany: a 1-minute rising/falling siren warns of danger; a '
          '1-minute steady tone means all clear. Follow local notices.',
      rulesTitle: 'Sirens',
      rules: ['Hear the alert', 'Check official advice', 'Respond safely'],
    ),
    ComicChapter(
      id: 'sturm',
      title: 'Storms, floods and heat',
      lede: 'Sometimes the weather can be dangerous.',
      panels: [
        ComicPanel(
          image: 'sturm-1',
          description:
              'Mila, Nuss and Dad sit indoors on the sofa, outside a storm '
              'rages with rain',
          lines: [
            ComicLine(
              _mila,
              'During a storm, we stay inside and away from windows.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-2',
          description:
              'Dad and Mila, with Nuss in her arms, go up the stairs, outside '
              'the street is under water',
          lines: [
            ComicLine(
              _papa,
              'During a flood, we go upstairs, never into the basement!',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-3',
          description:
              'Dad sets out the go-bag, a radio, water and a flashlight, '
              'outside houses stand in the water',
          lines: [
            ComicLine(
              _nuss,
              'Our go-bag and radio are ready. We follow official alerts.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-4',
          description:
              'Dad, Mila in a sun hat and Nuss drink water in the shade of a '
              'tree',
          lines: [
            ComicLine(
              _mila,
              'On very hot days: find shade, rest and drink enough water!',
            ),
          ],
        ),
      ],
      note:
          'Never walk or drive through floodwater. During thunderstorms, do '
          'not shelter under trees.',
      rulesTitle: 'Weather',
      rules: ['Shelter indoors', 'During floods, stay out of basements'],
    ),
    ComicChapter(
      id: 'feuer',
      title: 'Beeping alarm, smell of smoke',
      lede: 'A smoke alarm warns us about a fire.',
      panels: [
        ComicPanel(
          image: 'feuer-1',
          description:
              'In the hall a smoke alarm beeps on the ceiling, smoke is '
              'coming in, Mila points up',
          lines: [ComicLine(_mila, 'The smoke alarm is beeping! Fire!')],
        ),
        ComicPanel(
          image: 'feuer-2',
          description:
              'Dad, Mila and Nuss crawl under the smoke to the open front '
              'door',
          lines: [
            ComicLine(
              _papa,
              'Find a safe exit quickly. Stay low if there is smoke.',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-3',
          description:
              'Outside, Dad pulls the front door shut, Mila holds Nuss in her '
              'arms',
          lines: [
            ComicLine(
              _mila,
              'Close the door behind us, and never go back inside!',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-4',
          description:
              'Dad is on the phone, Mila holds Nuss in her arms, behind them '
              'the fire brigade arrives',
          lines: [
            ComicLine(
              _papa,
              'Once we are outside, I call 112 and say if someone is missing.',
            ),
          ],
        ),
      ],
      note:
          'Never enter smoke-filled escape routes. If the exit is blocked, '
          'close the door and call for help at the window.',
      rulesTitle: 'Fire',
      rules: ['Get out, close the door, call 112', 'Never go back inside'],
    ),
    ComicChapter(
      id: 'krieg',
      title: 'When adults talk about war',
      lede: 'It’s okay to ask difficult questions.',
      panels: [
        ComicPanel(
          image: 'krieg-1',
          description:
              'Mila sits on the sofa looking worried and hugs her cuddly toy, '
              'Nuss sits with her, a radio is on the table',
          lines: [
            ComicLine(
              _mila,
              'The radio is talking about war. That scares me.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-2',
          description:
              'Dad sits with Mila on the sofa and talks to her kindly, Nuss '
              'listens',
          lines: [
            ComicLine(
              _papa,
              'I understand. You can ask me anything, and I will listen.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-3',
          description: 'Mila draws a heart, Nuss cuddles up to her',
          lines: [
            ComicLine(
              _nuss,
              'Talking, drawing and cuddling can help us feel better.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-4',
          description:
              'Dad, Mila and Nuss sit calmly beside a backpack, a radio, a '
              'flashlight and a first aid kit',
          lines: [
            ComicLine(
              _papa,
              'We check reliable news and calmly plan what we can do.',
            ),
          ],
        ),
      ],
      note:
          'Answer children honestly and in age-appropriate ways, acknowledge '
          'feelings and take news breaks.',
      rulesTitle: 'Feelings',
      rules: ['Ask questions', 'Share worries', 'Use trusted sources'],
    ),
  ],
  parentsIntro:
      'The comic is meant to be read together, from about five years old. '
      'One chapter an evening is plenty. The last chapter is deliberately '
      'calm. Read it when your child asks about the news, not as the '
      'starting point. What the chapters advise, for adults:',
  parentsTips: [
    'Emergency supplies: prepare to manage on your own for up to 10 days if '
        'possible; 3 days is a good start. Plan around 2 litres of water per '
        'person daily.',
    'Power outages: prepare lights, a radio and supplies. Electricity cuts '
        'can affect refrigeration, heating, lifts and communications.',
    'Public warnings: in Germany, a 1-minute rising/falling siren signals a '
        'warning; a 1-minute steady tone means all clear. Check the actual '
        'alert.',
    'Natural hazards: in a storm, seek shelter indoors. In a flood, go to '
        'higher floors; never enter basements, underpasses or underground '
        'car parks.',
    'Fires: use only safe escape routes, avoid smoke, close doors behind you '
        'and call 112 from outside. Never re-enter a burning building.',
    'Talking with children: take their worries seriously, explain honestly '
        'in age-appropriate terms, limit distressing news and avoid promises '
        'of absolute safety.',
  ],
  source:
      'Editorially checked in October 2026 against publicly available advice '
      'from the German Federal Office of Civil Protection (BBK): preparing '
      'for crises and disasters, sirens and public warnings in Germany, '
      'finding shelter, floods, fire safety and coping with fears and '
      'worries. Not officially approved or medically certified. Mila, Nuss '
      'and their story are this app’s own characters and not a BBK '
      'publication.',
);

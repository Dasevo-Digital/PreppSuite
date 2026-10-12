import 'kids_comic.dart';

const _mila = ComicSpeaker.mila;
const _nuss = ComicSpeaker.nuss;
const _papa = ComicSpeaker.papa;

const kidsComicEs = KidsComic(
  title: 'Mila y Nuss',
  subtitle: 'Nuestro cómic de emergencias',
  intro:
      'Seis historias para aprender y estar preparados: prepararse, mantener '
      'la calma, entender las alertas, ayudarse. Con la ardilla Nuss y con '
      'su papá, Mila aprende qué hacer cuando se va la luz, suena la sirena, '
      'llega una tormenta, hay un incendio o los mayores hablan de guerra.',
  coverDescription:
      'Mila y la ardilla Nuss recogen nueces en el jardín, al lado de una '
      'caja abierta con provisiones',
  speakers: {
    ComicSpeaker.mila: 'Mila',
    ComicSpeaker.nuss: 'Nuss',
    ComicSpeaker.papa: 'Papá',
  },
  numbers: [
    (number: '112', label: 'Bomberos y emergencias médicas'),
    (number: '110', label: 'Policía (Alemania)'),
  ],
  numbersNote: 'Niños: pedid ayuda a un adulto.',
  chapters: [
    ComicChapter(
      id: 'vorrat',
      title: 'Nuss prepara las provisiones',
      lede: '¿Y si un día falla algo importante?',
      panels: [
        ComicPanel(
          image: 'vorrat-1',
          description:
              'Mila y Nuss recogen nueces en una cesta en el jardín, al lado '
              'una caja abierta con latas, tarros y botellas de agua',
          lines: [
            ComicLine(
              _nuss,
              'Yo guardo nueces. ¿Qué guardamos nosotros para una emergencia?',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-2',
          description:
              'Papá y Mila llenan una estantería con botellas de agua, latas '
              'y tarros, Nuss mira',
          lines: [
            ComicLine(
              _papa,
              'Agua y alimentos duraderos: primero para 3 días, mejor para 10.',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-3',
          description:
              'Mila mete su osito en una mochila roja, en la mesa hay un '
              'botiquín, una linterna y una lista de cosas',
          lines: [
            ComicLine(
              _mila,
              '¡En la mochila necesitamos linterna, radio, medicinas y mi '
              'osito!',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-4',
          description:
              'En el parque, Papá le enseña a Mila una señal verde de punto '
              'de encuentro, Nuss va sentado en su hombro',
          lines: [
            ComicLine(
              _papa,
              'También sabemos dónde reunirnos y a qué números llamar.',
            ),
          ],
        ),
      ],
      note:
          'Calcula unos 2 litros de agua por persona y día para beber y '
          'cocinar. Incluye a las mascotas.',
      rulesTitle: 'Provisiones',
      rules: ['3 días es un buen comienzo', 'Mejor prepararse para 10'],
    ),
    ComicChapter(
      id: 'strom',
      title: 'De pronto, se va la luz',
      lede: 'No hay electricidad, ¿qué hacemos?',
      panels: [
        ComicPanel(
          image: 'strom-1',
          description:
              'Salón a oscuras por la tarde, Papá pulsa el interruptor, Mila '
              'y Nuss miran la lámpara',
          lines: [
            ComicLine(_mila, '¡Se ha apagado la luz! ¿Ha pasado algo malo?'),
          ],
        ),
        ComicPanel(
          image: 'strom-2',
          description:
              'Mila alumbra con una linterna, al lado una señal de velas '
              'tachadas, Nuss está junto a un farol',
          lines: [
            ComicLine(
              _papa,
              'Mantenemos la calma. Una linterna es más segura que una vela.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-3',
          description:
              'Papá cierra la nevera y señala la escalera, en el ascensor hay '
              'una señal de prohibido',
          lines: [
            ComicLine(
              _nuss,
              '¡Dejad cerrada la nevera! Y no uséis el ascensor.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-4',
          description:
              'Mila, Papá y Nuss escuchan una radio de manivela, la abuela '
              'sonríe en la puerta',
          lines: [
            ComicLine(
              _mila,
              'Oigamos la radio de manivela y veamos si la abuela necesita '
              'ayuda.',
            ),
          ],
        ),
      ],
      note:
          'Ten a mano linternas, pilas de repuesto, batería externa y radio a '
          'pilas o de manivela.',
      rulesTitle: 'Luz',
      rules: ['Linterna y radio', 'Mantener cerrada la nevera'],
    ),
    ComicChapter(
      id: 'sirene',
      title: 'Suena la sirena',
      lede: 'Ese sonido fuerte significa: ¡atención!',
      panels: [
        ComicPanel(
          image: 'sirene-1',
          description:
              'Mila, Papá y Nuss miran una sirena que suena en un mástil '
              'sobre los tejados',
          lines: [
            ComicLine(
              _nuss,
              '¿Oyes el sonido que sube y baja? ¡Puede ser una alerta!',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-2',
          description:
              'Papá lleva a Mila de la mano por la puerta de casa, Nuss los '
              'acompaña',
          lines: [
            ComicLine(
              _papa,
              'Buscamos un lugar seguro y entramos juntos en casa.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-3',
          description:
              'En la mesa de la cocina Papá enciende la radio y sostiene un '
              'móvil con una señal de aviso, Mila y Nuss escuchan',
          lines: [
            ComicLine(
              _mila,
              '¿Qué ha pasado? Escuchemos la radio y consultemos alertas '
              'oficiales.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-4',
          description:
              'Papá les explica el aviso a Mila y a Nuss, en la ventana una '
              'marca verde',
          lines: [
            ComicLine(
              _papa,
              'El aviso nos dice cómo protegernos de ese peligro concreto.',
            ),
          ],
        ),
      ],
      note:
          'En Alemania: sirena que sube y baja 1 minuto = alerta; tono '
          'constante 1 minuto = fin de alerta. Atiende los avisos locales.',
      rulesTitle: 'Sirenas',
      rules: ['Oír la alerta', 'Consultar avisos oficiales', 'Actuar'],
    ),
    ComicChapter(
      id: 'sturm',
      title: 'Tormentas, inundaciones y calor',
      lede: 'A veces el tiempo puede ser peligroso.',
      panels: [
        ComicPanel(
          image: 'sturm-1',
          description:
              'Mila, Nuss y Papá están dentro en el sofá, fuera hay una '
              'tormenta con lluvia',
          lines: [
            ComicLine(
              _mila,
              'Si hay tormenta, nos quedamos dentro, lejos de las ventanas.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-2',
          description:
              'Papá y Mila, con Nuss en brazos, suben la escalera, fuera la '
              'calle está inundada',
          lines: [
            ComicLine(
              _papa,
              'Si hay inundación, subimos de planta. ¡Nunca al sótano!',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-3',
          description:
              'Papá prepara la mochila, una radio, agua y una linterna, fuera '
              'hay casas en el agua',
          lines: [
            ComicLine(
              _nuss,
              'La mochila y la radio están listas. Seguimos las alertas.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-4',
          description:
              'Papá, Mila con sombrero de sol y Nuss beben agua a la sombra '
              'de un árbol',
          lines: [
            ComicLine(
              _mila,
              'Cuando hace mucho calor: ¡sombra, descansos y agua!',
            ),
          ],
        ),
      ],
      note:
          'No camines ni conduzcas por zonas inundadas. Si hay tormenta '
          'eléctrica, no te refugies bajo los árboles.',
      rulesTitle: 'Temporal',
      rules: ['Refugiarse dentro', 'Si hay inundación, evitar el sótano'],
    ),
    ComicChapter(
      id: 'feuer',
      title: 'Suena la alarma y hay humo',
      lede: 'El detector de humo avisa del fuego.',
      panels: [
        ComicPanel(
          image: 'feuer-1',
          description:
              'En el pasillo pita un detector de humo en el techo, entra '
              'humo, Mila señala hacia arriba',
          lines: [ComicLine(_mila, '¡Suena el detector de humo! ¡Fuego!')],
        ),
        ComicPanel(
          image: 'feuer-2',
          description:
              'Papá, Mila y Nuss gatean por debajo del humo hacia la puerta '
              'abierta',
          lines: [
            ComicLine(
              _papa,
              'Vamos rápido a una salida segura. Si hay humo, agáchate.',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-3',
          description:
              'Fuera, Papá cierra la puerta de casa, Mila lleva a Nuss en '
              'brazos',
          lines: [
            ComicLine(
              _mila,
              'Cerramos la puerta al salir, ¡y no volvemos a entrar!',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-4',
          description:
              'Papá habla por teléfono, Mila lleva a Nuss en brazos, detrás '
              'llegan los bomberos',
          lines: [
            ComicLine(_papa, 'Ya fuera, llamo al 112 y digo si falta alguien.'),
          ],
        ),
      ],
      note:
          'No entres en rutas de salida llenas de humo. Si no puedes salir, '
          'cierra la puerta y pide ayuda desde una ventana.',
      rulesTitle: 'Fuego',
      rules: ['Salir, cerrar la puerta, llamar al 112', 'No regresar'],
    ),
    ComicChapter(
      id: 'krieg',
      title: 'Cuando los mayores hablan de guerra',
      lede: 'Está bien hacer preguntas difíciles.',
      panels: [
        ComicPanel(
          image: 'krieg-1',
          description:
              'Mila está triste en el sofá y abraza su peluche, Nuss está a '
              'su lado, en la mesa hay una radio',
          lines: [
            ComicLine(
              _mila,
              'En la radio hablan de una guerra. Me da miedo.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-2',
          description:
              'Papá se sienta con Mila en el sofá y le habla con cariño, Nuss '
              'escucha',
          lines: [
            ComicLine(
              _papa,
              'Lo entiendo. Puedes preguntarme lo que quieras; te escucharé.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-3',
          description: 'Mila dibuja un corazón, Nuss se acurruca a su lado',
          lines: [
            ComicLine(
              _nuss,
              'Hablar, dibujar y abrazarnos puede hacernos sentir mejor.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-4',
          description:
              'Papá, Mila y Nuss están sentados con calma junto a una '
              'mochila, una radio, una linterna y un botiquín',
          lines: [
            ComicLine(
              _papa,
              'Comprobamos las noticias y pensamos con calma qué hacer.',
            ),
          ],
        ),
      ],
      note:
          'Responde con sinceridad y según la edad, escucha sus emociones y '
          'haz pausas de las noticias.',
      rulesTitle: 'Emociones',
      rules: ['Preguntar', 'Compartir miedos', 'Buscar fuentes fiables'],
    ),
  ],
  parentsIntro:
      'El cómic está pensado para leerlo juntos a partir de unos cinco '
      'años. Basta con un capítulo por noche. El último capítulo es '
      'tranquilo a propósito: léelo cuando tu hijo o hija pregunte por las '
      'noticias, no como primer capítulo. Lo que aconsejan los capítulos, '
      'para personas adultas:',
  parentsTips: [
    'Provisiones de emergencia: si es posible, prepara provisiones para 10 '
        'días; 3 días es un buen inicio. Calcula unos 2 litros de agua por '
        'persona y día.',
    'Cortes de electricidad: prepara iluminación, radio y provisiones. Un '
        'apagón puede afectar al frío, la calefacción, los ascensores y las '
        'comunicaciones.',
    'Alertas públicas: en Alemania, 1 minuto de sirena ascendente y '
        'descendente = alerta; 1 minuto de tono constante = fin. Comprueba '
        'el aviso concreto.',
    'Riesgos naturales: con tormenta, busca refugio en un edificio. Con '
        'inundación, sube a plantas superiores; evita sótanos, pasos '
        'subterráneos y garajes.',
    'Incendios: usa solo salidas seguras, evita el humo, cierra las puertas '
        'al salir y llama al 112 desde fuera. Nunca vuelvas a entrar.',
    'Hablar con los niños: escucha sus preocupaciones, explica con '
        'sinceridad según su edad, limita las noticias angustiosas y no '
        'prometas seguridad absoluta.',
  ],
  source:
      'Adaptación editorial de octubre de 2026, basada en las '
      'recomendaciones públicas de la Oficina Federal alemana de Protección '
      'Civil (BBK): preparación ante crisis y catástrofes, sirenas y alertas '
      'en Alemania, buscar refugio, inundaciones, prevención de incendios y '
      'afrontar miedos y preocupaciones. Sin aprobación oficial ni '
      'certificación médica. Mila, Nuss y su historia son personajes propios '
      'de esta app y no una publicación del BBK.',
);

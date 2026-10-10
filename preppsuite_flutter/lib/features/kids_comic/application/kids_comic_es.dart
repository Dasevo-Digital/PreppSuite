import 'kids_comic.dart';

const _mila = ComicSpeaker.mila;
const _nuss = ComicSpeaker.nuss;
const _papa = ComicSpeaker.papa;
const _vecina = ComicSpeaker.neighbour;

const kidsComicEs = KidsComic(
  title: 'Mila y Nuss',
  subtitle: 'Un cómic de emergencias para niños',
  intro:
      'Nuss es una ardilla que cada otoño guarda provisiones. Mila aprende '
      'de él y de su papá qué hacer cuando de repente algo es distinto de '
      'lo normal: cuando se va la luz, suena la sirena, llega una tormenta, '
      'hay un incendio o los mayores hablan de guerra.',
  coverDescription:
      'Mila y la ardilla Nuss bajo un árbol con un montón de nueces',
  speakers: {
    ComicSpeaker.mila: 'Mila',
    ComicSpeaker.nuss: 'Nuss',
    ComicSpeaker.papa: 'Papá',
    ComicSpeaker.neighbour: 'Sra. Yilmaz',
  },
  numbers: [
    (number: '112', label: 'Bomberos y ambulancia'),
    (number: '110', label: 'Policía'),
  ],
  chapters: [
    ComicChapter(
      id: 'vorrat',
      title: 'Nuss guarda provisiones',
      lede:
          'Quien está preparado tiene menos miedo. Por eso todo empieza '
          'aquí, en un día cualquiera.',
      rulesTitle: 'Provisiones',
      rules: [
        'Agua y comida para unos días',
        'Una mochila de emergencia para cada uno',
        'Los números de teléfono en papel',
        'Acordar un punto de encuentro',
      ],
      panels: [
        ComicPanel(
          image: 'vorrat-1',
          description:
              'Nuss está sentado bajo un árbol junto a un montón de nueces, '
              'Mila lo mira',
          lines: [
            ComicLine(
              _nuss,
              'Recojo nueces para el invierno. Así tengo bastantes, aunque '
              'fuera esté todo nevado.',
            ),
            ComicLine(
              _mila,
              '¡Qué listo! ¿Las personas también necesitamos provisiones así?',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-2',
          description:
              'Papá le enseña a Mila una estantería con botellas de agua y '
              'latas',
          lines: [
            ComicLine(
              _papa,
              'Sí. Tenemos agua y comida para unos días. Si alguna vez las '
              'tiendas están cerradas, nos apañamos igual.',
            ),
            ComicLine.caption(
              'Unos 2 litros por persona y día, para beber y cocinar.',
              lead: '¿Cuánta agua?',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-3',
          description:
              'Mila prepara una mochila con linterna, cantimplora y conejo '
              'de peluche',
          lines: [
            ComicLine(
              _mila,
              'En mi mochila de emergencia van: la linterna, la cantimplora, '
              'una chaqueta de abrigo y mi conejo de peluche Momo.',
            ),
            ComicLine(
              _nuss,
              'Y una nota con los teléfonos de mamá y papá. Si el móvil se '
              'queda sin batería, el papel ayuda.',
            ),
          ],
        ),
        ComicPanel(
          image: 'vorrat-4',
          description:
              'Un cartel verde de punto de encuentro delante de la casa, '
              'Papá y Mila al lado',
          lines: [
            ComicLine(
              _papa,
              'Si alguna vez nos perdemos, nos encontramos aquí, junto al '
              'cartel delante de casa.',
            ),
            ComicLine(
              _mila,
              '¡Y mi dirección me la sé de memoria: Lindenweg 4!',
            ),
            ComicLine.caption(
              '112 para bomberos y ambulancia, 110 para la policía. Los dos '
              'números son gratis.',
              lead: 'Emergencias:',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'strom',
      title: 'De repente todo está oscuro',
      lede:
          'Un apagón llega sin avisar. La luz, la tele y la calefacción se '
          'apagan, y el móvil ya no carga.',
      rulesTitle: 'Apagón',
      rules: [
        'Mantener la calma',
        'Linterna en vez de vela',
        'Dejar la nevera cerrada',
        'Escuchar la radio, preguntar a los vecinos',
      ],
      panels: [
        ComicPanel(
          image: 'strom-1',
          description:
              'Una habitación oscura de noche, Mila asustada, Papá a su lado',
          lines: [
            ComicLine(_mila, '¡Papá! ¡Se ha ido la luz, y la tele también!'),
            ComicLine(
              _papa,
              'Es un apagón. Lo primero, mantenemos la calma. Estoy aquí.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-2',
          description:
              'Nuss alumbra con una linterna, al lado una vela tachada',
          lines: [
            ComicLine(
              _nuss,
              '¡Linterna en vez de vela! Una vela se puede caer, y entonces '
              'hay fuego.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-3',
          description: 'Papá mantiene cerrada la nevera, Mila mira',
          lines: [
            ComicLine(
              _papa,
              'La nevera la dejamos cerrada. Así dentro se mantiene fría '
              'más tiempo.',
            ),
            ComicLine(_mila, '¿Y el ascensor de casa?'),
            ComicLine(
              _papa,
              'Sin corriente no funciona. Vamos por la escalera.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-4',
          description:
              'Papá le da a la manivela de una radio, Mila y Nuss escuchan',
          lines: [
            ComicLine(
              _papa,
              'Esta radio funciona con pilas o con la manivela. En la radio '
              'dicen qué pasa y cuánto va a durar.',
            ),
            ComicLine.caption(
              'Abrigarse, acurrucarse juntos y hacer sombras chinescas con '
              'la linterna. Así el tiempo pasa más rápido.',
            ),
          ],
        ),
        ComicPanel(
          image: 'strom-5',
          wide: true,
          description:
              'Mila y Papá llaman a la puerta de la vecina, que abre con '
              'una sonrisa',
          lines: [
            ComicLine(
              _mila,
              'La señora Yilmaz, la de al lado, vive sola. ¿Le preguntamos '
              'si necesita algo?',
            ),
            ComicLine(
              _vecina,
              '¡Qué amables sois! Me vendría bien una manta.',
            ),
            ComicLine(
              _papa,
              'Buena idea, Mila. Cuando los vecinos se ayudan, es más fácil '
              'para todos.',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'sirene',
      title: 'Suena la sirena',
      lede:
          'Las sirenas avisan a todo el mundo a la vez. Lo importante es '
          'cómo suenan.',
      rulesTitle: 'Sirena',
      rules: [
        'Sube y baja: aviso, a casa',
        'Ventanas y puertas cerradas',
        'Radio o app de avisos encendida',
        'Tono largo: fin del aviso',
      ],
      panels: [
        ComicPanel(
          image: 'sirene-1',
          description:
              'Una sirena en un poste con ondas de sonido rojas, Mila '
              'asustada',
          lines: [
            ComicLine.caption(
              'Es un aviso.',
              lead: 'Un sonido que sube y baja durante un minuto:',
            ),
            ComicLine(_mila, '¿Qué significa eso?'),
            ComicLine(
              _nuss,
              '¡Atención! Ha pasado algo. Ahora escuchamos con cuidado.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-2',
          description: 'Mila camina con Nuss hacia una casa',
          lines: [
            ComicLine(
              _nuss,
              'Entra en la casa más cercana. Si estás fuera, quédate con tu '
              'profesora o con un adulto que conozcas.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sirene-3',
          description:
              'Dentro: Papá cierra la ventana, la radio está sobre la mesa',
          lines: [
            ComicLine(
              _papa,
              'Ventanas y puertas cerradas, radio encendida. En la radio y '
              'en la app de avisos dicen qué tenemos que hacer ahora.',
            ),
            ComicLine(_mila, 'Me quedo contigo.'),
          ],
        ),
        ComicPanel(
          image: 'sirene-4',
          description:
              'La sirena con un tono verde y tranquilo, Mila respira aliviada',
          lines: [
            ComicLine.caption(
              'Fin del aviso. El peligro ha pasado.',
              lead: 'Un tono largo, sin subir ni bajar:',
            ),
            ComicLine(_mila, '¡Uf!'),
            ComicLine(
              _nuss,
              'Una vez al año, el día de prueba de avisos en septiembre, '
              'todas las sirenas se prueban a la vez. Así no tienes que '
              'asustarte.',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'sturm',
      title: 'Tormenta e inundación',
      lede:
          'Las tormentas eléctricas, el viento fuerte y la lluvia intensa '
          'son lo más frecuente aquí. Contra todo ello casi siempre sirve '
          'lo mismo: meterse en casa.',
      rulesTitle: 'Tormenta e inundación',
      rules: [
        'Con tormenta, a casa y lejos de los árboles',
        'Dentro, lejos de la ventana',
        'Nunca cruzar el agua andando',
        'Con inundación, hacia arriba, no al sótano',
      ],
      panels: [
        ComicPanel(
          image: 'sturm-1',
          description:
              'Una nube de tormenta con un rayo sobre un árbol, Mila se '
              'aleja corriendo del árbol',
          lines: [
            ComicLine(
              _nuss,
              'Con tormenta, rápido a casa. ¡No te pongas debajo de un '
              'árbol!',
            ),
            ComicLine(_mila, '¿Y dentro?'),
            ComicLine(
              _nuss,
              'Lejos de la ventana. Fuera, el viento puede hacer volar ramas '
              'y tejas.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-2',
          description:
              'Papá y Mila se quedan en la acera seca; delante de ellos la '
              'calle está inundada',
          lines: [
            ComicLine.caption(
              'El agua suele ser más fuerte y más profunda de lo que parece.',
              lead: 'Inundación:',
            ),
            ComicLine(
              _papa,
              'Nunca cruzamos andando el agua de la calle. ¡Y con '
              'inundación tampoco bajamos al sótano!',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-3',
          description:
              'Mila y Nuss arriba en la casa con la mochila, abajo hay agua',
          lines: [
            ComicLine(
              _mila,
              'Subimos y esperamos hasta que los bomberos digan que vuelve a '
              'ser seguro.',
            ),
            ComicLine(
              _nuss,
              'La mochila de emergencia y la radio nos las llevamos.',
            ),
          ],
        ),
        ComicPanel(
          image: 'sturm-4',
          description:
              'Un día caluroso de verano, Mila bebe a la sombra de un árbol',
          lines: [
            ComicLine.caption(
              'también es un peligro.',
              lead: 'El calor fuerte',
            ),
            ComicLine(
              _nuss,
              'Beber mucho, quedarse a la sombra y a mediodía mejor jugar '
              'dentro.',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'feuer',
      title: 'Pita y huele a humo',
      lede:
          'El fuego en casa es el peligro que los niños tienen más '
          'probabilidades de vivir ellos mismos. Aquí cuenta cada segundo.',
      rulesTitle: 'Fuego',
      rules: [
        'Salir y gritar fuerte «¡Fuego!»',
        'Agacharse o gatear',
        'Nunca esconderse, nunca volver',
        '112: ¿Dónde? ¿Qué? Luego esperar',
      ],
      panels: [
        ComicPanel(
          image: 'feuer-1',
          description:
              'Un detector de humo pitando en el techo, debajo humo, Mila '
              'asustada',
          lines: [
            ComicLine(_mila, '¡El detector de humo está pitando!'),
            ComicLine(
              _nuss,
              '¡Sal de casa ahora mismo! Y grita fuerte «¡Fuego!» para que '
              'todos lo oigan.',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-2',
          description:
              'Mila gatea a cuatro patas por debajo del humo hacia la '
              'puerta',
          lines: [
            ComicLine.caption(
              'Abajo, cerca del suelo, hay menos humo. Por eso: agacharse o '
              'gatear.',
            ),
            ComicLine(
              _nuss,
              '¡No te escondas nunca, ni debajo de la cama ni en el armario! '
              'Los bomberos tienen que poder encontrarte.',
            ),
            ComicLine(_mila, 'Y cierro la puerta al salir.'),
          ],
        ),
        ComicPanel(
          image: 'feuer-3',
          description:
              'Fuera, en el punto de encuentro: Papá llama al 112 con el '
              'móvil, Mila se agarra a él',
          lines: [
            ComicLine(_mila, '¡Momo sigue dentro!'),
            ComicLine(
              _papa,
              'Nunca volvemos a entrar en casa. Eso lo hacen los bomberos. '
              'Las cosas se pueden reemplazar, a ti no.',
            ),
          ],
        ),
        ComicPanel(
          image: 'feuer-4',
          description: 'Un móvil grande con el número 112, Nuss lo señala',
          lines: [
            ComicLine(_mila, '¿Y si estoy sola?'),
            ComicLine(
              _nuss,
              'Entonces llamas tú misma al 112. Es gratis y funciona también '
              'sin saldo.',
            ),
            ComicLine.caption(
              '¿Dónde es? ¿Qué ha pasado? Luego esperas. La central hace '
              'preguntas y es la primera en colgar.',
              lead: 'Por teléfono dices:',
            ),
          ],
        ),
      ],
    ),
    ComicChapter(
      id: 'krieg',
      title: 'Cuando los mayores hablan de guerra',
      lede:
          'A veces los niños oyen noticias que les dan miedo. Hablar de '
          'ello ayuda más que callar.',
      rulesTitle: 'Cuando tengo miedo',
      rules: [
        'Hablar de ello',
        'Preguntar a los adultos, no creer a internet',
        'Si hay aviso: habitación sin ventanas, quedarse juntos',
        'No tocar cosas raras',
      ],
      panels: [
        ComicPanel(
          image: 'krieg-1',
          description:
              'Mila está junto a la radio con cara triste, Papá está con ella',
          lines: [
            ComicLine(
              _mila,
              'En la radio hablan de guerra. ¿Va a venir aquí también?',
            ),
            ComicLine(
              _papa,
              'Qué bien que lo preguntes. Aquí ahora mismo estamos seguros. '
              'Y muchísimas personas trabajan cada día para que siga así.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-2',
          description:
              'Mila pinta un dibujo con un corazón, Nuss está sentado con ella',
          lines: [
            ComicLine(
              _nuss,
              'Tener miedo está bien. Cuéntaselo a alguien: a papá, a tu '
              'profesora o a la abuela.',
            ),
            ComicLine(
              _mila,
              'A mí también me ayuda pintar. Y abrazar a Momo.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-3',
          description:
              'La familia en una habitación sin ventanas con mochila, radio '
              'y conejo de peluche',
          lines: [
            ComicLine.caption('', lead: 'Si alguna vez hay un aviso:'),
            ComicLine(
              _papa,
              'Entonces vamos a una habitación sin ventanas, por ejemplo al '
              'pasillo o al sótano. Nos llevamos la mochila de emergencia, '
              'la radio y la linterna.',
            ),
            ComicLine(_mila, 'Y nos quedamos juntos.'),
          ],
        ),
        ComicPanel(
          image: 'krieg-4',
          description:
              'Un móvil con un signo de interrogación; al lado, en la '
              'hierba, un objeto extraño que nadie toca',
          lines: [
            ComicLine(
              _nuss,
              'No todo lo que pone en internet es verdad. Mejor pregunta a '
              'los adultos o escucha las noticias en la radio.',
            ),
            ComicLine(
              _mila,
              'Y si fuera encuentro algo raro, no lo toco y se lo digo a un '
              'adulto.',
            ),
          ],
        ),
        ComicPanel(
          image: 'krieg-5',
          wide: true,
          description: 'Mila, Papá y Nuss, contentos, bajo el gran árbol',
          lines: [
            ComicLine(
              _mila,
              'Ahora sé lo que puedo hacer. Así me siento mucho mejor.',
            ),
            ComicLine(
              _nuss,
              '¿Ves? Quien está preparado tiene menos miedo.',
            ),
          ],
        ),
      ],
    ),
  ],
  parentsIntro:
      'El cómic está pensado para leerlo juntos a partir de unos cinco '
      'años. Basta con un capítulo por noche. El último capítulo es '
      'tranquilo a propósito. Léalo cuando su hijo o hija pregunte por las '
      'noticias, no como primer capítulo.',
  parentsTips: [
    'Responder a las preguntas con sinceridad y brevedad. Los niños no '
        'necesitan detalles, pero notan cuando se les oculta algo.',
    'Preparar juntos la mochila de emergencia. Quien puede hacer algo por '
        'sí mismo se siente menos indefenso.',
    'Practicar juntos el punto de encuentro, la dirección y los números '
        '112 y 110, mejor fuera, delante de la puerta.',
    'Aprovechar el día de prueba de avisos de septiembre para hablar de '
        'las señales de las sirenas.',
    'Probar juntos el detector de humo, para que el pitido sea conocido y '
        'no asuste.',
  ],
  source:
      'Las normas de comportamiento siguen las recomendaciones de la '
      'Oficina Federal de Protección Civil y Asistencia en Catástrofes de '
      'Alemania (BBK) sobre la preparación ante emergencias. Mila, Nuss y '
      'su historia son personajes propios de esta app y no una publicación '
      'de la BBK.',
);

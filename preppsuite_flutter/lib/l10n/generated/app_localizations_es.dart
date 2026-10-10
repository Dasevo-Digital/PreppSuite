// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get airQualityEntryHint =>
      'Partículas, ozono y dióxido de nitrógeno en una estación cercana.';

  @override
  String get airQualityTitle => 'Calidad del aire';

  @override
  String get airQualityNoneChosen => 'Aún no has elegido ninguna estación';

  @override
  String get airQualityChoose => 'Elegir una estación';

  @override
  String get airQualityChange => 'Otra estación';

  @override
  String get airQualityRefresh => 'Recargar';

  @override
  String get airQualitySearchHint => 'Lugar, estación o estado federado';

  @override
  String get airQualitySearchEmpty => 'No se ha encontrado ninguna estación.';

  @override
  String get airQualityLoadFailed =>
      'Ahora mismo no se puede acceder a las mediciones.';

  @override
  String get airQualityOffline =>
      'Última medición guardada: la consulta acaba de fallar.';

  @override
  String get airQualityStale =>
      'Esta medición tiene más de tres horas. La estación no está informando en este momento.';

  @override
  String get airQualityIncomplete =>
      'No todos los contaminantes que mide esta estación se han comunicado en esta hora. La clase se basa en los que sí.';

  @override
  String get airQualityComponents => 'Contaminantes por separado';

  @override
  String airQualityLeading(String code, String value, String unit) {
    return 'Determinante: $code con $value $unit';
  }

  @override
  String airQualitySpan(String min, String max) {
    return 'de $min a $max';
  }

  @override
  String airQualityMeasuredAt(String when) {
    return 'Medido el $when';
  }

  @override
  String get airQualityVeryGood => 'Muy buena';

  @override
  String get airQualityGood => 'Buena';

  @override
  String get airQualityModerate => 'Moderada';

  @override
  String get airQualityPoor => 'Mala';

  @override
  String get airQualityVeryPoor => 'Muy mala';

  @override
  String get airQualityUnknown => 'Sin clase';

  @override
  String get airQualityNoWarning =>
      'Esto es una medición, no un aviso. Si de verdad se avisa de algo, el aviso llega por la lista de avisos de esta app.';

  @override
  String get airQualityAdvice =>
      'Lo que la UBA recomienda en cada clase lo publica la propia UBA. Esta app no da consejos de salud propios.';

  @override
  String get airQualitySource =>
      'Fuente: índice de calidad del aire de la Agencia Federal de Medio Ambiente (Umweltbundesamt, UBA). La clasificación y los umbrales son de la UBA.';

  @override
  String get roadClosureTitle => 'Cortes en autopistas';

  @override
  String get roadClosureEntryHint =>
      'Lo que está cerrado en las autopistas que sigues.';

  @override
  String get roadClosureNoneChosen => 'Aún no has elegido ninguna autopista';

  @override
  String get roadClosureWhy =>
      'Cuando hay que abandonar una región, «qué camino está abierto» es una pregunta más concreta que cualquier lista de control. El servicio responde por carretera, así que las carreteras importantes se nombran una sola vez.';

  @override
  String get roadClosureChoose => 'Elegir autopistas';

  @override
  String get roadClosureChange => 'Cambiar la selección';

  @override
  String get roadClosureDone => 'Listo';

  @override
  String get roadClosureRefresh => 'Recargar';

  @override
  String get roadClosureLoadFailed =>
      'Ahora mismo no se puede acceder a los avisos de tráfico.';

  @override
  String get roadClosureNow => 'Ahora';

  @override
  String get roadClosureNothingNow => 'Ningún corte ni aviso en este momento.';

  @override
  String get roadClosureLater => 'Anunciado';

  @override
  String get roadClosureBlocked => 'Cortado';

  @override
  String roadClosureFrom(String when) {
    return 'Desde $when';
  }

  @override
  String get roadClosureSource =>
      'Fuente: datos abiertos de tráfico de Autobahn GmbH des Bundes. No se enumeran las obras que no cortan nada.';

  @override
  String get appTitle => 'PreppSuite';

  @override
  String get householdNameLabel => 'Nombre del hogar';

  @override
  String get countryLabel => 'País';

  @override
  String get regionKeyLabel => 'Clave regional (opcional)';

  @override
  String get regionKeyHelper => 'Solo en Alemania, para avisos más precisos';

  @override
  String get createButton => 'Crear';

  @override
  String get fieldRequired => 'Este campo es obligatorio.';

  @override
  String get errorGeneric =>
      'Se ha producido un error inesperado. Inténtalo de nuevo.';

  @override
  String get errorNoConnection =>
      'Sin conexión. Comprueba la red e inténtalo de nuevo.';

  @override
  String get errorArchiveUnreadable =>
      'No se ha podido leer el archivo. Puede que se haya movido o que el disco en el que está no esté conectado.';

  @override
  String get errorFileUnreadable => 'No se ha podido acceder al archivo.';

  @override
  String get errorDownloadFailed =>
      'La descarga se ha detenido. Si la vuelves a iniciar, continúa donde se quedó.';

  @override
  String get errorServiceUnavailable =>
      'El servicio no ha respondido. No es culpa tuya: inténtalo más tarde.';

  @override
  String get errorDatabase =>
      'La base de datos de la app ha informado de un problema. Reiniciar suele solucionarlo.';

  @override
  String get errorDiskFull =>
      'El disco está lleno. Libera algo de espacio e inténtalo de nuevo.';

  @override
  String get errorLocalDataLocked =>
      'Los datos locales están bloqueados. Reinicia la app y lee el aviso de la primera pantalla.';

  @override
  String get errorLocalDataBusy =>
      'Las bases de datos se están cifrando. Espera a que termine.';

  @override
  String get errorPlatformRefused =>
      'El sistema lo ha denegado. Comprueba en los ajustes si PreppSuite tiene permiso para ello.';

  @override
  String get navInventory => 'Provisiones';

  @override
  String get navHousehold => 'Hogar';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navShelters => 'Refugios';

  @override
  String get inventoryTitle => 'Provisiones';

  @override
  String get inventoryEmpty =>
      'Aún no hay artículos. Toca + para añadir el primero.';

  @override
  String get addItemButton => 'Añadir artículo';

  @override
  String get editItemTitle => 'Editar artículo';

  @override
  String get addItemTitle => 'Añadir artículo';

  @override
  String get itemNameLabel => 'Nombre';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get categoryWater => 'Agua';

  @override
  String get categoryFood => 'Alimentos';

  @override
  String get categoryMedical => 'Medicinas';

  @override
  String get categoryTools => 'Herramientas';

  @override
  String get categoryDocuments => 'Documentos';

  @override
  String get categoryEnergy => 'Energía';

  @override
  String get categoryHygiene => 'Higiene';

  @override
  String get categoryOther => 'Otros';

  @override
  String get quantityLabel => 'Cantidad';

  @override
  String get unitLabel => 'Unidad';

  @override
  String get storageLocationLabel => 'Lugar de almacenamiento';

  @override
  String get expirationDateLabel => 'Fecha de caducidad (opcional)';

  @override
  String get minQuantityLabel => 'Cantidad mínima (opcional)';

  @override
  String caloriesTotalHint(Object total) {
    return 'Suma $total kcal en existencias.';
  }

  @override
  String supplyCalculatorDaysLabel(int days) {
    return 'Provisiones para $days días';
  }

  @override
  String get supplyCalculatorWaterLabel => 'Agua potable';

  @override
  String get supplyCalculatorCaloriesLabel => 'Calorías';

  @override
  String supplyCalculatorProgress(String current, String target, String unit) {
    return '$current / $target $unit';
  }

  @override
  String get notesLabel => 'Notas (opcional)';

  @override
  String get saveButton => 'Guardar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get lowStockBadge => 'Pocas existencias';

  @override
  String get expiredBadge => 'Caducado';

  @override
  String get invalidNumber => 'Introduce un número válido.';

  @override
  String get clearDateButton => 'Borrar fecha';

  @override
  String get scanBarcodeButton => 'Escanear código de barras';

  @override
  String get scannerHint => 'Mantén el código de barras a la vista';

  @override
  String get scannerTorchOn => 'Encender la luz';

  @override
  String get scannerTorchOff => 'Apagar la luz';

  @override
  String scannedBarcodeLabel(String barcode) {
    return 'Código de barras: $barcode';
  }

  @override
  String get productNotFound =>
      'Producto no encontrado: rellena los datos a mano.';

  @override
  String get itemPhotoLabel => 'Foto';

  @override
  String get addPhotoButton => 'Añadir foto';

  @override
  String get takePhotoButton => 'Hacer foto';

  @override
  String get chooseFromGalleryButton => 'Elegir de la galería';

  @override
  String get removePhotoButton => 'Quitar foto';

  @override
  String get csvImportButton => 'Importar CSV';

  @override
  String get csvImportTitle => 'Importar CSV';

  @override
  String get csvImportInstructionsTitle => 'Formato esperado';

  @override
  String get csvImportInstructionsBody =>
      'La primera fila debe ser una fila de encabezado. Columnas obligatorias: name, category, quantity, unit, storageLocation. Columnas opcionales: expirationDate, minQuantity, notes. También se reconocen los nombres de columna en alemán (Name, Kategorie, Menge, Einheit, Lagerort, Ablaufdatum, Mindestbestand, Notizen).\n\nCategoría: water, food, medical, tools, documents, energy, hygiene u other (también valen los nombres en alemán, p. ej. Wasser, Lebensmittel).\nFechas: AAAA-MM-DD o DD.MM.AAAA.\nNúmeros: \".\" o \",\" como separador decimal.\nDelimitador: \",\" o \";\", se detecta automáticamente.';

  @override
  String get csvImportPickFileButton => 'Elegir archivo CSV…';

  @override
  String get csvImportChangeFileButton => 'Elegir otro archivo…';

  @override
  String get csvImportParsing => 'Leyendo el archivo…';

  @override
  String csvImportSummary(int valid, int total) {
    return 'Se pueden importar $valid de $total filas.';
  }

  @override
  String csvImportRowError(int row, String reason) {
    return 'Fila $row: $reason';
  }

  @override
  String get csvImportReasonMissingColumns =>
      'Faltan columnas obligatorias (nombre, categoría, cantidad, unidad, lugar de almacenamiento).';

  @override
  String get csvImportReasonNameMissing => 'Falta el nombre.';

  @override
  String csvImportReasonUnknownCategory(String value) {
    return 'Categoría desconocida \"$value\".';
  }

  @override
  String csvImportReasonInvalidQuantity(String value) {
    return 'Cantidad no válida \"$value\".';
  }

  @override
  String get csvImportReasonUnitMissing => 'Falta la unidad.';

  @override
  String get csvImportReasonStorageLocationMissing =>
      'Falta el lugar de almacenamiento.';

  @override
  String csvImportReasonInvalidDate(String value) {
    return 'Fecha no válida \"$value\".';
  }

  @override
  String csvImportReasonInvalidMinQuantity(String value) {
    return 'Cantidad mínima no válida \"$value\".';
  }

  @override
  String csvImportImportButton(int count) {
    return 'Importar $count filas';
  }

  @override
  String csvImportSuccessMessage(int count) {
    return '$count artículos importados.';
  }

  @override
  String get csvImportNoValidRows =>
      'No se han encontrado filas válidas en este archivo.';

  @override
  String csvImportFileReadError(String error) {
    return 'No se ha podido leer este archivo: $error';
  }

  @override
  String csvImportRowLabel(int row) {
    return 'Fila $row';
  }

  @override
  String get csvImportEditRowTooltip => 'Editar';

  @override
  String get csvImportRemoveRowTooltip => 'Quitar de la importación';

  @override
  String get csvImportEditRowTitle => 'Editar fila';

  @override
  String get cameraDeniedTitle => 'Cámara no permitida';

  @override
  String get cameraDeniedBody =>
      'PreppSuite no tiene permiso para usar la cámara. Permítelo en los ajustes del sistema y vuelve a abrir esta pantalla.';

  @override
  String get cameraUnsupportedTitle => 'Sin cámara';

  @override
  String get cameraUnsupportedBody =>
      'Este dispositivo no puede escanear con una cámara.';

  @override
  String get cameraFailedTitle => 'La cámara no ha arrancado';

  @override
  String get cameraFailedBody => 'El visor no ha querido iniciarse.';

  @override
  String get cameraAlternativeBarcode =>
      'Sin cámara, a mano: vuelve atrás y escribe tú mismo el nombre, la cantidad y la unidad.';

  @override
  String get cameraAlternativeTransfer =>
      'Sin cámara, un hogar se traslada a través de la carpeta compartida o de un archivo.';

  @override
  String get hazardReleaseTitle => 'Sustancias peligrosas en el aire';

  @override
  String get hazardReleaseEntryHint =>
      'Qué hacer cuando se ha liberado algo: en casa, al aire libre, en el coche.';

  @override
  String get hazardReleaseIntro =>
      'Cuando un aviso dice que se han liberado sustancias peligrosas, los primeros minutos son decisivos. Lo que sigue son las instrucciones de la Oficina Federal de Protección Civil y Asistencia en Catástrofes de Alemania (BBK), reproducidas y no interpretadas.';

  @override
  String get hazardReleaseHomeTitle => 'Si estás en casa';

  @override
  String get hazardReleaseHomeStay =>
      'Quédate en el edificio. Acoge a los transeúntes que estén en peligro y avisa a los demás vecinos.';

  @override
  String get hazardReleaseHomeWindows => 'Cierra ventanas y puertas.';

  @override
  String get hazardReleaseHomeVent =>
      'Apaga ventiladores y aire acondicionado, cierra las rejillas de ventilación de las ventanas.';

  @override
  String get hazardReleaseHomeRoom =>
      'Ve a una habitación interior protegida, mejor una sin ventana al exterior.';

  @override
  String get hazardReleaseHomeCandles =>
      'Nada de velas ni nada parecido: consumen oxígeno inútilmente.';

  @override
  String get hazardReleaseHomeRadio =>
      'Enciende la radio, FM y la emisora regional, o la televisión. Sigue los anuncios de las autoridades y de los servicios de emergencia.';

  @override
  String get hazardReleaseHomePhone =>
      'Usa el teléfono solo en caso de emergencia.';

  @override
  String get hazardReleaseHomeMask =>
      'Si la sustancia entra: usa la protección respiratoria que tengas e improvisa una mascarilla si hace falta.';

  @override
  String get hazardReleaseHomeWait =>
      'Espera al fin de la alerta antes de salir del edificio o abrir una ventana.';

  @override
  String get hazardReleaseOutsideTitle => 'Si estás al aire libre';

  @override
  String get hazardReleaseOutsideCross =>
      'Muévete en perpendicular al viento, ni a favor ni en contra. Respira a través de una protección, de un pañuelo si no hay otra cosa.';

  @override
  String get hazardReleaseOutsideBuilding =>
      'Ve al edificio cerrado más cercano y pide que te dejen entrar.';

  @override
  String get hazardReleaseOutsideClothes =>
      'Tras el contacto, cámbiate la ropa exterior y el calzado al entrar, guárdalos en una bolsa de plástico y déjalos fuera de la zona de vivienda, delante del edificio si es posible.';

  @override
  String get hazardReleaseOutsideWash =>
      'Lávate en este orden: primero bien las manos, luego la cara y el pelo, después la nariz y las orejas, con agua y jabón.';

  @override
  String get hazardReleaseOutsideBio =>
      'Con sustancias biológicas, desinfecta también las manos.';

  @override
  String get hazardReleaseCarTitle => 'Si estás en el coche';

  @override
  String get hazardReleaseCarVent =>
      'Apaga la ventilación y cierra las ventanillas.';

  @override
  String get hazardReleaseCarRadio =>
      'Escucha la radio, FM y la emisora regional, y sigue las indicaciones.';

  @override
  String get hazardReleaseCarBuilding =>
      'Ve al edificio cerrado más cercano, salvo que las autoridades digan otra cosa.';

  @override
  String get hazardReleaseCellarTitle =>
      '¿Sótano o piso superior? Depende de la sustancia';

  @override
  String get hazardReleaseCellarChemical =>
      'Con sustancias químicas, evita el sótano. La mayoría de los gases y vapores pesan más que el aire y se acumulan en hondonadas y sótanos.';

  @override
  String get hazardReleaseCellarRadio =>
      'Con material radiactivo es al revés: mejor una habitación del sótano. La radiación ionizante se atenúa al atravesar la materia, y en un sótano la atenuación por la tierra circundante y los pisos de encima es especialmente grande.';

  @override
  String get hazardReleaseCellarNote =>
      'No es una contradicción, sino la misma idea dos veces: el gas baja, la radiación se frena con la masa. De qué caso se trata, lo dice el aviso.';

  @override
  String get hazardReleaseIodineLink =>
      'Yodo radiactivo: para qué sirven las pastillas de yodo';

  @override
  String get hazardReleaseSource =>
      'Fuente: Oficina Federal de Protección Civil y Asistencia en Catástrofes (BBK), \"Handeln bei Gefahrstoff-Freisetzung\".';

  @override
  String get iodineTitle => 'Pastillas de yodo';

  @override
  String get iodineEntryHint =>
      'Quién las toma, cuándo y por qué solo cuando se indica.';

  @override
  String get iodineIntro =>
      'Un accidente nuclear puede liberar yodo radiactivo. Se acumula en la tiroides y puede causar cáncer en ella más adelante. Una pastilla de yodo de dosis alta satura antes la tiroides con yodo no radiactivo, para que no absorba más. Esto se llama bloqueo tiroideo.';

  @override
  String get iodineOnlyOnOrderTitle => 'Solo cuando se indique expresamente';

  @override
  String get iodineOnlyOnOrderBody =>
      'Las pastillas de yodo de dosis alta solo deben tomarse cuando las autoridades de protección civil lo pidan expresamente, y solo en la dosis que indiquen. La BfS desaconseja firmemente tomarlas por iniciativa propia, porque los efectos secundarios pueden llegar a un fallo cardiovascular agudo.';

  @override
  String get iodineOnlyThyroidTitle => 'Protegen la tiroides y nada más';

  @override
  String get iodineOnlyThyroidBody =>
      'Y solo frente al yodo radiactivo. Contra cualquier otra sustancia radiactiva no sirven. Haber tomado una no es protección y no sustituye seguir las instrucciones.';

  @override
  String get iodineWhoTitle => 'Quién';

  @override
  String get iodineWhoUnder45 =>
      'Todas las personas hasta los 45 años, en las zonas afectadas. La dosis depende de la edad y la indican las autoridades.';

  @override
  String get iodineWhoChildren =>
      'Especialmente importante para niños y adolescentes hasta los 18: su tiroides es especialmente sensible.';

  @override
  String get iodineWhoPregnant =>
      'También las embarazadas, ante todo para proteger al feto.';

  @override
  String get iodineWhoOver45 =>
      'A partir de los 45 se desaconseja. Ahí el riesgo de efectos secundarios supera al cáncer de tiroides evitado.';

  @override
  String get iodineWhoThyroid =>
      'Quien tenga una enfermedad de tiroides solo las toma tras consultar con su médico.';

  @override
  String get iodineWhenTitle => 'Cuándo';

  @override
  String get iodineWhenBody =>
      'El momento decide si funcionan. Lo ideal es aproximadamente una hora antes del contacto con el aire que lleva el yodo radiactivo. Si se toman demasiado pronto, el yodo ya se ha eliminado; si se toman demasiado tarde, la tiroides ya ha absorbido el radiactivo. Las autoridades de protección civil anuncian el momento a través de los medios.';

  @override
  String get iodineHowOftenTitle => 'Con qué frecuencia';

  @override
  String get iodineHowOftenBody =>
      'En general basta con una vez. Otra pastilla solo si la autoridad lo recomienda.';

  @override
  String get iodineWhereTitle => 'De dónde';

  @override
  String get iodineWhereBody =>
      'Son competencia de los estados federados. Alrededor de las centrales nucleares, las pastillas se reparten de antemano a los hogares o se guardan en el lugar, en ayuntamientos y parques de bomberos. Además, hay más de 180 millones de pastillas almacenadas en todo el país; en caso de incidente se reparten en parques de bomberos, ayuntamientos, farmacias o colegios electorales conocidos, tras un llamamiento en los medios.';

  @override
  String get iodineRangeTitle => 'Hasta dónde';

  @override
  String get iodineRangeBody =>
      'En un accidente con una liberación considerable, se puede recomendar tomarlas a adultos hasta 100 kilómetros de distancia, y a niños en toda Alemania.';

  @override
  String get iodineHazardLink =>
      'Qué más hacer: sustancias peligrosas en el aire';

  @override
  String get iodineSource =>
      'Fuente: Oficina Federal de Protección Radiológica (BfS), \"Einnahme und Wirkung von Jodtabletten\".';

  @override
  String get burglaryTitle => 'Robo en vivienda';

  @override
  String get burglaryEntryHint =>
      'Sorprender a alguien, lo que viene después y cómo prevenirlo.';

  @override
  String get burglaryRuleTitle => 'La regla que va primero';

  @override
  String get burglaryRuleBody =>
      'No te pongas en peligro ni a ti ni a nadie. Evita cualquier enfrentamiento en lo posible y en ningún caso te cruces en el camino del ladrón.';

  @override
  String get burglaryCaughtTitle => 'Si sorprendes a alguien';

  @override
  String get burglaryCaughtLeave =>
      'Intenta salir del piso o de la casa y avisa a los vecinos.';

  @override
  String get burglaryCaughtWindow =>
      'Si no puedes salir: abre una ventana si puedes y pide ayuda a gritos.';

  @override
  String get burglaryCaughtCall => 'Llama enseguida al 110.';

  @override
  String get burglaryCaughtDescribe =>
      'Da a la policía la mejor descripción que puedas: la persona, un posible vehículo de huida y la dirección en que se fueron.';

  @override
  String get burglaryAfterTitle => 'Después';

  @override
  String get burglaryAfterThreat =>
      'Llama al 110 si estás en peligro inmediato.';

  @override
  String get burglaryAfterReport =>
      'Denúncialo en cualquier comisaría. También si el intento fracasó o no se llevaron nada.';

  @override
  String get burglaryAfterNoTidy =>
      'No ordenes. Deja todo como lo encontraste y toca lo menos posible hasta que se hayan recogido las huellas.';

  @override
  String get burglaryAfterList =>
      'Haz una lista de lo que se han llevado, lo más precisa posible. Los tiques y números de serie ayudan si algo vuelve a aparecer.';

  @override
  String get burglaryAfterKeys =>
      'Si faltan llaves: haz cambiar los bombines de las cerraduras por precaución.';

  @override
  String get burglaryAfterPhone =>
      'Haz bloquear las tarjetas y los teléfonos robados a través de la línea alemana de bloqueo 116 116.';

  @override
  String get burglaryPossessionsLink =>
      'La lista de objetos de valor a la que se refiere la policía ya la tienes';

  @override
  String get burglaryPossessionsHint =>
      'El inventario del hogar de esta app es justo eso: rellenado antes de que pase algo, es la lista que te pedirán después.';

  @override
  String get burglaryPreventTitle => 'Prevención';

  @override
  String get burglaryPreventWho =>
      'La mayoría de los robos no son obra de profesionales, sino de oportunistas que atacan ventanas y puertas con herramientas sencillas para hacer palanca. La entrada suele ser una ventana de fácil acceso, o una puerta de ventana o de piso.';

  @override
  String get burglaryPreventDay =>
      'Al contrario de lo que se cree, los robos suelen producirse de día: en horario escolar, laboral y de compras, al atardecer y los fines de semana. Más de un tercio de todos los robos en viviendas ocurren de día.';

  @override
  String get burglaryPreventMechanical =>
      'La policía recomienda asegurar mecánicamente todas las ventanas y puertas. La tecnología no disuade de lo que deja entrar.';

  @override
  String get burglaryPreventNew =>
      'En obra nueva y reformas: ventanas y puertas antirrobo certificadas según DIN EN 1627 y siguientes, a partir de la clase de resistencia RC 2. Allí está comprobado que hoja, cerco, cerradura y herrajes juntos no dejan ningún punto débil.';

  @override
  String get burglaryPreventRetro =>
      'Para reformar lo existente: sistemas según DIN 18104 partes 1 y 2. Las piezas deben estar adaptadas entre sí en su efecto.';

  @override
  String get burglaryPreventSide =>
      'Las puertas laterales pueden reforzarse con cerrojos macizos, barras resistentes o una cerradura de barra transversal.';

  @override
  String get burglaryPreventFit =>
      'La protección instalada solo funciona si está bien instalada. Y la tecnología no sustituye lo segundo que nombra la policía: un comportamiento consciente de la seguridad y un vecindario atento.';

  @override
  String get burglarySource =>
      'Fuente: la prevención policial del crimen de los estados federados y la federación alemanes (polizei-beratung.de) y la campaña K-EINBRUCH. Cifras de la estadística policial de criminalidad de 2025.';

  @override
  String get supplyGroupsTitle => 'Grupos de provisiones';

  @override
  String get supplyGroupsEntryHint =>
      '¿Cubren las provisiones todos los grupos, no solo las calorías?';

  @override
  String get supplyGroupsIntro =>
      'Diez días de calorías pueden ser diez días de pasta. La Oficina Federal de Agricultura y Alimentación de Alemania indica, en su calculadora de provisiones, una cantidad por persona y día para cada grupo de alimentos. Esto es lo que tienes al lado.';

  @override
  String get supplyGroupsPersonsNote =>
      'Contado por persona y día, sin distinguir por edad: así funciona la tabla de la BLE. El agua potable es distinta: allí su nota a pie de página menciona a los niños por separado, y la calculadora de provisiones sigue esa nota.';

  @override
  String get supplyGroupGrain => 'Cereales, pan, patatas';

  @override
  String get supplyGroupVegetables => 'Verduras, setas';

  @override
  String get supplyGroupFruit => 'Fruta';

  @override
  String get supplyGroupDrinks => 'Bebidas';

  @override
  String get supplyGroupDairy => 'Leche y lácteos';

  @override
  String get supplyGroupProtein => 'Huevos, carne, embutido y pescado';

  @override
  String get supplyGroupFats => 'Grasas y aceite';

  @override
  String get supplyGroupNone => 'En ningún grupo';

  @override
  String get supplyGroupLabel => 'Grupo de provisiones';

  @override
  String get supplyGroupHelper =>
      'Solo alimentos y agua. Sin grupo, el artículo no cuenta en ninguno.';

  @override
  String get supplyGroupsUnassignedTitle => 'Sin grupo';

  @override
  String get supplyGroupsUnassignedBody =>
      'Estos artículos no cuentan en ningún grupo de arriba. La app no los asigna por su cuenta: \"condimento para gratinado de pasta\" no es un cereal, y adivinar aquí fallaría demasiadas veces.';

  @override
  String get supplyGroupsUnmeasuredTitle => 'Grupo sí, cantidad no';

  @override
  String get supplyGroupsUnmeasuredBody =>
      'Estos tienen grupo, pero su unidad no se puede reducir a gramos o mililitros, o no encaja con el grupo. También faltan en las cifras de arriba.';

  @override
  String get supplyGroupsAllAssigned =>
      'Todos los alimentos y el agua están en un grupo.';

  @override
  String get supplyGroupsSource =>
      'Fuente: la calculadora de provisiones de la Oficina Federal de Agricultura y Alimentación de Alemania (BLE), cantidades por persona y día con 2200 kcal.';

  @override
  String supplyGroupsShare(String have, String target) {
    return '$have de $target';
  }

  @override
  String get recipeIngredientsTitle => 'Ingredientes';

  @override
  String recipeInStock(String names) {
    return 'En las provisiones: $names';
  }

  @override
  String get recipeNotInStock => 'No encontrado en las provisiones';

  @override
  String get recipeOnlyCookable =>
      'Mostrar solo aquello para lo que las provisiones tienen las palabras';

  @override
  String get recipeMatchNote =>
      'Se comparan nombres, no contenidos: la app ve que \"garbanzos\" aparece en tus provisiones, pero no si la lata sigue llena ni si la cantidad basta. Un ingrediente genérico cuenta todo lo que hayas asignado al grupo de alimentos correspondiente.';

  @override
  String get recipeNoneCookable =>
      'Ninguna receta tiene todos sus ingredientes nombrados en las provisiones.';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get navChecklists => 'Listas';

  @override
  String get checklistsTitle => 'Listas de control';

  @override
  String get checklistKindPreparation => 'Preparación';

  @override
  String get checklistKindResponse => 'Cuando ocurre';

  @override
  String get checklistKindPreparationIntro =>
      'Lo que tiene que estar listo antes de que pase algo.';

  @override
  String get checklistKindResponseIntro => 'Qué hacer mientras está pasando.';

  @override
  String get checklistKindLabel => 'Tipo de lista';

  @override
  String get checklistKindEmpty => 'Aún no hay nada en esta parte.';

  @override
  String get checklistsEmpty =>
      'Aún no hay listas de control. Toca + para crear la primera.';

  @override
  String get createTemplateButton => 'Nueva lista';

  @override
  String get createTemplateTitle => 'Nueva lista';

  @override
  String get templateTitleLabel => 'Nombre de la lista';

  @override
  String get checklistCategoryFirstAid => 'Primeros auxilios';

  @override
  String get checklistCategoryCustom => 'Propia';

  @override
  String get builtInBadge => 'Incluida';

  @override
  String get duplicateTemplateAction => 'Duplicar';

  @override
  String get deleteTemplateAction => 'Eliminar lista';

  @override
  String get addChecklistItemHint => 'Añadir un punto…';

  @override
  String get addButton => 'Añadir';

  @override
  String checklistProgress(int checked, int total) {
    return '$checked de $total';
  }

  @override
  String get budgetTitle => 'Presupuesto';

  @override
  String get budgetEmpty =>
      'Aún no hay gastos registrados. Toca + para añadir la primera entrada.';

  @override
  String get addBudgetEntryButton => 'Añadir entrada';

  @override
  String get addBudgetEntryTitle => 'Añadir entrada';

  @override
  String get editBudgetEntryTitle => 'Editar entrada';

  @override
  String get budgetLabelLabel => 'Concepto';

  @override
  String get amountLabel => 'Importe';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get purchaseDateLabel => 'Fecha de compra (opcional)';

  @override
  String get budgetTotalLabel => 'Total';

  @override
  String get warningsTitle => 'Avisos';

  @override
  String get warningsEmpty => 'Ahora mismo no hay avisos para tu región.';

  @override
  String get warningsNinaHintTitle => 'Avisos con la app cerrada';

  @override
  String get warningsNinaHintBody =>
      'PreppSuite consulta los canales oficiales de avisos cada 15 minutos y los muestra como resumen. Para alertas inmediatas que te lleguen con la app cerrada, usa NINA, de la Oficina Federal de Protección Civil de Alemania: la misma fuente oficial, en segundos en lugar de minutos.';

  @override
  String get warningDayToday => 'Hoy es el día nacional de avisos';

  @override
  String warningDayIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'dentro de $days días',
      one: 'dentro de un día',
    );
    return 'Día nacional de avisos $_temp0';
  }

  @override
  String get warningDayBody =>
      'Aviso de prueba a las 11:00, fin de la alerta a las 11:45. Se prueban a la vez las sirenas, el Cell Broadcast, la radio y las apps de avisos. Es el único día del año en que puedes comprobar si lo que debería llegarte llega de verdad; un aviso que nunca llega pasa desapercibido el resto del tiempo.';

  @override
  String get warningDayNotificationTitle => 'Hoy es el día nacional de avisos';

  @override
  String get warningDayNotificationBody =>
      'El aviso de prueba sale a las 11:00 y el fin de la alerta a las 11:45. Un buen momento para comprobar que te llegan las sirenas, el Cell Broadcast y las apps de avisos.';

  @override
  String get pegelTitle => 'Niveles de agua';

  @override
  String get pegelEntryHint =>
      'El nivel de tu propio río, con los valores de referencia del aforo';

  @override
  String get pegelNoneChosen => 'Aún no has elegido ningún aforo.';

  @override
  String get pegelUpstreamHint =>
      'Elige el aforo que está río arriba de ti. El más cercano no sirve si está río abajo: muestra lo que ya ha pasado, no lo que viene.';

  @override
  String get pegelChoose => 'Elegir un aforo';

  @override
  String get pegelChange => 'Elegir otro aforo';

  @override
  String get pegelSearchHint => 'Buscar un aforo o una vía navegable';

  @override
  String get pegelSearchEmpty => 'No se ha encontrado ningún aforo.';

  @override
  String get pegelLoadFailed =>
      'No se ha podido cargar la lista de aforos. Necesita conexión una vez.';

  @override
  String get pegelOffline => 'Sin conexión: este es el último valor obtenido.';

  @override
  String get pegelStale =>
      'Tiene más de una hora. Los aforos interiores informan cada 15 minutos, así que lo que falta es la conexión y no el agua.';

  @override
  String pegelMeasuredAt(String time) {
    return 'Medido $time';
  }

  @override
  String get pegelRefresh => 'Actualizar';

  @override
  String pegelKilometre(String km) {
    return 'Kilómetro del río $km';
  }

  @override
  String get pegelReferences => 'Valores de referencia de este aforo';

  @override
  String get pegelNoReferences =>
      'Para este aforo no se publican valores de referencia, así que la cifra queda sin escala.';

  @override
  String get pegelNoMeldestufe =>
      'Sin nivel de alerta: los fijan los estados federados y no están en estos datos. Los avisos oficiales de inundación están en la lista de avisos.';

  @override
  String get pegelSource =>
      'Fuente: PEGELONLINE, gestionado por la administración alemana de vías navegables. Solo vías navegables federales: el arroyo que inunda un pueblo no está aquí.';

  @override
  String get pegelBandRecordLow => 'Más bajo que nunca medido';

  @override
  String get pegelBandLow => 'Aguas bajas';

  @override
  String get pegelBandOrdinary => 'Dentro del rango habitual';

  @override
  String get pegelBandElevated => 'Por encima de la media';

  @override
  String get pegelBandFlood => 'Crecida';

  @override
  String get pegelBandRecordHigh => 'Más alto que nunca medido';

  @override
  String get pegelBandUnknown => 'No se puede situar';

  @override
  String pegelTrendRising(String change) {
    return 'Subiendo, $change cm en 24 horas';
  }

  @override
  String pegelTrendFalling(String change) {
    return 'Bajando, $change cm en 24 horas';
  }

  @override
  String get pegelTrendSteady => 'Apenas ha cambiado en 24 horas';

  @override
  String get pegelTrendUnknown => 'Historial no disponible';

  @override
  String get pegelRefMean => 'Nivel medio';

  @override
  String get pegelRefMeanFlood => 'Nivel medio de crecida';

  @override
  String get pegelRefHighest => 'Nivel máximo medido';

  @override
  String get pegelRefMeanLow => 'Nivel medio de estiaje';

  @override
  String get pegelRefLowest => 'Nivel mínimo medido';

  @override
  String get warningSeverityMinor => 'Leve';

  @override
  String get warningSeverityModerate => 'Moderado';

  @override
  String get warningSeveritySevere => 'Grave';

  @override
  String get warningSeverityExtreme => 'Extremo';

  @override
  String warningBannerMore(int count) {
    return '+$count más';
  }

  @override
  String get warningExpiredLabel => 'Caducado';

  @override
  String get warningSourceBbk =>
      'Oficina Federal de Protección Civil de Alemania (BBK)';

  @override
  String get warningSourceMeteoalarm => 'MeteoAlarm';

  @override
  String get exportPdfButton => 'Exportar equipamiento que falta';

  @override
  String get pdfReportTitle => 'Informe de equipamiento que falta';

  @override
  String pdfGeneratedOn(String date) {
    return 'Generado el $date';
  }

  @override
  String get pdfChecklistSectionTitle => 'Puntos de listas pendientes';

  @override
  String get pdfNoMissingChecklistItems =>
      'Nada pendiente: todas las listas están completas.';

  @override
  String get pdfInventorySectionTitle => 'Provisiones con pocas existencias';

  @override
  String get pdfNoLowStockItems => 'Nada por debajo de su cantidad mínima.';

  @override
  String get pdfColumnItem => 'Artículo';

  @override
  String get pdfColumnQuantity => 'Cantidad';

  @override
  String get pdfColumnMinQuantity => 'Mínimo';

  @override
  String get pdfColumnUnit => 'Unidad';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystemOption => 'Sistema';

  @override
  String get languageGermanOption => 'Deutsch';

  @override
  String get languageEnglishOption => 'English';

  @override
  String get languageSpanishOption => 'Español';

  @override
  String inventoryAttentionTooltip(int count) {
    return '$count artículo(s) con pocas existencias o caducados';
  }

  @override
  String get settingsCategoryWarnings => 'Avisos y lugares';

  @override
  String get settingsCategoryWarningsBody =>
      'Notificaciones, lugares vigilados y estado de actualización';

  @override
  String get settingsCategoryReminders => 'Recordatorios';

  @override
  String get settingsCategoryRemindersBody =>
      'Baterías, aparatos y fechas de caducidad';

  @override
  String get settingsCategoryAppearance => 'Apariencia e idioma';

  @override
  String get settingsCategoryAppearanceBody =>
      'Esquema de colores e idioma de la app';

  @override
  String get settingsCrisisModeTitle => 'Modo crisis';

  @override
  String get settingsCrisisModeHint =>
      'Hace más grandes los textos y los controles en toda la app y reduce las animaciones.';

  @override
  String get settingsCategoryData => 'Datos y seguridad';

  @override
  String get settingsCategoryDataBody =>
      'Bloqueo, compartir, copia de seguridad y restablecer';

  @override
  String get settingsCategoryOffline => 'Sin conexión y almacenamiento';

  @override
  String get settingsCategoryOfflineBody =>
      'Mapas, archivos y lugares de almacenamiento';

  @override
  String get settingsCategoryAbout => 'Acerca de PreppSuite';

  @override
  String get settingsCategoryAboutBody =>
      'Versiones de la app y de los módulos locales';

  @override
  String get themeSystemOption => 'Sistema';

  @override
  String get themeLightOption => 'Claro';

  @override
  String get themeDarkOption => 'Oscuro';

  @override
  String get settingsMyRegionTitle => 'Mi región';

  @override
  String get settingsNoRegionSet => 'Ninguna región fijada';

  @override
  String get settingsNoAdditionalRegions =>
      'Aún no has añadido regiones adicionales.';

  @override
  String get settingsAddRegionButton => 'Añadir región';

  @override
  String get settingsAddRegionDialogTitle => 'Añadir región';

  @override
  String get settingsRegionTypeKreis => 'Distrito (Kreis)';

  @override
  String get settingsRegionTypeBundesland => 'Estado federado (Bundesland)';

  @override
  String get settingsKreisSchluesselLabel =>
      'Clave de distrito (Kreisschlüssel, 5 cifras)';

  @override
  String get settingsKreisSchluesselInvalid =>
      'Introduce una clave de distrito de 5 cifras.';

  @override
  String get settingsKreisSchluesselHelper =>
      'Cinco cifras, p. ej. 03241 para la región de Hannover.';

  @override
  String get settingsBundeslandLabel => 'Estado federado';

  @override
  String get settingsBundeslandRequired => 'Elige un estado federado.';

  @override
  String get settingsWarningReadinessTitle => 'Preparación para avisos';

  @override
  String get settingsWarningReadinessBody =>
      'Comprueba la configuración local. El sistema operativo programa las actualizaciones en segundo plano y no las garantiza.';

  @override
  String get settingsWarningReadinessNotifications =>
      'Notificaciones de avisos';

  @override
  String get settingsWarningReadinessRegions => 'Regiones vigiladas';

  @override
  String get settingsWarningReadinessRefresh => 'Última actualización completa';

  @override
  String get settingsWarningReadinessEnabled => 'Activadas';

  @override
  String get settingsWarningReadinessDisabled => 'No activadas';

  @override
  String settingsWarningReadinessRegionsSet(int count) {
    return 'Lugar principal y $count regiones adicionales';
  }

  @override
  String get settingsWarningReadinessRegionsMissing =>
      'Aún no hay lugar principal configurado';

  @override
  String get settingsWarningReadinessNeverUpdated =>
      'Aún no hay ninguna actualización completa';

  @override
  String get settingsWarningReadinessJustNow => 'Actualizado ahora mismo';

  @override
  String settingsWarningReadinessMinutesAgo(int minutes) {
    return 'Actualizado hace $minutes minutos';
  }

  @override
  String settingsWarningReadinessHoursAgo(int hours) {
    return 'Actualizado hace $hours horas';
  }

  @override
  String settingsWarningReadinessDaysAgo(int days) {
    return 'Actualizado hace $days días';
  }

  @override
  String get settingsWarningReadinessBlockedTitle =>
      'Actualización en segundo plano omitida';

  @override
  String get settingsWarningReadinessBlockedBody =>
      'La última actualización programada no pudo abrir los datos locales. Abre la app una vez después de desbloquear el dispositivo.';

  @override
  String get settingsWarningReadinessLaggingTitle => 'Parcialmente inaccesible';

  @override
  String get warningSourceLaggingMeteoAlarm =>
      'Los avisos meteorológicos europeos (MeteoAlarm) no estaban accesibles en la última actualización. Los avisos oficiales de la BBK no se ven afectados.';

  @override
  String get settingsLocalEncryptionTitle => 'Cifrado local';

  @override
  String get settingsLocalEncryptionStateEncrypted => 'Cifrado';

  @override
  String get settingsLocalEncryptionStatePlain => 'Sin cifrar';

  @override
  String settingsLocalEncryptionStatePartial(int count) {
    return '$count bases de datos aún sin cifrar';
  }

  @override
  String get settingsLocalEncryptionStateRecovery => 'Clave no disponible';

  @override
  String get settingsLocalEncryptionUnsupported =>
      'Esta versión no incluye biblioteca de cifrado.';

  @override
  String get settingsLocalEncryptionPortable =>
      'Una carpeta de datos que llevas contigo no se cifra: la clave se quedaría en este ordenador y la carpeta no se abriría en ningún otro.';

  @override
  String get settingsLocalEncryptionNoKeyStore =>
      'Este dispositivo no da acceso a un almacén de claves. En macOS la app necesita una firma para ello, que las versiones actuales aún no tienen. Sin ella, la base de datos, los ajustes personales y las fotos quedan sin cifrar.';

  @override
  String get settingsLocalEncryptionScope =>
      'También se cifran: los ajustes personales y las fotos de provisiones y bienes. No se incluyen: PDF, mapas, archivos ZIM ni nada que exportes.';

  @override
  String get settingsLocalEncryptionTestBackup =>
      'Probar una copia de seguridad';

  @override
  String get settingsLocalEncryptionTestBackupHint =>
      'Vuelve a leer un archivo de copia de seguridad. No se cambia nada.';

  @override
  String settingsLocalEncryptionBackupVerified(int rows) {
    return 'Copia de seguridad leída: $rows registros.';
  }

  @override
  String get settingsLocalEncryptionBackupUnreadable =>
      'Este archivo no se ha podido leer como copia de seguridad de este hogar.';

  @override
  String get settingsLocalEncryptionBackupNever =>
      'Aún no se ha probado ninguna copia de seguridad.';

  @override
  String get settingsLocalEncryptionBackupStale =>
      'La última prueba tiene más de un día.';

  @override
  String get settingsLocalEncryptionStart => 'Cifrar ahora los datos locales';

  @override
  String get settingsLocalEncryptionConfirmTitle => '¿Cifrar ahora?';

  @override
  String get settingsLocalEncryptionConfirmBody =>
      'Se reescriben todas las bases de datos locales. Temporalmente hace falta tanto espacio libre como ocupe la más grande. Mantén el dispositivo con alimentación y la app abierta mientras dura. Después hay que reiniciar PreppSuite.';

  @override
  String get settingsLocalEncryptionRunning =>
      'Cifrando las bases de datos. Deja la app abierta.';

  @override
  String get settingsLocalEncryptionDoneTitle => 'Cifrado terminado';

  @override
  String get settingsLocalEncryptionDoneBody =>
      'Cierra PreppSuite ahora y vuelve a abrirla.';

  @override
  String get settingsLocalEncryptionFailed =>
      'La actualización se ha detenido. Los datos se pueden leer y no han cambiado.';

  @override
  String get localDataRecoveryTitle => 'Datos locales bloqueados';

  @override
  String get localDataRecoveryBody =>
      'Este dispositivo ya no encuentra la clave de sus bases de datos locales. Los archivos siguen ahí, pero sin ella no se pueden leer. El camino de vuelta es una copia de seguridad.';

  @override
  String get localDataRecoveryRetry => 'Volver a intentarlo';

  @override
  String get localDataRecoveryStartOver => 'Configurar de nuevo';

  @override
  String get localDataRecoveryStartOverBody =>
      'Los archivos ilegibles se renombran, no se borran, y se quedan donde están. Después PreppSuite pregunta desde el principio, donde \"Restaurar desde una copia de seguridad\" recupera el hogar con el identificador que tenía.';

  @override
  String get settingsNotificationsToggleLabel => 'Avisarme de nuevos avisos';

  @override
  String get settingsNotificationsToggleHint =>
      'Solo notificaciones locales, mientras la app está en marcha: sin servidor push.';

  @override
  String get settingsUseLocationButton =>
      'Determinar el estado federado por la ubicación';

  @override
  String get settingsLocationNoMatchMessage =>
      'No se ha podido asignar tu ubicación a un estado federado alemán.';

  @override
  String get shelterMapTitle => 'Refugios';

  @override
  String shelterInfoLine(int radius) {
    return 'OpenStreetMap y WWBOTA/DLBOTA cargados en un radio de $radius km.';
  }

  @override
  String shelterInfoLineIdle(int radius) {
    return 'Fuentes: OpenStreetMap y WWBOTA/DLBOTA, en un radio de $radius km.';
  }

  @override
  String get shelterLegendTitle => 'Leyenda de marcadores';

  @override
  String shelterLegendSummary(int green, int yellow, int red) {
    return 'Verde $green · Amarillo $yellow · Rojo $red';
  }

  @override
  String get shelterLegendGreenLabel => 'Verde';

  @override
  String get shelterLegendGreenDescription =>
      'confirmado oficialmente como refugio utilizable';

  @override
  String get shelterLegendYellowLabel => 'Amarillo';

  @override
  String get shelterLegendYellowDescription =>
      'posible refugio, acceso/uso sin confirmar';

  @override
  String get shelterLegendRedLabel => 'Rojo';

  @override
  String get shelterLegendRedDescription =>
      'no habilitado, histórico o solo informativo';

  @override
  String get shelterDisclaimer =>
      'Este mapa no sustituye un aviso oficial, una evacuación ni una instrucción de los servicios de emergencia.';

  @override
  String get shelterNoConfirmedShelters =>
      'En los datos oficiales cargados no se conoce ningún refugio público habilitado actualmente en Alemania. Si eso cambia, aparecerán aquí en verde.';

  @override
  String shelterFilterAll(int count) {
    return 'Todos $count';
  }

  @override
  String shelterFilterCount(String label, int count) {
    return '$label $count';
  }

  @override
  String get shelterSearchHint => 'Código postal o lugar';

  @override
  String get shelterSearchButton => 'Buscar';

  @override
  String get shelterSearchNoResult => 'No se ha encontrado ningún resultado.';

  @override
  String get shelterUseLocationButton => 'Consultar la ubicación actual';

  @override
  String get shelterRefreshButton => 'Actualizar';

  @override
  String get shelterWwbotaErrorMessage =>
      'No se ha podido cargar WWBOTA/DLBOTA.';

  @override
  String get shelterOverpassErrorMessage =>
      'No se ha podido cargar OpenStreetMap/Overpass.';

  @override
  String get shelterEmptyPrompt =>
      'Aún no hay ninguna ubicación cargada. Usa tu ubicación actual o busca un lugar.';

  @override
  String get shelterListHeading => 'Refugios encontrados';

  @override
  String get shelterListEmpty =>
      'Nada en este radio. Prueba con uno mayor o con otro lugar.';

  @override
  String shelterDistanceMeters(int meters, String direction) {
    return '$meters m $direction';
  }

  @override
  String shelterDistanceKilometers(String km, String direction) {
    return '$km km $direction';
  }

  @override
  String shelterListSubtitle(
    String distance,
    String confidence,
    String source,
  ) {
    return '$distance · $confidence · $source';
  }

  @override
  String get shelterDirectionNorth => 'al norte';

  @override
  String get shelterDirectionNorthEast => 'al noreste';

  @override
  String get shelterDirectionEast => 'al este';

  @override
  String get shelterDirectionSouthEast => 'al sureste';

  @override
  String get shelterDirectionSouth => 'al sur';

  @override
  String get shelterDirectionSouthWest => 'al suroeste';

  @override
  String get shelterDirectionWest => 'al oeste';

  @override
  String get shelterDirectionNorthWest => 'al noroeste';

  @override
  String shelterShowOnMap(String name) {
    return 'Mostrar $name en el mapa';
  }

  @override
  String shelterMarkerTooltip(String name, String confidence, String source) {
    return '$name · $confidence · $source';
  }

  @override
  String get shelterAttribution => '© colaboradores de OpenStreetMap';

  @override
  String get expiryReminderTitle => 'Provisión a punto de caducar';

  @override
  String expiryReminderBody(String name, int days) {
    return '$name caduca dentro de $days días.';
  }

  @override
  String expiryReminderBodyTomorrow(String name) {
    return '$name caduca mañana.';
  }

  @override
  String get settingsExpiryRemindersHint =>
      'Un recordatorio antes de que caduque una provisión. Elige con cuántos días de antelación.';

  @override
  String get settingsExpiryRemindersDisabledHint =>
      'Activa las notificaciones arriba para que se puedan programar recordatorios.';

  @override
  String get settingsExpiryRemindersNoneHint =>
      'No hay antelación elegida: no se programará ningún recordatorio.';

  @override
  String get settingsScheduledRemindersUnsupported =>
      'Linux no admite notificaciones programadas.';

  @override
  String get settingsChargeReminderHint =>
      'Te recuerda cargar y probar baterías externas, pilas recargables, linternas y radios de emergencia.';

  @override
  String get settingsChargeReminderDisabledHint =>
      'Activa las notificaciones arriba para programar el recordatorio de carga.';

  @override
  String get settingsChargeReminderNoneHint =>
      'No hay ningún recordatorio de carga programado.';

  @override
  String get settingsChargeReminderCustom => 'Personalizado…';

  @override
  String get settingsChargeReminderCustomTitle => 'Intervalo propio';

  @override
  String get settingsChargeReminderCustomLabel => 'Días entre comprobaciones';

  @override
  String settingsChargeReminderCustomInvalid(int min, int max) {
    return 'Introduce un número entero entre $min y $max.';
  }

  @override
  String get settingsChargeReminderOff => 'Desactivado';

  @override
  String chargeReminderInterval(int days) {
    return 'cada $days días';
  }

  @override
  String get chargeReminderTitle => 'Comprobar baterías y aparatos';

  @override
  String get chargeReminderBody =>
      'Carga y prueba baterías externas, pilas recargables, linternas y radios de emergencia.';

  @override
  String expiryLeadDaysLabel(int days) {
    return '$days días';
  }

  @override
  String get itemExpiryRemindersLabel => 'Recordatorios para este artículo';

  @override
  String get itemExpiryRemindersTitle => 'Antelación para este artículo';

  @override
  String get itemExpiryRemindersHint =>
      'Solo se aplica a esta entrada. Si no tiene una propia, cuenta el ajuste fijado para todo el hogar.';

  @override
  String get itemExpiryRemindersDefault => 'Como en el hogar';

  @override
  String get itemExpiryRemindersOwn => 'Antelación propia';

  @override
  String get itemExpiryRemindersNever => 'No recordarme nunca este artículo';

  @override
  String get itemExpiryRemindersNone => 'Ninguno';

  @override
  String get itemExpiryRemindersDefaultNone =>
      'Como el hogar: sin recordatorio';

  @override
  String itemExpiryRemindersDefaultWith(String days) {
    return 'Como el hogar: $days';
  }

  @override
  String get expiryLeadDayOneLabel => '1 día';

  @override
  String get consumeAction => 'Consumir';

  @override
  String consumeDialogTitle(String name) {
    return 'Consumir $name';
  }

  @override
  String get consumeDialogAmountLabel => 'Cantidad';

  @override
  String consumeDialogRemaining(String quantity, String unit) {
    return 'En existencias: $quantity $unit';
  }

  @override
  String get consumeDialogConfirm => 'Descontar';

  @override
  String get consumeDialogAll => 'Consumido del todo';

  @override
  String get consumeInvalidAmount =>
      'La cantidad debe ser mayor que 0 y como mucho lo que hay en existencias.';

  @override
  String consumeDialogEquals(String amount, String unit) {
    return 'Son $amount $unit.';
  }

  @override
  String consumeDialogAmountHint(String unit) {
    return '¿Cuántos $unit?';
  }

  @override
  String get packageNameLabel => 'Envase (opcional)';

  @override
  String get packageNameHint => 'p. ej. tarro, lata, unidad';

  @override
  String get packageSizeLabel => 'Contenido por envase';

  @override
  String packageHelp(String unit) {
    return 'Permite descontar lo consumido en envases enteros; la app lo convierte a $unit.';
  }

  @override
  String get packageIncomplete => 'Un envase necesita nombre y contenido.';

  @override
  String get packageSizeInvalid => 'Introduce un número mayor que 0.';

  @override
  String inventoryPackageCount(String count, String package) {
    return '$count × $package';
  }

  @override
  String inventoryPackageCountApprox(String count, String package) {
    return '≈ $count × $package';
  }

  @override
  String syncAgeMinutes(int count) {
    return '$count minutos';
  }

  @override
  String syncAgeHours(int count) {
    return '$count horas';
  }

  @override
  String syncAgeDays(int count) {
    return '$count días';
  }

  @override
  String get csvExportButton => 'Exportar como CSV';

  @override
  String get csvExportDialogTitle => 'Guardar las provisiones como CSV';

  @override
  String csvExportSuccessMessage(int count) {
    return '$count artículos exportados';
  }

  @override
  String get csvExportEmptyMessage => 'Aún no hay artículos que exportar.';

  @override
  String get csvExportErrorMessage => 'No se ha podido escribir el archivo.';

  @override
  String get calendarExportButton => 'Fechas de caducidad como calendario';

  @override
  String get calendarExportDialogTitle =>
      'Guardar las fechas de caducidad como archivo de calendario';

  @override
  String get calendarExportEmpty =>
      'Ningún artículo tiene una fecha de caducidad próxima y el recordatorio de baterías está desactivado.';

  @override
  String calendarExportSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Archivo de calendario guardado con $count fechas de caducidad',
      one: 'Archivo de calendario guardado con una fecha de caducidad',
      zero: 'Archivo de calendario guardado con el recordatorio de baterías',
    );
    return '$_temp0';
  }

  @override
  String calendarExpiryTitle(String name) {
    return 'Consumir preferentemente: $name';
  }

  @override
  String get profileSetupTitle => 'Configura tu hogar';

  @override
  String get profileSetupIntro =>
      'PreppSuite funciona por completo en este dispositivo. No hay cuenta ni servidor: solo estos datos, para que los avisos y los objetivos de provisiones se ajusten a tu situación.';

  @override
  String get profileSetupSubmit => 'Empezar';

  @override
  String stepperDecrease(String label) {
    return 'Uno menos: $label';
  }

  @override
  String stepperIncrease(String label) {
    return 'Uno más: $label';
  }

  @override
  String stepperValue(String label, int value) {
    return '$label: $value';
  }

  @override
  String deleteItemAction(String item) {
    return 'Eliminar «$item»';
  }

  @override
  String get mapDownloadSearchAction => 'Buscar este lugar';

  @override
  String warningBannerSeverity(String severity, String headline) {
    return '$severity: $headline';
  }

  @override
  String get shoppingListTitle => 'Lista de la compra';

  @override
  String shoppingListTargetHeading(int days) {
    return 'Frente al objetivo de $days días';
  }

  @override
  String shoppingListTargetMet(int days) {
    return 'El agua y la energía están cubiertas para $days días.';
  }

  @override
  String shoppingListWaterGap(String liters) {
    return 'Faltan por comprar $liters l de agua';
  }

  @override
  String shoppingListEnergyGap(String kcal) {
    return 'Faltan por comprar $kcal kcal de alimentos';
  }

  @override
  String shoppingListDaysCovered(int covered, int days) {
    return 'Las provisiones alcanzan ahora para $covered de $days días.';
  }

  @override
  String get shoppingListDaysUnknown =>
      'No hay personas en el hogar, así que no hay nada que calcular.';

  @override
  String get shoppingListItemsHeading => 'Por debajo del mínimo';

  @override
  String get shoppingListItemsEmpty => 'Nada está por debajo de su mínimo.';

  @override
  String get shoppingListNoMinimums =>
      'Aquí solo aparecen los artículos a los que diste una cantidad mínima. Fija una en un artículo y se vigilará.';

  @override
  String shoppingListShortfall(String amount, String unit, String minimum) {
    return 'Faltan $amount $unit para $minimum';
  }

  @override
  String get shoppingListCopy => 'Copiar lista';

  @override
  String get shoppingListCopied => 'Lista de la compra copiada.';

  @override
  String get rotationTitle => 'Consumir primero';

  @override
  String get rotationExpiredHeading => 'Ha pasado su fecha';

  @override
  String get rotationSoonHeading => 'Consumir pronto';

  @override
  String get rotationLaterHeading => 'Aguanta por ahora';

  @override
  String rotationExpiredSince(int days) {
    return 'hace $days días';
  }

  @override
  String get rotationExpiresToday => 'Hoy';

  @override
  String rotationDaysLeft(int days) {
    return 'quedan $days días';
  }

  @override
  String get rotationEmpty =>
      'Aquí no hay nada que rotar. Solo se listan los artículos con fecha a los que les queda algo.';

  @override
  String get rotationHint =>
      'La sal y similares no llevan fecha y se dejan fuera a propósito: taparían las filas que sí la tienen.';

  @override
  String get consumeScanAction => 'Escanear para consumir';

  @override
  String consumeScanNotFound(String barcode) {
    return 'Ningún artículo con el código de barras $barcode en este hogar.';
  }

  @override
  String get sharingErrorLocked =>
      'Esta carpeta está cifrada y este dispositivo no tiene la frase de contraseña. No se lee ni se escribe nada hasta que la introduzcas.';

  @override
  String get folderEncryptionOff =>
      'Desactivado. Todo lo que hay en la carpeta lo puede leer quien pueda verla, incluido tu proveedor de sincronización.';

  @override
  String get folderEncryptionOn =>
      'Activado. La carpeta solo contiene archivos sellados.';

  @override
  String get folderEncryptionEnable => 'Activar el cifrado';

  @override
  String get folderEncryptionUnlock => 'Introducir frase de contraseña';

  @override
  String get folderEncryptionPassphrase => 'Frase de contraseña';

  @override
  String get folderEncryptionRepeat => 'Repetir la frase de contraseña';

  @override
  String get folderEncryptionMismatch => 'Las dos entradas no coinciden.';

  @override
  String folderEncryptionTooShort(int count) {
    return 'Al menos $count caracteres. Es lo único que hay entre la carpeta y quien pueda leerla.';
  }

  @override
  String get folderEncryptionWrong =>
      'Esa frase de contraseña no abre esta carpeta.';

  @override
  String get folderEncryptionNoRecovery =>
      'Sin ella no hay forma de volver a entrar. PreppSuite no puede restablecerla, ni nadie más: anótala en un lugar seguro antes de continuar.';

  @override
  String get folderEncryptionOtherDevices =>
      'Todos los demás dispositivos de este hogar tienen que actualizarse y recibir la misma frase de contraseña. Hasta entonces dejan de ver filas nuevas.';

  @override
  String get folderEncryptionEnabled =>
      'La carpeta compartida está ahora cifrada.';

  @override
  String get folderEncryptionUnlocked => 'Carpeta desbloqueada.';

  @override
  String get householdPlanTitle => 'Plan de emergencia';

  @override
  String get householdPlanIntro =>
      'Acordado antes de que haga falta. Todos en el hogar deberían saberlo de memoria, así que anota solo lo que dirías de verdad en voz alta.';

  @override
  String get householdPlanEmpty => 'Aún no hay nada acordado.';

  @override
  String get householdPlanMeetingNear => 'Punto de encuentro cercano';

  @override
  String get householdPlanMeetingNearHint =>
      'Accesible a pie, sin plan: la esquina, la entrada del vecino.';

  @override
  String get householdPlanMeetingFar => 'Punto de encuentro más lejano';

  @override
  String get householdPlanMeetingFarHint =>
      'Para cuando se desaloja toda la zona y no se puede llegar al cercano.';

  @override
  String get householdPlanContactName => 'Contacto fuera de la zona';

  @override
  String get householdPlanContactNameHint =>
      'Alguien fuera de la región al que todos llaman. Las líneas locales son las primeras en saturarse; una llamada a la comarca vecina suele entrar cuando una al otro lado de la calle no.';

  @override
  String get householdPlanContactPhone => 'Su número';

  @override
  String get householdPlanKitLocation => 'Dónde está el equipaje de emergencia';

  @override
  String get householdPlanKitLocationHint =>
      'Para que nadie lo busque a oscuras.';

  @override
  String get householdPlanShutoff =>
      'Dónde se cortan el agua, el gas y la electricidad';

  @override
  String get householdPlanContactPoint => 'El punto de contacto del municipio';

  @override
  String get householdPlanContactPointHint =>
      'El edificio con alimentación de emergencia que abre cuando la luz lleva mucho tiempo cortada: da información, y allí se puede transmitir una llamada de emergencia cuando ningún teléfono funciona. Su nombre cambia según el estado federado; el municipio sabe dónde está el más cercano. No es un punto de encuentro: aquí se va a pedir ayuda, no a encontrarse.';

  @override
  String get householdPlanNotes => 'Cualquier otra cosa';

  @override
  String get householdPlanSaved => 'Plan guardado.';

  @override
  String get householdPlanCleared => 'Plan eliminado.';

  @override
  String get householdPlanClear => 'Eliminar plan';

  @override
  String get householdPlanClearConfirm =>
      '¿Eliminar el plan en todos los dispositivos de este hogar?';

  @override
  String get householdPlanShared =>
      'Este plan llega a todos los dispositivos del hogar a través de la carpeta compartida.';

  @override
  String get householdPlanNothingEntered =>
      'Anota al menos una cosa antes de guardar.';

  @override
  String get drillsEmergencyMode => 'Modo de emergencia';

  @override
  String get drillsCallEmergency => 'Llamar al 112';

  @override
  String get drillsHarmless =>
      'Un simulacro no cambia provisiones ni envía mensajes.';

  @override
  String get drillsReset => 'Empezar de nuevo';

  @override
  String get drillsTitle => 'Modo de emergencia y simulacros';

  @override
  String get drillsSubtitle =>
      'Una tarjeta para seguir paso a paso y simulacros realistas en casa';

  @override
  String get drillsImmediateDanger =>
      'En peligro inmediato, llama primero al 112. Después consulta los avisos oficiales, dile a tu familia lo que dice el plan del hogar y ahorra energía.';

  @override
  String get drillsSectionTitle => 'Modo simulacro';

  @override
  String get emergencyCardsTitle => 'Tarjetas de emergencia';

  @override
  String get emergencyCardsIntro =>
      'Lo que querría saber una ambulancia, para cada persona del hogar. Solo hace falta el nombre: una tarjeta que no dice más que un nombre y una alergia ya merece la pena.';

  @override
  String get emergencyCardsEmpty => 'Aún no hay tarjetas.';

  @override
  String emergencyCardsCount(int count) {
    return '$count personas';
  }

  @override
  String get emergencyCardAdd => 'Añadir persona';

  @override
  String get emergencyCardEdit => 'Editar tarjeta';

  @override
  String get emergencyCardName => 'Nombre';

  @override
  String get emergencyCardBirthYear => 'Año de nacimiento';

  @override
  String get emergencyCardBirthYearHint =>
      'Solo el año. Un sanitario necesita saber más o menos a quién atiende, no un cumpleaños.';

  @override
  String get emergencyCardBloodType => 'Grupo sanguíneo';

  @override
  String get emergencyCardAllergies => 'Alergias';

  @override
  String get emergencyCardMedication => 'Medicación habitual';

  @override
  String get emergencyCardMedicationHint =>
      'Lo que hay que tener en las provisiones y lo que nadie debería tener que adivinar.';

  @override
  String get emergencyCardConditions => 'Enfermedades previas';

  @override
  String get emergencyCardInsurance => 'Seguro médico';

  @override
  String get emergencyCardDoctor => 'Médico';

  @override
  String get emergencyCardContact => 'A quién llamar por esta persona';

  @override
  String get emergencyCardDoctors => 'Médicos';

  @override
  String get emergencyCardDoctorAdd => 'Añadir un médico';

  @override
  String get emergencyCardSpecialty => 'Especialidad';

  @override
  String get emergencyCardSpecialtyHint => 'médica de familia, cardiólogo';

  @override
  String get emergencyCardContacts => 'A quién llamar por esta persona';

  @override
  String get emergencyCardContactAdd => 'Añadir un contacto';

  @override
  String get emergencyCardRelation => 'Relación';

  @override
  String get emergencyCardRelationHint => 'pareja, hijo, vecina';

  @override
  String get emergencyCardPhone => 'Número de teléfono';

  @override
  String get emergencyCardPersonRemove => 'Quitar entrada';

  @override
  String get emergencyCardNotes => 'Otros';

  @override
  String get emergencyCardNameRequired => 'Una tarjeta necesita un nombre.';

  @override
  String get emergencyCardRemoved => 'Tarjeta eliminada.';

  @override
  String get lockScreenCardAction => 'Como imagen de pantalla de bloqueo';

  @override
  String get lockScreenCardTitle => 'Imagen para la pantalla de bloqueo';

  @override
  String get lockScreenCardIntro =>
      'Los sanitarios no desbloquean el teléfono de un desconocido, pero ven su pantalla de bloqueo. La imagen se abre en el menú de compartir: elige allí \"Guardar imagen\" y ponla como fondo de la pantalla de bloqueo en los Ajustes.';

  @override
  String get lockScreenCardPrivacy =>
      'Cualquiera que tenga el teléfono en la mano puede leer lo que hay en la imagen. Elige solo lo que deba ayudar en una emergencia.';

  @override
  String get lockScreenCardCreate => 'Crear imagen';

  @override
  String get lockScreenCardHeading => 'EN CASO DE EMERGENCIA';

  @override
  String get lockScreenCardCall => 'Llamar en caso de emergencia';

  @override
  String get lockScreenCardFailed => 'No se ha podido crear la imagen.';

  @override
  String emergencyCardRemoveConfirm(String name) {
    return '¿Eliminar la tarjeta de $name en todos los dispositivos de este hogar?';
  }

  @override
  String get emergencyCardsHealthWarning =>
      'Son datos de salud y viajan por la carpeta compartida a todos los dispositivos. Cifra la carpeta antes de introducirlos.';

  @override
  String get emergencyCardsHealthEncrypted =>
      'Son datos de salud. La carpeta compartida por la que viajan está cifrada.';

  @override
  String get emergencyCardBirthYearInvalid => 'Eso no es un año.';

  @override
  String get settingsSharingTitle => 'Carpeta compartida';

  @override
  String get sharingIntro =>
      'Las provisiones, las listas y los gastos viven en una carpeta que ven varios dispositivos: un directorio de Nextcloud, Syncthing, iCloud Drive o Dropbox. PreppSuite solo escribe archivos ahí. Qué los transporta lo eliges tú.';

  @override
  String get sharingInactive =>
      'Este dispositivo no comparte nada. Todo se queda aquí.';

  @override
  String sharingActiveFolder(String path) {
    return 'Carpeta: $path';
  }

  @override
  String get sharingChooseFolderAction => 'Elegir carpeta';

  @override
  String get sharingChangeFolderAction => 'Elegir otra carpeta';

  @override
  String get sharingLeaveAction => 'Dejar de compartir';

  @override
  String get sharingSyncNowAction => 'Sincronizar ahora';

  @override
  String get sharingSyncing => 'Sincronizando …';

  @override
  String get sharingNeverSynced => 'Aún no se ha sincronizado nunca.';

  @override
  String sharingLastSynced(String age) {
    return 'Última sincronización hace $age.';
  }

  @override
  String sharingDeviceCount(int count) {
    return '$count dispositivos comparten esta carpeta.';
  }

  @override
  String get sharingDeviceCountOne =>
      'De momento solo este dispositivo usa la carpeta.';

  @override
  String sharingReceived(int count) {
    return '$count entradas tomadas de otros dispositivos.';
  }

  @override
  String get sharingUpToDate => 'Todo está al día.';

  @override
  String get sharingErrorUnwritable =>
      'No se puede escribir en esta carpeta. En Android el permiso se pierde al reinstalar y se puede revocar en los ajustes del sistema: basta con elegir la carpeta de nuevo. Si no, comprueba que sigue ahí y que se puede escribir en ella.';

  @override
  String get sharingErrorUnreadable =>
      'Ya hay un hogar en esta carpeta y no se puede leer. Probablemente viene de una versión más reciente de PreppSuite.';

  @override
  String get sharingErrorVersion =>
      'Los archivos de esta carpeta vienen de una versión más reciente. No se ha cambiado nada.';

  @override
  String get sharingErrorFailed =>
      'La sincronización ha fallado. El siguiente intento se hace solo.';

  @override
  String sharingJoinedOther(String name) {
    return 'Este dispositivo pertenece ahora al hogar «$name». Sus entradas existentes vinieron con él.';
  }

  @override
  String get sharingLeaveDialogTitle => '¿Dejar de compartir?';

  @override
  String get sharingLeaveDialogBody =>
      'Este dispositivo dejará de sincronizar. No se borra nada, ni aquí ni en la carpeta.';

  @override
  String get sharingLeaveDialogConfirm => 'Dejar';

  @override
  String get sharingErrorDifferentHousehold =>
      'Esta carpeta pertenece a otro hogar. No se ha fusionado nada: dos conjuntos de datos sin relación no se pueden volver a separar.';

  @override
  String get mapAttributionOffline =>
      '© colaboradores de OpenStreetMap · © OpenMapTiles';

  @override
  String get settingsOfflineMapTitle => 'Mapa sin conexión';

  @override
  String get offlineMapIntro =>
      'Sin un mapa propio, la app obtiene las teselas de OpenStreetMap, así que necesita conexión. Un archivo PMTiles en el dispositivo lo sustituye por completo.';

  @override
  String get offlineMapInactive =>
      'No hay mapa elegido. Las teselas vienen de la red.';

  @override
  String offlineMapActive(String name) {
    return '$name';
  }

  @override
  String offlineMapZoomRange(int min, int max) {
    return 'Niveles de zoom de $min a $max.';
  }

  @override
  String get offlineMapChooseAction => 'Elegir un mapa';

  @override
  String get offlineMapChangeAction => 'Elegir otro mapa';

  @override
  String get offlineMapForgetAction => 'Volver a en línea';

  @override
  String get offlineMapErrorUnreadable =>
      'No se puede leer el archivo. Se espera un archivo PMTiles versión 3.';

  @override
  String get offlineMapErrorNotVector =>
      'El archivo contiene teselas de imagen ya terminadas en lugar de datos vectoriales. PreppSuite dibuja el mapa por sí misma y necesita teselas vectoriales.';

  @override
  String get offlineMapErrorSchema =>
      'El archivo usa un esquema distinto al del estilo de mapa incluido. Se necesita un archivo con esquema OpenMapTiles: consulta docs/karte-offline.md en el código fuente.';

  @override
  String get navKnowledge => 'Saber';

  @override
  String get knowledgeTitle => 'Saber';

  @override
  String get knowledgeEmptyTitle => 'Aún no hay archivo de conocimiento';

  @override
  String get knowledgeEmptyBody =>
      'Un archivo ZIM en el dispositivo, por ejemplo la Wikipedia de Kiwix, hace que consultar no dependa de la red. El botón de abajo descarga uno de la biblioteca de Kiwix; también se puede elegir un archivo que ya esté aquí.';

  @override
  String get knowledgeChooseAction => 'Elegir un archivo';

  @override
  String get knowledgeChangeAction => 'Elegir otro archivo';

  @override
  String get articleLinkLeavesArchive =>
      'Ese enlace apunta fuera del archivo. PreppSuite solo muestra lo que hay en el archivo.';

  @override
  String get knowledgeSearchHint => 'Buscar títulos';

  @override
  String get knowledgeSearchNote =>
      'Busca en los títulos, no en el texto de los artículos.';

  @override
  String knowledgeNoResults(String query) {
    return 'Ningún título empieza por «$query».';
  }

  @override
  String get knowledgeSuggestionsTitle => 'Por dónde empezar';

  @override
  String get knowledgeSuggestionsBody =>
      'Puedes tener varios archivos a la vez y cambiar con un toque. Los archivos se quedan donde están.';

  @override
  String get knowledgeSuggestionWikibooks =>
      'Libros de texto, incluido un curso completo de matemáticas de secundaria.';

  @override
  String get knowledgeSuggestionKlexikon =>
      'Una enciclopedia escrita para niños de primaria.';

  @override
  String get knowledgeSuggestionPhet =>
      'Experimentos interactivos de física, química y matemáticas.';

  @override
  String get knowledgeSuggestionWikiversity =>
      'Material de cursos y de enseñanza.';

  @override
  String get knowledgeSuggestionWikipedia =>
      'Todo lo demás. Con diferencia el mayor de todos.';

  @override
  String get knowledgeSuggestionMedicine =>
      'Solo los artículos médicos de Wikipedia, en una fracción del tamaño.';

  @override
  String get knowledgeSuggestionIfixit =>
      'Instrucciones de reparación de electrodomésticos y electrónica, con imágenes.';

  @override
  String get knowledgeSuggestionKhan =>
      'El currículo escolar de principio a fin: solo en inglés, no existe archivo en alemán.';

  @override
  String get knowledgeAddAction => 'Añadir otro archivo';

  @override
  String get knowledgeRemoveAction => 'Quitar este archivo';

  @override
  String knowledgeSwitchFailed(String name) {
    return 'No se puede abrir $name. Puede que el archivo se haya movido.';
  }

  @override
  String get knowledgeErrorUnreadable =>
      'No se puede leer el archivo. Se espera un archivo ZIM, del tipo que publica Kiwix.';

  @override
  String get knowledgeArticleUnsupported =>
      'En esta plataforma no se pueden mostrar artículos: falta el componente de navegador. Buscar funciona, leer no.';

  @override
  String get knowledgeArticleNoEngine =>
      'Falta el componente de navegador del sistema. En Linux es WebKitGTK (paquete libwebkit2gtk-4.1), en Windows el runtime de WebView2.';

  @override
  String knowledgeSource(String name) {
    return 'De $name';
  }

  @override
  String get knowledgeModeTitles => 'Títulos';

  @override
  String get knowledgeModeFullText => 'Texto completo';

  @override
  String get knowledgeFullTextNote => 'Busca en el texto de los artículos.';

  @override
  String get knowledgeIndexMissingTitle => 'Sin índice de texto completo';

  @override
  String get knowledgeIndexMissingBody =>
      'Buscar en el texto necesita un índice. La app lo crea una vez; después responde al instante.';

  @override
  String get knowledgeIndexCountAction => 'Contar artículos';

  @override
  String get knowledgeIndexBuildAction => 'Crear índice';

  @override
  String get knowledgeIndexContinueAction => 'Seguir creando';

  @override
  String get knowledgeIndexCancelAction => 'Detener';

  @override
  String get knowledgeIndexDiscardAction => 'Descartar índice';

  @override
  String knowledgeIndexStorage(String size) {
    return 'Índice de búsqueda: $size';
  }

  @override
  String get knowledgeIndexCompactHint =>
      'Este índice usa un formato antiguo. Volver a crearlo en forma compacta ahorra espacio sin cambiar la búsqueda normal de texto completo.';

  @override
  String get knowledgeIndexCompactAction => 'Volver a crear el índice compacto';

  @override
  String knowledgeIndexArticles(int count) {
    return '$count artículos en este archivo.';
  }

  @override
  String get knowledgeIndexLargeWarning =>
      'Son muchos. Cuenta con una hora o más y varios gigabytes en disco. Puedes detenerlo en cualquier momento y conservar lo hecho.';

  @override
  String knowledgeIndexScanning(int done, int total) {
    return 'Contando artículos: $done de $total.';
  }

  @override
  String knowledgeIndexIndexing(int done, int total) {
    return '$done de $total artículos.';
  }

  @override
  String knowledgeIndexPartial(int done, int total) {
    return 'Detenido en $done de $total artículos. Busca en lo que ya contiene.';
  }

  @override
  String knowledgeIndexReady(int count) {
    return '$count artículos indexados.';
  }

  @override
  String get knowledgeIndexBuiltInTitle => 'El archivo trae su propio índice';

  @override
  String knowledgeIndexBuiltIn(int count) {
    return '$count artículos, que se pueden buscar enseguida. El archivo lleva su propio índice de texto completo, así que no hay nada que crear.';
  }

  @override
  String get knowledgeIndexBuiltInStemming =>
      'Las búsquedas coinciden por raíz: \"supplies\" también encuentra \"supply\".';

  @override
  String get downloadFolderTitle => 'Carpeta de descargas';

  @override
  String get downloadFolderChange => 'Elegir carpeta';

  @override
  String get downloadFolderReset => 'Restablecer';

  @override
  String get downloadResumingLabel => 'Conexión interrumpida: reanudando…';

  @override
  String downloadRunningLabel(String name) {
    return 'Descargando $name';
  }

  @override
  String get downloadCancelAction => 'Cancelar';

  @override
  String downloadFailedLabel(String error) {
    return 'Descarga detenida: $error';
  }

  @override
  String downloadFinishedLabel(String name) {
    return '$name se ha terminado de descargar.';
  }

  @override
  String downloadNotOpenedLabel(String name, String reason) {
    return '$name se ha descargado, pero no se puede abrir: $reason';
  }

  @override
  String get downloadRetryAction => 'Volver a intentarlo';

  @override
  String get downloadDismissAction => 'Descartar';

  @override
  String downloadOfSize(String done, String total) {
    return '$done de $total';
  }

  @override
  String progressPercent(int percent) {
    return '$percent %';
  }

  @override
  String get downloadBusyMessage =>
      'Ya hay una descarga en curso. Solo se hace una a la vez.';

  @override
  String get downloadStartAction => 'Descargar';

  @override
  String get downloadConfirmTitle => '¿Descargar?';

  @override
  String downloadConfirmBody(String name, String size, String folder) {
    return '$name ocupa $size y se guardará en $folder. Sigue mientras la app esté abierta y se puede reanudar más tarde.';
  }

  @override
  String get knowledgeDownloadAction => 'Descargar un archivo';

  @override
  String get kiwixTitle => 'Biblioteca de Kiwix';

  @override
  String get kiwixIntro =>
      'Wikipedia y otras colecciones como archivo ZIM, gratis y sin cuenta. Elige un idioma y descarga lo que quieras tener sin conexión.';

  @override
  String get kiwixLanguageLabel => 'Idioma';

  @override
  String get kiwixSearchHint => 'Buscar colecciones';

  @override
  String get kiwixNoResults =>
      'No se ha encontrado nada. ¿Otro idioma u otro término de búsqueda?';

  @override
  String kiwixLoadError(String error) {
    return 'No se ha podido acceder a la biblioteca: $error';
  }

  @override
  String kiwixArticleCount(String count) {
    return '$count artículos';
  }

  @override
  String get kiwixFullTextTag => 'índice de texto completo';

  @override
  String get kiwixFlavourMaxi => 'completo';

  @override
  String get kiwixFlavourMini => 'solo introducciones';

  @override
  String get kiwixFlavourNopic => 'sin imágenes';

  @override
  String kiwixResultCount(String shown, String total) {
    return '$shown de $total';
  }

  @override
  String get kiwixLoadMore => 'Cargar más';

  @override
  String get mapDownloadAction => 'Descargar un mapa';

  @override
  String get mapDownloadTitle => 'Descargar zona de mapa';

  @override
  String get mapDownloadZoomLabel => 'Detalle';

  @override
  String get mapDownloadZoomHint =>
      'El nivel 12 muestra pueblos y carreteras principales; el nivel 14, calles y edificios individuales.';

  @override
  String mapDownloadTileCount(String count, String size) {
    return '$count teselas, unos $size';
  }

  @override
  String mapDownloadTooLarge(String count) {
    return '$count teselas son demasiadas. Reduce la zona o el nivel de detalle.';
  }

  @override
  String mapDownloadRunning(String done, String total, String size) {
    return '$done de $total teselas, $size descargados';
  }

  @override
  String get mapDownloadFinished => 'El mapa está listo y ya se está usando.';

  @override
  String mapDownloadFailed(String error) {
    return 'La descarga ha fallado: $error';
  }

  @override
  String get mapDownloadSourceLabel => 'Fuente del mapa';

  @override
  String get mapDownloadSourceOpenFreeMap => 'OpenFreeMap (gratis, sin clave)';

  @override
  String get mapDownloadSourceMapTiler =>
      'MapTiler (necesita una cuenta y una clave)';

  @override
  String get mapDownloadApiKeyLabel => 'Clave de API';

  @override
  String get mapDownloadApiKeyHint =>
      'De tu cuenta de MapTiler. Se queda en este dispositivo.';

  @override
  String get mapDownloadPolite =>
      'Las teselas vienen de un servidor público que también usan otras personas. No descargues más de lo que necesitas.';

  @override
  String mapDownloadLabel(String zoom) {
    return 'Zona propia, nivel $zoom';
  }

  @override
  String get mapDownloadSearchHint => 'Localidad, comarca, estado o país';

  @override
  String get mapDownloadSearchNoResults =>
      'No se ha encontrado nada. ¿Otro nombre?';

  @override
  String mapDownloadSearchFailed(String error) {
    return 'No se ha podido acceder a la búsqueda de lugares: $error';
  }

  @override
  String get mapDownloadAreaViewport => 'Zona visible';

  @override
  String mapDownloadAreaPlace(String name, String kind) {
    return '$name · $kind';
  }

  @override
  String get mapDownloadDetailAuto =>
      'El nivel más profundo en el que todavía cabe esta zona.';

  @override
  String mapDownloadDeepestPossible(String count, String level) {
    return 'En el nivel 14 serían $count teselas: demasiadas. El nivel $level es el más profundo para esta zona.';
  }

  @override
  String get mapDownloadScopePlace => 'Solo este lugar';

  @override
  String get mapDownloadScopeRegion => 'Con el estado federado';

  @override
  String get mapDownloadScopeCountry => 'Todo el país';

  @override
  String get mapDownloadWorldBase => 'Mundo';

  @override
  String get mapDownloadScopeContinent => 'Todo el continente';

  @override
  String get mapContinentEurope => 'Europa';

  @override
  String get mapContinentAfrica => 'África';

  @override
  String get mapContinentAsia => 'Asia';

  @override
  String get mapContinentNorthAmerica => 'América del Norte';

  @override
  String get mapContinentSouthAmerica => 'América del Sur';

  @override
  String get mapContinentOceania => 'Oceanía';

  @override
  String get mapDownloadStaggered =>
      'Escalonado: más grueso hacia fuera, todo el detalle en el centro.';

  @override
  String mapDownloadStep(String label, String from, String to, String count) {
    return '$label: nivel $from a $to, $count teselas';
  }

  @override
  String get mapDownloadNoPlan =>
      'Ni siquiera escalonado cabe. Elige un lugar más pequeño.';

  @override
  String mapDownloadEstimatedTime(String minutes) {
    return 'Tarda unos $minutes minutos.';
  }

  @override
  String get mapDownloadResolving => 'Calculando los alrededores …';

  @override
  String get mapDownloadUnfinishedTitle => 'Descarga sin terminar';

  @override
  String mapDownloadUnfinishedBody(String label, String done, String total) {
    return '$label: ya hay $done de $total teselas.';
  }

  @override
  String get mapDownloadResumeAction => 'Reanudar';

  @override
  String get mapDownloadDiscardAction => 'Descartar';

  @override
  String get settingsLocationServicesOff =>
      'Los servicios de ubicación están desactivados. Actívalos en los ajustes del sistema.';

  @override
  String get settingsLocationDeniedForever =>
      'El acceso a la ubicación está denegado para PreppSuite. El sistema no volverá a preguntar: permítelo en los ajustes del sistema.';

  @override
  String get settingsLocationDenied =>
      'Esto necesita acceso a tu ubicación. Elige mejor el estado federado de la lista.';

  @override
  String settingsLocationUnavailable(String detail) {
    return 'La ubicación no está disponible en este dispositivo: $detail';
  }

  @override
  String get navMap => 'Mapa';

  @override
  String get distressTitle => 'Señal de socorro';

  @override
  String get distressIntro =>
      'Para cuando ya no hay red pero alguien todavía podría verte. La pantalla parpadea con un ritmo que conocen los rescatadores: levántala hacia la ladera o el valle.';

  @override
  String get distressBattery =>
      'Esto consume brillo y, por tanto, batería. Actívalo cuando alguien pueda estar ahí, no por si acaso.';

  @override
  String get distressStart => 'Empezar a señalizar';

  @override
  String get distressStop => 'Detener';

  @override
  String get distressPause => 'Pausa: aquí va la respuesta';

  @override
  String distressFlash(int number, int total) {
    return 'Señal $number de $total';
  }

  @override
  String get distressSos => 'SOS';

  @override
  String get distressSosHint =>
      'Tres cortas, tres largas, tres cortas: como un solo carácter, no como tres letras.';

  @override
  String get distressAlpine => 'Señal de socorro alpina';

  @override
  String get distressAlpineHint =>
      'Seis señales en un minuto, luego un minuto sin nada y vuelta a empezar. La pausa forma parte: distingue la señal de alguien que camina con una linterna.';

  @override
  String get distressAlpineAnswer => 'Respuesta a una señal de socorro';

  @override
  String get distressAlpineAnswerHint =>
      'Tres señales en un minuto, dentro de la pausa del otro: te he visto.';

  @override
  String get myPositionAction => 'Transmitir mi posición';

  @override
  String get myPositionTitle => 'Mi posición';

  @override
  String get myPositionIntro =>
      'Lee en voz alta lo que te pidan. Una central de emergencias suele querer grados y minutos, y los repite.';

  @override
  String get myPositionOffline =>
      'La app lo calcula por sí misma. No necesita red, que es justo cuando se necesita.';

  @override
  String get myPositionMeasure => 'Volver a medir';

  @override
  String get myPositionCopied => 'Copiado.';

  @override
  String myPositionAccuracy(int metres) {
    return 'El receptor indica ±$metres m.';
  }

  @override
  String get myPositionAccuracyPoor =>
      'Con eso no se llega a un número de portal. Vuelve a medir a cielo abierto y dile a la central lo aproximado que es.';

  @override
  String myPositionStale(int minutes) {
    return 'Esta posición tiene $minutes minutos. El dispositivo no ha podido obtener una nueva ahora mismo: vuelve a medir a cielo abierto antes de transmitirla.';
  }

  @override
  String nearbyStale(int minutes) {
    return 'Calculado con la última posición conocida, de hace $minutes minutos.';
  }

  @override
  String get myPositionDms => 'Grados, minutos, segundos';

  @override
  String get myPositionDmsHint =>
      'Lo que pide una central por teléfono, y lo que sobrevive a leerse en voz alta y anotarse.';

  @override
  String get myPositionUtm => 'UTM';

  @override
  String get myPositionUtmHint =>
      'Metros en una cuadrícula. Los servicios de emergencia y la agencia técnica de socorro trabajan con ellos.';

  @override
  String get myPositionMgrs => 'MGRS';

  @override
  String get myPositionMgrsHint =>
      'La misma cuadrícula como una referencia corta, tal como la rotula un mapa cuadriculado.';

  @override
  String get myPositionPlusCode => 'Plus Code';

  @override
  String get myPositionPlusCodeHint =>
      'Diez caracteres y ningún mapa, para alguien que lo va a teclear.';

  @override
  String get myPositionDecimal => 'Grados decimales';

  @override
  String get myPositionDecimalHint =>
      'Lo que se introduce en una app de mapas.';

  @override
  String get mapMyLocationAction => 'Mi ubicación';

  @override
  String get mapCoverageMissing =>
      'El mapa sin conexión no llega hasta aquí. Para esta zona nunca se descargó nada.';

  @override
  String mapCoverageIncomplete(int present, int total) {
    return 'El mapa sin conexión solo cubre parte de esta vista: unas $present teselas de $total. El resto queda vacío porque nunca se descargó.';
  }

  @override
  String get mapCoverageUseOnline => 'Usar el mapa en línea';

  @override
  String get mapCoverageUseOffline => 'Usar el mapa sin conexión';

  @override
  String get mapTilesUnavailable =>
      'Algunas teselas nunca llegaron del servidor. Lo que falla es la conexión, no la app.';

  @override
  String get mapSourceOffline => 'Sin conexión';

  @override
  String get mapSourceOnline => 'En línea';

  @override
  String mapSourceOfflineDetail(String name, int min, int max) {
    return 'Dibujando desde $name, zoom de $min a $max.';
  }

  @override
  String get mapSourceOnlineDetail =>
      'Dibujando teselas de OpenStreetMap. Necesita conexión.';

  @override
  String get mapSourceNoArchive =>
      'Aún no hay ningún mapa en este dispositivo. Hasta que se descargue uno, las teselas vienen de OpenStreetMap y necesitan conexión.';

  @override
  String get mapZoomIn => 'Acercar';

  @override
  String get mapZoomOut => 'Alejar';

  @override
  String supplyCalculatorHouseholdLine(String who) {
    return '$who: según el hogar';
  }

  @override
  String supplyCalculatorAdults(String count) {
    return '$count adultos';
  }

  @override
  String supplyCalculatorChildren(String count) {
    return '$count niños';
  }

  @override
  String supplyCalculatorDogs(String count) {
    return '$count perros';
  }

  @override
  String supplyCalculatorCats(String count) {
    return '$count gatos';
  }

  @override
  String get supplyCalculatorPetFoodNote =>
      'La comida para mascotas no cuenta en las calorías: perros y gatos necesitan una reserva propia. Su agua de bebida sí está incluida.';

  @override
  String get supplyCalculatorSourceTitle => 'De dónde salen las cifras';

  @override
  String get supplyCalculatorSourceBody =>
      'Para adultos, la BBK indica 1,5 litros de líquido al día más 0,5 litros para cocinar, y unas 2200 kcal. Para niños la propia BBK no indica nada, pero remite a la Oficina Federal de Agricultura y Alimentación, cuya tabla de provisiones lo dice en una nota a pie de página: los niños hasta 12 años (no los lactantes) necesitan de media 1 litro al día, según la DGE y el Instituto Max Rubner. La app usa eso: 1 litro más los mismos 0,5 litros para cocinar. A partir de los 65, la misma nota recomienda 2 litros al día; la edad no está en el perfil del hogar, así que solo aparece como nota en la pantalla de provisiones. Las 1400 kcal de un niño siguen siendo una estimación prudente de esta app: no hay cifra oficial. Para lactantes nadie indica una cantidad: la nota los excluye expresamente, «niños (no lactantes)», y esta app no inventa ninguna cifra. El BZfE solo nombra el tipo de provisión: leche de fórmula o alimento infantil, purés, agua limpia para prepararlos, además de pañales y productos de cuidado. Introdúcelos como artículos propios y calcúlalos según lo que tu hijo consume realmente en un día. Para perros y gatos solo se cuenta el agua, según la regla veterinaria de unos 60 ml por kilo: 1,2 litros para un perro de 20 kg, 0,25 litros para un gato de 4 kg. Lo que no son los dos litros: agua para algo que no sea beber y cocinar. La guía de la BBK los cuenta expresamente como 1,5 litros para beber y 0,5 para cocinar; para lavarse, fregar y el inodoro no indica ninguna cantidad, solo un recipiente para guardarla. Esta app no inventa ninguna cifra para ello: eso se planifica con la lista de control «Agua». Para algo exacto, el Vorratskalkulator del BMEL.';

  @override
  String get householdChildrenLabel => 'Niños';

  @override
  String get householdDogsLabel => 'Perros';

  @override
  String get householdCatsLabel => 'Gatos';

  @override
  String get householdAdultsLabel => 'Adultos';

  @override
  String get storageTipsTitle => 'Consejos de almacenamiento';

  @override
  String get waterTreatmentTitle => 'Potabilizar agua';

  @override
  String get waterTreatmentIntro =>
      'Las provisiones son una cosa. Cuando escasean o el grifo ya no es seguro, cuenta lo que se puede hacer con lo que hay, y lo que no.';

  @override
  String get waterTreatmentChemistryTitle =>
      'Ningún método sirve contra la química';

  @override
  String get waterTreatmentChemistryBody =>
      'El combustible, los productos químicos y el material radiactivo no salen del agua con ninguno de estos métodos. El agua de una calle inundada, o de cerca de un depósito de gasóleo que se ha soltado, no se vuelve potable hirviéndola. Esa agua se queda donde está.';

  @override
  String get waterTreatmentBoilTitle => 'Hervir';

  @override
  String get waterTreatmentBoilCloudy =>
      'El agua turbia, primero a través de un paño limpio, papel de cocina o un filtro de café, o déjala reposar y saca el agua clara.';

  @override
  String get waterTreatmentBoilStep =>
      'Lleva el agua clara a ebullición fuerte. La OMS considera suficiente una ebullición fuerte para inactivar bacterias, virus y parásitos; los CDC recomiendan un minuto en ebullición fuerte, tres minutos a gran altitud, por encima de unos 2000 metros.';

  @override
  String get waterTreatmentBoilStore =>
      'Déjala enfriar y guárdala en recipientes limpios con tapa hermética.';

  @override
  String get waterTreatmentChlorineTitle => 'Desinfectante';

  @override
  String get waterTreatmentChlorineStep =>
      'Dosifica según la etiqueta, remueve bien y déjala reposar al menos 30 minutos antes de beber.';

  @override
  String get waterTreatmentChlorineLimit =>
      'Actúa contra bacterias y virus, pero peor que hervir contra los parásitos Cryptosporidium y Giardia: las pastillas de cloro y de yodo no matan Cryptosporidium. Donde puedas hervir, hierve.';

  @override
  String get waterTreatmentFilterTitle => 'Filtrar';

  @override
  String get waterTreatmentFilterBody =>
      'Un filtro quita la turbidez y, según el filtro, también gérmenes. Lo que hace viene escrito en él: no todos retienen virus. Solo sustituye a hervir donde lo diga.';

  @override
  String get waterTreatmentSources =>
      'Fuentes: Guías de la OMS para la calidad del agua potable y \"Boil water\"; CDC, cómo hacer el agua segura en una emergencia.';

  @override
  String get waterTreatmentOpen => 'Potabilizar agua';

  @override
  String get storageTipsIntro =>
      'La BBK recomienda provisiones para diez días y, para las cantidades, remite a las tablas de provisiones de la Oficina Federal de Agricultura y Alimentación. Aquí están, adaptadas a tu hogar.';

  @override
  String storagePeopleLine(Object count) {
    return 'Para $count personas: según el hogar';
  }

  @override
  String storageDaysLabel(Object days) {
    return '$days días';
  }

  @override
  String get storageFewerDays => 'Un día menos';

  @override
  String get storageMoreDays => 'Un día más';

  @override
  String get storageScaledNote =>
      'La tabla está impresa para una persona y diez días. Todas las cantidades de aquí están convertidas.';

  @override
  String get storageDietMixed => 'Dieta mixta';

  @override
  String get storageDietVegetarian => 'Vegetariana';

  @override
  String storageAmountGrams(Object value) {
    return '$value g';
  }

  @override
  String storageAmountKilograms(Object value) {
    return '$value kg';
  }

  @override
  String storageAmountLiters(Object value) {
    return '$value l';
  }

  @override
  String storageAmountPieces(Object count) {
    return '$count uds.';
  }

  @override
  String storageKcal(Object kcal) {
    return '$kcal kcal';
  }

  @override
  String storageVariantLine(Object kcal, Object name) {
    return 'o $name: $kcal kcal';
  }

  @override
  String get storageAddToInventory => 'Añadir a las provisiones';

  @override
  String get storageFromTableNote =>
      'Tomado de la tabla de provisiones de la BLE.';

  @override
  String get storageUnitGram => 'g';

  @override
  String get storageUnitLiter => 'l';

  @override
  String get storageUnitPiece => 'uds.';

  @override
  String get storageNutrientProtein => 'Proteínas';

  @override
  String get storageNutrientFiber => 'Fibra';

  @override
  String get storageNutrientIron => 'Hierro';

  @override
  String get storageNutrientVitaminB12 => 'Vitamina B12';

  @override
  String get storageNutrientHealthyFats => 'Grasas saludables';

  @override
  String get storageNutrientFluid => 'Líquido';

  @override
  String get storageNutrientLegendTitle => 'Qué significan las marcas';

  @override
  String get storageNutrientLegendBody =>
      'Las marcas en los alimentos no están en la tabla oficial: son una lectura propia de esta app. Muestran para qué está sobre todo un alimento, para que veas qué se va con un grupo que quitas. Orientación, no consejo dietético.';

  @override
  String get storageTipsGeneralTitle => 'Consejos generales';

  @override
  String get storageTipRotate =>
      'Rota las provisiones: usa siempre primero lo más antiguo y repónlo. Así no caduca nada y no se compra nada para la basura.';

  @override
  String get storageTipCoolDryDark =>
      'Guarda en lugar fresco, seco y oscuro, mejor en recipientes que cierren bien.';

  @override
  String get storageTipEatWhatYouStore =>
      'Guarda solo lo que de verdad comes. Una provisión que no le gusta a nadie nunca se acaba y al final se tira.';

  @override
  String get storageTipNoPower =>
      'Cuenta con un corte de luz: no planifiques nada que haya que refrigerar o congelar.';

  @override
  String get storageTipReadyToEat =>
      'Elige una parte que se pueda comer sin cocinar, por si también falla el gas o la placa.';

  @override
  String get storageTipCanOpener =>
      'Acuérdate de un abrelatas que funcione sin electricidad.';

  @override
  String get storageTipSpecialNeeds =>
      'Los niños pequeños, las mascotas, los medicamentos y las dietas especiales también van en la lista. La tabla no los cubre.';

  @override
  String get storageVeganTitle => '¿Vegano?';

  @override
  String get storageVeganBody =>
      'No hay tabla vegana oficial: la BLE publica estas dos y ninguna tercera, y la app no inventa una. En una dieta vegana se sustituyen dos líneas de la tabla vegetariana: 2,5 kg de leche y lácteos, y los cinco huevos. Las bebidas vegetales enriquecidas y los productos de soja cubren proteínas y calcio. Para la vitamina B12, el yodo, el hierro y los omega-3, la DGE advierte expresamente en una dieta vegana: la B12 solo se cubre de forma fiable con un suplemento, y entonces va en las provisiones como todo lo demás.';

  @override
  String get storageSourceTitle => 'De dónde salen las cifras';

  @override
  String get storageSourceBody =>
      'En su página \"Bevorraten\", la BBK indica diez días y 1,5 litros de líquido más 0,5 litros para cocinar al día; para las cantidades remite a las tablas de provisiones de la Oficina Federal de Agricultura y Alimentación (BLE, 2024, ernaehrungsvorsorge.de). Cada línea de aquí viene de ahí: una provisión básica para una persona y diez días con una media de 2.200 kcal al día, una vez como dieta mixta y otra ovolactovegetariana. Las cifras de energía son del Bundeslebensmittelschlüssel 3.02 del Instituto Max Rubner; las cantidades siguen los valores de referencia de la DGE, la ÖGE y la SGE. El escalado es lineal en personas y días. Las marcas en los alimentos son un añadido de esta app y no aparecen en ninguna tabla oficial.';

  @override
  String get nutritionSectionTitle => 'Valores nutricionales';

  @override
  String get nutritionSectionHint =>
      'Por cada 100 g, o por 100 ml en bebidas, exactamente como los indica la etiqueta. Al escanear un código de barras se rellena lo que dice; la app hace las multiplicaciones.';

  @override
  String get proteinLabel => 'Proteínas';

  @override
  String get carbohydrateLabel => 'Hidratos de carbono';

  @override
  String get fatLabel => 'Grasas';

  @override
  String get fiberLabel => 'Fibra';

  @override
  String get supplyCalculatorInfantNote =>
      'Los lactantes no se cuentan aquí: qué guardar para ellos está en «De dónde salen las cifras».';

  @override
  String get supplyCalculatorSeniorNote =>
      'A partir de los 65, la DGE recomienda beber 2 litros al día en lugar de 1,5: planifica medio litro más por persona y día para las personas mayores del hogar.';

  @override
  String get warningFilterSearchHint => 'Lugar, región o palabra clave';

  @override
  String get warningFilterSearchClear => 'Borrar búsqueda';

  @override
  String get warningFilterActive => 'Activos';

  @override
  String get warningFilterExpired => 'Caducados';

  @override
  String get warningFilterMyRegions => 'Mis regiones';

  @override
  String get warningFilterSevere => 'Graves y superiores';

  @override
  String warningFilterResultCount(Object shown, Object total) {
    return '$shown de $total avisos';
  }

  @override
  String get warningFilterClear => 'Quitar filtro';

  @override
  String warningsEmptyFiltered(Object total) {
    return 'Ninguno de los $total avisos coincide con el filtro.';
  }

  @override
  String get checklistCategoryInformation => 'Mantenerse informado';

  @override
  String get checklistCategoryEvacuation => 'Equipaje de emergencia';

  @override
  String get checklistCategorySafety => 'Seguridad en casa';

  @override
  String get checklistCategoryHazards => 'Peligros naturales';

  @override
  String get checklistCategoryWellbeing => 'Miedos y preocupaciones';

  @override
  String get checklistCategoryPets => 'Mascotas';

  @override
  String get navOverview => 'Resumen';

  @override
  String get navWarnings => 'Avisos';

  @override
  String get navMore => 'Más';

  @override
  String overviewSupplyTitle(Object days) {
    return 'Provisiones para $days días';
  }

  @override
  String overviewSupplyWater(Object current, Object target) {
    return '$current de $target L';
  }

  @override
  String overviewSupplyCalories(int current, int target) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat targetNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    return '$currentString de $targetString kcal';
  }

  @override
  String get overviewAttentionTitle => 'Requiere atención';

  @override
  String get overviewNothingStored =>
      'Aún no se ha añadido nada a las provisiones.';

  @override
  String get overviewChargeDue => 'Comprobar los aparatos recargables';

  @override
  String overviewChargeOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: 'un día',
    );
    return 'Atrasado $_temp0';
  }

  @override
  String get overviewChargeDueToday => 'Toca hoy';

  @override
  String overviewChargeNext(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'dentro de $days días',
      one: 'dentro de un día',
    );
    return 'Próxima comprobación $_temp0';
  }

  @override
  String get overviewChargeNeverChecked => 'Aún no confirmado';

  @override
  String get overviewChargeDone => 'Comprobado';

  @override
  String get overviewExpired => 'caducado';

  @override
  String get overviewLowStock => 'por debajo del mínimo';

  @override
  String get overviewExpiringSoon => 'caduca en 30 días';

  @override
  String get overviewNoWarnings =>
      'Ahora mismo no hay avisos para tus regiones.';

  @override
  String overviewChecklistLists(Object complete, Object total) {
    return '$complete de $total listas completas';
  }

  @override
  String get overviewResourcesTitle => 'Recursos';

  @override
  String overviewItemCount(Object count) {
    return '$count entradas';
  }

  @override
  String get photoEditTitle => 'Recortar foto';

  @override
  String get photoEditHint =>
      'Arrastra el recuadro sobre la parte que quieres conservar.';

  @override
  String get photoEditRotateLeft => 'Girar a la izquierda';

  @override
  String get photoEditRotateRight => 'Girar a la derecha';

  @override
  String get photoEditReset => 'Imagen completa';

  @override
  String get photoEditFailed =>
      'Esta imagen no se puede editar. Se queda como está.';

  @override
  String get editPhotoButton => 'Recortar foto';

  @override
  String get sharingErrorEncryptionChanged =>
      'Sincronización detenida: faltan los metadatos de cifrado o se han restablecido. Restaura el household.json cifrado desde una copia de seguridad. No se han escrito datos del hogar sin cifrar.';

  @override
  String get searchUnavailable =>
      'La búsqueda no está disponible ahora mismo. Inténtalo de nuevo.';

  @override
  String get inventoryFilters => 'Filtrar y ordenar';

  @override
  String get inventoryFilterCategory => 'Categoría';

  @override
  String get inventoryFilterLocation => 'Lugar de almacenamiento';

  @override
  String get inventoryFilterStatus => 'Estado de existencias';

  @override
  String get inventoryFilterAll => 'Todo';

  @override
  String get inventoryNoLocation => 'Sin lugar de almacenamiento';

  @override
  String get inventoryExpiringSoon => 'Caduca en los próximos 7 días';

  @override
  String get inventorySortLabel => 'Ordenar por';

  @override
  String get inventorySortName => 'Nombre';

  @override
  String get inventorySortExpiry => 'Fecha de caducidad';

  @override
  String get inventorySortAttention => 'Requiere atención';

  @override
  String get inventoryApplyFilters => 'Aplicar';

  @override
  String get inventoryResetFilters => 'Restablecer filtros';

  @override
  String get inventoryFiltersActive => 'Filtros activos';

  @override
  String get inventorySearchHint => 'Buscar provisiones';

  @override
  String get inventoryClearSearch => 'Borrar búsqueda';

  @override
  String get inventoryNoMatches =>
      'No hay provisiones que coincidan. Ajusta la búsqueda o los filtros.';

  @override
  String get unsavedChangesTitle => '¿Descartar los cambios?';

  @override
  String get unsavedChangesMessage => 'Tus cambios aún no se han guardado.';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get discardChanges => 'Descartar';

  @override
  String get inventoryItemDeleted => 'Provisión eliminada';

  @override
  String get undoAction => 'Deshacer';

  @override
  String get budgetEntryDeleted => 'Gasto eliminado';

  @override
  String emergencyRadioChannels(int count) {
    return '$count canales';
  }

  @override
  String get overviewStartTitle => 'Tu primer paso hacia la preparación';

  @override
  String get overviewStartHint =>
      'Añade agua o alimentos para ver cuánto duran las provisiones de tu hogar.';

  @override
  String get overviewAddFirst => 'Añadir tu primera provisión';

  @override
  String get overviewOpen => 'Abrir';

  @override
  String get warningMoreInformation => 'Más información de la fuente del aviso';

  @override
  String get warningWhatToDoNow => 'Qué hacer ahora';

  @override
  String get moreActions => 'Más acciones';

  @override
  String get checklistLinkStockAction => 'Vincular con provisiones';

  @override
  String get checklistLinkStockTitle => 'Elegir artículo de provisiones';

  @override
  String get checklistUnlinkStockAction => 'Quitar vínculo';

  @override
  String get checklistNoStockToLink =>
      'Aún no hay ningún artículo de provisiones que vincular.';

  @override
  String checklistLinkedStock(String name, num quantity, String unit) {
    return '$name: $quantity $unit disponibles';
  }

  @override
  String get navEmergency => 'Emergencia';

  @override
  String get emergencyTitle => 'Emergencia y preparación';

  @override
  String get emergencyCall112 => 'Emergencias 112';

  @override
  String get emergencyCall110 => 'Policía 110';

  @override
  String get emergencyCurrentWarnings => 'Avisos actuales';

  @override
  String get emergencyNoWarnings => 'No hay avisos activos relevantes';

  @override
  String get readinessTitle => 'Preparación sin conexión';

  @override
  String get readinessReady => 'listo';

  @override
  String get readinessNeedsWork => 'pendiente';

  @override
  String get readinessInventory => 'Provisiones registradas';

  @override
  String get readinessChecklists => 'Listas empezadas';

  @override
  String get readinessPlan => 'Plan de emergencia completo';

  @override
  String get readinessCards => 'Tarjetas de emergencia registradas';

  @override
  String get readinessMap => 'Mapa sin conexión disponible';

  @override
  String get readinessKnowledge => 'Saber sin conexión disponible';

  @override
  String get readinessMapMissing => 'Sin mapa sin conexión';

  @override
  String get readinessKnowledgeMissing => 'Sin saber sin conexión';

  @override
  String get emergencyPlanMissing => 'El plan de emergencia no está completo';

  @override
  String get emergencyPlanHeading => 'Datos importantes';

  @override
  String get knowledgeLibraryTitle => 'Tus archivos';

  @override
  String get knowledgeLibraryEmpty =>
      'No queda ningún archivo en la biblioteca.';

  @override
  String get knowledgeManageArchives => 'Gestionar archivos';

  @override
  String knowledgeArchiveCount(int count) {
    return '$count archivos en este dispositivo';
  }

  @override
  String get backupCreate => 'Crear copia de seguridad';

  @override
  String get backupRestore => 'Restaurar copia de seguridad';

  @override
  String get backupHint =>
      'Provisiones, listas, plan de emergencia, tarjetas de emergencia, fotos, documentos propios, mapa sin conexión y archivos de conocimiento. El archivo contiene datos personales y debe guardarse de forma segura.';

  @override
  String get backupCreated => 'Copia de seguridad guardada.';

  @override
  String backupRestored(int count) {
    return 'Copia de seguridad restaurada: se han aplicado $count registros más recientes.';
  }

  @override
  String get backupInvalid =>
      'Esta copia de seguridad pertenece a otro hogar o está dañada.';

  @override
  String get backupFailed => 'No se ha podido procesar la copia de seguridad.';

  @override
  String get backupPassphraseTitle => 'Cifrar copia de seguridad';

  @override
  String get backupPassphrase => 'Contraseña';

  @override
  String get backupPassphraseRepeat => 'Repetir contraseña';

  @override
  String get backupPassphraseWarning =>
      'Sin esta frase de contraseña el archivo no se puede volver a abrir, tampoco por ti. No hay camino de vuelta ni puerta trasera. Anótala donde se guardan los pasaportes, y no en el dispositivo que esta copia debe sustituir.';

  @override
  String backupPassphraseInvalid(int count) {
    return 'Introduce al menos $count caracteres; las dos entradas tienen que coincidir.';
  }

  @override
  String get warningInstructionsTitle => 'Acciones recomendadas';

  @override
  String get warningShowMap => 'Mostrar la zona en el mapa';

  @override
  String warningDetailsPeriod(String start, String end) {
    return 'Aviso del: $start – $end';
  }

  @override
  String get warningDetailsUntilFurtherNotice => 'hasta nuevo aviso';

  @override
  String warningDetailsLevel(String severity) {
    return 'Nivel de aviso: $severity';
  }

  @override
  String get warningDetailsAffectedRegions => 'Región(es) afectada(s)';

  @override
  String get warningDetailsNoInstructions =>
      'Este aviso no incluía acciones recomendadas.';

  @override
  String get warningDetailsNoArea =>
      'La fuente del aviso no detalló más la zona afectada.';

  @override
  String get warningDetailsSource => 'Fuente del aviso y publicación';

  @override
  String get warningDetailsRelevance => 'Por qué se muestra este aviso';

  @override
  String get warningRelevanceOwnDistrict => 'Afecta a tu propio distrito.';

  @override
  String get warningRelevanceFollowedDistrict =>
      'Afecta a un distrito adicional guardado.';

  @override
  String get warningRelevanceOwnState => 'Afecta a tu estado federado.';

  @override
  String get warningRelevanceFollowedState =>
      'Afecta a un estado federado adicional guardado.';

  @override
  String get warningRelevanceNationwide =>
      'Se aplica en todo el país o la fuente no nombra una zona más precisa.';

  @override
  String get warningRelevanceNoPlaces =>
      'No hay ningún lugar de avisos configurado, así que la app muestra los avisos de Alemania.';

  @override
  String get warningRelevanceOtherRegion =>
      'No está asignado a ninguna de tus regiones guardadas.';

  @override
  String warningDetailsPublished(String time) {
    return 'Publicado: $time';
  }

  @override
  String get warningDetailsOfflineHint =>
      'El mapa, la zona y las acciones recomendadas se guardaron con este aviso y se pueden leer sin conexión.';

  @override
  String get knowledgeBrowseTitle => 'Explorar el archivo';

  @override
  String get knowledgeBrowseBody =>
      'Abre la página principal, elige una letra inicial o descubre un artículo al azar.';

  @override
  String get knowledgeMainPageAction => 'Página principal';

  @override
  String get knowledgeRandomAction => 'Artículo al azar';

  @override
  String knowledgeArchiveStats(int articles, String size) {
    return '$articles entradas · unos $size';
  }

  @override
  String knowledgeTotalSize(String size) {
    return 'Tamaño total: unos $size';
  }

  @override
  String get knowledgeDocumentsTitle => 'Documentos personales';

  @override
  String get knowledgeDocumentsIntro =>
      'Los archivos PDF, EPUB y Markdown se quedan en su ubicación original y no se duplican.';

  @override
  String get knowledgeDocumentAdd => 'Añadir documento';

  @override
  String get knowledgeDocumentAddFolder => 'Añadir carpeta';

  @override
  String get knowledgeDocumentFolderScope =>
      'Se incorporan los archivos PDF, EPUB y Markdown que están directamente en esta carpeta, sin subcarpetas.';

  @override
  String knowledgeDocumentFolderFound(int found) {
    return '$found archivos encontrados';
  }

  @override
  String knowledgeDocumentFolderLimit(int limit) {
    return 'Se incorporarán los primeros $limit.';
  }

  @override
  String get knowledgeDocumentFolderEmpty =>
      'En esta carpeta no hay archivos PDF, EPUB ni Markdown.';

  @override
  String get knowledgeDocumentFolderUnreadable =>
      'No se ha podido leer la carpeta.';

  @override
  String knowledgeDocumentFolderAdded(int added, int known) {
    return '$added añadidos nuevos, $known ya estaban en la biblioteca';
  }

  @override
  String knowledgeDocumentFolderProgress(int done, int total) {
    return '$done de $total leídos';
  }

  @override
  String get knowledgeDocumentFolderOnComputer =>
      'En un ordenador se pueden añadir carpetas enteras; en un teléfono, un archivo cada vez.';

  @override
  String get knowledgeDocumentsEmpty =>
      'Aún no se han añadido documentos personales.';

  @override
  String get knowledgeDocumentRemove => 'Quitar de la biblioteca';

  @override
  String get knowledgeDocumentOpenFailed =>
      'No se ha podido abrir el documento.';

  @override
  String get knowledgeDocumentOpenExternal => 'Abrir externamente';

  @override
  String get knowledgeDocumentContinue => 'Seguir leyendo';

  @override
  String get emergencyDirectoryTitle =>
      'Llamadas de emergencia, contactos y radio';

  @override
  String get emergencyMedicalService => 'Servicio médico de guardia 116117';

  @override
  String get emergencyPoisonTitle => 'Centros de información toxicológica';

  @override
  String get emergencyPoisonHint =>
      'Ante síntomas que ponen en peligro la vida, llama primero al 112. El centro toxicológico competente asesora en caso de sospecha de intoxicación.';

  @override
  String get emergencyRadioTitle => 'Rangos de frecuencia de radio';

  @override
  String get emergencyRadioHint =>
      'Las frecuencias de las emisoras locales cambian. Durante un incidente haz una búsqueda de emisoras y sigue los anuncios oficiales. Transmite solo donde el servicio de radio correspondiente lo permita.';

  @override
  String get emergencySirenTitle => 'Señales de sirena';

  @override
  String get emergencySirenHint =>
      'Recomendadas en todo el país, pero no reguladas igual en todas partes: en caso de duda, cuenta lo que anunció tu propio municipio. A cada aviso le sigue lo mismo: entrar en un edificio, cerrar las ventanas, encender la radio.';

  @override
  String get emergencySirenWarning =>
      'Sonido ascendente y descendente, un minuto';

  @override
  String get emergencySirenWarningMeaning =>
      'Aviso. Peligro cerca. Entra en un edificio, cierra ventanas y puertas, enciende la radio y espera los anuncios.';

  @override
  String get emergencySirenAllClear => 'Tono continuo y uniforme, un minuto';

  @override
  String get emergencySirenAllClearMeaning =>
      'Fin de la alerta. El peligro ha pasado. Llega por la misma vía que el aviso.';

  @override
  String get emergencySirenFire => 'Tono interrumpido dos veces, un minuto';

  @override
  String get emergencySirenFireMeaning =>
      'Alarma de bomberos. Llama a los efectivos y no va dirigida a la población: no hay que hacer nada.';

  @override
  String get emergencyContactsTitle => 'Contactos de emergencia cercanos';

  @override
  String get emergencyContactsEmpty =>
      'Aún no hay contactos cercanos guardados.';

  @override
  String get emergencyContactAdd => 'Añadir contacto';

  @override
  String get emergencyContactName => 'Nombre';

  @override
  String get emergencyContactPhone => 'Número de teléfono';

  @override
  String get emergencyContactAddress => 'Dirección';

  @override
  String get emergencyContactCoordinates => 'Coordenadas (latitud, longitud)';

  @override
  String get emergencyContactEdit => 'Editar contacto';

  @override
  String get emergencyContactDelete => 'Eliminar contacto';

  @override
  String get emergencyOpenMapAction => 'Abrir en el mapa';

  @override
  String get prepperRecipesTitle => 'Recetas de emergencia';

  @override
  String get prepperRecipesIntro =>
      'Comidas sencillas con provisiones de larga duración, usando poca agua y energía. Ajusta las cantidades al hogar.';

  @override
  String get preservationTitle => 'Conservar alimentos';

  @override
  String get preservationIntro =>
      'Métodos probados para los alimentos que tienes. Trabaja con limpieza, respeta los tiempos de procesado seguros y desecha los tarros abombados o sospechosos.';

  @override
  String get storageOfficialCalculator =>
      'Abrir la calculadora oficial de provisiones';

  @override
  String get storageOfficialTips =>
      'Más consejos sobre provisiones de alimentos';

  @override
  String get resetTitle => 'Restablecer';

  @override
  String get resetSettings => 'Restablecer los ajustes de la app';

  @override
  String get resetSettingsHint =>
      'Restaura los valores por defecto de idioma, apariencia, notificaciones, recordatorios y proveedor de mapas. Los datos y las descargas se conservan.';

  @override
  String get resetHousehold => 'Eliminar el hogar y los datos locales';

  @override
  String get resetHouseholdHint =>
      'Elimina de forma permanente de este dispositivo las provisiones, listas, plan de emergencia y tarjetas de emergencia de este hogar.';

  @override
  String get resetConfirmTitle => '¿Restablecer ahora?';

  @override
  String get resetConfirmHousehold =>
      'Los datos locales del hogar se eliminarán de forma permanente. Si hace falta, crea antes una copia de seguridad.';

  @override
  String get resetDone => 'Restablecimiento completado.';

  @override
  String get knowledgeDocumentIndexTitle => 'Búsqueda sin conexión';

  @override
  String get knowledgeDocumentIndexOption =>
      'Hacer que este documento se pueda buscar';

  @override
  String get knowledgeDocumentIndexPrivacy =>
      'El índice de texto se queda solo en este dispositivo. El archivo original no se copia.';

  @override
  String get knowledgeDocumentIndexed => 'Listo para la búsqueda sin conexión';

  @override
  String get knowledgeDocumentIndexing => 'Creando el índice …';

  @override
  String get knowledgeDocumentNotIndexed => 'No está en la búsqueda';

  @override
  String get knowledgeDocumentNoText =>
      'Sin texto legible (posiblemente un escaneo)';

  @override
  String knowledgeDocumentTooLarge(String limit) {
    return 'Demasiado grande para el índice (máximo $limit)';
  }

  @override
  String get knowledgeDocumentIndexFailed => 'No se ha podido crear el índice';

  @override
  String get knowledgeDocumentReindex => 'Volver a crear el índice de búsqueda';

  @override
  String get knowledgeDocumentChanged =>
      'Archivo modificado, índice de búsqueda desactualizado';

  @override
  String knowledgeDocumentChangedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count documentos han cambiado desde que se indexaron. La búsqueda todavía encuentra su contenido antiguo.',
      one: 'Un documento ha cambiado desde que se indexó. La búsqueda todavía encuentra su contenido antiguo.',
    );
    return '$_temp0';
  }

  @override
  String get knowledgeDocumentRefreshChanged => 'Actualizar índice';

  @override
  String get knowledgeDocumentClearIndex => 'Eliminar el índice de búsqueda';

  @override
  String get knowledgeDocumentClearIndexBody =>
      'Se eliminarán los datos de búsqueda de todos los documentos personales. Los archivos originales no se tocan.';

  @override
  String knowledgeDocumentIndexSummary(int indexed, int total) {
    return '$indexed de $total documentos se pueden buscar';
  }

  @override
  String get knowledgePersonalResults => 'Documentos personales';

  @override
  String get knowledgePersonalResultHint =>
      'Resultados del índice local de documentos';

  @override
  String get radioEmergencyTitle => 'Frecuencias de radio de emergencia';

  @override
  String get radioEmergencyEntryHint =>
      'PMR446, Freenet, CB y radioafición: frecuencias, normas e indicaciones';

  @override
  String get radioEmergencyIntro =>
      'El 112 sigue siendo la primera vía para las emergencias. Las frecuencias de radio son un posible recurso alternativo cuando hay equipos homologados; no se vigilan de forma permanente.';

  @override
  String get radioCbTitle => 'Radio CB: canales de llamada y de ayuda';

  @override
  String get radioCbHintsTitle => 'Indicaciones para la radio CB';

  @override
  String get radioCbRule =>
      'En Alemania la radio CB tiene asignación general. Usa solo equipos homologados y respeta los requisitos de potencia, modo y antena.';

  @override
  String get radioAmateurTitle =>
      'Radioafición: centros de actividad de emergencia de la IARU';

  @override
  String get radioLegalTitle => 'Aviso legal';

  @override
  String get radioAmateurLegal =>
      'En Alemania la radioafición solo puede practicarse con una licencia de radioaficionado válida. Estas frecuencias son centros de información y actividad, no servicios de emergencia garantizados.';

  @override
  String get radioNoGuaranteedMonitoring =>
      'No esperes respuesta: llama siempre primero al 112 cuando esté disponible.';

  @override
  String get radioListenFirst =>
      'Escucha un buen rato antes de transmitir. No interfieras en el tráfico de emergencia en curso.';

  @override
  String get radioEmergencyCall =>
      'Llama solo en una emergencia real. Indica primero la ubicación, el peligro y la ayuda necesaria; de forma breve y clara.';

  @override
  String get radioUseHintsTitle => 'Indicaciones de uso';

  @override
  String get radioBriefMessage =>
      'Usa la potencia de transmisión más baja posible, confirma la recepción y acuerda horas fijas de contacto cuando escasee la energía.';

  @override
  String get radioOfficialRules =>
      'Abrir las normas de la Agencia Federal de Redes';

  @override
  String get radioIaruSource =>
      'Abrir las frecuencias de emergencia de DARC / IARU';

  @override
  String get knowledgeApolloTitle => 'Base de conocimiento APOLLO';

  @override
  String get knowledgeApolloMissionTitle =>
      'Conocimiento para circunstancias excepcionales';

  @override
  String get knowledgeApolloMissionBody =>
      'Crea una biblioteca local para la acción práctica, el conocimiento básico y el aprendizaje en casa. Los archivos se quedan en tu dispositivo y se pueden leer sin conexión a internet.';

  @override
  String get knowledgeApolloReady => 'Biblioteca sin conexión abierta y lista';

  @override
  String get knowledgeApolloNotReady => 'Aún no hay ningún archivo abierto';

  @override
  String knowledgeApolloStatus(int count, String size) {
    return '$count archivos registrados · tamaño conocido: $size';
  }

  @override
  String get knowledgeApolloStatusHint =>
      'La barra es una guía para ocho archivos básicos recomendados; tú eliges el tamaño y la selección.';

  @override
  String get knowledgeApolloDownloadedTitle => 'Contenido descargado';

  @override
  String get knowledgeApolloDownloaded => 'Descargado';

  @override
  String get knowledgeApolloOpened => 'Abrir';

  @override
  String get knowledgeApolloStartTitle => 'Primero el conocimiento práctico';

  @override
  String get knowledgeApolloStartBody =>
      'Empieza por temas que ayudan directamente durante una interrupción. Después añade formación escolar y fundamentos.';

  @override
  String get knowledgeApolloMedicalTitle => 'Medicina y primeros auxilios';

  @override
  String get knowledgeApolloMedicalBody =>
      'Usa WikiMed para consultar directamente nociones médicas básicas y primeros auxilios. No sustituye a la atención de emergencia ni a la atención médica profesional.';

  @override
  String get knowledgeApolloSurvivalTitle =>
      'Supervivencia, bushcraft y autosuficiencia';

  @override
  String get knowledgeApolloSurvivalBody =>
      'Potabilizar agua, refugio, saneamiento y salud tras una catástrofe, tecnología apropiada y reparaciones: las colecciones de agua y de ayuda tras catástrofes y Appropedia (en inglés), además de iFixit.';

  @override
  String get knowledgeApolloRepairTitle => 'Oficio, energía y reparación';

  @override
  String get knowledgeApolloRepairBody =>
      'Herramientas, reparaciones, tecnología sencilla y oficios prácticos: conocimiento que mantiene los equipos y las provisiones útiles durante más tiempo.';

  @override
  String get knowledgeApolloFoundationsTitle => 'Fundamentos y educación';

  @override
  String get knowledgeApolloBasicsTitle =>
      'Naturaleza, sociedad y conocimiento básico';

  @override
  String get knowledgeApolloBasicsBody =>
      'Matemáticas, lengua, ciencias, historia y artículos de fondo fiables para consultar.';

  @override
  String get knowledgeApolloSchoolTitle => 'Aprender en casa';

  @override
  String get knowledgeApolloSchoolBody =>
      'Explicaciones para niños, libros, ejercicios y simulaciones para aprender de forma estructurada sin red.';

  @override
  String get knowledgeApolloAdvancedTitle => 'Estudios avanzados y currículo';

  @override
  String get knowledgeApolloAdvancedBody =>
      'Cursos más amplios para temas avanzados. Los recursos en inglés están marcados como complemento.';

  @override
  String get knowledgeApolloPersonalTitle => 'Añadir material propio';

  @override
  String get knowledgeApolloPersonalBody =>
      'Añade archivos locales PDF, EPUB y Markdown y pon el texto legible a disposición de la búsqueda de texto completo sin conexión.';

  @override
  String get knowledgeApolloDownloadHint =>
      'Abre la biblioteca de Kiwix con una búsqueda adecuada. Comprueba el idioma, la edición y el espacio necesario antes de descargar.';

  @override
  String get statusSupplyTitle => 'Provisiones';

  @override
  String statusSupplyCovered(int days) {
    return 'Alcanzan para $days días';
  }

  @override
  String statusSupplyShort(int days, int target) {
    return 'Alcanzan para $days de $target días';
  }

  @override
  String get statusSupplyUnknown => 'Aún no hay nada registrado';

  @override
  String statusSupplyBasis(int target) {
    return 'Según las propias cifras de la BBK: $target días, 2 l y 2200 kcal por persona y día.';
  }

  @override
  String statusSupplyUncounted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas no se cuentan',
      one: 'Una entrada no se cuenta',
    );
    return '$_temp0: su unidad no nombra ninguna medida.';
  }

  @override
  String get statusSituationTitle => 'Situación';

  @override
  String get statusSituationQuiet => 'Ningún aviso oficial';

  @override
  String get statusSituationQuietHint =>
      'Las autoridades publican avisos, no confirmaciones de que todo va bien. Que no haya ninguno en vigor no significa que no pase nada.';

  @override
  String statusSituationActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avisos',
      one: 'Un aviso',
    );
    return '$_temp0 para tu zona';
  }

  @override
  String homeWidgetUpdated(String time) {
    return 'A las: $time';
  }

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHint => 'Pantalla, provisión, punto de lista …';

  @override
  String get searchStartHint =>
      'Escribe para buscar en toda la app: pantallas, provisiones, puntos de listas y el inventario del hogar.';

  @override
  String searchNothingFound(String query) {
    return 'No se ha encontrado nada para «$query».';
  }

  @override
  String get searchAction => 'Buscar';

  @override
  String get searchGroupScreens => 'Pantallas';

  @override
  String get searchGroupInventory => 'Provisiones';

  @override
  String get searchGroupChecklists => 'Listas de control';

  @override
  String get searchGroupPossessions => 'Inventario del hogar';

  @override
  String get settingsVersionInfoFirstAid => 'Contenido de primeros auxilios';

  @override
  String get settingsVersionInfoFirstAidValue =>
      'Estado de fuentes ERC 2025 (edición GRC)';

  @override
  String get settingsVersionInfoApp => 'App PreppSuite';

  @override
  String settingsVersionInfoAppValue(String version, String build) {
    return '$version · compilación $build';
  }

  @override
  String get settingsVersionInfoDatabase => 'Base de datos del hogar';

  @override
  String get settingsVersionInfoKnowledgeIndex =>
      'Índice de texto completo de los archivos de conocimiento';

  @override
  String get settingsVersionInfoDocumentsIndex =>
      'Índice de texto completo de documentos';

  @override
  String settingsVersionInfoSchema(int version) {
    return 'Esquema $version';
  }

  @override
  String get settingsVersionInfoOfflineMap => 'Formato del mapa sin conexión';

  @override
  String get settingsVersionInfoPmtiles => 'PMTiles v3';

  @override
  String get settingsVersionInfoUnavailable => 'No disponible';

  @override
  String get readinessOpenDashboard => 'Comprobar la preparación';

  @override
  String get readinessDashboardHint =>
      'Paquetes sin conexión y actualidad de los datos de avisos';

  @override
  String readinessSummary(int ready, int total) {
    return '$ready de $total áreas listas';
  }

  @override
  String get readinessSummaryHint =>
      'Resuelve lo que falta antes de un incidente y repite la comprobación tras cambios en el dispositivo.';

  @override
  String get readinessOfflinePackages => 'Paquetes sin conexión';

  @override
  String get readinessPackageReady => 'Abierto y legible';

  @override
  String get readinessPackageMissing => 'Sin configurar o ilegible';

  @override
  String readinessArchivesReady(int count) {
    return '$count archivos registrados; el archivo elegido está abierto';
  }

  @override
  String get readinessWarningData => 'Datos oficiales de avisos';

  @override
  String get readinessWarningNeverUpdated =>
      'Aún no hay ninguna actualización completa en este dispositivo';

  @override
  String readinessWarningUpdated(String age) {
    return 'Última actualización completa: $age';
  }

  @override
  String get readinessWarningBlocked =>
      'La última actualización en segundo plano no pudo acceder a los datos locales.';

  @override
  String get readinessBackup => 'Copia de seguridad comprobada';

  @override
  String get readinessBackupNeverVerified =>
      'En este dispositivo aún no se ha abierto ni comprobado con éxito ninguna copia de seguridad';

  @override
  String readinessBackupVerified(String age) {
    return 'Copia de seguridad abierta con éxito: $age';
  }

  @override
  String readinessBackupStale(String age) {
    return 'Última comprobación de copia de seguridad: $age; vuelve a comprobar antes de hacer cambios';
  }

  @override
  String readinessMapReadyNoPlaces(String label) {
    return '$label es legible; no hay lugares guardados para comprobar la cobertura';
  }

  @override
  String readinessMapCoverage(int covered, int total, String label) {
    return '$covered de $total lugares guardados están cubiertos por $label';
  }

  @override
  String get readinessJustNow => 'ahora mismo';

  @override
  String readinessMinutesAgo(int minutes) {
    return 'hace $minutes minutos';
  }

  @override
  String readinessHoursAgo(int hours) {
    return 'hace $hours horas';
  }

  @override
  String readinessDaysAgo(int days) {
    return 'hace $days días';
  }

  @override
  String get emergencyPlanExport => 'Plan de emergencia en PDF';

  @override
  String get emergencyPlanPdfCards => 'Tarjetas de emergencia';

  @override
  String get emergencyPlanPdfCardsWarning =>
      'Esta hoja contiene datos de salud: grupo sanguíneo, alergias, medicación y enfermedades previas. Quien la coja puede leerlos, y ningún bloqueo protege un papel. Guárdala donde guardas tus documentos, llévala contigo en lugar de dejarla atrás y destrúyela en vez de tirarla.';

  @override
  String get emergencyPlanCardsAskTitle =>
      '¿Imprimir también las tarjetas de emergencia?';

  @override
  String emergencyPlanCardsAskBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: 'una persona',
    );
    return 'En papel, las tarjetas funcionan cuando el teléfono está sin batería o ha desaparecido, que es la razón de tenerlas. También significa una hoja suelta con el grupo sanguíneo, las alergias, la medicación y las enfermedades previas de $_temp0. Nada en papel se puede revocar, borrar a distancia ni proteger con contraseña.';
  }

  @override
  String get emergencyPlanCardsAskWithout => 'Solo el plan';

  @override
  String get emergencyPlanCardsAskWith => 'Incluir las tarjetas';

  @override
  String get emergencyPlanPdfTitle => 'Plan de emergencia personal';

  @override
  String get emergencyPlanPdfMeetingPoints => 'Puntos de encuentro';

  @override
  String get emergencyPlanPdfContact => 'Contacto fuera de la zona';

  @override
  String get emergencyPlanPdfEquipment =>
      'Equipo de emergencia y puntos de corte';

  @override
  String get emergencyPlanPdfEmpty => 'Sin rellenar';

  @override
  String get settingsRegionUnknownKey => 'Clave desconocida: compruébala';

  @override
  String get settingsRegionKeyInvalid =>
      'Introduce cinco o doce cifras (por ejemplo 03101).';

  @override
  String get shelterOverpassBusyMessage =>
      'OpenStreetMap/Overpass está ocupado ahora mismo (límite de peticiones). Inténtalo de nuevo dentro de unos segundos.';

  @override
  String shelterSourceFailureReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String shelterCachedAt(Object date, Object time) {
    return 'Se muestran datos de refugios guardados del $date, $time, porque al menos una fuente no está disponible ahora mismo.';
  }

  @override
  String get appLockTitle => 'Bloqueo de la app';

  @override
  String get appLockDisabledHint =>
      'Protege la app con una frase de contraseña propia cuando sales de ella.';

  @override
  String get appLockEnabledHint =>
      'La frase de contraseña se pide al volver a la app.';

  @override
  String get appLockSetTitle => 'Configurar el bloqueo de la app';

  @override
  String get appLockDisableTitle => 'Desactivar el bloqueo de la app';

  @override
  String get appLockDialogHint =>
      'La frase de contraseña no se guarda. Protege el acceso a la app abierta.';

  @override
  String get appLockPassphraseLabel => 'Frase de contraseña';

  @override
  String get appLockConfirmLabel => 'Repetir la frase de contraseña';

  @override
  String get appLockPassphraseTooShort =>
      'La frase de contraseña debe tener al menos 12 caracteres.';

  @override
  String get appLockPassphraseMismatch =>
      'Las frases de contraseña no coinciden.';

  @override
  String get appLockEnableButton => 'Activar el bloqueo';

  @override
  String get appLockDisableButton => 'Desactivar el bloqueo';

  @override
  String get appLockUnlockTitle => 'Desbloquear PreppSuite';

  @override
  String get appLockUnlockButton => 'Desbloquear';

  @override
  String get appLockIncorrectPassphrase =>
      'La frase de contraseña no es correcta.';

  @override
  String get appLockEnabled => 'El bloqueo de la app está activo.';

  @override
  String get appLockDisabled => 'El bloqueo de la app está desactivado.';

  @override
  String get appLockStatusUnavailableTitle =>
      'Estado del bloqueo no disponible';

  @override
  String get appLockStatusUnavailableBody =>
      'Ahora mismo no se puede leer de forma segura el estado del bloqueo. La app sigue cerrada hasta que vuelva a estar disponible.';

  @override
  String get appLockSettingsUnavailable =>
      'Ahora mismo no se puede leer de forma segura el estado del bloqueo.';

  @override
  String get appLockRetry => 'Volver a intentarlo';

  @override
  String get kiwixLanguageSearchHint => 'Buscar idioma';

  @override
  String kiwixLanguageCount(int count) {
    return '$count idiomas';
  }

  @override
  String get kiwixLanguageNoMatch => 'No se ha encontrado ningún idioma.';

  @override
  String kiwixLanguageArchives(int count) {
    return '$count archivos';
  }

  @override
  String downloadRemainingHours(int hours, int minutes) {
    return 'quedan $hours h $minutes min';
  }

  @override
  String downloadRemainingMinutes(int minutes) {
    return 'quedan $minutes min';
  }

  @override
  String downloadRemainingSeconds(int seconds) {
    return 'quedan $seconds s';
  }

  @override
  String get articleLoadFailed => 'No se ha podido cargar la página.';

  @override
  String articleHttpStatus(String status) {
    return 'El archivo respondió con $status.';
  }

  @override
  String get articleReload => 'Recargar';

  @override
  String get knowledgeArchiveNoCover => 'Sin portada en este archivo';

  @override
  String get radiationTitle => 'Radiación gamma';

  @override
  String get radiationEntryHint =>
      'Tasa de dosis ambiental en una estación de medición de la BfS';

  @override
  String get radiationNoneChosen => 'Aún no has elegido ninguna estación';

  @override
  String get radiationChoose => 'Elegir una estación';

  @override
  String get radiationChange => 'Otra estación';

  @override
  String get radiationRefresh => 'Actualizar';

  @override
  String get radiationSearchHint => 'Lugar o código postal';

  @override
  String get radiationSearchEmpty => 'No se ha encontrado ninguna estación.';

  @override
  String get radiationLoadFailed => 'No se han podido cargar las mediciones.';

  @override
  String get radiationOffline =>
      'Último valor conocido. No se ha podido acceder al servicio de la BfS.';

  @override
  String get radiationStale =>
      'Tiene más de dos horas. La red informa cada hora, así que falta la conexión, no es un valor estable.';

  @override
  String get radiationUnvalidated =>
      'Valor bruto sin revisar. La BfS publica primero las mediciones horarias sin revisar; un fallo técnico parece una medición.';

  @override
  String radiationMeasuredAt(String time) {
    return 'Medido hasta $time';
  }

  @override
  String radiationHeight(String metres) {
    return '$metres m sobre el nivel del mar';
  }

  @override
  String radiationPostalCode(String code) {
    return 'Código postal $code';
  }

  @override
  String radiationBaseline(String value) {
    return 'Lo habitual en esta estación: $value µSv/h';
  }

  @override
  String radiationNoBaseline(String floor, String ceiling) {
    return 'Esta estación aún no tiene un valor de referencia propio, así que la medición se compara con el rango natural nacional de $floor a $ceiling µSv/h, que es más grueso: en la Selva Negra 0,16 µSv/h es completamente normal.';
  }

  @override
  String radiationSplit(String terrestrial, String cosmic) {
    return 'De ellos, $terrestrial µSv/h del suelo y $cosmic µSv/h del espacio';
  }

  @override
  String get radiationBandOrdinary => 'Normal para esta estación';

  @override
  String get radiationBandWeather =>
      'Elevado, lo que es normal después de llover';

  @override
  String get radiationBandUnusual => 'Más de lo que explica el tiempo';

  @override
  String get radiationBandUnknown =>
      'Por encima del rango natural, sin valor de referencia propio';

  @override
  String get radiationWeatherExplained =>
      'La lluvia arrastra del aire los productos de desintegración del radón y eleva la medición hasta el triple durante unas horas. Es inofensivo y baja por sí solo; el periodo de semidesintegración es de unos 30 minutos. La nieve recién caída hace lo mismo, mientras que la nieve acumulada protege del suelo y baja la medición.';

  @override
  String get radiationUnusualExplained =>
      'Según la BfS, solo cabe pensar en un suceso radiológico cuando una medición claramente elevada se mantiene un día o más, o supera ese factor de tres, o cuando la sonda está averiada. Un valor aislado no es un aviso: un aviso oficial llegaría por los avisos de esta app.';

  @override
  String get radiationNoWarning =>
      'Esto es la medición y su contexto, no un aviso. Los avisos oficiales llegan por los avisos de esta app.';

  @override
  String get radiationSource =>
      'Fuente: Bundesamt für Strahlenschutz (BfS), red ODL. Datenlizenz Deutschland – Namensnennung 2.0.';

  @override
  String get fireDangerTitle => 'Peligro de incendio forestal';

  @override
  String get fireDangerEntryHint =>
      'El índice de peligro de incendio forestal del DWD para una estación';

  @override
  String get fireDangerNoneChosen => 'Aún no has elegido ninguna estación';

  @override
  String get fireDangerChoose => 'Elegir una estación';

  @override
  String get fireDangerChange => 'Otra estación';

  @override
  String get fireDangerRefresh => 'Actualizar';

  @override
  String get fireDangerSearchHint => 'Lugar o estado federado';

  @override
  String get fireDangerSearchEmpty => 'No se ha encontrado ninguna estación.';

  @override
  String get fireDangerLoadFailed =>
      'No se ha podido cargar el índice de peligro de incendio forestal.';

  @override
  String get fireDangerOffline =>
      'Último estado conocido. No se ha podido acceder al servidor del DWD.';

  @override
  String fireDangerStale(String date) {
    return 'Esto es del $date y no de hoy. El DWD solo emite el índice durante la temporada de incendios, más o menos de marzo a octubre; fuera de ella no llega nada nuevo.';
  }

  @override
  String fireDangerStep(int step) {
    return 'Nivel $step de 5';
  }

  @override
  String fireDangerIssuedFor(String date) {
    return 'Emitido para el $date';
  }

  @override
  String get fireDangerLevel1 => 'Peligro muy bajo';

  @override
  String get fireDangerLevel2 => 'Peligro bajo';

  @override
  String get fireDangerLevel3 => 'Peligro moderado';

  @override
  String get fireDangerLevel4 => 'Peligro alto';

  @override
  String get fireDangerLevel5 => 'Peligro muy alto';

  @override
  String get fireDangerAhead => 'Los próximos días';

  @override
  String fireDangerPeak(int step, int days) {
    return 'Sube al nivel $step dentro de $days días';
  }

  @override
  String fireDangerPeakTomorrow(int step) {
    return 'Sube al nivel $step mañana';
  }

  @override
  String get fireDangerToday => 'Hoy';

  @override
  String fireDangerInDays(int days) {
    return 'Dentro de $days días';
  }

  @override
  String get fireDangerTomorrow => 'Mañana';

  @override
  String get fireDangerNoWarning =>
      'El índice describe el potencial meteorológico de incendio forestal. No es un aviso ni una prohibición de entrar en el bosque; las prohibiciones las dictan los estados federados, y los avisos oficiales llegan por los avisos de esta app.';

  @override
  String get fireDangerSource =>
      'Fuente: Deutscher Wetterdienst (DWD), índice de peligro de incendio forestal WBI.';

  @override
  String fireDangerState(String state) {
    return 'Estado federado $state';
  }

  @override
  String get nearbyTitle => 'Cerca';

  @override
  String get nearbyEntryHint =>
      'Farmacia, agua, combustible: del mapa descargado, sin red.';

  @override
  String nearbySearchFrom(String place) {
    return 'Buscando alrededor de $place';
  }

  @override
  String get nearbyMapCentre => 'el centro del mapa';

  @override
  String get nearbyMyPosition => 'tu posición';

  @override
  String get nearbyUseMyLocation => 'Usar mi ubicación';

  @override
  String get nearbyFromOwnPlace => 'O busca desde uno de tus propios lugares:';

  @override
  String get nearbyNoCentre => 'Aún no has elegido ningún punto';

  @override
  String get nearbyNoCentreWhy =>
      'Esta búsqueda necesita un punto de partida. Usa tu posición, o abre el mapa, muévelo a la zona y busca desde ahí.';

  @override
  String get nearbyOpenMap => 'Abrir el mapa';

  @override
  String get nearbyRadius => 'Radio';

  @override
  String nearbyRadiusKm(int km) {
    return '$km km';
  }

  @override
  String nearbySearching(int done, int total) {
    return '$done de $total teselas leídas';
  }

  @override
  String get nearbyNothingFound => 'No se ha encontrado nada.';

  @override
  String get nearbyNothingFoundWhy =>
      'El mapa no contiene ninguno de estos puntos en este radio. Un radio mayor puede ayudar, o la zona solo se descargó con poco detalle.';

  @override
  String get nearbyNoArchive => 'No hay ningún mapa descargado';

  @override
  String get nearbyNoArchiveWhy =>
      'Esta búsqueda lee el mapa que hay en este dispositivo. Sin un mapa descargado no hay nada en lo que buscar.';

  @override
  String get nearbyDownloadMap => 'Descargar un mapa';

  @override
  String get nearbyTooShallow => 'El mapa no llega a suficiente detalle';

  @override
  String get nearbyTooShallowWhy =>
      'Los puntos individuales aparecen a partir del nivel de zoom 14. Este archivo se queda antes: dibuja un mapa perfectamente bueno y no contiene ni una farmacia. Vuelve a descargar la zona con más nivel de detalle.';

  @override
  String get nearbyOutsideArchive => 'Fuera de la zona descargada';

  @override
  String get nearbyOutsideArchiveWhy =>
      'Este punto no está dentro de lo descargado. El mapa no sabe nada aquí, ni siquiera que falte algo.';

  @override
  String get nearbyCaveats =>
      'Solo se puede encontrar lo que se descargó y lo que voluntarios introdujeron en OpenStreetMap. Que un punto esté en el mapa no garantiza que esté abierto, abastecido o atendido.';

  @override
  String get nearbyShelterNote =>
      'En OpenStreetMap, un «shelter» es casi siempre una marquesina de autobús o un refugio de montaña, no un refugio de protección. Por eso este tipo no se lista aquí.';

  @override
  String get nearbyKindWater => 'Agua';

  @override
  String get nearbyKindHealth => 'Salud';

  @override
  String get nearbyKindFood => 'Alimentos';

  @override
  String get nearbyKindFuel => 'Combustible y electricidad';

  @override
  String get nearbyKindHardware => 'Herramientas y materiales';

  @override
  String get nearbyKindHelp => 'Ayuda y autoridades';

  @override
  String get poiDrinkingWater => 'Agua potable';

  @override
  String get poiPharmacy => 'Farmacia';

  @override
  String get poiHospital => 'Hospital';

  @override
  String get poiClinic => 'Clínica';

  @override
  String get poiDoctors => 'Consulta médica';

  @override
  String get poiSupermarket => 'Supermercado';

  @override
  String get poiConvenience => 'Tienda de conveniencia';

  @override
  String get poiBakery => 'Panadería';

  @override
  String get poiButcher => 'Carnicería';

  @override
  String get poiGreengrocer => 'Frutería';

  @override
  String get poiMarketplace => 'Mercado';

  @override
  String get poiDeli => 'Charcutería';

  @override
  String get poiFuel => 'Gasolinera';

  @override
  String get poiChargingStation => 'Punto de carga';

  @override
  String get poiDoityourself => 'Tienda de bricolaje';

  @override
  String get poiHardware => 'Ferretería';

  @override
  String get poiFireStation => 'Parque de bomberos';

  @override
  String get poiPolice => 'Policía';

  @override
  String get poiTownhall => 'Ayuntamiento';

  @override
  String get poiCommunityCentre => 'Centro cívico';

  @override
  String get daylightTitle => 'Luz del día y luna';

  @override
  String get daylightEntryHint =>
      'Sol, crepúsculo y luna, calculados en el dispositivo, sin red.';

  @override
  String get daylightNoPlace => 'Aún no has fijado ningún lugar';

  @override
  String get daylightNoPlaceWhy =>
      'Dónde están el sol y la luna depende de dónde estés. Fija el lugar una vez: se recuerda y no hace falta nunca más.';

  @override
  String get daylightSetPlace => 'Fijar el lugar';

  @override
  String get daylightChangePlace => 'Cambiar el lugar';

  @override
  String get daylightCoordinates => 'Coordenadas';

  @override
  String get daylightCoordinatesHint => '52.2689, 10.5268';

  @override
  String get daylightCoordinatesBad =>
      'Dos números, latitud y longitud, por ejemplo 52.2689, 10.5268.';

  @override
  String get daylightPlaceName => 'Nombre (opcional)';

  @override
  String get daylightToday => 'Hoy';

  @override
  String get daylightTomorrow => 'Mañana';

  @override
  String get daylightSunrise => 'Salida del sol';

  @override
  String get daylightSunset => 'Puesta del sol';

  @override
  String get daylightSolarNoon => 'Mediodía solar';

  @override
  String get daylightCivilDawn => 'Primera luz';

  @override
  String get daylightCivilDusk => 'Última luz';

  @override
  String get daylightNauticalDawn => 'Empieza el crepúsculo';

  @override
  String get daylightNauticalDusk => 'Acaba el crepúsculo';

  @override
  String daylightDayLength(String duration) {
    return 'Duración del día $duration';
  }

  @override
  String daylightEveningTwilight(String duration) {
    return 'Después $duration de luz aprovechable';
  }

  @override
  String get daylightAlwaysUp => 'Hoy el sol no se pone.';

  @override
  String get daylightAlwaysDown => 'Hoy el sol no sale.';

  @override
  String get daylightMoon => 'Luna';

  @override
  String get daylightMoonrise => 'Salida de la luna';

  @override
  String get daylightMoonset => 'Puesta de la luna';

  @override
  String daylightMoonIllumination(int percent) {
    return '$percent % iluminada';
  }

  @override
  String get daylightMoonUpAllDay =>
      'La luna está sobre el horizonte todo el día.';

  @override
  String get daylightMoonDownAllDay =>
      'Hoy la luna no sale por encima del horizonte.';

  @override
  String get daylightMoonNoRise =>
      'Hoy no sale la luna: sale unos 50 minutos más tarde cada día.';

  @override
  String get daylightMoonNoSet => 'Hoy no se pone la luna.';

  @override
  String get daylightWhy =>
      'Sin interruptor de la luz, el sol marca la jornada, y que la luna esté arriba decide si se puede uno mover de noche. Las dos son preguntas con respuestas exactas, y ninguna se puede consultar sin red salvo que la respuesta ya esté en el dispositivo.';

  @override
  String get daylightAccuracy =>
      'Todo se calcula en el dispositivo, no se descarga nada. Comprobado con las tablas del Observatorio Naval de EE. UU.: en 112 horas comparadas, el sol y la luna se desvían como mucho un minuto. Las horas suponen un horizonte despejado; colinas, árboles y edificios las desplazan.';

  @override
  String get moonPhaseNew => 'Luna nueva';

  @override
  String get moonPhaseWaxingCrescent => 'Luna creciente';

  @override
  String get moonPhaseFirstQuarter => 'Cuarto creciente';

  @override
  String get moonPhaseWaxingGibbous => 'Gibosa creciente';

  @override
  String get moonPhaseFull => 'Luna llena';

  @override
  String get moonPhaseWaningGibbous => 'Gibosa menguante';

  @override
  String get moonPhaseLastQuarter => 'Cuarto menguante';

  @override
  String get moonPhaseWaningCrescent => 'Luna menguante';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get radioEverydayTitle => 'Radio sin licencia: PMR446 y Freenet';

  @override
  String get radioEverydayIntro =>
      'Las dos bandas que muchos hogares tienen de verdad. No necesitan registro ni examen, ni infraestructura: de aparato a aparato, de uno a pocos kilómetros. Precisamente por eso van aquí junto a la CB y la radioafición.';

  @override
  String get radioPmrTitle => 'PMR446';

  @override
  String get radioPmrRange => '446,0–446,2 MHz';

  @override
  String get radioPmrChannels =>
      '16 canales analógicos, separación de 12,5 kHz';

  @override
  String get radioPmrPower => 'Como máximo 0,5 W PRA';

  @override
  String get radioPmrAntenna => 'Solo antenas integradas';

  @override
  String get radioPmrPeerToPeer =>
      'Solo de aparato a aparato. Sin estación fija, sin repetidor, sin conexión a una red.';

  @override
  String get radioPmrSource =>
      'Bundesnetzagentur, Vfg. 91/2025 (asignación general para dispositivos de corto alcance), banda 83. Sustituye a la Vfg. 46/2020, válida hasta el 31 de diciembre de 2035. El plan de canales está en la norma armonizada, no en la asignación.';

  @override
  String get radioFreenetTitle => 'Freenet Deutschland';

  @override
  String get radioFreenetRange => '149,01875–149,11875 MHz';

  @override
  String get radioFreenetAnalogue =>
      '6 canales de 12,5 kHz, analógicos o digitales';

  @override
  String get radioFreenetDigital =>
      'Más 12 canales de 6,25 kHz, solo digitales';

  @override
  String get radioFreenetPower =>
      'Como máximo 1 W PRA. A menos de 10 km de las fronteras belga y polaca, solo 0,5 W.';

  @override
  String get radioFreenetHandheld =>
      'Radios portátiles con alimentación propia, manejables con una mano. No se permiten estaciones fijas.';

  @override
  String get radioFreenetAntenna =>
      'Solo la antena integrada o una intercambiable en la propia radio. No se permite una antena con cable coaxial ni en un mástil.';

  @override
  String get radioFreenetPeerToPeer =>
      'Solo de aparato a aparato. Sin repetidor, sin relé, sin pasarela a internet.';

  @override
  String get radioFreenetDuration =>
      'Sin transmisión continua. La norma corta a los 180 segundos; también por debajo, transmite solo lo necesario.';

  @override
  String get radioFreenetGermanyOnly =>
      'Esta asignación solo es válida en Alemania.';

  @override
  String get radioFreenetExtras => 'VOX y CTCSS están expresamente permitidos.';

  @override
  String get radioFreenetSource =>
      'Bundesnetzagentur, Vfg. 45/2025, corregida por la Mitt. 193/2025. En vigor desde el 1 de octubre de 2025, válida hasta el 30 de septiembre de 2035; sustituye a la Vfg. 60/2019.';

  @override
  String get radioCallingChannelTitle => 'No hay canal de llamada oficial';

  @override
  String get radioCallingChannelNone =>
      'Ni PMR446 ni Freenet tienen un canal de emergencia o de llamada fijado por el regulador. Lo que existe son convenciones entre usuarios, y no son uniformes.';

  @override
  String get radioCallingChannelThree =>
      'La más extendida es la iniciativa privada «Canal 3»: PMR446 446,03125 MHz, Freenet 149,0500 MHz, CB 26,985 MHz. Un número para las tres bandas. En otros sitios se usa el canal 1.';

  @override
  String get radioCallingChannelNoListener =>
      'No cuentes con que alguien escuche. Nadie está obligado a vigilar ninguno de estos canales.';

  @override
  String get energyTitle => 'Energía y combustible';

  @override
  String get energyEntryHint =>
      'Cuánto duran la electricidad, el gas, el combustible y la luz.';

  @override
  String get energyIntro =>
      'La app calcula cuánto duran los alimentos y el agua. Esta es la misma cuenta para lo que usas para cocinar, calentar e iluminar.';

  @override
  String get energyNothingYet => 'Aún no hay nada introducido';

  @override
  String get energyNothingYetWhy =>
      'Introduce lo que tienes y lo que lo consume. Las dos cifras vienen impresas en el propio objeto: «160 g/h» en el hornillo, «230 g» en el cartucho. Aquí no se estima nada por ti.';

  @override
  String get energyReserves => 'Almacenado';

  @override
  String get energyDraws => 'Consumido por';

  @override
  String get energyAddReserve => 'Añadir una reserva';

  @override
  String get energyAddDraw => 'Añadir un consumidor';

  @override
  String get energyEditReserve => 'Cambiar la reserva';

  @override
  String get energyEditDraw => 'Cambiar el consumidor';

  @override
  String get energyDelete => 'Eliminar';

  @override
  String get energyLabel => 'Nombre';

  @override
  String get energyKind => 'Tipo';

  @override
  String get energyAmount => 'Cantidad';

  @override
  String get energyPerHour => 'Consumo por hora';

  @override
  String get energyHoursPerDay => 'Horas al día';

  @override
  String get energyNumberNeeded => 'Un número mayor que cero.';

  @override
  String get energyLabelNeeded =>
      'Un nombre, para que la fila siga diciendo algo más adelante.';

  @override
  String energyDays(int days) {
    return '$days días';
  }

  @override
  String get energyOneDay => '1 día';

  @override
  String get energyZeroDays => 'No llega a un día';

  @override
  String energyPerDayIs(String amount, String unit, String stored) {
    return '$amount $unit al día de $stored $unit';
  }

  @override
  String get energyUnused =>
      'Almacenado, pero nada lo consume. Introduce el consumidor, o no hay nada que dividir.';

  @override
  String get energyEmpty => 'Algo lo consume y no hay nada.';

  @override
  String energyShortest(String kind, String days) {
    return 'Lo primero en agotarse: $kind – $days';
  }

  @override
  String get energyShortestWhy =>
      'Esa es la autonomía del hogar. Cuatro reservas, cada una con una cifra tranquilizadora, no son cuatro respuestas: cuenta la más pequeña.';

  @override
  String get energyNoAnswer =>
      'Aún no hay autonomía: cada reserva necesita un consumidor, o no hay nada que dividir.';

  @override
  String get energySources =>
      'Todas las cifras de aquí son tuyas. Esta app no estima ningún consumo: lo que consume un hornillo está escrito en el hornillo, y lo que consume un aparato, en su fuente de alimentación. Solo hace las cuentas.';

  @override
  String get energyKindElectricity => 'Electricidad';

  @override
  String get energyKindGas => 'Gas';

  @override
  String get energyKindLiquidFuel => 'Combustible líquido';

  @override
  String get energyKindSolidFuel => 'Combustible sólido';

  @override
  String get energyKindCandles => 'Velas';

  @override
  String get energyKindElectricityHint =>
      'Baterías externas, pilas, lo que da un día de sol: en vatios hora.';

  @override
  String get energyKindGasHint =>
      'Cartuchos y bombonas: en gramos, como indica su consumo un hornillo.';

  @override
  String get energyKindLiquidFuelHint =>
      'Gasolina, diésel, queroseno, aceite para lámparas, alcohol: en litros.';

  @override
  String get energyKindSolidFuelHint =>
      'Leña, briquetas, carbón, pellets: en kilos.';

  @override
  String get energyKindCandlesHint =>
      'En horas de combustión: unidades por el tiempo de combustión de cada una que indica el paquete.';

  @override
  String get energyUnitWattHours => 'Wh';

  @override
  String get energyUnitGrams => 'g';

  @override
  String get energyUnitLiters => 'l';

  @override
  String get energyUnitKilograms => 'kg';

  @override
  String get energyUnitHours => 'h';

  @override
  String get energyHelperTitle => 'Convertir';

  @override
  String get energyHelperGasBottle =>
      '¿Bombona en kilos? Por 1000 da gramos: 5 kg son 5000 g.';

  @override
  String get energyHelperCandles =>
      '¿Velas? Unidades por el tiempo de combustión de cada una. 40 velas de té de 4 horas son 160 horas.';

  @override
  String get energyHelperPowerbank =>
      '¿Batería externa en mAh? Por 3,7 V, dividido entre 1000, da vatios hora: 20000 mAh son 74 Wh. Ojo: eso es la celda, no el enchufe. Al elevar a 5 V se pierde algo; cuánto depende del aparato, por eso aquí no se da ningún porcentaje.';

  @override
  String get transferTitle => 'Transferir sin red';

  @override
  String get transferIntro =>
      'Un dispositivo muestra una serie de imágenes y el otro las graba. Sin red, sin carpeta compartida, sin emparejar: los dos dispositivos solo tienen que estar uno al lado del otro.';

  @override
  String get transferSend => 'Mostrar el hogar';

  @override
  String get transferReceive => 'Grabar el hogar';

  @override
  String get transferSendTitle => 'Mostrar el hogar';

  @override
  String get transferSendHint =>
      'Apunta la cámara del otro dispositivo a esta pantalla. Las imágenes van en bucle: la que se pierda vuelve a pasar sola.';

  @override
  String transferFrameOf(int index, int total) {
    return 'Imagen $index de $total';
  }

  @override
  String get transferSendNothing =>
      'Este hogar aún no tiene nada que se pueda transferir.';

  @override
  String get transferSlower => 'Más lento';

  @override
  String get transferFaster => 'Más rápido';

  @override
  String get transferReceiveTitle => 'Grabar el hogar';

  @override
  String get transferReceiveHint =>
      'Mantenlo apuntando a la pantalla del otro dispositivo y déjalo ahí hasta que esté completo.';

  @override
  String transferProgress(int received, int total) {
    return '$received de $total imágenes';
  }

  @override
  String get transferWaiting => 'Aún no se ha reconocido ninguna imagen.';

  @override
  String transferDone(int rows) {
    return 'Completo. $rows filas incorporadas.';
  }

  @override
  String get transferNothingNew => 'Completo. Todo ya se conocía.';

  @override
  String get transferBroken =>
      'Las imágenes no encajan entre sí. Vuelve a grabarlas.';

  @override
  String get transferWrongHousehold =>
      'Es otro hogar. Solo se incorpora lo que pertenece a este.';

  @override
  String get transferCameraNeeded => 'Para grabar hace falta la cámara.';

  @override
  String get transferSendOverNetwork => 'Por la red (rápido)';

  @override
  String get transferSendOverNetworkHint =>
      'Los dos dispositivos están en la misma red: wifi de casa, un punto de acceso, un camping. El código de aquí es la llave: solo entra quien lo graba. Todo el hogar pasa de una vez, en ambas direcciones.';

  @override
  String get transferSendWaiting => 'Esperando al otro dispositivo …';

  @override
  String get transferSendNoNetwork =>
      'Este dispositivo no está en ninguna red. Queda la serie de imágenes.';

  @override
  String get transferUseChain => 'Mostrar sin red';

  @override
  String get transferUseNetwork => 'Usar la red';

  @override
  String get transferSendChainHint =>
      'Sin red: apunta la cámara del otro dispositivo a esta pantalla. Las imágenes van en bucle: la que se pierda vuelve a pasar sola.';

  @override
  String transferHandoverDone(int rows) {
    return 'Sincronizado. $rows filas incorporadas.';
  }

  @override
  String transferHandoverPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Han venido $count fotos.',
      one: 'Ha venido una foto.',
    );
    return '$_temp0';
  }

  @override
  String get transferHandoverNothing =>
      'Sincronizado. Los dos dispositivos ya estaban en el mismo punto.';

  @override
  String get transferUnreachable =>
      'No se puede acceder al otro dispositivo. ¿Están los dos en la misma red?';

  @override
  String get portableTitle => 'Carpeta de datos';

  @override
  String get portableInstalled => 'En este equipo';

  @override
  String get portableInstalledHint =>
      'Hogar, provisiones, fotos y ajustes están donde este sistema operativo los guarda para los programas.';

  @override
  String get portableCarried => 'En un disco que llevas contigo';

  @override
  String portableSourceBeside(String folder) {
    return 'Encontrada como carpeta llamada «$folder» junto al programa.';
  }

  @override
  String get portableSourceChosen => 'Elegida una vez y recordada.';

  @override
  String portableSourceEnvironment(String variable) {
    return 'Indicada por la variable de entorno $variable.';
  }

  @override
  String portableExplain(String folder) {
    return 'Crea una carpeta llamada «$folder» junto al programa y el siguiente inicio la usará. No se crea nada por sí solo: una copia instalada se comporta exactamente como siempre.';
  }

  @override
  String get portableExplainMac =>
      'En macOS la app funciona en un entorno aislado, a propósito, porque eso evita que el sistema vuelva a pedir acceso a carpetas tras cada actualización. Una app aislada no puede leer una carpeta junto al programa. Por eso aquí la carpeta se elige una vez por Mac en lugar de encontrarse.';

  @override
  String get portableChoose => 'Elegir una carpeta';

  @override
  String get portableForget => 'Volver a este equipo';

  @override
  String get portableRestartNeeded => 'Se aplica en el siguiente inicio.';

  @override
  String get portableTakeover =>
      'La primera vez que se usa una carpeta nueva, la app incorpora una vez lo que hay en este equipo: copiado, no movido. La instalación de aquí no se toca.';

  @override
  String get portableRelativeNote =>
      'Los mapas, archivos y documentos que están en el mismo disco se recuerdan en relación con él. Se vuelven a encontrar aunque el disco aparezca con otra letra en el siguiente equipo.';

  @override
  String get portableFolderUnusable => 'No se puede escribir en esta carpeta.';

  @override
  String get portableChoiceMissingTitle => 'Falta la carpeta de datos elegida';

  @override
  String get portableChoiceMissingBody =>
      'Elegiste una vez una carpeta de datos y ahora no se puede acceder a ella. Hasta que vuelva, la app trabaja con los datos de este equipo: otro hogar. Lo que introduzcas ahora no estará en la carpeta que elegiste.';

  @override
  String portableChoiceMissingWhere(String path) {
    return 'Elegiste: $path';
  }

  @override
  String get portableChoiceMissingHint =>
      'Normalmente el disco no está conectado. Conéctalo y vuelve a iniciar la app.';

  @override
  String get portableUnsupported =>
      'Una carpeta de datos que se lleva consigo solo es posible en ordenadores, no en teléfonos: allí el sistema decide dónde viven los datos de una app.';

  @override
  String get articleReaderSimple => 'Vista sencilla';

  @override
  String get articleReaderWhy =>
      'Esta página se muestra sin el componente de navegador del sistema: texto, títulos, listas, enlaces e imágenes. Faltan los scripts, las fórmulas compuestas y los estilos más finos.';

  @override
  String get articleReaderLoading => 'Cargando …';

  @override
  String get articleReaderFailed => 'No se ha podido leer el artículo.';

  @override
  String get articleReaderEmpty => 'Esta página no contiene texto legible.';

  @override
  String get articleReaderImageMissing => 'Imagen no disponible';

  @override
  String get articleReaderExternal =>
      'Lleva fuera del archivo y no se ha abierto.';

  @override
  String get articleReaderOpenInBrowser => 'Abrir en un navegador';

  @override
  String get articleViewerChoiceTitle => 'Mostrar un artículo';

  @override
  String get articleViewerChoiceWhy =>
      'En Linux y Windows esta app no dispone de un componente de navegador integrado. Por eso un artículo se abre en una ventana propia del sistema, o la app lo dibuja por sí misma.';

  @override
  String get articleViewerChoiceWindow => 'Una ventana propia';

  @override
  String get articleViewerChoiceWindowWhy =>
      'Muestra el artículo completo: scripts, fórmulas compuestas, el diseño propio de la página. Necesita el componente de navegador del sistema: WebKitGTK en Linux, el runtime de WebView2 en Windows.';

  @override
  String get articleViewerChoiceBuiltIn => 'Dentro de la app';

  @override
  String get articleViewerChoiceBuiltInWhy =>
      'No necesita nada del sistema y se queda en la misma ventana. El tamaño de texto y los colores de la app se aplican también al artículo. Sin scripts, sin fórmulas compuestas, sin cuadros informativos flotantes.';

  @override
  String get articleViewerChoiceFallbackNote =>
      'Si falta el componente del sistema, la app dibuja el artículo por sí misma de todos modos: esta elección solo cambia lo que se intenta primero.';

  @override
  String get outageTitle => 'Corte de luz';

  @override
  String get outageEntryHint =>
      'Cuánto aguantan todavía el frigorífico y el congelador.';

  @override
  String get outageIntro =>
      'Mientras no hay luz, el frío se agota. Toca cuando empiece y la app sigue contando, aunque la cierres.';

  @override
  String get outageStart => 'Se acaba de ir la luz';

  @override
  String get outageEnded => 'Ha vuelto la luz';

  @override
  String outageRunningSince(String time) {
    return 'En curso desde las $time';
  }

  @override
  String get outageChangeStart => 'Otra hora';

  @override
  String get outageStoreRefrigerator => 'Frigorífico';

  @override
  String get outageStoreFreezer => 'Congelador';

  @override
  String outageRemaining(String left) {
    return 'Quedan $left';
  }

  @override
  String outageRemainingHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String outageRemainingMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String outageUntil(String time) {
    return 'Hasta las $time';
  }

  @override
  String outageGrace(String left) {
    return 'Plazo superado: desechar en $left';
  }

  @override
  String get outageSpoilt => 'Desechar los alimentos perecederos';

  @override
  String get outageFreezerFill => 'Congelador';

  @override
  String get outageFreezerFull => 'Bien lleno';

  @override
  String get outageFreezerHalf => 'Medio lleno o menos';

  @override
  String get outageFreezerWhy =>
      'Un congelador lleno aguanta unas 48 horas; uno medio lleno, unas 24. El frío está en los propios alimentos, no en el aparato.';

  @override
  String get outageRulesTitle => 'Normas';

  @override
  String get outageRuleClosed =>
      'Mantén la puerta cerrada. Cada apertura cuesta horas, y las cifras de aquí solo valen con la puerta cerrada.';

  @override
  String outageRuleTwoHours(int degrees) {
    return 'Todo lo que haya pasado dos horas por encima de $degrees °C se tira: carne, pescado, huevos, lácteos, sobras.';
  }

  @override
  String get outageRuleTaste =>
      'Nunca pruebes la comida para decidir. No se nota al probarla.';

  @override
  String get outageRuleRefreeze =>
      'Se puede volver a congelar mientras queden cristales de hielo. La calidad se resiente, la seguridad no.';

  @override
  String get outageRuleGenerator =>
      'Usa un generador solo al aire libre, al menos a 6 metros de ventanas, puertas y un garaje adosado.';

  @override
  String get outageRuleUnplug =>
      'Desenchufa los aparatos: la luz vuelve con un pico de tensión.';

  @override
  String get outageSource =>
      'Las cifras en horas son de FEMA (ready.gov) y del USDA (FSIS). Ninguna autoridad alemana publica cifras para esto, por eso se nombra aquí la fuente.';

  @override
  String get dailyDoseLabel => 'Tomado al día';

  @override
  String get dailyDoseHelper =>
      'En la misma unidad que las existencias: con 60 pastillas y 2 al día, introduce «2». Déjalo vacío si no se toma a diario.';

  @override
  String get medicationTitle => 'Medicación';

  @override
  String get medicationEntryHint => 'Cuánto dura la medicación.';

  @override
  String get medicationIntro =>
      'La misma cuenta que para provisiones y combustible, aplicada al botiquín: existencias divididas entre lo que se toma al día. Las dos cifras son tuyas: la app nunca adivina una dosis.';

  @override
  String get medicationNothingYet => 'Aún no hay medicación introducida';

  @override
  String get medicationNothingYetWhy =>
      'Introduce un medicamento como artículo de provisiones en la categoría «Medicinas» e indica lo que se toma al día. Solo entonces hay algo que calcular.';

  @override
  String get medicationNoAnswer =>
      'Ningún medicamento tiene introducida una cantidad diaria: sin ella no hay nada que dividir.';

  @override
  String medicationShortest(String name, String days) {
    return 'Se acaba primero: $name: $days';
  }

  @override
  String get medicationShortestWhy =>
      'Esa es la autonomía del botiquín. Reponer necesita una consulta y una farmacia, y en una emergencia ninguna de las dos está disponible enseguida.';

  @override
  String medicationRunsOut(String date) {
    return 'Se acaba el $date';
  }

  @override
  String medicationDays(int days) {
    return '$days días';
  }

  @override
  String get medicationOneDay => '1 día';

  @override
  String get medicationZeroDays => 'Menos de un día';

  @override
  String medicationStock(String quantity, String unit, String dose) {
    return '$quantity $unit en existencias, $dose al día';
  }

  @override
  String get medicationWithoutDoseTitle => 'Sin cantidad diaria';

  @override
  String get medicationWithoutDoseWhy =>
      'Están en las provisiones pero no se cuentan. Se nombran aquí en lugar de omitirse en silencio; si no, la cifra de arriba parecería cubrir todo el botiquín.';

  @override
  String get medicationSource =>
      'FEMA y los CDC aconsejan tener una reserva de medicamentos con receta y saber cuánto dura. Qué tamaño puede tener esa reserva es cosa de la consulta médica: la app solo cuenta lo que hay.';

  @override
  String get possessionsTitle => 'Inventario del hogar';

  @override
  String get possessionsEntryHint =>
      'Lo que posee el hogar, para la aseguradora.';

  @override
  String get possessionsEmpty => 'Aún no hay nada introducido';

  @override
  String get possessionsWhy =>
      'Tras un incendio, una inundación o un robo, la aseguradora pregunta qué había. Nadie responde a eso de memoria. Esta lista no son las provisiones: es lo que habría que reponer.';

  @override
  String get possessionsNoRoom => 'Sin habitación indicada';

  @override
  String possessionsTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String possessionsWithoutPrice(int count) {
    return '$count entradas sin precio no están en el total.';
  }

  @override
  String get possessionsExport => 'Exportar como PDF';

  @override
  String get possessionsPdfTitle => 'Inventario del hogar';

  @override
  String get possessionsKeepElsewhere =>
      'Esta lista no debe estar solo en la casa que describe. Imprímela y guárdala en otro sitio, o envíatela por correo. Las fotos no están en este archivo: solo están en el dispositivo que las hizo.';

  @override
  String get possessionAdd => 'Entrada';

  @override
  String get possessionAddTitle => 'Nueva entrada';

  @override
  String get possessionEditTitle => 'Editar entrada';

  @override
  String get possessionNameLabel => 'Objeto';

  @override
  String get possessionNameNeeded =>
      'Un nombre, o la fila no dirá nada más adelante.';

  @override
  String get possessionRoomLabel => 'Habitación';

  @override
  String get possessionRoomHelper =>
      'Salón, sótano, garaje: como lo recorras tú.';

  @override
  String get possessionSerialLabel => 'Número de serie';

  @override
  String get possessionSerialHelper =>
      'El único campo que no se puede reconstruir después. Suele estar detrás o debajo.';

  @override
  String get possessionPriceLabel => 'Precio de compra';

  @override
  String get possessionCurrencyLabel => 'Moneda';

  @override
  String get possessionAcquiredLabel => 'Comprado el';

  @override
  String get possessionAcquiredNone => 'Sin fecha';

  @override
  String get possessionPhotoTitle => 'Foto';

  @override
  String get possessionPhotoWhy =>
      'Una imagen convence a una aseguradora más que cualquier descripción. Se queda en este dispositivo y no va a la carpeta compartida.';

  @override
  String get possessionPhotoCamera => 'Hacer foto';

  @override
  String get possessionPhotoGallery => 'Elegir foto';

  @override
  String get possessionPhotoRemove => 'Quitar foto';

  @override
  String get possessionRemoveTitle => '¿Eliminar la entrada?';

  @override
  String possessionRemoveBody(String name) {
    return '«$name» se eliminará en todos los dispositivos del hogar.';
  }

  @override
  String possessionsCount(int count) {
    return '$count objetos';
  }

  @override
  String get firstAidTitle => 'Primeros auxilios';

  @override
  String get firstAidContentVersionTitle => 'De dónde salen estas guías';

  @override
  String get firstAidContentVersionBody =>
      'El contenido sigue las Guías 2025 del Consejo Europeo de Resucitación (ERC). Las páginas de «Malestar psíquico» siguen las IFRC International first aid, resuscitation and education guidelines 2025. Lo que enseña un curso de primeros auxilios lo acuerdan conjuntamente las organizaciones de ayuda; en un curso, vale lo que se diga allí.';

  @override
  String get firstAidEntryHint =>
      'Instrucciones, dibujos y un marcapasos para las compresiones torácicas. Sin red, sin descargas.';

  @override
  String get firstAidSearchHint => '¿Qué buscas?';

  @override
  String get firstAidSearchEmpty => 'Aquí no hay ninguna guía para eso.';

  @override
  String get firstAidDisclaimer =>
      'Estas guías no sustituyen un curso de primeros auxilios ni una llamada de emergencia. En caso de duda: llama al 112 y no cuelgues; el operador te guiará.';

  @override
  String get firstAidGroupBasics => 'Lo primero';

  @override
  String get firstAidGroupLifeThreatening => 'Peligro para la vida';

  @override
  String get firstAidGroupInjury => 'Lesiones';

  @override
  String get firstAidGroupIllness => 'Enfermedad repentina';

  @override
  String get firstAidGroupEnvironment => 'Frío, calor, veneno';

  @override
  String get firstAidGroupMental => 'Malestar psíquico';

  @override
  String get firstAidCallNow => 'Llamar al 112';

  @override
  String get firstAidCallFirst => 'Aquí primero se llama y después se ayuda.';

  @override
  String get firstAidSteps => 'Pasos';

  @override
  String get firstAidReadAloud => 'Leer los pasos en voz alta';

  @override
  String get firstAidStopReading => 'Dejar de leer';

  @override
  String get firstAidCautions => 'No hacer';

  @override
  String firstAidSource(String source) {
    return 'Fuente: $source';
  }

  @override
  String get firstAidOpenPacer => 'Iniciar el marcapasos';

  @override
  String get firstAidVideos => 'Vídeos';

  @override
  String get firstAidVideosNone =>
      'No hay ningún vídeo instalado para esta guía.';

  @override
  String get firstAidVideoManage => 'Gestionar el paquete de vídeos';

  @override
  String get firstAidVideoMissing =>
      'El archivo de vídeo ya no está. Vuelve a descargar el paquete.';

  @override
  String get firstAidVideoRestart => 'Desde el principio';

  @override
  String get firstAidVideoSystemPlayer =>
      'Este sistema no puede reproducir vídeo dentro de la app. El botón de abajo abre el archivo en el reproductor propio del ordenador.';

  @override
  String get firstAidVideoOpenExternal => 'Abrir en el reproductor del sistema';

  @override
  String get firstAidVideoNotACourse =>
      'Un vídeo no es un curso. Los movimientos solo se quedan cuando los has hecho tú mismo.';

  @override
  String get firstAidVideoPackTitle => 'Paquete de vídeos';

  @override
  String get firstAidVideoPackWhy =>
      'Las guías no necesitan vídeo: el texto, las figuras y los dibujos están completos y siempre ahí. Los vídeos son un extra para la tarde en que te sientas a aprender bien los movimientos, y son una descarga aparte, porque diez películas pesan más que toda la app.';

  @override
  String get firstAidVideoPackWhereTitle => 'Dónde conseguir uno';

  @override
  String get firstAidVideoPackWhereBody =>
      'No hay paquetes ya hechos, y esta app no remite a ninguno. Todos los vídeos alemanes de primeros auxilios aprovechables tienen derechos de autor: material íntegro de las organizaciones de ayuda. Material con licencia libre existe sobre todo en Wikimedia Commons, pero poco: el 22 de septiembre de 2026 la categoría «Videos of cardiopulmonary resuscitation» tenía ocho archivos, la mayoría no en alemán, uno de ellos la reanimación de un perro. Cada licencia está en la página de su archivo y hay que comprobarlas una a una.';

  @override
  String get firstAidVideoPackWhereHow =>
      'Para crear tu propio paquete, consulta docs/erste-hilfe.md en el código fuente. El crédito y la licencia de cada clip se muestran después bajo el vídeo.';

  @override
  String get firstAidVideoPackFromNetwork => 'Por la red';

  @override
  String get firstAidVideoPackUrlLabel =>
      'Dirección de la descripción del paquete';

  @override
  String get firstAidVideoPackUrlHelper =>
      'La dirección de un paket.json. Esta app no incluye ninguno: introduce la dirección donde publicaste tu paquete.';

  @override
  String get firstAidVideoPackFetch => 'Obtener la descripción';

  @override
  String get firstAidVideoPackFromFile => 'Desde un archivo';

  @override
  String get firstAidVideoPackFromFileWhy =>
      'Un paquete en zip, desde una memoria USB o desde la carpeta compartida. Es la vía que funciona sin red, es decir, en la situación para la que está hecha esta app.';

  @override
  String get firstAidVideoPackImport => 'Elegir un archivo de paquete';

  @override
  String get firstAidVideoPackNone =>
      'Aún no hay ningún paquete de vídeos instalado.';

  @override
  String firstAidVideoPackInstalled(int present, int total, String size) {
    return '$present de $total vídeos presentes, $size en disco';
  }

  @override
  String get firstAidVideoPackRemove => 'Eliminar el paquete de vídeos';

  @override
  String get firstAidVideoPackRemoveBody =>
      'Los archivos de vídeo y la descripción del paquete se eliminan del dispositivo. Las guías no se tocan.';

  @override
  String firstAidVideoPackOffer(int count, String size) {
    return '$count vídeos, $size en total';
  }

  @override
  String get firstAidVideoPackStart => 'Obtenerlos todos';

  @override
  String firstAidVideoPackProgress(int done, int total) {
    return '$done de $total hechos';
  }

  @override
  String firstAidVideoPackDone(int done, int total) {
    return '$done de $total vídeos obtenidos';
  }

  @override
  String get firstAidVideoPackLicenceNote =>
      'Cada vídeo nombra a su autor y su licencia. Descarga solo paquetes cuyas películas se puedan transmitir.';

  @override
  String get firstAidVideoPackBadUrl => 'Esa no es una dirección completa.';

  @override
  String get firstAidVideoPackClose => 'Cerrar';

  @override
  String get pacerTitle => 'Marcapasos';

  @override
  String get pacerStart => 'Iniciar';

  @override
  String get pacerStop => 'Detener';

  @override
  String get pacerIdle =>
      'Marca el ritmo de las compresiones torácicas: como tono, como destello y, en un teléfono, como vibración. La pantalla se mantiene encendida mientras funciona.';

  @override
  String pacerElapsed(String time) {
    return 'En marcha $time';
  }

  @override
  String get pacerDepth =>
      '5–6 cm de profundidad · en vertical desde arriba · deja que el pecho vuelva del todo';

  @override
  String get pacerNoSound =>
      'Sin sonido en este dispositivo. El ritmo sigue parpadeando.';

  @override
  String pacerPerMinute(int rate) {
    return '$rate/min';
  }

  @override
  String pacerOfCycle(int total, int cycle) {
    return 'de $total · ronda $cycle';
  }

  @override
  String get pacerBreathe => 'Ahora 2 insuflaciones';

  @override
  String get pacerSwapNow => 'Relevaos si sois dos';

  @override
  String get pacerPushOnly => 'Comprimir sin parar';

  @override
  String get pacerPushOnlyShort => 'Solo compresiones';

  @override
  String get warningSituationMapTitle => 'Mapa de la situación de avisos';

  @override
  String get warningSituationMapEmpty =>
      'No hay avisos activos para esta selección.';

  @override
  String get warningSituationMapNoGeometry =>
      'Los avisos activos no incluyen zonas de mapa. Sus indicaciones completas siguen disponibles sin conexión en la lista de avisos.';

  @override
  String get warningSituationMapFailed =>
      'No se ha podido leer la situación de avisos guardada.';

  @override
  String get warningSituationMapTapHint =>
      'Toca el mapa para ver qué se aplica en un punto.';

  @override
  String get warningSituationMapAtPoint => 'En este punto';

  @override
  String get warningSituationMapNothingHere =>
      'Ninguna de las zonas mostradas cubre este punto.';

  @override
  String get knowledgeApolloPackagesTitle => 'Estado de los paquetes APOLLO';

  @override
  String knowledgeApolloPackageSummary(int installed, int total) {
    return '$installed de $total fuentes recomendadas disponibles';
  }

  @override
  String get knowledgeApolloPackageInstalled =>
      'Descargado y registrado en la biblioteca';

  @override
  String get knowledgeApolloPackageMissing => 'Aún no está en la biblioteca';

  @override
  String get readinessEquipment => 'Equipos y baterías comprobados';

  @override
  String get readinessEquipmentOff =>
      'La rutina de comprobación está desactivada';

  @override
  String get readinessEquipmentNotChecked =>
      'Aún no se ha confirmado ninguna comprobación';

  @override
  String get readinessEquipmentDue => 'Toca una comprobación';

  @override
  String get readinessEquipmentChecked =>
      'Se confirmó una comprobación dentro del intervalo elegido';

  @override
  String get transferNearbyTitle => 'Dispositivos en la red local';

  @override
  String get transferNearbyHint =>
      'Solo se buscan señales de disponibilidad aleatorias y de corta duración. Elige un dispositivo y después escanea su código QR visible; sin ese código no se transfiere nada.';

  @override
  String get transferNearbyEmpty =>
      'Aún no se ha encontrado en esta red ningún dispositivo PreppSuite listo para transferir.';

  @override
  String get transferNearbyUnavailable =>
      'La detección de dispositivos no está disponible en esta red ahora mismo. Aun así puedes escanear el código QR directamente.';

  @override
  String get transferNearbyDevice => 'Dispositivo PreppSuite listo';

  @override
  String get transferNearbyScanHint =>
      'Escanea el código QR de este dispositivo para la entrega segura';

  @override
  String get settingsRegionLabel => 'Etiqueta (opcional)';

  @override
  String get settingsRegionLabelHelper =>
      'Por ejemplo casa, trabajo o un familiar.';

  @override
  String get knowledgeCheckTitle => 'Comprueba tus conocimientos';

  @override
  String get knowledgeCheckIntro =>
      'Los primeros auxilios se olvidan sin avisar. Unas pocas preguntas muestran qué se mantiene y qué no.';

  @override
  String knowledgeCheckProgress(int number, int total) {
    return 'Pregunta $number de $total';
  }

  @override
  String get knowledgeCheckRight => 'Correcto.';

  @override
  String get knowledgeCheckWrong => 'No del todo.';

  @override
  String get knowledgeCheckReadGuide => 'Leer la guía';

  @override
  String get knowledgeCheckNext => 'Siguiente';

  @override
  String get knowledgeCheckFinish => 'Terminar';

  @override
  String knowledgeCheckResult(int right, int total) {
    return '$right de $total correctas.';
  }

  @override
  String knowledgeCheckHeld(int held, int total) {
    return 'Se mantienen $held de $total preguntas.';
  }

  @override
  String get knowledgeCheckComeBack =>
      'Vuelve dentro de unos meses. No mañana: no es para eso.';

  @override
  String get knowledgeCheckReview => 'Merece la pena releer';

  @override
  String get knowledgeCheckAgain => 'Otra ronda';

  @override
  String get mapPlacesImport => 'Importar lugares';

  @override
  String get mapPlacesExport => 'Entregar lugares';

  @override
  String get mapPlacesExportGpx => 'Entregar como GPX';

  @override
  String get mapPlacesExportKml => 'Entregar como KML';

  @override
  String get mapPlacesExportFailed => 'No se ha podido escribir el archivo.';

  @override
  String get mapPlacesImportNothing =>
      'En este archivo no hay ningún lugar que la app pueda leer.';

  @override
  String mapPlacesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se han añadido $count lugares.',
      one: 'Se ha añadido un lugar.',
      zero: 'Todos los lugares ya estaban aquí.',
    );
    return '$_temp0';
  }

  @override
  String get mapPlacesTitle => 'Mis lugares';

  @override
  String get mapPlacesIntro =>
      'Los lugares personales aparecen como marcadores en el mapa. Solo se quedan en este dispositivo.';

  @override
  String get mapPlacesEmpty =>
      'Aún no hay lugares personales. Guarda puntos de encuentro, puntos de reparto o provisiones importantes.';

  @override
  String get mapPlaceAdd => 'Añadir lugar';

  @override
  String get mapPlaceEdit => 'Editar lugar';

  @override
  String get mapPlacePrivacy =>
      'Estos datos de ubicación se quedan en este dispositivo y no se comparten con el hogar.';

  @override
  String get mapPlaceLabel => 'Etiqueta';

  @override
  String get mapPlaceLatitude => 'Latitud';

  @override
  String get mapPlaceLongitude => 'Longitud';

  @override
  String get mapPlaceNote => 'Nota (opcional)';

  @override
  String get mapPlaceNoteHint =>
      'Por ejemplo acceso, provisiones u hora de encuentro';

  @override
  String get mapPlaceCoordinatesInvalid =>
      'Introduce una etiqueta y coordenadas válidas.';

  @override
  String mapPlaceDeleteConfirm(Object label) {
    return '¿Quitar «$label»?';
  }

  @override
  String drillsLastCompleted(String date) {
    return 'completado por última vez: $date';
  }

  @override
  String get hubTitle => 'Organización para crisis';

  @override
  String get hubPrivacyNote =>
      'Todo lo de aquí se queda en este dispositivo. Si exportas un registro de incidentes, decides tú quién lo recibe.';

  @override
  String get hubNotCheckedYet => 'aún sin comprobar';

  @override
  String get hubAutonomyTitle => 'Autosuficiencia';

  @override
  String get hubAutonomyHint =>
      'Autonomía en días, calculada a partir de tus provisiones y tu plan de energía. La cifra más baja es el próximo cuello de botella.';

  @override
  String hubAutonomyIncomplete(String resources) {
    return 'La autosuficiencia aún no está completa. Pendiente: $resources.';
  }

  @override
  String hubAutonomyKnownSoFar(int days, String resource) {
    return 'De lo conocido: $days días, cuello de botella $resource.';
  }

  @override
  String hubAutonomyRange(int days, String resource) {
    return '$days días por tu cuenta – cuello de botella: $resource';
  }

  @override
  String get hubAutonomyOpen => 'pendiente';

  @override
  String hubAutonomyDays(int days) {
    return '$days días';
  }

  @override
  String get hubAutonomyAddByHand => 'Rellenar a mano';

  @override
  String get hubAutonomyDialogTitle => 'Autonomía en días';

  @override
  String get hubAutonomyDialogHint =>
      'Lo que la app puede calcular a partir de tus provisiones y tu plan de energía ya está en pantalla. Esto es solo para lo que no puede dividir.';

  @override
  String hubAutonomyDaysField(String label) {
    return '$label – días';
  }

  @override
  String get hubAutonomyFromStock => 'Calculado a partir de tus provisiones';

  @override
  String hubAutonomyByHandWith(String reason) {
    return 'Introducido a mano – $reason';
  }

  @override
  String hubAutonomyNotCounted(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas no contadas: $reason',
      one: 'Una entrada no contada: $reason',
    );
    return '$_temp0';
  }

  @override
  String get hubResourceWater => 'Agua';

  @override
  String get hubResourceFood => 'Alimentos';

  @override
  String get hubResourceMedicine => 'Medicamentos';

  @override
  String get hubResourceEnergy => 'Energía';

  @override
  String get hubResourceHygiene => 'Higiene';

  @override
  String get hubGapOnlyByHand => 'la app no cuenta esto';

  @override
  String get hubGapNoEnergyPlan => 'aún no hay plan de energía';

  @override
  String get hubGapNothingRecorded =>
      'aún no hay nada registrado en tus provisiones';

  @override
  String get hubGapNoLiters => 'no registrado en litros';

  @override
  String get hubGapNoCalories => 'sin cifra de calorías';

  @override
  String get hubGapNoDose => 'sin dosis diaria';

  @override
  String get hubGapNoDraw => 'nada lo consume';

  @override
  String get hubWaterHygieneTitle => 'Agua e higiene';

  @override
  String get hubWaterHygieneHint =>
      'Planifica por separado el agua potable, el agua de uso, la potabilización, la rotación de garrafas, el inodoro y los residuos.';

  @override
  String get hubWaterHygieneLabel => 'Plan de agua e higiene';

  @override
  String get hubWaterHygieneTemplate =>
      'Agua potable: …\nAgua de uso: …\nFuentes y potabilización: …\nRotación de garrafas: …\nInodoro, residuos y productos de limpieza: …';

  @override
  String get hubPowerOutageTitle => 'Plan para cortes de luz';

  @override
  String get hubPowerOutageHint =>
      'Prepara la hora de inicio, la cadena de frío, las prioridades de carga, la luz, la información y un calor seguro.';

  @override
  String get hubPowerOutageTemplate =>
      'Anota la hora de inicio. Mantén cerrados el frigorífico y el congelador. Apunta las prioridades de carga, la radio, la luz, el calor seguro y a quién contactar.';

  @override
  String get hubCookingTitle => 'Cocinar con las provisiones';

  @override
  String get hubCookingHint =>
      'Planifica comidas en torno a las provisiones, el agua y el combustible que necesitan.';

  @override
  String get hubCookingLabel => 'Plan para cocinar con las provisiones';

  @override
  String get hubCookingTemplate =>
      'Plato: …\nIngredientes de las provisiones: …\nAgua: …\nCombustible y tiempo de cocción: …\nLugar seguro para cocinar: …';

  @override
  String get hubCookingRecipes => 'Abrir las recetas sin conexión';

  @override
  String get hubRedundancyTitle => 'Segundas vías';

  @override
  String get hubRedundancyHint =>
      'Anota una segunda vía para el agua, la luz, cocinar, la información y la comunicación.';

  @override
  String get hubRedundancyTemplate =>
      'Agua: vía principal / alternativa\nLuz: vía principal / alternativa\nCocinar: vía principal / alternativa\nInformación y comunicación: vía principal / alternativa';

  @override
  String get hubClimateRoomTitle => 'Habitación para el frío y el calor';

  @override
  String get hubClimateRoomHint =>
      'Decide de antemano qué habitación usar, qué ponerse, cómo ventilar y cómo calentarla o enfriarla de forma segura.';

  @override
  String get hubClimateRoomLabel => 'Habitación para el frío y el calor';

  @override
  String get hubClimateRoomTemplate =>
      'Habitación: …\nCalor/frescor: …\nMantas y ropa: …\nVentilación: …\nDetector de CO y aparatos seguros: …';

  @override
  String get hubRadioTitle => 'Plan de recepción de radio';

  @override
  String get hubRadioHint =>
      'Anota las emisoras locales de FM y DAB, los receptores y cómo se alimentan.';

  @override
  String get hubRadioAdd => 'Añadir una emisora';

  @override
  String get hubRadioDialogTitle => 'Añadir recepción de radio';

  @override
  String get hubRadioStation => 'Emisora';

  @override
  String get hubRadioBand => 'Banda';

  @override
  String get hubRadioFrequency => 'Frecuencia o canal';

  @override
  String get hubRadioReceiver => 'Receptor';

  @override
  String get hubRadioPower => 'Alimentación';

  @override
  String hubRadioDetails(
    String band,
    String frequency,
    String receiver,
    String power,
    String checked,
  ) {
    return '$band · $frequency\n$receiver · $power\nProbado: $checked';
  }

  @override
  String get hubFolderTitle => 'Carpeta de emergencia';

  @override
  String get hubFolderHint =>
      'Controla la carpeta en sí: sin contenido ni datos personales.';

  @override
  String get hubFolderLocation => 'Dónde se guarda';

  @override
  String get hubFolderLocationHint => 'p. ej. un armario con llave';

  @override
  String get hubFolderNotSet => 'sin fijar';

  @override
  String get hubFolderCopies =>
      'Las copias de los papeles importantes están listas';

  @override
  String get hubFolderTakeAlong => 'Llevarla en una evacuación';

  @override
  String get hubFolderCheckedToday => 'Comprobada hoy';

  @override
  String get hubCommunicationTitle => 'Plan de comunicación';

  @override
  String get hubCommunicationHint =>
      'A quién se contacta y en qué orden, quién coordina desde fuera, y mensajes de estado cortos para redes saturadas.';

  @override
  String get hubCommunicationTemplate =>
      '¿A quién se contacta y en qué orden? ¿Quién coordina desde fuera?\n\nPlantilla: Estamos bien. Próximo contacto a las …';

  @override
  String get hubStatusSafe => 'Estamos bien. Próximo contacto a las …';

  @override
  String get hubStatusHelp => 'Necesitamos ayuda con … Punto de encuentro: …';

  @override
  String get hubSupportTitle => 'Plan de apoyo';

  @override
  String get hubSupportHint =>
      'Apoyo personal, medicamentos, ayudas técnicas y transporte durante una evacuación.';

  @override
  String get hubSupportTemplate =>
      'Solo lo necesario: la ayuda requerida, medicamentos, ayudas técnicas, apoyo fiable y transporte.';

  @override
  String get hubPetsTitle => 'Plan de emergencia para mascotas';

  @override
  String get hubPetsHint =>
      'Prepara el transporte, la comida, los medicamentos, los cuidados y otro alojamiento para los animales.';

  @override
  String get hubPetsTemplate =>
      'Transportín, provisiones, veterinario, cuidados, alojamiento que admita mascotas y copias de los papeles.';

  @override
  String get hubMobilityTitle => 'Vehículo y desplazamientos';

  @override
  String get hubMobilityHint =>
      'Un equipo en el vehículo, una reserva de combustible o carga, otras formas de viajar y quién recoge a quién.';

  @override
  String get hubMobilityLabel => 'Plan de movilidad';

  @override
  String get hubMobilityTemplate =>
      'Vehículo, objetivo de carga o combustible, equipo, ruta alternativa, transporte público y recogida.';

  @override
  String get hubUtilitiesTitle => 'Suministros cortados';

  @override
  String get hubUtilitiesHint =>
      'Dónde están las llaves de corte y alternativas manuales para electricidad, agua, gas, calefacción y teléfono.';

  @override
  String get hubUtilitiesLabel => 'Plan de suministros';

  @override
  String get hubUtilitiesTemplate =>
      'Puntos de corte, a quién llamar, energía de reserva, dónde coger agua, calefacción y formas de comunicarse sin cobertura.';

  @override
  String get hubMaintenanceTitle => 'Mantenimiento';

  @override
  String get hubMaintenanceHint =>
      'Comprueba con regularidad, para que el equipo importante funcione cuando haga falta.';

  @override
  String hubMaintenanceLastChecked(String date) {
    return 'Última comprobación: $date';
  }

  @override
  String get hubEvacuationTitle => 'Tarjetas de evacuación';

  @override
  String get hubEvacuationHint =>
      'Puntos de encuentro y rutas seguras, anotados para poder leerlos sin conexión.';

  @override
  String get hubEvacuationAdd => 'Añadir una tarjeta';

  @override
  String get hubEvacuationRemove => 'Quitar tarjeta';

  @override
  String get hubEvacuationDialogTitle => 'Tarjeta de evacuación';

  @override
  String get hubEvacuationLabel => 'Nombre, p. ej. Casa';

  @override
  String get hubEvacuationStart => 'Punto de partida';

  @override
  String get hubEvacuationDestination => 'Punto de encuentro o destino';

  @override
  String get hubEvacuationRoute => 'Ruta y alternativas';

  @override
  String get hubEvacuationPlaces => 'Lugares importantes por el camino';

  @override
  String get hubEvacuationStartOpen => 'Inicio sin fijar';

  @override
  String get hubEvacuationDestinationOpen => 'Destino sin fijar';

  @override
  String hubEvacuationSummary(
    String start,
    String destination,
    String checked,
  ) {
    return '$start → $destination\nComprobado: $checked';
  }

  @override
  String hubEvacuationStartLine(String value) {
    return 'Inicio: $value';
  }

  @override
  String hubEvacuationDestinationLine(String value) {
    return 'Destino: $value';
  }

  @override
  String get hubEvacuationPlacesLine => 'Lugares importantes';

  @override
  String get hubEventsTitle => 'Registro de incidentes';

  @override
  String get hubEventsHint =>
      'Anota observaciones y lo que se hizo, con la hora, y expórtalo como PDF si hace falta.';

  @override
  String get hubEventsAdd => 'Añadir una entrada';

  @override
  String get hubEventsExport => 'Exportar como PDF';

  @override
  String get hubEventsDialogTitle => 'Registrar un incidente';

  @override
  String get hubEventsKind => 'Tipo';

  @override
  String get hubEventsKindHint => 'Incidente';

  @override
  String get hubEventsNote => 'Observación o daño';

  @override
  String get hubEventsAction => 'Lo que se hizo';

  @override
  String hubEventsObservationLine(String text) {
    return 'Observación: $text';
  }

  @override
  String hubEventsActionLine(String text) {
    return 'Acción: $text';
  }

  @override
  String get hubEventsPdfTitle => 'PreppSuite – registro de incidentes';

  @override
  String get hubEventsPdfFile => 'preppsuite-registro-incidentes.pdf';

  @override
  String get hubActionsTitle => 'Qué hacer y cuándo';

  @override
  String get hubActionsHint =>
      'Preparación según el aviso con que se cuente: ahora mismo, en 48 horas y con varios días de antelación.';

  @override
  String get hubActionNowTitle => 'Ahora mismo';

  @override
  String get hubActionNowBody =>
      'Lee el mensaje oficial, aléjate del peligro, enciende la radio e informa brevemente a tu familia.';

  @override
  String get hubActionTwoDaysTitle => 'En 24–48 horas';

  @override
  String get hubActionTwoDaysBody =>
      'Comprueba el agua, las provisiones, los medicamentos, las baterías y el vehículo. Prepara la casa y el equipo.';

  @override
  String get hubActionDaysTitle => 'Con varios días de antelación';

  @override
  String get hubActionDaysBody =>
      'Repasa la tarjeta de evacuación, organiza el apoyo, revisa los planes de mascotas y de suministros.';

  @override
  String hubActionDone(String date) {
    return 'Hecho: $date';
  }

  @override
  String get hubCrisisTitle => 'Modo crisis y resumen';

  @override
  String get hubCrisisHint =>
      'Una visualización más grande en toda la app y un resumen imprimible para el hogar o el equipo.';

  @override
  String get hubCrisisSwitch => 'Modo crisis';

  @override
  String get hubCrisisSwitchHint =>
      'Hace más grandes los textos y los controles en toda la app y reduce las animaciones: el mismo interruptor que en los ajustes.';

  @override
  String get hubBriefingButton => 'Resumen de emergencia en PDF';

  @override
  String get hubBriefingPdfTitle => 'PreppSuite – resumen de emergencia';

  @override
  String hubBriefingCreated(String date) {
    return 'Creado: $date';
  }

  @override
  String get hubBriefingRadio => 'Radio';

  @override
  String hubBriefingRadioLine(
    String station,
    String band,
    String frequency,
    String receiver,
  ) {
    return '$station: $band $frequency · $receiver';
  }

  @override
  String get hubBriefingEvacuation => 'Evacuación';

  @override
  String hubBriefingEvacuationLine(
    String label,
    String start,
    String destination,
  ) {
    return '$label: $start -> $destination';
  }

  @override
  String get hubBriefingPdfFile => 'preppsuite-resumen-emergencia.pdf';

  @override
  String get hubAnalogTitle => 'En papel';

  @override
  String get hubAnalogHint =>
      'Ten disponibles impresiones, mapas, notas y llaves de repuesto sin batería ni red.';

  @override
  String get hubAnalogTemplate =>
      'Mapas impresos, una lista de teléfonos, instrucciones, efectivo, llaves de repuesto y dónde se guardan.';

  @override
  String get hubMutualAidTitle => 'Ayudarse mutuamente';

  @override
  String get hubMutualAidHint =>
      'Planifica habilidades, equipos y formas seguras de contactar en tu entorno. No se publica nada.';

  @override
  String get hubMutualAidLabel => 'Tarjeta de ayuda e intercambio';

  @override
  String get hubMutualAidTemplate =>
      'Tus propias habilidades y equipos, el apoyo que necesitas, personas de confianza y dónde entregar cosas.';

  @override
  String get hubPracticeTitle => 'Práctica y mantenimiento';

  @override
  String get hubPracticeHint =>
      'Practica con regularidad con el filtro de agua, la cocina, la radio, el equipo y las rutinas en papel.';

  @override
  String get hubPracticeLabel => 'Plan de práctica y mantenimiento';

  @override
  String get hubPracticeTemplate =>
      'Próxima práctica: …\nProbar el filtro de agua: …\nCocinar sin electricidad: …\nComprobar la radio y el equipo: …';

  @override
  String get hubNoteEmpty => 'Aún no se ha anotado nada.';

  @override
  String hubNoteUpdated(String date) {
    return 'Última actualización: $date';
  }

  @override
  String get hubNoteCreate => 'Escribir un plan';

  @override
  String get hubNoteEdit => 'Editar';

  @override
  String get hubNoteCopyTemplate => 'Copiar plantilla';

  @override
  String get hubEntryRemove => 'Quitar entrada';

  @override
  String get hubClose => 'Cerrar';

  @override
  String get hubCancel => 'Cancelar';

  @override
  String get hubSave => 'Guardar';

  @override
  String hubDateTime(String date, String time) {
    return '$date · $time';
  }

  @override
  String get hubTaskBatteriesTitle => 'Pilas y baterías externas';

  @override
  String get hubTaskBatteriesHint => 'Comprobar la carga y los repuestos';

  @override
  String get hubTaskRadioTitle => 'Radio y plan de recepción';

  @override
  String get hubTaskRadioHint =>
      'Probar las emisoras, la antena y la alimentación';

  @override
  String get hubTaskWaterFilterTitle => 'Filtro de agua y garrafas';

  @override
  String get hubTaskWaterFilterHint =>
      'Comprobar el filtro, las juntas y las existencias';

  @override
  String get hubTaskKitTitle => 'Equipo de emergencia';

  @override
  String get hubTaskKitHint =>
      'Comprobar la ropa, la luz y las necesidades personales';

  @override
  String get hubTaskMedicineTitle => 'Botiquín';

  @override
  String get hubTaskMedicineHint =>
      'Comprobar las fechas de caducidad y los medicamentos personales';

  @override
  String get hubTaskExtinguisherTitle => 'Extintor y detectores de humo';

  @override
  String get hubTaskExtinguisherHint =>
      'Comprobar la fecha de revisión y las pilas';

  @override
  String get hubTaskVehicleTitle => 'Vehículo y desplazamientos';

  @override
  String get hubTaskVehicleHint =>
      'Comprobar el combustible, los neumáticos y las rutas alternativas';

  @override
  String hubFolderCheckedTodayWith(String date) {
    return 'Comprobada hoy · última vez $date';
  }

  @override
  String get hubBriefingCommunication => 'Comunicación';

  @override
  String get hubBriefingSupport => 'Apoyo';

  @override
  String get hubBriefingPets => 'Mascotas';

  @override
  String get hubBriefingMobility => 'Desplazamientos';

  @override
  String get hubBriefingUtilities => 'Suministros';

  @override
  String get hubBriefingPowerOutage => 'Corte de luz';

  @override
  String get hubBriefingRedundancy => 'Segundas vías';

  @override
  String get hubBriefingClimate => 'Frío y calor';

  @override
  String get hubRadioPowerExample => 'Pilas';

  @override
  String get hubEventsNoteHint => 'Observación';

  @override
  String hubEventSummary(String when, String text) {
    return '$when\n$text';
  }

  @override
  String get hubSituationTitle => 'Está pasando algo';

  @override
  String hubSituationOutage(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Corte de luz desde hace $hours horas',
      one: 'Corte de luz desde hace una hora',
      zero: 'Corte de luz, acaba de empezar',
    );
    return '$_temp0';
  }

  @override
  String hubSituationMoreWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Y $count avisos más',
      one: 'Y un aviso más',
    );
    return '$_temp0';
  }

  @override
  String get hubSituationCrisisMode => 'Activar el modo crisis';

  @override
  String get hubSituationLog => 'Anotarlo en el registro';

  @override
  String get hubSituationOutageKind => 'Corte de luz';

  @override
  String get hubFolderReportButton => 'Carpeta de emergencia en PDF';

  @override
  String get hubFolderReportTitle => 'Carpeta de emergencia';

  @override
  String get hubFolderReportIntro =>
      'Imprímela y guárdala fuera de casa: con familiares, en el vehículo o en el equipo. No sustituye a los documentos originales.';

  @override
  String get hubFolderReportFile => 'preppsuite-carpeta-emergencia.pdf';

  @override
  String get hubFolderReportRoute => 'Ruta';

  @override
  String get hubFolderReportPlaces => 'Lugares importantes';

  @override
  String get hubFolderReportAutonomy => 'Autosuficiencia';

  @override
  String get mapWaterTitle => 'Agua potable afectada';

  @override
  String mapWaterStock(String value) {
    return 'Tu propia agua potable: $value';
  }

  @override
  String mapWaterStockUnknown(String reason) {
    return 'Hasta dónde llega tu propia reserva aún está pendiente: $reason.';
  }

  @override
  String get mapWaterNearby => 'Agua potable cerca';

  @override
  String get mapWaterAdviceNote =>
      'Qué hacer con el agua lo dice el propio aviso. Esta app no publica cifras propias sobre ello.';

  @override
  String get setupChoiceTitle => 'Configurar un hogar';

  @override
  String get setupChoiceIntro =>
      '¿Ya existe este hogar en otro dispositivo? Entonces tráelo en lugar de empezar uno nuevo; si no, acabarás con dos hogares uno al lado del otro que nunca se fusionan.';

  @override
  String get setupChoiceNewTitle => 'Empezar un hogar nuevo';

  @override
  String get setupChoiceNewBody =>
      'El primer dispositivo. Todo lo demás se puede entregar desde aquí más adelante.';

  @override
  String get setupChoiceFolderTitle => 'Elegir una carpeta compartida';

  @override
  String get setupChoiceFolderBody =>
      'Si el hogar vive en una carpeta que ven los dos dispositivos (iCloud, Nextcloud, una memoria USB o una carpeta que alguna app de sincronización mantiene al día), este dispositivo se une a ella y se mantiene actualizado solo.';

  @override
  String get setupChoiceScanTitle => 'Tomarlo de otro dispositivo';

  @override
  String get setupChoiceScanBody =>
      'El otro dispositivo muestra un código QR y este lo lee. Por la red local, todo el hogar pasa de una vez; sin red, como una serie de imágenes.';

  @override
  String get setupChoiceSafeNote =>
      'Ahora es el momento más seguro para esto: este dispositivo aún no tiene datos propios que haya que volver a marcar.';

  @override
  String get setupChoiceRestoreTitle =>
      'Restaurar desde una copia de seguridad';

  @override
  String get setupChoiceRestoreBody =>
      'Lee un archivo de copia de seguridad protegido con contraseña. El hogar vuelve con el identificador que tenía.';

  @override
  String setupRestoreDone(int count) {
    return '$count registros restaurados.';
  }

  @override
  String get setupRestoreFailed =>
      'No se ha podido leer este archivo. Contraseña incorrecta, o no es una copia de seguridad de PreppSuite.';

  @override
  String get setupRestoreDefaultName => 'Hogar restaurado';

  @override
  String get setupFolderSearching => 'Leyendo la carpeta …';

  @override
  String setupFolderFound(String name) {
    return 'Hogar encontrado: $name';
  }

  @override
  String get setupFolderFoundBody =>
      'Este dispositivo se unirá a él. El nombre y el país vienen de la carpeta; la región y el tamaño del hogar se quedan en este dispositivo.';

  @override
  String get setupFolderEmpty =>
      'Aún no hay ningún hogar en esta carpeta. Se creará uno nuevo y se escribirá en ella.';

  @override
  String get setupScanHint =>
      'Primero rellena lo que pertenece a este dispositivo. Después lee el código QR del otro dispositivo y se incorporará el hogar.';

  @override
  String get setupScanContinue => 'Continuar al escaneo';

  @override
  String setupJoinFailed(String reason) {
    return 'No se ha podido unir: $reason';
  }

  @override
  String get setupDoneFolder =>
      'Carpeta conectada. A partir de ahora el hogar se mantiene al día solo.';

  @override
  String setupDoneScan(int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: 'Han llegado $rows entradas.',
      one: 'Ha llegado una entrada.',
      zero: 'No traía nada nuevo.',
    );
    return 'Hogar incorporado. $_temp0';
  }

  @override
  String get setupScanCancelled =>
      'Cancelado: no se ha incorporado ningún hogar.';

  @override
  String setupAdopted(String name) {
    return 'Hogar «$name» incorporado.';
  }

  @override
  String get transferAdoptHousehold => 'Incorporar el hogar de este código';

  @override
  String get transferConflictTitle => 'Dos hogares distintos';

  @override
  String transferConflictBody(String mine) {
    return 'Este dispositivo pertenece a «$mine», el código pertenece a otro hogar. Lo que pase ahora no se puede deshacer: dos conjuntos de datos fusionados no se pueden volver a separar.';
  }

  @override
  String get transferConflictMerge => 'Fusionarlos';

  @override
  String transferConflictMergeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Las $count entradas propias pasan al otro hogar, y los datos de ese hogar vienen aquí. No se pierde nada.',
      one: 'La única entrada propia pasa al otro hogar, y los datos de ese hogar vienen aquí. No se pierde nada.',
      zero: 'Este dispositivo no tiene nada que aportar y simplemente se une al otro hogar.',
    );
    return '$_temp0';
  }

  @override
  String get transferConflictReplace =>
      'Descartar los datos de este dispositivo';

  @override
  String transferConflictReplaceBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se eliminan las $count entradas propias.',
      one: 'Se elimina la única entrada propia.',
    );
    return '$_temp0 Después aquí solo queda el otro hogar.';
  }

  @override
  String get transferConflictKeep => 'No cambiar nada';

  @override
  String get transferConflictKeepBody =>
      'No se incorpora nada. Si es el otro dispositivo el que debe unirse a este, muestra el código allí y léelo allí.';

  @override
  String get transferConflictCancelled => 'Cancelado. No se ha cambiado nada.';

  @override
  String get transferConflictReplaced =>
      'Datos de este dispositivo descartados, el otro hogar incorporado.';

  @override
  String get backupShare => 'Compartir la copia de seguridad';

  @override
  String get backupShareHint =>
      'Entrégala a otra app, por ejemplo una nube a la que no llega el selector de archivos. El archivo está cifrado con tu frase de contraseña; quien lo reciba sin ella no puede hacer nada con él.';

  @override
  String get backupShareSubject => 'Copia de seguridad de PreppSuite';

  @override
  String get toolsHubTitle => 'Organización para crisis';

  @override
  String get toolsHubBody =>
      'Radio, carpeta de emergencia, mantenimiento, tarjetas de evacuación y registro de incidentes';

  @override
  String get toolsLearnTitle => 'Una ronda rápida';

  @override
  String get toolsLearnBody =>
      'Repasos cortos sin conexión, junto a los simulacros y el archivo de conocimiento.';

  @override
  String toolsAnswerRight(String explanation) {
    return 'Correcto. $explanation';
  }

  @override
  String toolsAnswerWrong(String explanation) {
    return 'Vuelve a mirarlo: $explanation';
  }

  @override
  String toolsDrillDuration(int minutes) {
    return 'Preparación: $minutes minutos';
  }

  @override
  String toolsDrillMeta(String duration, String completed) {
    return '$duration · $completed';
  }

  @override
  String get toolsLessonCommunicationTitle => 'Comunicación';

  @override
  String get toolsLessonCommunicationSummary =>
      'Descargar las redes y coordinar los contactos.';

  @override
  String get toolsLessonCommunicationQuestion =>
      '¿Qué vía suele funcionar mejor cuando la red móvil está saturada?';

  @override
  String get toolsLessonCommunicationAnswerA => 'Una llamada larga';

  @override
  String get toolsLessonCommunicationAnswerB =>
      'Un mensaje corto que indique una hora para responder';

  @override
  String get toolsLessonCommunicationAnswerC =>
      'Volver a marcar una y otra vez';

  @override
  String get toolsLessonCommunicationExplanation =>
      'Los mensajes cortos necesitan menos capacidad de red y ahorran batería.';

  @override
  String get toolsLessonEvacuationTitle => 'Evacuación';

  @override
  String get toolsLessonEvacuationSummary =>
      'Tener listos el plan, el equipo y el punto de encuentro.';

  @override
  String get toolsLessonEvacuationQuestion =>
      '¿Qué conviene comprobar antes de una evacuación?';

  @override
  String get toolsLessonEvacuationAnswerA =>
      'El punto de encuentro, la ruta y el apoyo que necesite cada uno';

  @override
  String get toolsLessonEvacuationAnswerB => 'Solo la app del tiempo';

  @override
  String get toolsLessonEvacuationAnswerC => 'Solo el indicador de combustible';

  @override
  String get toolsLessonEvacuationExplanation =>
      'Un punto de encuentro claro, la ruta y las necesidades individuales evitan el estrés y las malas decisiones.';

  @override
  String get toolsLessonPowerTitle => 'Corte de luz';

  @override
  String get toolsLessonPowerSummary => 'Asegurar luz, información y energía.';

  @override
  String get toolsLessonPowerQuestion =>
      '¿Para qué sirve la radio de pilas o de manivela?';

  @override
  String get toolsLessonPowerAnswerA => 'Para sustituir a los avisos oficiales';

  @override
  String get toolsLessonPowerAnswerB => 'Como canal adicional de información';

  @override
  String get toolsLessonPowerAnswerC => 'Solo para escuchar música';

  @override
  String get toolsLessonPowerExplanation =>
      'La radio complementa los avisos del sistema y funciona cuando internet no.';

  @override
  String get toolsDrillPowerTitle => '72 horas sin electricidad';

  @override
  String get toolsDrillPowerStepA =>
      'Preparar luz, radio y una batería externa';

  @override
  String get toolsDrillPowerStepB =>
      'Comprobar el agua, el hornillo y las provisiones';

  @override
  String get toolsDrillPowerStepC =>
      'Mantener cerrados el frigorífico y el congelador';

  @override
  String get toolsDrillEvacuationTitle => 'Evacuación en 15 minutos';

  @override
  String get toolsDrillEvacuationStepA => 'Guardar documentos y medicamentos';

  @override
  String get toolsDrillEvacuationStepB =>
      'Comprobar el punto de encuentro y la ruta en el mapa sin conexión';

  @override
  String get toolsDrillEvacuationStepC =>
      'Repasar quién está en el hogar y cómo localizarlo';

  @override
  String get toolsDrillCommunicationTitle => 'La comunicación ha caído';

  @override
  String get toolsDrillCommunicationStepA =>
      'Comprobar la radio local y los avisos';

  @override
  String get toolsDrillCommunicationStepB =>
      'Tener a mano los contactos cercanos y el punto de encuentro';

  @override
  String get toolsDrillCommunicationStepC =>
      'Usar una radio solo en un servicio que se te permita usar';

  @override
  String get recipeOnlyInGerman => 'Solo disponible en alemán';

  @override
  String get recipeOnlyInEnglish => 'Solo disponible en inglés';

  @override
  String get emergencyMapReady => 'Abierto y listo para usar';

  @override
  String get emergencyOfflineMapTitle => 'Mapa sin conexión';

  @override
  String get emergencyKnowledgeArchivesTitle => 'Archivos de conocimiento';

  @override
  String get knowledgeBookmarksTitle => 'Marcadores';

  @override
  String get emergencyRadioFm => 'FM (VHF)';

  @override
  String get emergencyRadioMediumWave => 'Onda media / AM';

  @override
  String get emergencyRadioFreenet => 'Freenet (Alemania)';

  @override
  String get emergencyMapMissing =>
      'Aún no hay ningún paquete de mapa comprobado';

  @override
  String get emergencyKnowledgeReady => 'Archivo abierto y listo para usar';

  @override
  String get emergencyKnowledgeMissing =>
      'Aún no hay ningún archivo de conocimiento comprobado';

  @override
  String get knowledgeNoBookmarks =>
      'Aún no hay marcadores. Abre un artículo y toca el símbolo de marcador.';

  @override
  String get knowledgeInOpenArchive => 'En el archivo abierto';

  @override
  String get knowledgeOpenArchiveFirst =>
      'Abre primero el archivo en la biblioteca';

  @override
  String get radioCbCallingChannel =>
      'El canal habitual de llamada y socorro en la radio CB.';

  @override
  String get radioCbRoadChannel =>
      'Un canal muy usado en carretera y por los camioneros.';

  @override
  String caloriesPer100Label(String basis) {
    return 'Calorías por $basis (kcal, opcional)';
  }

  @override
  String get unitInfoAction => '¿Por qué una medida?';

  @override
  String get unitInfoTitle => '¿Por qué g, kg, ml o l?';

  @override
  String get unitInfoWhy =>
      'Los valores nutricionales vienen impresos en cada paquete por 100 g o por 100 ml. Unas existencias solo se convierten en la ración de un día si la cantidad se puede expresar también en gramos, y lo que pesan seis latas está en la lata, no en esta app.';

  @override
  String get unitInfoAccepted =>
      'Estas con un toque, y escritas también valen: gramo, kilo, mililitro, litro.';

  @override
  String get unitInfoExempt =>
      'Esto solo se aplica a alimentos y agua. Los medicamentos se siguen contando en pastillas, o la autonomía por dosis diaria deja de cuadrar; las herramientas se cuentan en unidades.';

  @override
  String get unitInfoKept =>
      'Unas existencias contadas en latas o tarros se quedan exactamente como están. Simplemente no entran en la calculadora de provisiones hasta que la unidad nombre una medida.';

  @override
  String get unitMeasureRequired => 'Esto necesita una medida: g, kg, ml o l.';

  @override
  String nutritionPer100Label(String nutrient, String basis) {
    return '$nutrient por $basis';
  }

  @override
  String get foodWithoutMeasureTitle => 'No se cuenta: una unidad sin medida';

  @override
  String foodWithoutMeasureBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos se cuentan',
      one: 'Un alimento se cuenta',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No cuentan',
      one: 'No cuenta',
    );
    return '$_temp0 en una unidad a la que no se puede aplicar ninguna etiqueta: una lata, un tarro. $_temp1 en la calculadora de provisiones hasta que la unidad sea g, kg, ml o l.';
  }

  @override
  String get transferInterrupted =>
      'Se estableció la conexión pero la transferencia no terminó. Mantén los dos dispositivos despiertos e inténtalo de nuevo; con muchas fotos tarda un poco.';

  @override
  String transferLastSeen(int frame) {
    return 'Última lectura: imagen $frame';
  }

  @override
  String transferLastSeenMixed(int frame, int discarded) {
    return 'Última lectura: imagen $frame · $discarded imágenes eran de otra transferencia';
  }

  @override
  String get operationsTitle => 'Situación ahora';

  @override
  String get operationsWarning => 'Aviso activo para tus lugares';

  @override
  String get operationsQuiet => 'Tus lugares seguidos están tranquilos';

  @override
  String get operationsOpenWarnings => 'Consultar avisos';

  @override
  String get operationsOpenReadiness => 'Abrir preparación';

  @override
  String operationsNextTask(String task) {
    return 'Siguiente: $task';
  }

  @override
  String get operationsChargeDue => 'Comprobar baterías y equipos';

  @override
  String get operationsInventoryMissing => 'Configurar las provisiones';

  @override
  String get operationsReady =>
      'La preparación básica está lista; revisa los detalles cuando haga falta';

  @override
  String get followedPlacesTitle => 'Mis lugares de avisos';

  @override
  String get followedPlacesIntro =>
      'Avisos para casa y otras regiones importantes. Las etiquetas de los lugares adicionales se quedan en este dispositivo.';

  @override
  String get followedPlacesPrimary => 'Lugar principal';

  @override
  String get followedPlacesAdditional => 'Lugares adicionales';

  @override
  String followedPlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lugares adicionales',
      one: '1 lugar adicional',
    );
    return '$_temp0';
  }

  @override
  String get followedPlacesOpen => 'Gestionar lugares de avisos';

  @override
  String get householdPlanShareSafety => 'Compartir mensaje de seguridad';

  @override
  String householdPlanSafetyMessage(String meetingPoint) {
    return 'Estamos bien.\\nPunto de encuentro: $meetingPoint\\nPróxima actualización: …';
  }

  @override
  String get toolsDrillEquipmentTitle => 'Comprobar baterías y equipos';

  @override
  String get toolsDrillEquipmentStepA =>
      'Cargar y etiquetar baterías externas, linternas y pilas de repuesto';

  @override
  String get toolsDrillEquipmentStepB =>
      'Probar la radio, los cargadores y los cables desde la red o una batería externa';

  @override
  String get toolsDrillEquipmentStepC =>
      'Fijar la fecha de la próxima comprobación';

  @override
  String get toolsDrillRadioTitle => 'Comprobación de radio e información';

  @override
  String get toolsDrillRadioStepA =>
      'Comprobar las pilas, la antena y la recepción de la radio';

  @override
  String get toolsDrillRadioStepB =>
      'Anotar las emisoras locales, los canales de avisos y las frecuencias acordadas';

  @override
  String get toolsDrillRadioStepC =>
      'Transmitir solo en un servicio de radio autorizado y anotar una breve prueba de recepción';

  @override
  String get operationsWarningDetail =>
      'Abrir detalles, zonas afectadas y acciones recomendadas';

  @override
  String get navGroupNow => 'Ahora';

  @override
  String get navGroupPrepare => 'Preparar';

  @override
  String get navGroupOffline => 'Sin conexión';

  @override
  String get navGroupProfile => 'Perfil y ajustes';

  @override
  String get emergencyCardCareTitle => 'Apoyo y dependencias';

  @override
  String get emergencyCardCareHint =>
      'Para necesidades de electricidad, ayudas técnicas, cuidados o transporte, escribe aquí una nota breve y concreta, por ejemplo «silla de ruedas: batería de repuesto en el pasillo; transporte: …». Esta información es sensible.';

  @override
  String get shareFailed => 'No se ha podido abrir el menú de compartir.';

  @override
  String get householdPlanSafetyHint =>
      'Ajusta el mensaje y la hora de la próxima actualización antes de compartir.';

  @override
  String get hubResilienceTitle => 'Vías de aviso y red';

  @override
  String get hubResilienceHint =>
      'Prepara localmente los canales de aviso, el apoyo personal, las fuentes, el aprendizaje y la ayuda cercana.';

  @override
  String get resilienceWarningTitle => 'Comprobar las vías de aviso';

  @override
  String get resilienceWarningHint =>
      'Marca una vía como correcta solo después de haberla probado de verdad en este dispositivo o en el hogar.';

  @override
  String get resilienceWarningNina =>
      'App de avisos NINA configurada y probada';

  @override
  String get resilienceWarningCell =>
      'Cell Broadcast comprobado en este dispositivo';

  @override
  String get resilienceWarningSiren =>
      'Sirena o vía de aviso municipal aclarada';

  @override
  String get resilienceWarningRadio =>
      'Radio y emisora local de avisos probadas';

  @override
  String get resilienceSupportTitle => 'Apoyo personal';

  @override
  String get resilienceSupportHint =>
      'Plan opcional para dependencias durante un corte o una evacuación. No guardes ningún diagnóstico médico.';

  @override
  String get resilienceSupportPower =>
      'Ayudas que dependen de la electricidad y energía de reserva revisadas';

  @override
  String get resilienceSupportEvacuation => 'Ayuda para salir de casa aclarada';

  @override
  String get resilienceSupportTransport => 'Transporte o recogida organizados';

  @override
  String get resilienceSupportMedicine =>
      'Plan de medicación y reserva revisados';

  @override
  String get resilienceSupportAssistance =>
      'Cuidados, asistencia o necesidades de los animales aclarados';

  @override
  String get resilienceSupportNote => 'Plan personal breve';

  @override
  String get resilienceSourcesTitle => 'Brújula de fuentes';

  @override
  String get resilienceSourcesHint =>
      'Anota solo fuentes cuya información compruebes tú mismo. Añade siempre una vía sin internet.';

  @override
  String get resilienceSourcesEmpty =>
      'Aún no hay ninguna fuente local anotada.';

  @override
  String get resilienceSourceAdd => 'Añadir fuente';

  @override
  String get resilienceSourceLabel => 'Organización o tema';

  @override
  String get resilienceSourceChannel => 'Vía de acceso';

  @override
  String get resilienceSourceFallback => 'Alternativa sin conexión';

  @override
  String get resilienceLearningTitle => 'Rutas de aprendizaje APOLLO';

  @override
  String get resilienceLearningHint =>
      'Marca una ruta solo después de descargarla y hacer una breve prueba sin conexión.';

  @override
  String get resilienceLearningOpen => 'Abrir APOLLO';

  @override
  String get resilienceLearningMedical =>
      'Primeros auxilios y nociones médicas';

  @override
  String get resilienceLearningWater => 'Agua, higiene y cocina';

  @override
  String get resilienceLearningRepair => 'Reparación y energía';

  @override
  String get resilienceLearningNavigation =>
      'Orientación, radio y comunicación';

  @override
  String get resilienceLearningSchool => 'Fundamentos y aprendizaje con niños';

  @override
  String get resilienceNeighborhoodTitle => 'Ayuda vecinal';

  @override
  String get resilienceNeighborhoodHint =>
      'Habilidades voluntarias y vías de contacto seguras. Basta con un alias; no hacen falta nombres reales.';

  @override
  String get resilienceNeighborhoodEmpty =>
      'Aún no hay ninguna capacidad cercana anotada.';

  @override
  String get resilienceNeighborhoodAdd => 'Añadir capacidad';

  @override
  String get resilienceNeighborAlias => 'Alias o función';

  @override
  String get resilienceNeighborSkill => 'Habilidad o equipo';

  @override
  String get resilienceNeighborContact => 'Vía de contacto acordada';

  @override
  String get resilienceNeighborMeeting => 'Punto de encuentro';

  @override
  String get resilienceMaintenanceSchedule => 'Intervalo de comprobación';

  @override
  String get resilienceMaintenanceOff => 'Sin programar';

  @override
  String get resilienceMaintenanceDue => 'Toca comprobar';

  @override
  String resilienceMaintenanceEveryDays(int days) {
    return 'Cada $days días';
  }

  @override
  String get statusSupplyLimitWater => 'Factor limitante: el agua potable.';

  @override
  String get statusSupplyLimitCalories =>
      'Factor limitante: las calorías disponibles.';

  @override
  String get statusSupplyLimitBoth =>
      'Factores limitantes: el agua potable y las calorías disponibles.';

  @override
  String get hubComicTitle => 'Hablar con los niños sobre emergencias';

  @override
  String get hubComicHint =>
      'El cómic «Mila y Nuss» explica a los niños en seis capítulos cortos qué pueden hacer en un corte de luz, cuando suena la sirena, en una tormenta, en un incendio y cuando se habla de guerra. Viene con la app y no necesita internet.';

  @override
  String get hubComicOpen => 'Leer el cómic';

  @override
  String comicChapterNumber(int number) {
    return 'Capítulo $number';
  }

  @override
  String get comicRulesTitle => 'Para recordar';

  @override
  String get comicRulesHint =>
      'Todas las normas y los números de emergencia de un vistazo';

  @override
  String get comicNumbersTitle => 'Números de emergencia';

  @override
  String get comicParentsTitle => 'Para padres y cuidadores';

  @override
  String comicNext(String title) {
    return 'Siguiente: $title';
  }

  @override
  String knowledgeDocumentReadingProgress(String received, String total) {
    return 'Leyendo el archivo: $received de $total';
  }

  @override
  String knowledgeDocumentReadingBytes(String received) {
    return 'Leyendo el archivo: $received';
  }

  @override
  String knowledgeDocumentPreparing(int done, int total) {
    return 'Preparando el texto: $done de $total';
  }

  @override
  String knowledgeDocumentTooLargeForReader(String size, String limit) {
    return 'Este archivo ocupa $size. En este dispositivo, el lector integrado abre archivos de hasta $limit. Otra app puede leerlo igualmente.';
  }

  @override
  String get knowledgeDocumentTooLargeInside =>
      'Este documento contiene más de lo que el lector integrado puede manejar en este dispositivo. Otra app puede leerlo igualmente.';

  @override
  String get knowledgeDocumentTruncated =>
      'A partir de aquí el documento es demasiado largo para el lector integrado. Otra app muestra el resto.';

  @override
  String get emergencyComicHint =>
      'Un cómic de emergencia para niños: qué hacer en un corte de luz, cuando suena la sirena, en una tormenta, en un incendio y cuando se habla de guerra.';

  @override
  String get backupContentsTitle => 'Qué entra en la copia de seguridad';

  @override
  String get backupRestoreContentsTitle => 'Qué se restaura';

  @override
  String get backupContentsHousehold => 'Hogar, ajustes y plan de emergencia';

  @override
  String get backupContentsAlways => 'siempre incluido';

  @override
  String backupContentsPhotos(int count) {
    return 'Fotos ($count)';
  }

  @override
  String backupContentsDocuments(int count) {
    return 'Documentos propios ($count)';
  }

  @override
  String get backupContentsMap => 'Mapa sin conexión';

  @override
  String get backupContentsArchives => 'Archivos de conocimiento';

  @override
  String get backupContentsPresent => 'ya está en este dispositivo';

  @override
  String backupContentsTotal(String size) {
    return 'Unos $size en total';
  }

  @override
  String get backupContentsSizeUnknown => 'tamaño desconocido';

  @override
  String get backupContentsLargeHint =>
      'Una copia grande no se puede enviar por mensajería ni por correo. El mapa y los archivos de conocimiento también se pueden volver a descargar más tarde.';

  @override
  String get backupContentsContinue => 'Continuar';

  @override
  String get backupProgressWriting => 'Escribiendo la copia de seguridad …';

  @override
  String get backupProgressRestoring => 'Restaurando archivos …';

  @override
  String get backupProgressPreparing => 'Preparando …';

  @override
  String get backupCancelled =>
      'Cancelado. No se ha conservado ningún archivo incompleto.';

  @override
  String backupFilesUnreadable(String files) {
    return 'No está en la copia porque no se pudo leer: $files';
  }

  @override
  String backupFilesRestored(int count) {
    return '$count archivos restaurados.';
  }

  @override
  String backupFilesFailed(String files) {
    return 'No restaurado: $files';
  }

  @override
  String get heavyRainTitle => 'Lluvias torrenciales y crecidas';

  @override
  String get heavyRainEntryHint =>
      'Qué profundidad alcanza el agua en tu dirección tras un aguacero o en una crecida.';

  @override
  String get heavyRainIntro =>
      'El mapa de peligro por lluvias torrenciales de la Agencia Federal Alemana de Cartografía y Geodesia (BKG) muestra dónde se acumula el agua tras un aguacero y a qué velocidad fluye. Consultado una vez con conexión, el resultado se queda en el dispositivo.';

  @override
  String get heavyRainUseLocation => 'Usar mi ubicación';

  @override
  String get heavyRainSearchAddress => 'Introducir una dirección';

  @override
  String get heavyRainAddressHint => 'Calle, número, localidad';

  @override
  String get heavyRainCheck => 'Consultar';

  @override
  String get heavyRainNotFound => 'No se ha encontrado esta dirección.';

  @override
  String get heavyRainFailed =>
      'El servicio de mapas del BKG no ha respondido.';

  @override
  String get heavyRainScenarioExceptional => 'Lluvia torrencial excepcional';

  @override
  String get heavyRainScenarioExceptionalBody =>
      'Estadísticamente una vez cada 100 años.';

  @override
  String get heavyRainScenarioExtreme => 'Lluvia torrencial extrema';

  @override
  String get heavyRainScenarioExtremeBody =>
      '100 mm de lluvia en una hora, 90 mm en Renania del Norte-Westfalia.';

  @override
  String heavyRainDepth(int radius, String range) {
    return 'Profundidad del agua en un radio de $radius m: $range';
  }

  @override
  String heavyRainFlow(String range) {
    return 'Velocidad del flujo: $range';
  }

  @override
  String get heavyRainDepthClass0 => 'menos de 10 cm';

  @override
  String get heavyRainDepthClass1 => 'de 10 a 30 cm';

  @override
  String get heavyRainDepthClass2 => 'de 30 a 50 cm';

  @override
  String get heavyRainDepthClass3 => 'de 50 a 100 cm';

  @override
  String get heavyRainDepthClass4 => 'de 100 a 200 cm';

  @override
  String get heavyRainDepthClass5 => 'de 200 a 400 cm';

  @override
  String get heavyRainDepthClass6 => '400 cm o más';

  @override
  String get heavyRainVelocityClass0 => 'menos de 0,2 m/s';

  @override
  String get heavyRainVelocityClass1 => 'de 0,2 a 0,5 m/s';

  @override
  String get heavyRainVelocityClass2 => 'de 0,5 a 1,0 m/s';

  @override
  String get heavyRainVelocityClass3 => 'de 1,0 a 2,0 m/s';

  @override
  String get heavyRainVelocityClass4 => '2,0 m/s o más';

  @override
  String get heavyRainNoValue =>
      'El mapa no contiene ningún valor para este lugar.';

  @override
  String heavyRainUncovered(String state) {
    return 'El mapa nacional no contiene datos para $state. El estado federado tiene mapas propios.';
  }

  @override
  String get heavyRainLimits =>
      'Un mapa indicativo: la simulación no tiene en cuenta el alcantarillado ni la infiltración, toda la lluvia fluye por la superficie. Bajo los edificios no suele haber valor, por eso se muestra el agua más profunda en 25 m alrededor del punto.';

  @override
  String heavyRainCheckedAt(String place, String date) {
    return '$place, consultado el $date';
  }

  @override
  String get heavyRainHerePlace => 'Lugar elegido';

  @override
  String heavyRainCellar(int count) {
    return 'Provisiones guardadas en el sótano: $count';
  }

  @override
  String get heavyRainOffline =>
      'Sin conexión con el servicio de mapas. Se muestra la última consulta.';

  @override
  String get heavyRainChangePlace => 'Consultar otro lugar';

  @override
  String get heavyRainRefresh => 'Volver a consultar';

  @override
  String heavyRainSource(String year) {
    return 'Fuente: Hinweiskarte Starkregengefahren, © BKG $year, dl-de/by-2-0';
  }

  @override
  String get heavyRainPrivacy =>
      'Para la consulta, las coordenadas se envían al servicio de mapas del BKG y una posición redondeada a un kilómetro a OpenStreetMap para saber el estado federado.';

  @override
  String get checkInTitle => 'Enviar señal de vida';

  @override
  String get checkInEntryHint =>
      'Decir por SMS que estás bien: un SMS suele llegar aunque los datos móviles estén saturados.';

  @override
  String get checkInStatusLabel => '¿Qué debe llegar?';

  @override
  String get checkInSafe => 'Estoy bien.';

  @override
  String get checkInNeedHelp => 'Necesito ayuda.';

  @override
  String get checkInOnMyWay => 'Voy de camino al punto de encuentro.';

  @override
  String checkInOnMyWayTo(String place) {
    return 'Voy de camino al punto de encuentro: $place.';
  }

  @override
  String checkInTime(String time) {
    return 'Hora: $time';
  }

  @override
  String get checkInAttachLocation => 'Adjuntar mi ubicación';

  @override
  String get checkInLocating => 'Buscando mi ubicación …';

  @override
  String get checkInNote => 'Nota adicional (opcional)';

  @override
  String get checkInPreview => 'Se enviará este mensaje';

  @override
  String get checkInRecipients => 'Destinatarios';

  @override
  String get checkInNoRecipients =>
      'Aún no hay destinatarios. Mejor alguien fuera de tu región: las redes locales son las primeras en saturarse en una emergencia.';

  @override
  String checkInSendTo(String name) {
    return 'SMS a $name';
  }

  @override
  String get checkInShare => 'Enviar con otra aplicación';

  @override
  String get checkInCopy => 'Copiar texto';

  @override
  String get checkInCopied => 'Texto copiado.';

  @override
  String get checkInAddContact => 'Añadir destinatario';

  @override
  String get checkInContactName => 'Nombre';

  @override
  String get checkInContactPhone => 'Número de teléfono';

  @override
  String get checkInContactInvalid =>
      'Introduce un nombre y un número de teléfono válido.';

  @override
  String get checkInRemoveContact => 'Eliminar destinatario';

  @override
  String checkInSuggestion(String name) {
    return 'Usar sugerencia: $name';
  }

  @override
  String get checkInNoSmsApp =>
      'Aquí no se puede abrir ninguna aplicación de SMS. Copia el texto o envíalo con otra aplicación.';

  @override
  String get checkInPrivacy =>
      'El mensaje solo se envía con la aplicación de SMS o mensajería que elijas. PreppSuite no envía nada por sí misma.';

  @override
  String get aedTitle => 'Desfibriladores cercanos';

  @override
  String get aedEntryHint =>
      'Dónde está el desfibrilador más cercano: busca una vez con conexión y después también sin ella.';

  @override
  String get aedCall112First =>
      'Ante una parada cardíaca, llama primero al 112 y empieza la reanimación. Quien esté libre trae el desfibrilador.';

  @override
  String get aedUseLocation => 'Buscar aquí';

  @override
  String get aedSearchAddress => 'Introducir una dirección';

  @override
  String aedNone(int radius) {
    return 'No hay ningún desfibrilador registrado en OpenStreetMap en un radio de $radius km.';
  }

  @override
  String aedFound(int count, int radius, String place, String date) {
    return '$count en un radio de $radius km, $place, a $date';
  }

  @override
  String aedDistance(String distance, String direction) {
    return '$distance $direction';
  }

  @override
  String get aedUnnamed => 'Desfibrilador';

  @override
  String aedLevel(String level) {
    return 'Planta: $level';
  }

  @override
  String aedOpeningHours(String hours) {
    return 'Accesible: $hours';
  }

  @override
  String get aedIndoor => 'en el interior';

  @override
  String get aedOutdoor => 'en el exterior';

  @override
  String get aedRestricted => 'no accesible al público';

  @override
  String get aedOpenMap => 'Abrir en el mapa';

  @override
  String get aedFailed => 'OpenStreetMap no ha respondido.';

  @override
  String get aedOffline => 'Sin conexión. Se muestra la última búsqueda.';

  @override
  String get aedIncomplete =>
      'Voluntarios registran las ubicaciones en OpenStreetMap. La lista no está completa y los horarios pueden cambiar.';

  @override
  String get aedSource => 'Datos: © colaboradores de OpenStreetMap, ODbL';

  @override
  String get aedHere => 'aquí';

  @override
  String get compassN => 'al norte';

  @override
  String get compassNE => 'al noreste';

  @override
  String get compassE => 'al este';

  @override
  String get compassSE => 'al sureste';

  @override
  String get compassS => 'al sur';

  @override
  String get compassSW => 'al suroeste';

  @override
  String get compassW => 'al oeste';

  @override
  String get compassNW => 'al noroeste';

  @override
  String get backupReminderTitle => 'Es hora de hacer una copia de seguridad';

  @override
  String backupReminderBody(String date) {
    return 'La última copia de seguridad en este dispositivo es del $date. Las fotos, los documentos propios y los archivos solo sobreviven a la pérdida del dispositivo en una copia.';
  }

  @override
  String get backupReminderBodyNever =>
      'Aún no se ha hecho ninguna copia de seguridad en este dispositivo. Las fotos, los documentos propios y los archivos solo sobreviven a la pérdida del dispositivo en una copia.';

  @override
  String get backupLastNever =>
      'Aún no hay ninguna copia de seguridad en este dispositivo.';

  @override
  String backupLastAt(String date, String age) {
    return 'Última copia de seguridad: $date ($age)';
  }

  @override
  String get backupReminderLabel => 'Recordar la próxima copia';

  @override
  String get readinessBackupMade => 'Copia de seguridad al día';

  @override
  String get readinessBackupMadeNever =>
      'Aún no hay ninguna copia en este dispositivo';

  @override
  String readinessBackupMadeAge(String age) {
    return 'Última copia: $age';
  }

  @override
  String get backupAgeToday => 'hoy';

  @override
  String get backupAgeYesterday => 'ayer';

  @override
  String get mapShowAeds => 'Mostrar desfibriladores';

  @override
  String get mapHideAeds => 'Ocultar desfibriladores';

  @override
  String get riverFloodTitle => 'Crecidas de ríos';

  @override
  String get riverFloodFrequent => 'Crecida frecuente (HQhäufig)';

  @override
  String get riverFloodHundred => 'Crecida centenaria (HQ100)';

  @override
  String get riverFloodExtreme => 'Crecida extrema (HQextrem)';

  @override
  String get riverFloodClass1 => 'hasta 0,5 m de agua';

  @override
  String get riverFloodClass2 => 'de 0,5 a 1 m de agua';

  @override
  String get riverFloodClass3 => 'de 1 a 2 m de agua';

  @override
  String get riverFloodClass4 => 'de 2 a 4 m de agua';

  @override
  String get riverFloodClass5 => 'más de 4 m de agua';

  @override
  String get riverFloodDry => 'sin inundación según el mapa';

  @override
  String riverFloodUncovered(String state) {
    return 'El mapa de peligro de inundación de $state aún no está incluido.';
  }

  @override
  String get riverFloodLimits =>
      'Mapas de peligro de inundación según la Directiva europea, profundidad del agua en un radio de 25 m. Las zonas tras diques y defensas no se incluyen o solo de forma aproximada.';

  @override
  String get riverFloodSource =>
      'Fuente: NLWKN, mapas de peligro de inundación (Directiva de inundaciones, 2.º ciclo)';

  @override
  String get riverFloodFailed =>
      'El servicio de mapas del estado federado no ha respondido.';

  @override
  String get emergencyPointsTitle =>
      'Pozos de emergencia, puntos de ayuda y sirenas';

  @override
  String get emergencyPointsEntryHint =>
      'Dónde hay agua e información durante un apagón, y si hay una sirena al alcance del oído.';

  @override
  String get emergencyPointsIntro =>
      'En un apagón prolongado, el agua corriente, el teléfono e internet fallan uno tras otro. Dónde están el pozo de emergencia y el punto de ayuda más cercanos aún se puede consultar ahora: la búsqueda se guarda y después está disponible sin conexión.';

  @override
  String emergencyPointsPlace(String place, String date) {
    return '$place, a $date';
  }

  @override
  String get sirenTitle => '¿Sirena al alcance del oído?';

  @override
  String sirenLikely(String distance, String direction) {
    return 'La sirena más cercana está a $distance $direction. Es muy probable que se oiga allí.';
  }

  @override
  String sirenMaybe(String distance, String direction) {
    return 'La sirena más cercana está a $distance $direction. Eso queda entre su alcance en ciudad y en campo abierto: quizá se oiga, aunque difícilmente con viento y ventanas cerradas. Aquí son importantes la app de alertas y la radio.';
  }

  @override
  String sirenUnlikely(String distance, String direction) {
    return 'La sirena registrada más cercana está a $distance $direction. Es lejos para una sirena. Aquí conviene confiar en la app de alertas y la radio.';
  }

  @override
  String sirenNone(int radius) {
    return 'En OpenStreetMap no hay ninguna sirena registrada en un radio de $radius km. Eso no significa que no la haya: en el día nacional de alerta de Alemania, el segundo jueves de septiembre a las 11, se puede comprobar uno mismo, y el ayuntamiento lo sabe.';
  }

  @override
  String sirenRangeMapped(String range) {
    return 'Alcance según el registro: $range';
  }

  @override
  String get sirenRule =>
      'Valor orientativo para la sirena de motor E57, con la que también se miden las sirenas electrónicas nuevas: unos 400 m en ciudad, 600 m en las afueras y 850 m en campo abierto. El viento, los edificios y las ventanas cerradas lo reducen mucho.';

  @override
  String get sirenUnnamed => 'Sirena';

  @override
  String get emergencyWellsTitle => 'Pozos de agua potable de emergencia';

  @override
  String emergencyWellsFound(int count, int radius) {
    return 'Los $count más cercanos en un radio de $radius km';
  }

  @override
  String emergencyWellsNone(int radius) {
    return 'No hay ningún pozo de emergencia registrado en un radio de $radius km.';
  }

  @override
  String get emergencyWellsWater =>
      'Los pozos de emergencia extraen agua subterránea que no siempre tiene calidad de agua potable. En caso de emergencia, las autoridades indican si hay que hervirla. Conviene tener bidones o cubos en casa para transportarla.';

  @override
  String get emergencyWellUnnamed => 'Pozo de emergencia';

  @override
  String emergencyWellNumber(String ref) {
    return 'N.º $ref';
  }

  @override
  String get emergencyWellOutOfOrder =>
      'Bomba averiada o cerrada en la última comprobación';

  @override
  String get emergencyHelpPointsTitle => 'Puntos de ayuda en catástrofes';

  @override
  String get emergencyHelpPointsHint =>
      'Un edificio con electricidad de emergencia que abre durante un apagón prolongado: allí hay información, y desde allí se puede hacer una llamada de emergencia cuando ya no funciona ningún teléfono.';

  @override
  String emergencyHelpPointsFound(int count, int radius) {
    return '$count en un radio de $radius km';
  }

  @override
  String emergencyHelpPointsNone(int radius) {
    return 'No hay ningún punto de ayuda registrado en un radio de $radius km. Muchos municipios los tienen sin que figuren en OpenStreetMap: el ayuntamiento sabe dónde está el más cercano.';
  }

  @override
  String get emergencyHelpPointUnnamed => 'Punto de ayuda';

  @override
  String get emergencyPointsIncomplete =>
      'Las ubicaciones las introducen voluntarios en OpenStreetMap. Sobre todo las sirenas y los puntos de ayuda aún faltan en muchos lugares.';

  @override
  String get mapShowEmergencyPoints => 'Mostrar pozos de emergencia y sirenas';

  @override
  String get mapHideEmergencyPoints => 'Ocultar pozos de emergencia y sirenas';

  @override
  String get measureConvertTitle => 'Indicar el contenido';

  @override
  String get measureConvertIntro =>
      'Estos alimentos se cuentan en envases. Con el contenido de un envase cuentan en la calculadora de provisiones, y se pueden seguir consumiendo envase a envase.';

  @override
  String get measureConvertAction => 'Indicar';

  @override
  String measureConvertPrompt(String package) {
    return '¿Cuánto contiene un envase «$package»?';
  }

  @override
  String get measureConvertHint => 'En la etiqueta, por ejemplo 400';

  @override
  String get measureConvertInvalid => 'Introduce una cantidad mayor que 0.';

  @override
  String measureConvertDone(String name) {
    return '«$name» ya cuenta en la calculadora de provisiones.';
  }

  @override
  String get measureConvertNoneLeft =>
      'Todos los alimentos tienen ya una medida.';

  @override
  String get riverFloodSourceBY =>
      'Fuente de datos: Agencia de Medio Ambiente de Baviera, www.lfu.bayern.de';

  @override
  String get riverFloodSourceNW =>
      'Fuente: Land NRW (2026), Licencia de datos de Alemania – atribución – versión 2.0 (www.govdata.de/dl-de/by-2-0)';

  @override
  String get callUnavailableTitle => 'Este dispositivo no puede llamar';

  @override
  String get callUnavailableBody =>
      'Marca el número en un teléfono, móvil o fijo:';

  @override
  String get callUnavailableCopy => 'Copiar número';

  @override
  String get emergencyAccessTitle => 'Emergencia';

  @override
  String get emergencyAccessButton => 'Emergencia: 112 y primeros auxilios';

  @override
  String get emergencyAccessCall112 => 'Llamar al 112 – bomberos y ambulancia';

  @override
  String get emergencyAccessCall110 => 'Llamar al 110 – policía';

  @override
  String get emergencyAccessNote =>
      'Esta ayuda forma parte de la app y no necesita datos guardados. Funciona aunque la app esté bloqueada o el hogar no se pueda cargar ahora.';

  @override
  String get householdLoadFailedTitle => 'El hogar no se puede cargar ahora';

  @override
  String get householdLoadRetry => 'Reintentar';

  @override
  String warningsTimeToday(String time) {
    return 'hoy $time';
  }

  @override
  String warningsUpdatedAt(String time) {
    return 'Actualizado: $time';
  }

  @override
  String get warningsStaleTitle => 'Avisos no actualizados';

  @override
  String warningsStaleBody(String time) {
    return 'La última actualización completa fue $time. Desde entonces puede haberse emitido un aviso que aquí falta. Atiende a la radio, las sirenas y los avisos por megafonía.';
  }

  @override
  String get warningsNeverBody =>
      'Aún no se han descargado avisos en este dispositivo; para ello la app necesita una vez conexión a internet. Hasta entonces, atiende a la radio, las sirenas y los avisos por megafonía.';

  @override
  String get warningsEmptyStale =>
      'No hay avisos guardados. Sin una actualización reciente no se puede saber si los hay ahora.';

  @override
  String get statusSituationStale => 'Desactualizado';

  @override
  String statusSituationStaleHint(String time) {
    return 'Última actualización: $time. Pueden faltar avisos.';
  }

  @override
  String get statusSituationNever =>
      'Aún no se han descargado avisos. La app necesita internet una vez para ello.';

  @override
  String snapshotRestoreAction(String date) {
    return 'Recuperar la copia automática del $date';
  }

  @override
  String get snapshotRestoreTitle => '¿Recuperar la copia automática?';

  @override
  String snapshotRestoreBody(String date) {
    return 'El hogar vuelve al estado del $date. Lo que se haya introducido después faltará. La base de datos dañada no se borra, se guarda al lado.';
  }

  @override
  String get snapshotRestoreConfirm => 'Recuperar';

  @override
  String get snapshotRestoreFailed => 'La recuperación no ha funcionado.';

  @override
  String get errorWidgetText =>
      'Esta parte de la app no se pudo mostrar. Lo ocurrido está en el registro de errores, en Ajustes → Acerca de.';

  @override
  String get errorLogTitle => 'Registro de errores';

  @override
  String get errorLogEmpty => 'No hay errores registrados.';

  @override
  String errorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas',
      one: 'Una entrada',
    );
    return '$_temp0. El registro se queda en este dispositivo; solo sale de él si lo compartes tú.';
  }

  @override
  String get errorLogShow => 'Mostrar';

  @override
  String get errorLogShare => 'Compartir';

  @override
  String get errorLogClear => 'Borrar';

  @override
  String get riverFloodClassUnknown => 'inundado, profundidad no indicada';

  @override
  String get riverFloodNoMap => 'no hay mapa para este escenario';

  @override
  String get riverFloodSourceNational =>
      'Fuente: mapas de peligro de inundación de los estados federados, reunidos a nivel nacional por el Instituto Federal de Hidrología (geoportal.bafg.de)';

  @override
  String get appLockBiometricTitle => 'Desbloquear con la cara o la huella';

  @override
  String get appLockBiometricHint =>
      'En lugar de escribir la frase de contraseña. Esta se mantiene y abre la app si el sensor no te reconoce.';

  @override
  String get appLockBiometricReason => 'Desbloquear PreppSuite';

  @override
  String get appLockBiometricButton => 'Con la cara o la huella';

  @override
  String get appLockBiometricNotConfirmed =>
      'No se confirmó la cara o la huella. El ajuste sigue desactivado.';

  @override
  String get shoppingListExport => 'Exportar como archivo';

  @override
  String get shoppingListExportDialogTitle =>
      'Guardar la lista de la compra como archivo';

  @override
  String get shoppingListExported =>
      'Lista de la compra guardada como archivo.';

  @override
  String get refillReminderTitle => 'Conseguir una nueva receta';

  @override
  String refillReminderBody(String name, String date) {
    return 'Según tu último recuento, $name dura hasta el $date.';
  }

  @override
  String get inventoryMemberLabel => 'Para quién';

  @override
  String get inventoryMemberHelper =>
      'Aparece entonces en la tarjeta de emergencia de esa persona, con cuánto dura.';

  @override
  String get inventoryMemberNone => 'Para todo el hogar';

  @override
  String get refillLeadLabel => 'Recordatorio de una nueva receta';

  @override
  String get refillLeadHelper =>
      'Para un envase del que se toma cada día. La app cuenta entonces desde el día en que anotaste o descontaste las existencias por última vez y te avisa antes de que se acaben.';

  @override
  String get refillLeadNone => 'Ninguno: una reserva de la que no se toma';

  @override
  String refillLeadDays(int days) {
    return '$days días antes de que se acabe';
  }

  @override
  String get emergencyCardStored => 'En la reserva';

  @override
  String emergencyCardStoredReach(String name, String days) {
    return '$name: $days';
  }

  @override
  String medicationInUse(String date) {
    return 'En uso diario, contado el $date';
  }

  @override
  String medicationRefillOn(String date) {
    return 'Recordatorio de nueva receta el $date';
  }

  @override
  String get medicationRefillDue => 'Es hora de una nueva receta';

  @override
  String get scenarioTitle => 'Sin electricidad, agua ni calefacción';

  @override
  String get scenarioOpen => 'Calcular un escenario';

  @override
  String get scenarioIntro =>
      'Lo que falta para pasar el tiempo elegido con tu propia reserva. Existencias, medicamentos y energía salen de lo que anotaste; la necesidad por persona, de la calculadora de reservas.';

  @override
  String get scenarioHorizonHours => '72 horas';

  @override
  String scenarioHorizonDays(int days) {
    return '$days días';
  }

  @override
  String get scenarioWater => 'Agua';

  @override
  String get scenarioFood => 'Comida';

  @override
  String get scenarioMedicine => 'Medicamentos';

  @override
  String get scenarioEnergy => 'Luz, cocina, calor';

  @override
  String scenarioNeedHave(String needed, String have) {
    return 'Necesario $needed, disponible $have';
  }

  @override
  String scenarioMissing(String amount) {
    return 'Faltan $amount';
  }

  @override
  String get scenarioCovered => 'Cubierto';

  @override
  String get scenarioNoMedicines =>
      'Ningún medicamento con dosis diaria en la reserva.';

  @override
  String scenarioWithoutDose(String names) {
    return 'Sin dosis diaria, por eso sin calcular: $names';
  }

  @override
  String get scenarioNoEnergyPlan =>
      'No hay consumo anotado. Lo que gastan la lámpara, el hornillo y la estufa se anota en Energía.';

  @override
  String scenarioEnergyUses(String uses) {
    return 'para $uses';
  }

  @override
  String scenarioEnergyUnused(String kinds) {
    return 'Disponible, pero sin consumo anotado: $kinds';
  }

  @override
  String get scenarioWaterLine => 'Agua potable';

  @override
  String get scenarioSource =>
      'Necesidad por persona como en la calculadora de reservas: según la BBK y la BLE donde publican cifras, y señalado allí donde no. Medicamentos según tu dosis diaria, energía según el consumo que anotaste para tus aparatos.';

  @override
  String get cardSpeciesDog => 'Perro';

  @override
  String get cardSpeciesCat => 'Gato';

  @override
  String get cardSpeciesOther => 'Otro animal';

  @override
  String get categoryPetFood => 'Comida para animales';

  @override
  String get dailyFoodLabel => 'Comida al día';

  @override
  String get dailyFoodHelper =>
      'En la misma unidad que las existencias: con una reserva en kilos y 200 g al día, aquí va «0,2». Déjalo vacío si no se da a diario.';

  @override
  String get inventoryAnimalLabel => 'Para qué animal';

  @override
  String get cardSpeciesLabel => 'Tarjeta para';

  @override
  String get cardSpeciesPerson => 'Una persona';

  @override
  String get cardChipNumber => 'Número de chip o tatuaje';

  @override
  String get cardChipNumberHint => 'Figura en el pasaporte de la mascota';

  @override
  String get cardVets => 'Veterinarios';

  @override
  String get cardVetHint => 'p. ej. veterinario habitual, clínica';

  @override
  String get cardVetAdd => 'Añadir veterinario';

  @override
  String get cardShelters => 'Quién acoge al animal en una emergencia';

  @override
  String get cardShelterHint => 'p. ej. vecina, residencia canina, protectora';

  @override
  String get cardAnimalHint =>
      'Guarda la cartilla de vacunación como PDF en Saber → Documentos personales, por ejemplo con la función de escaneo del teléfono. La comida y los medicamentos se asignan a este animal en la reserva. Para el agua sigue contando el número de animales del perfil del hogar.';

  @override
  String get cardVet => 'Veterinario';

  @override
  String get checklistFoodGroupsHint =>
      'Las cantidades de aquí son por persona. Cuánto de ello tiene ya tu hogar en la reserva lo muestran los grupos de reserva.';

  @override
  String get knowledgeSuggestionWater =>
      'Recoger y potabilizar agua. En inglés.';

  @override
  String get knowledgeSuggestionPostDisaster =>
      'Refugio, saneamiento, salud y comida tras una catástrofe. En inglés.';

  @override
  String get knowledgeSuggestionAppropedia =>
      'Tecnología apropiada para agua, saneamiento, energía y construir con lo que hay. En inglés.';

  @override
  String get kiwixOnDevice => 'Esta versión ya está en el dispositivo.';

  @override
  String get kiwixOtherBuildOnDevice =>
      'Hay otra versión en el dispositivo. Volver a descargar vale la pena si esta es más nueva.';

  @override
  String get kiwixAlreadyHereTitle => 'Ya está en el dispositivo';

  @override
  String kiwixAlreadyHereBody(String title) {
    return '«$title» ya está en el dispositivo en esta misma versión. ¿Descargarlo de nuevo, por ejemplo porque el archivo está dañado?';
  }

  @override
  String get kiwixDownloadAgain => 'Descargar de nuevo';

  @override
  String get kiwixCrisisShortcuts => 'Para una emergencia';

  @override
  String kiwixInEnglish(String name) {
    return '$name (en inglés)';
  }

  @override
  String knowledgeCostsArchives(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos, $size en el disco en total.',
      one: '1 archivo, $size en el disco.',
    );
    return '$_temp0';
  }

  @override
  String knowledgeCostsUnknown(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'De $count aún no se conoce el tamaño hasta que se hayan abierto una vez.',
      one: 'De uno aún no se conoce el tamaño hasta que se haya abierto una vez.',
    );
    return '$_temp0';
  }

  @override
  String knowledgeCostsIndexes(String size) {
    return 'Índices de búsqueda propios: $size.';
  }

  @override
  String knowledgeCostsMemory(String cluster, String cache) {
    return 'Solo hay un archivo abierto a la vez. Descomprime como máximo $cluster de golpe y guarda hasta $cache en caché; los demás solo ocupan espacio.';
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'ARES PATH';

  @override
  String get siteName => 'Meridiani · Contexto regional (100 km)';

  @override
  String get navPlan => 'PLAN';

  @override
  String get navSafety => 'SEGURIDAD';

  @override
  String get navScience => 'CIENCIA';

  @override
  String get language => 'Idioma';

  @override
  String get layersTitle => 'CAPAS DE DATOS';

  @override
  String layersActive(int n) {
    return '$n ACTIVAS';
  }

  @override
  String get layersReset => 'RESTABLECER';

  @override
  String get layerOptical => 'Superficie óptica';

  @override
  String get layerHillshade => 'Relieve (sombreado)';

  @override
  String get layerSlope => 'Relieve';

  @override
  String get layerForbidden => 'Zonas prohibidas';

  @override
  String get layerCuriosity => 'Recorrido de Curiosity';

  @override
  String get layerThermal => 'Térmica (THEMIS-IR día)';

  @override
  String get layerMinerals => 'Mineralogía';

  @override
  String get layerRadiation => 'Flujo de radiación';

  @override
  String get layerNoData => 'Sin datos todavía';

  @override
  String get kindMeasured => 'MEDIDO';

  @override
  String get kindModeled => 'MODELADO';

  @override
  String get kindExample => 'EJEMPLO';

  @override
  String get opacity => 'OPACIDAD';

  @override
  String get legendTitle => 'LEYENDA DE PENDIENTE';

  @override
  String get legendNominal => '< 10° nominal';

  @override
  String get legendCaution => '10–20° precaución';

  @override
  String get legendHigh => '20–25° precaución alta';

  @override
  String get legendForbidden => '> 25° prohibida';

  @override
  String get routesTitle => 'COMPARACIÓN DE RUTAS';

  @override
  String get routeSafe => 'Más segura';

  @override
  String get routeFast => 'Más rápida';

  @override
  String get routeScience => 'Más ciencia';

  @override
  String get metricDistance => 'Distancia';

  @override
  String get metricDuration => 'Duración';

  @override
  String get metricMaxSlope => 'Pendiente máx.';

  @override
  String get metricClimb => 'Ascenso';

  @override
  String get metricO2 => 'O₂ al volver';

  @override
  String get metricDose => 'Dosis';

  @override
  String get metricNoReturn => 'Punto de no retorno';

  @override
  String get metricWalk => 'Marcha';

  @override
  String get metricStops => 'Paradas de trabajo';

  @override
  String get hazardScore => 'PELIGRO';

  @override
  String get successScore => 'ÉXITO';

  @override
  String get breakdown => 'Desglose';

  @override
  String get hzSlope => 'Exposición a pendiente';

  @override
  String get hzTerrain => 'Terreno rugoso o suelto';

  @override
  String get hzWalkback => 'Más allá del regreso a pie';

  @override
  String get hzConsumables => 'Margen de consumibles';

  @override
  String get hzRadiation => 'Dosis de radiación';

  @override
  String get hzDay => 'Condiciones del día (ejemplo)';

  @override
  String get scValue => 'Valor científico';

  @override
  String get scTime => 'Factor de tiempo';

  @override
  String get scConsumables => 'Factor de consumibles';

  @override
  String get scPenalty => 'Penalización por peligro';

  @override
  String get objectivesTitle => 'OBJETIVOS CIENTÍFICOS';

  @override
  String get objectivesAdd => 'AÑADIR OBJETIVO';

  @override
  String get objectivesAddActive => 'TOCA EL MAPA PARA COLOCARLO';

  @override
  String get objectivesEmpty =>
      'Sin objetivos. Añade uno para planear una ruta.';

  @override
  String get typeSample => 'Muestra';

  @override
  String get typeImage => 'Imagen';

  @override
  String get typeMeasurement => 'Medición';

  @override
  String get typeEquipment => 'Equipo';

  @override
  String priorityLabel(int p) {
    return 'Prioridad $p';
  }

  @override
  String workMinutes(int m) {
    return '$m min';
  }

  @override
  String get objectiveEdit => 'Editar objetivo';

  @override
  String get objectiveNewName => 'Nuevo objetivo';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldType => 'Tipo';

  @override
  String get fieldPriority => 'Prioridad (1 a 5)';

  @override
  String get fieldWork => 'Tiempo de trabajo (min)';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Borrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get objectiveForbidden => 'En terreno prohibido';

  @override
  String get statusFeasible => 'FACTIBLE';

  @override
  String get statusNotFeasible => 'NO FACTIBLE';

  @override
  String get statusUnreachable => 'INALCANZABLE';

  @override
  String get statusNoTarget => 'SIN OBJETIVO';

  @override
  String get visits => 'Visita';

  @override
  String get skippedLabel => 'No incluidos';

  @override
  String get reasonBlocked => 'terreno prohibido';

  @override
  String get reasonUnreachable => 'inalcanzable';

  @override
  String get reasonTime => 'falta tiempo';

  @override
  String get reasonOxygen => 'falta oxígeno';

  @override
  String get reasonMargin => 'margen muy justo';

  @override
  String get reasonNotPrimary => 'no va en esta ruta';

  @override
  String get computing => 'CALCULANDO RUTAS…';

  @override
  String get assumptionsTitle => 'SUPUESTOS';

  @override
  String get assumptionsNote =>
      'Supuestos del equipo, no estándares de la NASA.';

  @override
  String get assumeSpeed => 'Velocidad en llano';

  @override
  String get assumeEva => 'Duración máxima de la salida';

  @override
  String get assumeO2 => 'Capacidad de oxígeno';

  @override
  String get assumeReserve => 'Reserva mínima de oxígeno';

  @override
  String get assumeSlopeLimit => 'Límite de pendiente (segura / otras)';

  @override
  String get assumeDose => 'Tasa de dosis de radiación (medida, RAD)';

  @override
  String get profileTitle => 'PERFIL DE ELEVACIÓN Y PENDIENTE';

  @override
  String get habitat => 'HÁBITAT';

  @override
  String get pnrShort => 'PNR';

  @override
  String get elevation => 'ELEV';

  @override
  String get attribution => 'HiRISE (NASA/JPL/UArizona) · USGS Astrogeology';

  @override
  String get hintDrag =>
      'Arrastra para mover · rueda para zoom · toca un objetivo para editarlo';

  @override
  String get zoomIn => 'Acercar';

  @override
  String get zoomOut => 'Alejar';

  @override
  String get zoomFit => 'Ajustar a la vista';

  @override
  String get soon => 'Próximamente';

  @override
  String get sciTargetsTitle => 'OBJETIVOS // SALIDA';

  @override
  String get sciDetail => 'DETALLE DEL OBJETIVO';

  @override
  String get sciOrbital => 'ORBITAL · HiRISE';

  @override
  String get sciGround => 'SUELO · FOTO DEL ROVER';

  @override
  String get sciGroundSoon => 'Sin foto del rover para este objetivo';

  @override
  String get sciGroundNote => 'Foto de ese sol, tomada cerca de esta parada';

  @override
  String get sciDataStack => 'DATOS EN ESTE PUNTO';

  @override
  String get sciPick => 'Elige un objetivo';

  @override
  String get stackOptical => 'Imagen óptica';

  @override
  String get stackTopo => 'Topografía y pendiente';

  @override
  String get stackThermal => 'Térmica (THEMIS-IR día)';

  @override
  String get stackThermalNote =>
      'Mosaico THEMIS-IR de día · unos 100 m/px · brillo relativo, no temperatura calibrada · fuente: Mars Trek';

  @override
  String get stackMinerals => 'Mineralogía';

  @override
  String get stackRadiation => 'Radiación';

  @override
  String get stackGeology => 'Unidad geológica';

  @override
  String get stackGeologyNote =>
      'Hesperian transition undivided unit (unidad de transición del Hespérico, sin dividir) · mapa geológico global del USGS (SIM 3292), escala 1:20 000 000, solo como contexto · fuente: Mars Trek';

  @override
  String get fieldElevation => 'Elevación';

  @override
  String get fieldSlope => 'Pendiente local';

  @override
  String get fieldRoughness => 'Rugosidad';

  @override
  String get fieldFromHabitat => 'Desde el hábitat';

  @override
  String get fieldDeltaElev => 'vs hábitat';

  @override
  String get opsTitle => 'OPERACIÓN EN EL SITIO';

  @override
  String get opsAllot => 'Tiempo de trabajo';

  @override
  String get opsVisitedBy => 'Incluido en las rutas';

  @override
  String get opsEdit => 'Editar objetivo';

  @override
  String get opsHere => 'Coordenadas';

  @override
  String get priorityHigh => 'ALTA';

  @override
  String get priorityMedium => 'MEDIA';

  @override
  String get priorityLow => 'BAJA';

  @override
  String stackPending(String source) {
    return 'Sin datos todavía · pendiente $source';
  }

  @override
  String get safeOverall => 'ESTADO GENERAL';

  @override
  String get safeGo => 'GO';

  @override
  String get safeCaution => 'PRECAUCIÓN';

  @override
  String get safeNoGo => 'NO-GO';

  @override
  String get safePending => 'PENDIENTE';

  @override
  String get safeIncomplete => 'DATOS INCOMPLETOS';

  @override
  String safeRealChecks(int n) {
    return '$n de 5 verificaciones usan datos reales';
  }

  @override
  String get checkRad => 'RAD';

  @override
  String get checkWeather => 'CLIMA';

  @override
  String get checkDust => 'POLVO';

  @override
  String get checkTerrain => 'TERRENO';

  @override
  String get checkConsumables => 'CONSUMIBLES';

  @override
  String get panelRadiation => 'RADIACIÓN · MSL RAD';

  @override
  String get panelWeather => 'CLIMA · MSL REMS';

  @override
  String get panelDust => 'POLVO Y OPACIDAD';

  @override
  String get panelTerrain => 'PELIGRO DEL TERRENO';

  @override
  String get panelConsumables => 'CONSUMIBLES Y REGRESO A PIE';

  @override
  String get pendingPhase4 =>
      'SIN DATOS TODAVÍA. Las series de RAD y REMS del Planetary Data System llegan en la fase 4.';

  @override
  String get exampleDose => 'Dosis de esta ruta con la tasa de ejemplo';

  @override
  String get exampleRate => 'Tasa de ejemplo';

  @override
  String get terrainByClass => 'Distancia por clase de pendiente';

  @override
  String get terrainRoughness => 'Rugosidad media';

  @override
  String get walkbackTitle => 'Regreso por parada';

  @override
  String get colStop => 'PARADA';

  @override
  String get colAlong => 'POR LA RUTA';

  @override
  String get colStraight => 'DESDE EL HÁBITAT';

  @override
  String get colWalkback => 'REGRESO DIRECTO A PIE';

  @override
  String get consO2 => 'Oxígeno al volver';

  @override
  String get consReserve => 'Reserva mínima';

  @override
  String get consTime => 'Tiempo de salida usado';

  @override
  String get consMax => 'Salida máxima';

  @override
  String get consCompare => 'Todas las rutas';

  @override
  String get consNote =>
      'Regreso a pie en línea recta a la velocidad en llano. Ignora pendientes y obstáculos.';

  @override
  String get safeSolTitle => 'SOL DE REFERENCIA';

  @override
  String get safeSolNote =>
      'Evaluación de un período pasado: datos medidos de REMS (hasta el sol 4843, marzo de 2026) y de RAD. No es un pronóstico ni las condiciones de hoy.';

  @override
  String get radRate => 'Tasa de dosis (detector E)';

  @override
  String get radBaseline => 'Línea base (60 sols)';

  @override
  String get radRatio => 'vs línea base';

  @override
  String get radProjected => 'Dosis de esta ruta';

  @override
  String get radHistory =>
      'Tasa de dosis media diaria, 60 sols hasta el sol de referencia';

  @override
  String get radUnitNote =>
      'Dosis absorbida en plástico equivalente a tejido. No es dosis equivalente (mSv).';

  @override
  String get radSource => 'RAD · NASA SPDF CDAWeb';

  @override
  String get radB => 'Detector B (silicio, sin la fuente del rover)';

  @override
  String get wxProfile => 'TEMPERATURA DEL AIRE POR HORA LOCAL (LMST)';

  @override
  String get wxAir => 'Temperatura del aire';

  @override
  String get wxGround => 'Temperatura del suelo';

  @override
  String get wxPressure => 'Presión';

  @override
  String get wxUv => 'Pico de UV (A+B+C)';

  @override
  String get wxHumidity => 'Humedad (máx.)';

  @override
  String get wxWindow => 'Ventana de la salida';

  @override
  String get wxMinWindow => 'Temperatura mínima del aire en la ventana';

  @override
  String get wxCoverage => 'horas con dato';

  @override
  String get wxNoData => 'sin dato';

  @override
  String get wxSource => 'REMS · NASA PDS Atmósferas';

  @override
  String get dustNone =>
      'El PDS no tiene un producto de opacidad del polvo de REMS. Pendiente de otra fuente.';

  @override
  String get rulesTitle => 'REGLAS GO / NO-GO (supuestos del equipo)';

  @override
  String get rulesRad => 'Radiación, múltiplo de la línea base';

  @override
  String get rulesAir => 'Temperatura del aire en la ventana de la salida';

  @override
  String get rulesStart => 'Inicio de la salida (hora solar media local)';

  @override
  String get rulesCrew =>
      'Supuesto: la salida es de dos astronautas; los consumibles y la dosis se calculan para uno. No se modela un rover.';

  @override
  String get rulesNote =>
      'Los umbrales son supuestos, no límites de la NASA. El polvo no tiene datos, así que el estado general queda incompleto.';

  @override
  String get safeIncomplete2 => 'EL POLVO NO TIENE DATOS';

  @override
  String get minLabel => 'mín.';

  @override
  String get maxLabel => 'máx.';

  @override
  String get utcLabel => 'UTC';

  @override
  String get wxAirShort => 'AIRE';

  @override
  String get wxGroundShort => 'SUELO';

  @override
  String get navHelmet => 'CASCO';

  @override
  String get navMission => 'MISIÓN';

  @override
  String get missionTitle => 'EVA simulada: telemetría del traje';

  @override
  String get missionNote =>
      'Simulación. El astronauta recorre la ruta seleccionada; cada lectura se calcula para esa posición con los datos reales de elevación, pendiente y REMS. El tiempo, el oxígeno y la dosis se interpolan de los totales de la ruta. No hay signos vitales ni sensores del traje: no hay datos para ellos.';

  @override
  String get missionStatus => 'Estado';

  @override
  String get missionNominal => 'NOMINAL';

  @override
  String get missionCaution => 'PRECAUCIÓN';

  @override
  String get missionAlert => 'ALERTA';

  @override
  String get missionPosition => 'Posición';

  @override
  String get missionDose => 'Dosis hasta aquí (est.)';

  @override
  String get missionO2Need => 'Oxígeno para volver a pie';

  @override
  String get missionO2Reserve => 'Reserva al regresar';

  @override
  String get missionSpeed => 'Velocidad';

  @override
  String get missionReset => 'Volver al inicio';

  @override
  String get missionAlertPnr => 'Pasado el punto de no retorno';

  @override
  String get missionAlertO2 => 'Oxígeno por debajo de lo que pide volver a pie';

  @override
  String get missionAlertO2Low => 'Reserva de oxígeno al regresar menor de 10%';

  @override
  String get missionAllClear => 'Sin alertas en esta posición';

  @override
  String get missionDone => 'Ruta terminada';

  @override
  String get helmetNoRoute => 'Calculando rutas…';

  @override
  String get helmetHabitat => 'HÁBITAT';

  @override
  String get helmetConcept => 'CONCEPTO';

  @override
  String get helmetTitle => 'Pantalla de visera del casco (HUD)';

  @override
  String get helmetNote =>
      'Concepto visual. La posición es simulada a lo largo de la ruta seleccionada. Las distancias, el rumbo, la pendiente y los objetivos salen del modelo de rutas; la temperatura del aire sale de REMS. No hay signos vitales ni sensores del traje: no hay datos para ellos.';

  @override
  String helmetBackdrop(String source) {
    return 'Fondo: foto real de Curiosity ($source); no es la vista de esta ruta.';
  }

  @override
  String get helmetNext => 'Siguiente';

  @override
  String helmetSlopeWarn(String deg, String dist) {
    return 'PRECAUCIÓN: PENDIENTE DE $deg° A $dist m';
  }

  @override
  String get helmetReturnTitle => 'REGRESO';

  @override
  String get helmetHabDist => 'Al hábitat (línea recta)';

  @override
  String get helmetWalkBack => 'Tiempo de regreso a pie';

  @override
  String get helmetPnr => 'Punto de no retorno en';

  @override
  String get helmetBeyondPnr => 'Pasado el punto';

  @override
  String get helmetYes => 'SÍ';

  @override
  String get helmetNo => 'NO';

  @override
  String get helmetHereTitle => 'AQUÍ';

  @override
  String get helmetHeading => 'Rumbo';

  @override
  String get helmetSlopeAhead => 'Pendiente adelante (90 m)';

  @override
  String get helmetAir => 'Temperatura del aire';

  @override
  String get helmetElapsed => 'Transcurrido (est.)';

  @override
  String get helmetO2 => 'Oxígeno (est.)';

  @override
  String get helmetPlay => 'Reproducir';

  @override
  String get helmetPause => 'Pausa';

  @override
  String get helmetProgress => 'Avance en la ruta';

  @override
  String get helmetSimulated => 'Posición simulada';

  @override
  String get helmetFootnote =>
      'El tiempo transcurrido y el oxígeno se interpolan de los totales de la ruta. La temperatura del aire usa el perfil por hora de REMS del sol de referencia a la hora local de la posición simulada.';

  @override
  String get modeTitle => 'MODO DE SALIDA';

  @override
  String get modeFoot => 'A pie';

  @override
  String get modeRover => 'Con rover';

  @override
  String get metricRover => 'Rover';

  @override
  String get metricRoverNone => 'no se usa';

  @override
  String get assumeRoverTitle => 'SUPUESTOS DEL MODO CON ROVER';

  @override
  String get assumeRoverSpeed => 'Velocidad del rover';

  @override
  String get assumeRoverSlope => 'Límite de pendiente del rover';

  @override
  String get assumeRoverRough => 'Rugosidad máxima del rover';

  @override
  String get assumeRoverO2 => 'Gasto de oxígeno sobre el rover';

  @override
  String get assumeRoverTransfer => 'Tiempo de subir o bajar';

  @override
  String get assumeRoverNote =>
      'El rover se deja en un punto de la ruta: va de ida por el primer tramo que puede recorrer y vuelve por el último. El resto es a pie. Las rutas siguen optimizadas para caminar. La velocidad y la pendiente salen del vehículo lunar de Apolo (NASA, NTRS 20250011301); los demás valores son supuestos del equipo.';

  @override
  String get modeSupport => 'Apoyo';

  @override
  String get metricEmergency => 'Regreso en emergencia';

  @override
  String get metricEmergencyFoot => 'A pie';

  @override
  String get assumeDispatch => 'Salida del rover de apoyo tras el aviso';

  @override
  String get assumeSupportNote =>
      'Un rover espera en el hábitat. La tripulación hace la misma ruta; el rover no cambia su tiempo ni su oxígeno. En una emergencia sale tras el aviso, solo anda por donde puede y se encuentra con el astronauta en el camino (se elige el mejor punto de encuentro). Acorta el tiempo de regreso, mueve el punto de no retorno y reduce el radio que cuenta en el puntaje de peligro. La velocidad y la pendiente salen del vehículo lunar de Apolo (NASA, NTRS 20250011301); los demás valores son supuestos del equipo.';

  @override
  String get modePair => 'Pareja';

  @override
  String get routePair1 => 'Astronauta 1';

  @override
  String get routePair2 => 'Astronauta 2';

  @override
  String get reasonOtherAstronaut => 'el otro astronauta';

  @override
  String get reasonNotInPair => 'la pareja no llega';

  @override
  String get pairTitle => 'SALIDA EN PAREJA';

  @override
  String get pairVisits => 'Objetivos';

  @override
  String get pairSeparation => 'Separación máxima';

  @override
  String get pairO2Min => 'Oxígeno mínimo';

  @override
  String pairNone(String limit) {
    return 'Ninguna pareja de rutas mantiene a los dos astronautas a menos de $limit m uno del otro.';
  }

  @override
  String get pairNote =>
      'La duración es la del astronauta que más tarda. El peligro es el mayor de los dos. El éxito cuenta los objetivos que visita cualquiera de los dos. Cada astronauta tiene su propio oxígeno.';

  @override
  String get assumePairTitle => 'SUPUESTOS DEL MODO EN PAREJA';

  @override
  String get assumePairSep => 'Separación máxima';

  @override
  String get assumePairSample => 'Separación comprobada cada';

  @override
  String get assumePairNote =>
      'Dos astronautas salen juntos del hábitat, se reparten los objetivos y deben mantenerse siempre a menos de la separación máxima (línea de vista y comunicación). Las salidas reales de la NASA van en pareja y juntas, así que este reparto es una extensión nuestra y el límite es un supuesto sin referencia. Cada ruta sigue la regla de ciencia: factible y, si tiene más de un objetivo, con margen cómodo.';

  @override
  String get siteChange => 'Cambiar de sitio';

  @override
  String get sitePending => 'Datos en preparación';

  @override
  String get siteLoadError =>
      'No se pudo cargar el sitio. Se queda abierto el actual.';

  @override
  String get modeObjective => 'Por objetivo';

  @override
  String get transportTitle => 'Transporte';

  @override
  String get transportFoot => 'A pie';

  @override
  String get transportVehicle => 'Vehículo';

  @override
  String get transportHybrid => 'Híbrido';

  @override
  String get transportHint =>
      'Solo cuenta en el modo «Por objetivo». Vehículo: se va en vehículo hasta el objetivo. Híbrido: en vehículo hasta donde el terreno lo permita y el resto a pie.';

  @override
  String get reasonRover => 'el vehículo quedaría sin recoger';

  @override
  String get assumeObjectiveNote =>
      'Cada objetivo trae su transporte. Hay un solo vehículo: sale del hábitat con el astronauta y se queda donde se aparca; para usarlo otra vez, la ruta tiene que pasar por ese punto. El camino a un objetivo «Vehículo» se busca solo por celdas que el vehículo puede recorrer. Velocidad, pendiente, rugosidad y cambio son los del rover.';

  @override
  String transportNoteNotHere(String name) {
    return '$name: el vehículo no está en este tramo, así que se hace a pie.';
  }

  @override
  String transportNoteCannotStart(String name) {
    return '$name: el vehículo no puede salir de aquí, así que se hace a pie.';
  }

  @override
  String transportNoteBlocked(String name) {
    return '$name: el vehículo no avanza en este tramo, así que se hace a pie.';
  }

  @override
  String transportNotePartial(String name) {
    return '$name: el vehículo no llega hasta ahí. Va hasta donde puede y el resto es a pie.';
  }

  @override
  String transportNoteNoRecovery(String name) {
    return '$name: en el regreso no hay un punto para recoger otra vez el vehículo, así que se hace a pie.';
  }

  @override
  String get transportNoteStranded =>
      'El vehículo quedaría sin recoger: el regreso no pasa por donde se aparcó.';

  @override
  String get msnTitle => 'Misiones';

  @override
  String get msnNew => 'Nueva misión';

  @override
  String get msnDuplicate => 'Duplicar';

  @override
  String get msnDelete => 'Borrar';

  @override
  String get msnDeleteLast => 'No se puede borrar la única misión.';

  @override
  String get msnDeleteTitle => '¿Borrar la misión?';

  @override
  String msnDeleteBody(String name) {
    return 'Se borrará $name de este dispositivo. No se puede deshacer.';
  }

  @override
  String get msnName => 'Nombre';

  @override
  String get msnNotes => 'Notas';

  @override
  String get msnSite => 'Sitio';

  @override
  String msnObjectives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count objetivos',
      one: '1 objetivo',
      zero: 'Sin objetivos',
    );
    return '$_temp0';
  }

  @override
  String get msnConsumables => 'Consumibles';

  @override
  String get msnEquipment => 'Equipo y herramientas';

  @override
  String get msnAddItem => 'Añadir';

  @override
  String get msnEmptyItems => 'Nada añadido.';

  @override
  String get msnItemName => 'Elemento';

  @override
  String get msnItemQty => 'Cantidad';

  @override
  String get msnItemUnit => 'Unidad';

  @override
  String get msnItemMass => 'Masa por unidad (kg)';

  @override
  String msnMassTotal(String kg) {
    return 'Masa declarada: $kg kg';
  }

  @override
  String get msnAssumeNote =>
      'Los consumibles y el equipo los escribe el usuario. No son datos de la NASA y todavía no cambian el cálculo de rutas.';

  @override
  String get msnRoutesNote =>
      'Las rutas se calculan con los objetivos de la misión abierta.';

  @override
  String get msnExport => 'Copiar JSON';

  @override
  String get msnCopied => 'Misión copiada como JSON.';

  @override
  String get msnOpenError => 'No se pudo abrir el sitio de esa misión.';

  @override
  String get msnCurrent => 'Abierta';

  @override
  String get siteIndicativeTag => 'Indicativo';

  @override
  String get siteIndicativeNote =>
      'Rutas indicativas: el relieve sale de un modelo de 200 m, así que las pendientes locales salen alisadas y la rugosidad no se conoce. Sirven como aproximación, no para evitar rocas ni pendientes pequeñas.';

  @override
  String get layerSlope15 => 'Pendiente mayor de 15 %';

  @override
  String get layerTransit => 'Zonas de tránsito (DCI + inercia térmica)';

  @override
  String get layerThermalNight => 'Inercia térmica relativa (THEMIS-IR noche)';

  @override
  String get layerMineralsPts => 'Minerales acuosos e hidratados';

  @override
  String get layerAqueousPts => 'Minerales acuosos · biofirmas';

  @override
  String get layerHydrousPts => 'Minerales hidratados (CRISM, OMEGA)';

  @override
  String get layerValleys => 'Redes de valles (Hynek 2010)';

  @override
  String get legendBiosigTitle => 'Búsqueda de biofirmas (desde órbita)';

  @override
  String get legendCarbonate => 'Carbonato';

  @override
  String get legendValleys => 'Red de valles (agua antigua)';

  @override
  String get legendBiosigNote =>
      'Filosilicatos y carbonatos: suelo con más probabilidad de conservar biofirmas. Detecciones orbitales de Mars Trek (NASA), no muestras. En Meridiani no hay carbonatos registrados; los sulfatos no se muestran.';

  @override
  String get layerZones => 'Zonas de exploración';

  @override
  String get legendTransitTitle => 'Zonas de tránsito (TES, 3.5 km por píxel)';

  @override
  String get legendTransitGreen => 'Mejor tránsito: DCI > 0.96 e inercia > 300';

  @override
  String get legendTransitYellow =>
      'Tránsito seguro: DCI > 0.95 e inercia de 180 a 300';

  @override
  String get legendTransitRed => 'Evitar: DCI < 0.94 e inercia < 150';

  @override
  String get legendTransitNone => 'Sin clasificar (fuera de esas reglas)';

  @override
  String get legendMineralsTitle => 'Minerales (desde órbita)';

  @override
  String get legendSulfate => 'Sulfato';

  @override
  String get legendPhyllo => 'Filosilicato (arcilla)';

  @override
  String get legendHydrous => 'Mineral hidratado';

  @override
  String get legendZonesTitle => 'Zonas de exploración (NASA, 2015)';

  @override
  String get legendHabitation => 'Zona habitable';

  @override
  String get legendLanding => 'Sitio de aterrizaje';

  @override
  String get legendEz => 'Zona de exploración';

  @override
  String get legendRoi => 'Región de interés';

  @override
  String get legendEzRadius => 'Radio de 100 km';

  @override
  String get legendSlope15 => 'Pendiente mayor de 15 % (evitar para una base)';

  @override
  String get transitNote =>
      'Los umbrales son supuestos del equipo sin referencia. El DCI y la inercia térmica salen de TES a 3.5 y 7.5 km: en una ventana de pocos kilómetros la capa tiene uno o dos colores.';

  @override
  String get srcTitle => 'Fuentes y datos';

  @override
  String get srcIntro =>
      'Cada valor de la app es de uno de tres tipos: dato real de la NASA, el USGS o ASU; un valor calculado por el equipo con esos datos; o un supuesto del equipo. Los archivos y las fechas de cada fuente están en las notas del proyecto (RECURSOS.md).';

  @override
  String get srcReal => 'Datos reales';

  @override
  String get srcModeled => 'Calculado por el equipo';

  @override
  String get srcAssumed => 'Supuestos';

  @override
  String get srcClose => 'Cerrar';

  @override
  String get safeNoEnvData =>
      'Este sitio no tiene mediciones de radiación ni de clima: RAD y REMS están en Curiosity, en el cráter Gale, así que esas dos verificaciones quedan pendientes. La dosis de las rutas usa la línea base de Gale como supuesto. Meridiani está más alto, con menos atmósfera encima, así que la dosis real probablemente es mayor.';

  @override
  String get doseGaleNote =>
      'Este sitio no tiene mediciones de radiación: la dosis usa la línea base de Gale (supuesto).';

  @override
  String get srcLink => 'Fuentes';

  @override
  String get layerNames => 'Nombres oficiales (UAI)';

  @override
  String get layerCraters => 'Cráteres de 1 km o más';

  @override
  String get layerGeology => 'Geología y dunas';

  @override
  String get routeAreaLabel => 'ÁREA DE RUTAS';

  @override
  String get legendGeologyTitle => 'Geología y dunas (USGS, escala global)';

  @override
  String get legendGeologyNote =>
      'El código de la unidad se escribe sobre cada área (por ejemplo Htu, mNh). Los campos de dunas salen en ámbar. El mapa es de escala global: no resuelve afloramientos pequeños.';

  @override
  String get legendCraters => 'Cráter de 1 km o más (base de Robbins)';

  @override
  String get legendNames => 'Nombre oficial de un rasgo (UAI)';

  @override
  String get contextNote =>
      'Fuera del recuadro punteado hay una imagen más gruesa (CTX) de contexto. Las rutas solo se calculan dentro del recuadro.';

  @override
  String get siteReachTag => 'Largo alcance';

  @override
  String get siteReachNote =>
      'Rutas de largo alcance: la rejilla es de 16 m sobre un relieve real, así que no ve obstáculos pequeños y la rugosidad no se conoce. El sitio de 4 km tiene el detalle; este llega a todo el alcance de la EVA (unos 12 km).';

  @override
  String mapTraceLegend(
    String viewW,
    String viewH,
    String traceW,
    String traceH,
  ) {
    return 'Vista actual: $viewW × $viewH km  ·  Traza disponible: $traceW × $traceH km';
  }
}

# Propuesta: ARES PATH (nombre provisional)

Borrador del 2026-11-14. Alcance recortado al objetivo del desafío: una herramienta hiperlocal para una caminata. Lo que queda fuera está en "Trabajo futuro". Las decisiones abiertas están al final.

## Objetivo

Que un astronauta en Marte pueda planificar y ejecutar una caminata segura y con ciencia útil, usando datos reales de la NASA combinados en un solo mapa por capas.

Criterio de éxito en la demo: el jurado ve rutas reales sobre terreno real, entiende por qué una es más segura que otra y ve qué ciencia se hace en cada parada.

## Qué es

Aplicación de tableta que reúne la información disponible de la NASA sobre una zona de caminata en Marte y la convierte en rutas comparables, cada una con sus implicaciones y sus puntajes. El sitio de demostración es la zona de crestas boxwork del Monte Sharp, en el cráter Gale.

Funciones de la primera versión:

1. **Mapa por capas a escala de caminata.** Óptico, pendiente, térmico, minerales y radiación sobre el mismo terreno (pocos kilómetros).
2. **Varias rutas, no una.** Para cada salida el sistema propone tres rutas (la más segura, la más rápida y la de más ciencia) con distancia, tiempo, oxígeno, dosis de radiación y punto de no retorno.
3. **Puntajes por ruta.** Puntaje de peligro y puntaje de éxito de misión, con el desglose a la vista.
4. **Decisión de salida.** Panel GO / NO-GO con radiación, clima, polvo y consumibles.
5. **Objetivos definidos por el astronauta.** El usuario marca sus propios objetivos en el mapa, además de los sugeridos.

Extras si hay tiempo: fichas de objetivos científicos con foto de rover y pantalla de casco (solo como concepto visual).

Diferencia frente a Mars Trek: Mars Trek muestra capas a escala regional. ARES PATH convierte las capas en una decisión: por dónde camino, cuánto tardo, salgo o no salgo.

## Punto de partida

La primera versión tiene un único punto de partida: un hábitat en el cráter Gale, cerca de las crestas boxwork. Todos los datos reales se preparan para esa zona.

Como contexto, la app muestra un mapa base del entorno de Gale para ubicar la zona de caminata. Ese mapa es solo de referencia: no lleva análisis ni rutas.

## Objetivos definidos por el astronauta

El astronauta toca el mapa para crear un objetivo y le asigna nombre, tipo (muestra, imagen, medición, instalación de equipo), prioridad y tiempo de trabajo. La app ofrece también objetivos sugeridos a partir de los datos: zonas con minerales hidratados, contactos geológicos y sitios ya estudiados por Curiosity.

Al crear o mover un objetivo, la app muestra los datos de ese punto en todas las capas y avisa si cae en zona prohibida.

Consecuencia técnica: las rutas no se pueden dejar calculadas de antemano. El cálculo se ejecuta dentro de la app cuando el usuario cambia sus objetivos. Lo que se prepara antes es el mapa de costos de la zona.

## Puntajes por ruta

Cada ruta recibe dos puntajes de 0 a 100, siempre con su desglose.

**Puntaje de peligro.** Suma ponderada de:

- Exposición a pendiente (metros recorridos por encima de cada umbral).
- Terreno suelto o rocoso.
- Dosis de radiación acumulada en la salida.
- Distancia y tiempo más allá del punto de regreso a pie.
- Margen de consumibles al volver (oxígeno, batería).
- Condiciones del día (polvo, temperatura, hora de puesta de sol).

**Puntaje de éxito de misión.** Fórmula simple que combina:

- Valor científico alcanzado (objetivos visitados, según prioridad).
- Margen de tiempo dentro de la ventana de la salida.
- Margen de consumibles.
- Penalización por peligro.

Los pesos son supuestos del equipo, no un estándar de la NASA. Se muestran en pantalla. El puntaje ordena rutas; no sustituye el criterio de la tripulación.

## Formato del mapa

- **Formato elegido:** aplicación de tableta que el astronauta lleva consigo (Flutter, Android). Hay también versión web para verla en PC durante la demostración.
- **Tipo de producto:** herramienta digital interactiva, no una instantánea. El usuario enciende capas, crea y mueve objetivos y ve cómo cambian las rutas y los puntajes.
- **Un solo sitio:** el sitio de demostración es Gale. Un generador de mapas de otros lugares o con otros datos queda como trabajo futuro (ver abajo).
- **Pantalla de casco (HUD):** el desafío menciona la visera del casco. Es un concepto visual con la posición simulada sobre la ruta (pestaña «Casco»).

## Quién sale: parejas y sin rover

- **Supuesto:** la salida se hace en pareja, como se hace en las caminatas reales. La app calcula consumibles y dosis para un astronauta. Que sean dos no cambia la ruta, y la regla de salida en pareja se muestra en el panel de reglas GO / NO-GO.
- **Modo con rover (opcional):** el panel de rutas tiene un selector «A pie / Con rover». Con rover, el vehículo se deja en un punto de la ruta, va de ida por el primer tramo transitable y vuelve por el último, y el resto es a pie. Cambia el tiempo, el oxígeno y los puntajes; las rutas siguen optimizadas para caminar. En este terreno el rover ayuda poco con el límite de 20° (una parte pequeña de cada ruta), porque el hábitat solo se conecta por un paso de unos 20°. Los supuestos están a la vista.
- **Modo con rover de apoyo (opcional):** un rover espera en el hábitat. Si hay una emergencia sale tras el aviso y se encuentra con el astronauta; acorta el tiempo de regreso y mueve el punto de no retorno, pero no cambia la ruta ni el consumo. En este terreno ayuda poco con el límite de 20° (solo llega por el primer tramo transitable).
- **Modo en pareja (opcional):** dos astronautas salen juntos, se reparten los objetivos y deben mantenerse siempre a menos de una separación máxima (supuesto de 500 m, para tener línea de vista y comunicación). Cada uno tiene su ruta y su oxígeno. Se muestra la separación máxima contra el límite, la duración (la del que más tarda) y los puntajes de la pareja. En la demostración la pareja visita tres objetivos en el mismo tiempo en que una sola persona visita dos. Es una extensión nuestra: las salidas reales van en pareja y juntas. Un rover presurizado o robótico que lleve a la tripulación o las herramientas cambiaría la velocidad, los consumibles y las rutas posibles, y no está modelado. Queda como trabajo futuro.
- **Puntos de encuentro y combinación de modos:** el modo en pareja no se combina con el rover ni modela puntos de encuentro. Queda como trabajo futuro.

## Inspiración en misiones a otros destinos

El desafío pide mirar cómo han hecho este tipo de mapas las misiones de la NASA a otros destinos. Lo que sigue son referencias de la planificación de caminatas en la Luna (Artemis). Los títulos y resúmenes salen de los registros públicos del servidor técnico de la NASA (NTRS), verificados el 2026-11-14. Son contexto de diseño, no validación de nuestros umbrales.

| Referencia | Qué muestra | Qué tomamos |
|---|---|---|
| Artemis Geospatial Data Team ([NTRS 20230006633](https://ntrs.nasa.gov/citations/20230006633)) | El equipo de la NASA produce modelos digitales de terreno, un índice de rugosidad del terreno y mapas de peligro para planificar recorridos teniendo en cuenta pendiente y rocas | La idea de derivar de un modelo de elevación capas de pendiente, rugosidad y peligro, y combinarlas en un costo de ruta |
| Evaluación de las regiones de interés de Artemis ([NTRS 20220012753](https://ntrs.nasa.gov/citations/20220012753)) | Usa rutas de ejemplo y un criterio de pendiente de 20° como objetivo inicial de planificación | Un límite de pendiente simple, visible y configurable. Nuestro límite de precaución es 20° y el de la ruta segura 22°, supuestos del equipo |
| Rendimiento del vehículo lunar de Apolo ([NTRS 20250011301](https://ntrs.nasa.gov/citations/20250011301)) | Compara el desempeño real de los vehículos de Apolo 15 y 16 con la pendiente y la rugosidad del terreno | Contexto histórico de que las salidas reales se planifican por pendiente. Es de un vehículo, no de una caminata a pie |
| Selección de sitios de Artemis III ([NTRS 20250011660](https://ntrs.nasa.gov/citations/20250011660)) | De 13 a 9 regiones candidatas, con pendiente, iluminación y visibilidad de la Tierra como criterios | Ver el sitio como un conjunto de criterios que se muestran juntos. Nosotros mostramos pendiente, radiación, clima y consumibles |
| NASA Worldview | Visor de capas por interruptor y opacidad (de la Tierra) | El panel de capas con interruptor y opacidad |

Lo que no hicimos: no cotejamos el flujo de trabajo con la herramienta Moon Trek, porque la búsqueda no encontró su documentación. Tampoco hay un traje con limitaciones de movilidad medidas: los parámetros de pendiente y velocidad son supuestos.

## Período de tiempo

La app evalúa un **período pasado**, no el presente ni el futuro. El desafío permite elegir un período pasado, uno futuro o ninguno.

- **Clima (REMS):** soles 4814 a 4843 del PDS (19 de febrero al 22 de marzo de 2026). La pantalla de Seguridad tiene un selector de sol y avisa, en una línea fija, que la evaluación es de un período pasado, no un pronóstico ni las condiciones de hoy.
- **Radiación (RAD):** la línea base sale de los 60 sols previos al periodo de REMS; la dosis del sol elegido sale de la serie de CDAWeb.
- **Terreno (relieve, ortofoto, pendiente):** no depende del tiempo; es información estable.
- **Pronóstico:** fuera de alcance. Las fuentes que usamos no traen datos predichos y no se simula el clima. Queda como trabajo futuro (modelos de clima de Marte).
- **Polvo:** sin dato, porque el PDS no tiene un producto de REMS para él.

## Meridiani, misiones y transporte (versión 0.5)

El usuario pidió ampliar el alcance el 2026-11-14. Lo que se añadió:

- **Meridiani Planum como segundo lugar**, con tres ventanas: **Endeavour** (4 × 4 km, relieve de 1 m y ortofoto HiRISE, rutas de calidad alta), **zona habitable** (20 × 20 km, relieve de 200 m, rutas indicativas) y **contexto regional** (100 × 100 km, para las capas científicas). La zona habitable es la de la primera reunión de zonas de exploración de la NASA (2015); no existe una zona «East Meridiani» en esos datos.
- **Misiones guardadas**: una misión reúne un sitio, uno o más objetivos (de los que se calculan las rutas), consumibles, equipo y notas. Se guardan en la tableta.
- **Transporte por objetivo**: a pie, en vehículo o híbrido (vehículo hasta donde el terreno lo permita y el resto a pie). El criterio entra en el cálculo de rutas.
- **Capas científicas y de tránsito**: pendiente mayor de 15 %, zonas de tránsito (índice de polvo e inercia térmica de TES, con umbrales del equipo), inercia térmica relativa de THEMIS-IR de noche, minerales acuosos e hidratados, y zonas de exploración.
- **Honestidad de los datos**: Meridiani no tiene mediciones de radiación ni de clima (RAD y REMS son de Curiosity, en Gale); la interfaz lo dice y la dosis usa la línea base de Gale como supuesto. Los objetivos de Meridiani son de ejemplo. Hay una lista de fuentes dentro de la app.

Un sitio con base permanente y misiones sucesivas (como plantea el texto del usuario sobre Meridiani) necesitaría además estudiar el aterrizaje repetido en un mismo punto y el uso de recursos locales; eso queda fuera de este alcance.

## Por qué el cráter Gale

1. **Es el único lugar de Marte con radiación medida en superficie.** El instrumento RAD de Curiosity mide dosis desde 2012. Ningún otro rover lleva un instrumento equivalente. El enunciado pide considerar radiación y clima espacial; en Gale ese dato es real y local, no una estimación.
2. **Tiene más de una década de clima local.** La estación REMS de Curiosity registra temperatura, presión, humedad y radiación ultravioleta por sol.
3. **El objetivo científico ya está validado por la NASA.** Curiosity estudió las crestas boxwork en 2025. El enunciado del desafío usa justo ese ejemplo y recomienda la región del Monte Sharp.
4. **Hay un mapa de ruta oficial de referencia.** Uno de los cinco recursos del desafío es la ruta propuesta de Curiosity por el Monte Sharp. Sirve para comparar nuestras rutas calculadas con una real.
5. **Tiene verdad de terreno.** Curiosity recorrió la zona. Sus fotos permiten mostrar la vista en primera persona de cada parada y comprobar si el mapa de pendientes coincide con lo que se ve en el suelo.
6. **Cobertura orbital de alta resolución.** La zona tiene imágenes HiRISE y modelos de elevación, necesarios para calcular pendientes a escala de caminata.
7. **Buenas condiciones físicas.** Está cerca del ecuador (4.6° S), con temperaturas menos extremas y buena luz solar. Está a unos 4.5 km bajo el nivel de referencia, con más atmósfera encima.

Limitación que hay que reconocer: en Gale no hay hielo de agua confirmado cerca de la superficie, que es un criterio habitual para elegir sitios de misiones tripuladas. Curiosity y Perseverance aterrizaron dentro de cráteres, pero los estudios para misiones tripuladas favorecen llanuras de latitudes medias con hielo accesible. Elegimos Gale por la calidad de sus datos, no porque sea el sitio de aterrizaje más probable.

## Datos

| Capa | Fuente | Para qué sirve |
|---|---|---|
| Óptico | HiRISE (orbitador MRO) | Ver rocas y crestas a 25 cm por píxel |
| Relieve | Modelo de elevación HiRISE | Calcular pendientes y zonas prohibidas |
| Térmico | THEMIS (Mars Odyssey) | Distinguir roca firme de arena suelta |
| Minerales | CRISM (orbitador MRO) | Ubicar sulfatos y arcillas de interés |
| Radiación y clima | RAD y REMS (Curiosity) | Decidir si se puede salir |
| Vista en el suelo | Cámaras de Curiosity | Mostrar qué se verá en cada parada |

Regla de honestidad en la interfaz: cada capa indica si el dato es medido, modelado o de ejemplo, y su resolución.

Datos reales hoy: óptico, relieve, térmico (THEMIS-IR de Mars Trek, brillo relativo), contexto geológico, radiación y clima (RAD y REMS) y las posiciones de Curiosity. Minerales (CRISM), polvo y fotos de rover siguen como ejemplo o pendientes. El detalle de cada fuente está en `RECURSOS.md` y el estado, en `RETOMAR.md`.

Pendiente de verificar: cobertura exacta del modelo de elevación HiRISE sobre la zona boxwork.

## Cálculo de ruta

Algoritmo A* sobre un raster de costo. No se usa IA para calcular la ruta.

- Costo por celda: pendiente, rugosidad y arena suelta. Las celdas por encima del límite quedan prohibidas.
- El resultado es determinista y explicable: cada giro tiene una causa que se puede mostrar.
- Varias rutas: el mismo algoritmo se ejecuta con pesos distintos (prioridad a seguridad, a tiempo o a ciencia). Cada resultado pasa por el cálculo de puntajes.
- La seguridad de la tripulación no admite una caja negra.

## Navegación durante la caminata

En Marte no hay GPS. Como concepto, la posición se obtendría combinando el punto de partida conocido, sensores de movimiento del traje, comparación de la cámara del casco con el mapa orbital y balizas de radio en el hábitat y el rover.

En el hackathon no se construye. La demo simula la posición del astronauta sobre la ruta.

## Tecnología

- **Dart / Flutter:** aplicación de tableta Android, con versión web para verla en una PC. Incluye el cálculo de rutas.
- **Python + rasterio (trae GDAL):** preparación de datos (recorte de rasters, pendiente, teselas, mapa de costos). Se ejecuta antes de la demo.

Sin servidor: mapas y datos van dentro de la aplicación. Funciona sin red, que es lo coherente con Marte: la comunicación con la Tierra tarda minutos.

## Fases

1. Datos: descargar y recortar HiRISE y el modelo de elevación de la zona, generar teselas, pendiente y mapa de costos. Es el mayor riesgo técnico; va primero.
2. Ruta: A* con tres perfiles de pesos y cálculo de puntajes.
3. Aplicación: mapa con capas, rutas comparadas y creación de objetivos.
4. Entorno: series de radiación (RAD) y clima (REMS), panel GO / NO-GO.
5. Extras: fichas de ciencia y pantalla de casco.
6. Entrega: video, texto y declaración de uso de IA.

El prototipo de Google Stitch (cinco pantallas) es la guía visual para la fase 3. Le faltan la comparación de tres rutas con puntajes y la creación de objetivos.

## Trabajo futuro (fuera del alcance del hackathon)

Estas ideas se sacaron de la primera versión porque se salen del objetivo del desafío, que pide una herramienta hiperlocal y señala que las regionales ya existen. Se conservan para mostrar la visión del proyecto.

- **Escala regional y global con análisis.** Capas de todo Marte: relieve MOLA, tipo de suelo, geología, radiación modelada según altitud.
- **Mapas de hielo de agua.** Proyecto SWIM (radar SHARAD) y espectrómetro de neutrones de Mars Odyssey. Poco útil en Gale, donde no hay hielo confirmado.
- **Evidencia de agua antigua a escala global.** Minerales hidratados de CRISM y OMEGA, redes de valles y deltas.
- **Analizar otros puntos de inicio o de aterrizaje.** Colocar un punto alternativo, comprobar que sea viable y comparar sus rutas y puntajes con los del punto principal. Es un problema de planificación de misión, no de caminata.
- **Más sitios.** Cada sitio sería un paquete de datos con el mismo formato (teselas, pendiente, objetivos, series de clima). Candidatos: cráter Jezero y una llanura con hielo como Arcadia Planitia.
- **Combinar los modos.** Un rover que transporte a la tripulación y sus herramientas, con astronautas en pareja y puntos de encuentro, optimizando las rutas para el rover y no solo para caminar.
- **Generador de mapas de varios lugares.** Un solo sistema que, dado un sitio, prepare capas, rejilla de costos y rutas con el mismo formato.
- **Servidor (Node.js + MySQL).** Solo haría falta con varios usuarios o zonas muy grandes.
- **Navegación real del traje.** Sensores, cámara y balizas.
- **Resumen de misión redactado por IA.** Pendiente de confirmar que las reglas permiten IA dentro del producto.

## Decisiones

Abiertas:

1. Fecha de entrega y tamaño del equipo.
2. Quién sabe Flutter y quién sabe Python.

Resueltas:

3. Interfaz en español e inglés, configurable (decidido el 2026-11-14).
4. Gale y Meridiani Planum (tres ventanas) son los sitios; se refuerzan con recursos oficiales y los demás quedan como trabajo futuro (decidido el 2026-11-14; ampliado ese mismo día de «Gale único sitio»).
5. La plataforma del producto es Android (tableta).

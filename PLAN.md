# Plan de desarrollo: ARES PATH

Escrito el 2026-11-14. Este documento es autosuficiente: una sesión nueva puede ejecutarlo sin el historial de la conversación. Leer antes `PROPUESTA.md` (qué se construye y por qué), `RECURSOS.md` (recursos oficiales) y `CLAUDE.md` (reglas).

Estado (2026-11-14): plan aprobado. Fases 0 a 4 cerradas; fase 5 en curso (capa térmica real, fila de geología y fotos del rover descargadas, aún sin conectar). Hábitat confirmado por el usuario (candidato 4). La app es de tableta Android y ya corre en la tablet de prueba; también corre en Chrome. Estado detallado, cómo continuar y registro de cambios: `RETOMAR.md` (leer primero). Resultados de la fase 0 en `RECURSOS.md`, sección "Datos de la zona de caminata (Fase 0)"; de las fases 1 a 4, en el bloque "Resultado" de cada fase.

## 1. Qué se construye

Aplicación de tableta (Flutter, con versión web para la demo) para planificar una caminata de astronauta en la zona de crestas boxwork del Monte Sharp, cráter Gale, Marte. Proyecto para el NASA Space Apps Challenge 2026, desafío "Interplanetary Survival Guide: Martian Map".

Funciones de la primera versión:

1. Mapa por capas a escala de caminata.
2. Tres rutas por salida: la más segura, la más rápida y la de más ciencia.
3. Puntaje de peligro y puntaje de éxito por ruta, con desglose visible.
4. Panel GO / NO-GO con radiación, clima, polvo y consumibles.
5. Objetivos científicos que el astronauta puede crear y mover en el mapa.

Un solo punto de partida: un hábitat cerca de las crestas boxwork. Sin servidor: todo va dentro de la app y funciona sin red.

### Objetivos del desafío que guían cada fase

| N.º | El enunciado pide | Fase que lo cubre |
|---|---|---|
| O1 | Vista por capas de una ubicación hiperlocal | 0, 1, 3 |
| O2 | Al menos tres tipos de datos de la NASA combinados | 1, 4 |
| O3 | Ruta que evita obstáculos, con movilidad en traje | 2, 3 |
| O4 | Seguridad: radiación y clima | 4 |
| O5 | Objetivos científicos de la misión | 3, 5 |
| O6 | Imágenes en primera persona | 5 |

### Fuera de alcance (no construir)

Escala regional o global con análisis, mapas de hielo, análisis de otros puntos de inicio o de aterrizaje, más sitios, servidor Node.js + MySQL, navegación real del traje, IA dentro del producto. Detalle en la sección "Trabajo futuro" de `PROPUESTA.md`.

Regla del usuario: si una idea o tarea se sale del objetivo del hackathon, avisar antes de hacerla.

## 2. Entorno

Comprobado el 2026-11-14 en la máquina del usuario (Linux Zorin OS 17.3, 8 núcleos, 62 GB de RAM). La tabla completa con versiones, la tablet de prueba y las trampas conocidas están en `RETOMAR.md`, sección 5. Resumen:

- Flutter 3.47.7 en `~/fvm/versions/3.47.7/bin/flutter` (no está en el `PATH`; usar la ruta completa). Android SDK en `~/Android/Sdk`, JDK 21, `adb`.
- Python 3.10 con `numpy`, `scipy`, `Pillow`, `requests`, `rasterio`, `pyproj` y `reportlab`. GDAL llega dentro de `rasterio`.
- Tablet de prueba: Samsung SM-X810 (Galaxy Tab S9+, Android 15), por adb en red.
- Playwright de Python con el Chrome del sistema (`channel="chrome"`) para capturas de la versión web.
- La carpeta del proyecto no es un repositorio git; hay un `.gitignore` listo (deja fuera `data/`, los APK y las compilaciones).

## 3. Respuestas del usuario (2026-11-14)

1. Instalar `rasterio` y `pyproj` con `pip install --user`: permitido. Hecho (rasterio 1.4.4, pyproj 3.7.1).
2. Descargar datos de servidores de la NASA y el USGS: permitido. Seguir informando nombre, origen y tamaño de cada archivo antes de descargar.
3. Idioma de la interfaz: español e inglés, configurable por el usuario. Consecuencia: todo texto de la app va en archivos de localización (ARB), nunca fijo en el código. Ver `flutter-setup-localization` en la fase 3.
4. Fecha de entrega y tamaño del equipo: sin dato. El usuario dijo "hoy comencemos". Seguir el orden de recorte de la sección 5 si el tiempo se acaba.
Decisiones posteriores del usuario (2026-11-14):

5. Hábitat: candidato 4 de `RECURSOS.md`, confirmado.
6. La plataforma del producto es Android (tableta); la versión web es solo para verla en una PC.
7. No compilar tras cada cambio: usar `flutter analyze` y `flutter test`, y la tablet en modo desarrollo para ver cambios. Builds de release solo a petición o para una entrega (regla en `CLAUDE.md`).
8. Documentar cada cambio en el momento, porque el usuario alterna entre cuentas: una línea en el registro de `RETOMAR.md`, y `PLAN.md` y `AI_USAGE.md` cuando corresponda.
9. Gale y Meridiani Planum (tres ventanas) como sitios; reforzar con los recursos oficiales del desafío (Mars Trek, USGS, PDS); otros sitios son trabajo futuro. (Antes: «Gale único sitio»; ampliado el 2026-11-14.)

## 4. Fases

Cada fase termina con algo que se puede ver y probar. No empezar una fase sin cerrar el criterio de la anterior.

### Fase 0. Verificar datos

Objetivo: confirmar que hay datos de alta resolución sobre la zona y fijar el área de trabajo. Es el mayor riesgo del proyecto.

Tareas:

1. Localizar la zona de crestas boxwork que Curiosity estudió en 2025 y obtener sus coordenadas de fuentes de la NASA. Coordenadas aproximadas de partida, sin verificar: 4.8° S, 137.4° E.
2. Comprobar qué productos cubren esa zona. Candidatos, todos por verificar:
   - Mosaicos del USGS para la misión MSL en Gale: ortofoto de 25 cm por píxel y modelo de elevación de 1 m por píxel (catálogo Astropedia del USGS).
   - Modelos de elevación HiRISE individuales: https://www.uahirise.org/dtm/
   - Teselas de Mars Trek: https://trek.nasa.gov/mars/
3. Fijar el recuadro de trabajo: unos 4 × 4 km que contengan el hábitat y las crestas.
4. Elegir la coordenada del hábitat: pendiente menor de 5°, suelo firme, a 1–2 km de las crestas.

Entregable: una sección nueva en `RECURSOS.md` con los archivos elegidos, su URL, tamaño, resolución, proyección y licencia, más el recuadro y la coordenada del hábitat.

Criterio de cierre: existe ortofoto y modelo de elevación de 1 m por píxel o mejor sobre todo el recuadro. Si no existe, detenerse, avisar al usuario y proponer una zona vecina de Gale que sí tenga cobertura.

### Fase 1. Preparar datos (Python)

Objetivo: convertir los rasters de la NASA en archivos ligeros que la app pueda cargar.

Estructura:

```
tools/                  scripts de Python
  01_recortar.py        recorta ortofoto y modelo de elevación al recuadro
  02_pendiente.py       calcula la pendiente en grados
  03_costos.py          construye el mapa de costos
  04_exportar.py        genera las imágenes y los JSON para la app
data/raw/               descargas originales (no versionar)
data/work/              intermedios
app/assets/site_gale/   salida final que consume la app
```

Tareas:

1. Recortar la ortofoto y el modelo de elevación al recuadro. Conservar la georreferencia.
2. Calcular la pendiente a partir del modelo de elevación.
3. Construir el mapa de costos en una rejilla de 2 m por celda (un recuadro de 4 km da 2000 × 2000 celdas). Guardar por separado pendiente, rugosidad y una máscara de zonas prohibidas.
4. Exportar para la app:
   - Ortofoto como imagen o pirámide de teselas en coordenadas de píxel.
   - Capa de pendiente coloreada (verde, ámbar, rojo) como PNG con transparencia.
   - Rejilla de costos como binario compacto (un byte por celda y por componente).
   - `site.json`: recuadro, tamaño de celda, origen, coordenada del hábitat y transformación entre píxel, metros y latitud/longitud.
5. Capas térmica (THEMIS) y de minerales (CRISM): solo si la fase 0 encontró productos ya derivados y fáciles de recortar. Si no, se muestran como ejemplo marcado.

Decisión técnica: tratar la zona como un plano local en metros. No reproyectar teselas de Marte dentro de la app. En Flutter, usar un sistema de coordenadas simple basado en píxeles. Esto evita los problemas de proyecciones planetarias.

Criterio de cierre: abrir la ortofoto y la capa de pendiente superpuestas y comprobar a ojo que las crestas y las laderas coinciden. Guardar esa imagen de comprobación.

**Resultado (2026-11-14): fase 1 cerrada.**

- Scripts: `tools/common.py`, `01_recortar.py`, `02_pendiente.py`, `03_costos.py`, `04_exportar.py` y `comprobar_capas.py`. Los umbrales y las unidades viven en `config/params.json`; `04_exportar.py` lo copia a `app/assets/site_gale/params.json`. Orden de ejecución: `cd tools`, y después los scripts numerados en orden.
- Salida en `app/assets/site_gale/` (52.9 MB): 341 teselas JPEG de la ortofoto (29 MB), `layers/slope.png`, `layers/hillshade.png`, cuatro binarios de rejilla en `grid/` (20 MB sin comprimir), `curiosity_waypoints.json` (317 puntos reales), `site.json` y `params.json`. `site.json` documenta el plano local, las fórmulas a latitud y longitud, el esquema de teselas y la lista de capas con su etiqueta medido, modelado o ejemplo.
- Comprobación: `docs/fase1_caja.jpg`, `docs/fase1_detalle_boxwork.jpg` y `docs/fase1_detalle_escarpe.jpg`. A ojo, los contornos de pendiente siguen los escarpes, los barrancos y los bordes de mesa de la ortofoto. Medido con el sol de la ortofoto (azimut 150°, altura 35°), el desfase entre ortofoto y modelo tiene mediana de +2 m este y 0 m norte (una celda), y 55 de 64 teselas de 500 m quedan dentro de 4 m.
- Decisiones: rejilla de 2 m; pendiente con diferencias centrales (línea base de 4 m); plano local en metros con x al este e y al sur desde la esquina noroeste; teselas de 512 px del nivel 0 (8 m por píxel) al 4 (0.5 m) sobre un mundo de 4096 m; el tramo de 20° a 25° queda como precaución alta y transitable, porque el plan no lo define.
- Hábitat: se ajustó 21 m al centro del disco llano más cercano en la rejilla de 2 m (E 8 142 553, N −283 637; lat −4.7851°, lon 137.3698°; elevación −3839 m; radio llano 21 m).

Para la fase 2, ver:

1. A 2 m el modelo deja celdas sueltas de pendiente alta en terreno liso (ruido del modelo) y no resuelve las crestas boxwork de 1 a 2 m de altura, que salen como manchas dispersas. Antes de A* evaluar filtrar las celdas prohibidas aisladas.
2. 4 de 103 waypoints de Curiosity en la campaña boxwork caen en celdas prohibidas. El rover pasó por ahí; el modelo es conservador o ruidoso en esos puntos.
3. No hay componente de arena suelta (`w_arena` = 0 hasta tener THEMIS). Las capas térmica, de minerales y de radiación van marcadas como ejemplo en `site.json`.
4. Los assets pesan 52.9 MB. Si la versión web carga lento, bajar la calidad JPEG o quitar el nivel 4 de teselas.

### Fase 2. Rutas y puntajes

Objetivo: calcular tres rutas y sus puntajes. Primero en Python, para validar rápido; después en Dart, dentro de la app.

Algoritmo: A* sobre la rejilla de costos, con ocho vecinos por celda. No usar IA para el cálculo.

Costo de pasar por una celda:

```
costo = distancia × (1 + w_pendiente × f(pendiente) + w_rugosidad × rugosidad + w_arena × arena)
```

Las celdas con pendiente por encima del límite son intransitables.

Perfiles (mismo algoritmo, pesos distintos):

| Perfil | Idea |
|---|---|
| Segura | Peso alto a pendiente y terreno suelto; límite de pendiente más bajo |
| Rápida | Peso bajo; minimiza el tiempo |
| Ciencia | Visita todos los objetivos, ordenados por prioridad, mientras el margen de consumibles lo permita |

Con varios objetivos, el orden de visita se resuelve por fuerza bruta si son seis o menos, y con vecino más cercano si son más.

Parámetros iniciales. Son supuestos del equipo, no estándares de la NASA. Deben vivir en un único archivo de configuración y mostrarse en la interfaz:

| Parámetro | Valor inicial |
|---|---|
| Pendiente nominal | menos de 10° |
| Pendiente de precaución | 10° a 20° |
| Pendiente prohibida | más de 25° |
| Velocidad en llano | 2.0 km/h, reducida según la pendiente |
| Duración máxima de la salida | 6 h |
| Reserva mínima de oxígeno al volver | 20 % |
| Tasa de dosis de radiación | la medida por RAD (del orden de 0.6–0.7 mSv por día; sustituir por el dato real en la fase 4) |

Métricas por ruta: distancia, tiempo total, tiempo en paradas, pendiente máxima, metros recorridos en cada clase de pendiente, desnivel acumulado, oxígeno restante al volver, dosis de radiación y punto de no retorno (el punto a partir del cual seguir cuesta menos que volver).

Puntaje de peligro (0 a 100; más alto es más peligroso). Suma ponderada de componentes normalizados de 0 a 1:

| Componente | Peso inicial |
|---|---|
| Exposición a pendiente | 30 |
| Terreno suelto o rocoso | 15 |
| Distancia más allá del regreso a pie | 20 |
| Margen de consumibles | 20 |
| Dosis de radiación | 5 |
| Condiciones del día | 10 |

Puntaje de éxito (0 a 100):

```
éxito = 100 × valor_científico × factor_tiempo × factor_consumibles × (1 − peligro / 200)
```

- `valor_científico`: suma de prioridades de los objetivos visitados, dividida entre la suma de todos.
- `factor_tiempo` y `factor_consumibles`: 1 con margen holgado; bajan de forma lineal hasta 0 cuando el margen se agota.

Mostrar siempre el desglose. El puntaje ordena rutas; no sustituye el criterio de la tripulación.

Entregables: `tools/05_rutas.py` con salida GeoJSON y métricas; después `app/lib/routing/` con el mismo algoritmo en Dart y pruebas unitarias.

Criterio de cierre:

- Las tres rutas son distintas y ninguna cruza celdas prohibidas.
- Comparación con la ruta real de Curiosity por la zona (recurso 3 de `RECURSOS.md`): la ruta segura debe evitar las mismas laderas. Anotar las diferencias.
- La versión en Dart da el mismo resultado que la de Python en tres casos de prueba.
- El cálculo en Dart tarda menos de 2 segundos en la versión web. Si tarda más, reducir la rejilla a 4 m por celda.

**Resultado (2026-11-14): fase 2 cerrada.**

- Código en Python: `tools/routing.py` (núcleo), `tools/05_rutas.py` (las tres rutas, GeoJSON e imagen), `tools/comparar_curiosity.py` y `tools/test_routing.py` (9 pruebas; A* da el mismo costo que Dijkstra de scipy). Código en Dart: `app/lib/routing/` (`model`, `grid`, `astar`, `metrics`, `planner`), con `app/test/routing_unit_test.dart` (8 pruebas) y `app/test/routing_golden_test.dart` (8 pruebas contra las referencias de Python en `app/test/golden/`). Parámetros en `config/params.json`; objetivos de ejemplo en `config/objectives.json`: cuatro paradas reales de Curiosity en la campaña boxwork. El tipo, la prioridad y el tiempo de trabajo son supuestos del equipo.
- Modelo: A* de ocho vecinos sin cortar esquinas. Al costo del plan se le añadió un término de tiempo (`w_time`): sube y baja cuestan distinto, y así la ruta rápida minimiza el tiempo de verdad. Perfiles: segura (límite de 22°, pesos 12 y 4), rápida (25°, 0.5 y 0.2, tiempo 1.0) y ciencia (25°, 4 y 1.5). Las métricas y los puntajes siguen el plan; la fórmula de cada componente está en `tools/routing.py` y los pesos en `config/params.json`.
- Decisiones que el plan no fijaba:
  1. Segura y rápida van al objetivo de mayor prioridad y vuelven. Ciencia añade objetivos por prioridad mientras quede margen cómodo (tiempo sobrante de al menos 25 % y oxígeno de al menos reserva más 30 puntos). Sin esa regla, ciencia agota el margen y su puntaje de éxito cae a 3.7.
  2. El límite de la segura es 22° y no 20°. El hábitat solo se conecta con el resto por un paso de unos 20° (19.5° a 4 m, 20.0° a 2 m); con 20° y la regla de no cortar esquinas queda aislado.
  3. El tramo de 20° a 25° es transitable (precaución alta).
  4. La dosis de radiación (0.65 mSv por día) y la componente "condiciones del día" (0) son datos de ejemplo hasta la fase 4.
  5. El punto de no retorno se calcula sobre la propia ruta: el primer punto desde el que terminar cuesta menos que deshacer lo andado.
  6. "Distancia más allá del regreso a pie" es la distancia en línea recta al hábitat por encima de 1.5 km (0.75 h a 2 km/h).
- Resultados a 4 m con los objetivos de ejemplo: segura 4218 m, 3.38 h, pendiente máxima 21.5°, peligro 20.2, éxito 32.1. Rápida 3495 m, 3.00 h, 24.2°, peligro 25.9, éxito 31.1. Ciencia visita t1 y t3: 3811 m, 3.60 h, 24.2°, peligro 23.4, éxito 44.2. Las tres son distintas y ninguna pisa celdas prohibidas (`docs/fase2_rutas_4m.jpg`, `docs/fase2_rutas_2m.jpg`). Los números cambian si cambia cualquier parámetro.
- Dart contra Python: en las tres rutas, a 4 m y a 2 m, el camino es idéntico celda por celda y las métricas coinciden con una diferencia relativa de 1e-6 o menos.
- Rendimiento en Chrome (sin pantalla, esta máquina de 8 núcleos), cálculo de las tres rutas con 18 búsquedas A*: 8 m, 0.45 s; 4 m, 1.5 s; 2 m, 6.7 s. La ruta rápida sola: 0.04 s, 0.23 s y 0.83 s. A 2 m no cumple el criterio de 2 s, así que `routing.cell_m` es 4. Medido con `app/lib/bench/bench_main.dart`.
- Comparación con Curiosity (`tools/comparar_curiosity.py`, 10 tramos de unos 350 m del recorrido real entre los soles 4400 y 5008):
  - Terreno pisado por el rover frente al disponible en el recuadro: nominal 62.8 % contra 40.8 %; precaución 34.4 % contra 34.2 %; precaución alta 1.7 % contra 8.7 %; prohibida 1.0 % contra 16.4 %. Curiosity evitó las pendientes de más de 20°, igual que la ruta segura.
  - Mediana por tramo: pendiente máxima 21.4° (rover), 12.8° (segura) y 16.9° (rápida); metros en precaución 133, 33 y 52.
  - Desviación lateral de nuestras rutas respecto al tramo real, mediana de las medianas: 10 m la segura y 18 m la rápida. En tres tramos (soles 4596-4660, 4855-4923 y 4923-4957) la mediana es de 21 a 45 m.
  - Diferencias: nuestras rutas son más cortas (329 m la segura y 293 m la rápida, contra 451 m del recorrido real) y pisan menos pendiente de precaución. Curiosity tenía otras restricciones que el modelo no tiene (arena, desgaste de ruedas, paradas científicas, orden de la misión), y los waypoints son finales de cada tramo de conducción, así que unirlos con rectas añade o quita recorrido. En los soles 4596-4660 la recta del rover cruza celdas de hasta 45°, que es un artefacto de esa unión. Es una comprobación de coherencia, no una validación para un traje.

Para la fase 3, ver:

1. El cálculo corre en el hilo principal. En una tableta tardará más que los 1.5 s medidos aquí: mostrar un indicador y reutilizar los tramos ya calculados cuando se mueve un objetivo (`Planner` ya guarda los tramos por extremos; falta invalidar solo los que tocan el objetivo movido). Si hace falta más velocidad: reusar el tramo inverso como tramo de vuelta (18 búsquedas pasan a 12) o previsualizar a 8 m.
2. La app carga hoy los binarios de 2 m (20 MB) y los agrega a 4 m al arrancar (0.2 s). Exportarlos ya a 4 m los dejaría en unos 5 MB.
3. El proyecto Flutter se creó con `flutter create` (web y Linux, plantilla vacía). El tema, el mapa y las pantallas siguen pendientes. Antes del mapa, consultar la documentación actual de `flutter_map`.
4. `app/pubspec.yaml` solo registra `site.json`, `params.json`, `objectives.json` y `grid/`. Las teselas y las capas de imagen se añaden en la fase 3.

### Fase 3. App Flutter: mapa, rutas y objetivos

Objetivo: la pantalla principal funcionando con datos reales.

Antes de escribir código: consultar la documentación actual del paquete de mapas elegido. Candidato: `flutter_map`. Confirmar que admite un sistema de coordenadas simple con imágenes superpuestas. No fiarse de la memoria para su API. Context7 requiere autorización del usuario mediante `/mcp`; si no está disponible, usar búsqueda web.

Estructura:

```
app/
  lib/
    main.dart
    theme/        colores y tipografías del prototipo
    data/         carga de site.json, rejilla y series
    routing/      A*, perfiles, métricas, puntajes
    screens/      plan, seguridad, ciencia
    widgets/      panel de capas, tarjetas de ruta, perfil de elevación
  assets/site_gale/
  test/
```

Tareas, en orden:

1. Crear el proyecto con soporte web y aplicar el tema.
2. Mapa con la ortofoto, zoom y desplazamiento, barra de escala y lectura de coordenadas.
3. Panel de capas: interruptor y opacidad por capa. Cada capa lleva una etiqueta: medido, modelado o ejemplo.
4. Dibujar las tres rutas con colores distintos, las zonas prohibidas, el hábitat y los objetivos.
5. Tarjetas de comparación: una por ruta, con métricas, los dos puntajes y su desglose. Al tocar una tarjeta se resalta su ruta.
6. Perfil de elevación de la ruta seleccionada, coloreado por clase de pendiente.
7. Objetivos: tocar el mapa para crear uno; editar nombre, tipo, prioridad y tiempo de trabajo; arrastrarlo; borrarlo. Cada cambio recalcula las rutas. Avisar si el objetivo cae en zona prohibida.
8. Objetivos sugeridos ya cargados: tres o cuatro puntos sobre las crestas.

Guía visual: las cinco pantallas de `stitch/` y el proyecto de Google Stitch "Martian Map — Gale Crater EVA Guide" (ID `13667341032760877`). Estilo: fondo carbón cálido `#0E0C0B`, acento naranja óxido `#E2622B`, cian para ciencia, verde, ámbar y rojo solo para estado; Space Grotesk en títulos, IBM Plex Sans en texto, JetBrains Mono en números; bordes finos, sin sombras ni degradados. Al prototipo le faltan la comparación de tres rutas y la creación de objetivos: diseñarlas con el mismo estilo.

Criterio de cierre: en Chrome, cargar la app, alternar capas, ver tres rutas con puntajes, crear un objetivo y comprobar que las rutas cambian. Hacer capturas con Playwright y revisarlas.

**Resultado (2026-11-14): fase 3 cerrada.**

- **Android (plataforma del producto):** la app se instaló y corre en la tablet Samsung SM-X810 (Galaxy Tab S9+, Android 15), conectada por adb en red (`100.84.142.127:55555`). Id de la app: `dev.aresPath.ares_path`; nombre: ARES PATH; solo horizontal y a pantalla completa. APK de release de 97.7 MB (`app/build/app/outputs/flutter-apk/app-release.apk`; incluye tres arquitecturas, con `--split-per-abi` baja). En la tablet las tres rutas se calculan en 0.76 s (en Chrome, 1.5 s). Se comprobó con capturas que carga, muestra el mapa y los paneles y reacciona al toque (la captura posterior mostró el idioma cambiado a español y el mapa ampliado y movido). Instalar de nuevo: `cd app && ~/fvm/versions/3.47.7/bin/flutter run -d 100.84.142.127:55555 --release`. Pendiente: probar a mano pellizco, arrastre de objetivos con el dedo y todas las pantallas en la tablet.
- Cómo ejecutarla en Chrome, desde `app/`: `~/fvm/versions/3.47.7/bin/flutter run -d chrome`. Pruebas: `flutter test` (16 pruebas, todas pasan). Versión web: `flutter build web --release`. `flutter analyze` sin avisos.
- Estructura de `app/lib/`: `main.dart`, `theme/` (colores y tipografías de Stitch), `l10n/` (textos ARB en inglés y español), `data/site_data.dart` (carga de `site.json`, rejilla y waypoints), `state/app_model.dart` (capas, objetivos, rutas, selección), `routing/` (fase 2), `screens/` (plan, seguridad, ciencia), `widgets/` (mapa, panel de capas, panel de rutas, perfil de elevación, barra superior, diálogo de objetivo, teselas) y `util/`.
- Pantallas, con el estilo de las de Stitch (fondo `#0E0C0B`, acento naranja `#E2622B`, cian para ciencia, bordes finos, sin sombras):
  - **Plan**: capas con interruptor, opacidad y etiqueta medido, modelado o ejemplo; mapa con las teselas reales, zoom con rueda, botones y pellizco, lectura de coordenadas, elevación y pendiente, y barra de escala; tres rutas dibujadas, hábitat, objetivos y punto de no retorno; tarjetas de comparación con métricas, los dos puntajes y su desglose; perfil de elevación coloreado por pendiente; objetivos que se crean tocando el mapa, se editan, se arrastran y se borran, con aviso si caen en zona prohibida; supuestos del modelo a la vista.
  - **Seguridad**: estado por verificación. Terreno y consumibles salen del modelo; radiación, clima y polvo quedan pendientes y marcados hasta la fase 4. Reparto de metros por clase de pendiente, tabla de regreso por parada y comparación de consumibles entre las tres rutas.
  - **Ciencia**: lista de objetivos, detalle con recorte de la ortofoto HiRISE y los datos de cada capa en ese punto. Térmica, minerales y radiación quedan marcadas como ejemplo sin datos; la foto del rover queda para la fase 5.
- Decisiones: mapa propio en el plano local en metros, sin `flutter_map` (el sistema de coordenadas simple no necesita proyecciones y así no hay una API que verificar); idioma configurable con ARB y botones EN y ES; `Space Grotesk` y `JetBrains Mono` copiadas de las fuentes instaladas en el sistema (`app/assets/fonts/`); `IBM Plex Sans` no está instalada, así que el texto usa `Inter` hasta que se autorice descargar `IBM Plex Sans`.
- Comprobado en Chrome con Playwright (1280 × 800): carga, alternar capas y opacidad, tres rutas con puntajes y desglose, crear un objetivo tocando el mapa y ver el recálculo de las rutas, editar y arrastrar un objetivo, zoom con rueda, cambio entre español e inglés y las tres pestañas. Capturas en `docs/fase3_*.png`. No probado: gestos táctiles reales ni una tableta.
- Fuera de esta fase y pendiente: pantalla de ruta con línea de tiempo y de casco (fase 5), botones "aprobar ruta" y "recalcular" del prototipo, GO / NO-GO con datos reales (fase 4) y fotos del rover (fase 5).
- Limitaciones conocidas: el cálculo de rutas bloquea el hilo principal unos 1.6 a 2.5 s tras cada cambio (se muestra un indicador); los assets pesan unos 56 MB; no hay pruebas de widgets, solo las del cálculo de rutas.

### Fase 4. Seguridad

Objetivo: panel GO / NO-GO con datos reales. Cubre O4 y completa los tres tipos de datos reales de O2.

Tareas:

1. Descargar series de radiación (RAD) y clima (REMS) de Curiosity desde el Planetary Data System de la NASA. Localizar el nodo y el producto exactos; no suponer la URL.
2. Convertirlas a JSON por sol: tasa de dosis, temperatura mínima y máxima, presión, ultravioleta. Opacidad del polvo si hay un producto disponible; si no, como ejemplo marcado.
3. Pantalla de seguridad: estado global, cinco verificaciones (radiación, clima, polvo, terreno, consumibles), gráfica de dosis, gráfica de temperatura del día con la ventana de la salida, y tabla de regreso por parada.
4. Reglas del GO / NO-GO: umbrales simples, configurables y visibles.
5. Usar la tasa de dosis real en el cálculo de la fase 2.

Criterio de cierre: los valores en pantalla coinciden con los archivos fuente en tres soles elegidos al azar.

**Resultado (2026-11-14): fase 4 cerrada.**

- Fuentes y formatos: detalle en `RECURSOS.md`, sección "Datos de radiación y clima (Fase 4)". Radiación de CDAWeb (NASA SPDF, `MSL_RAD_OBS-L2`, 1.9 MB) y clima de REMS en el PDS (`MSL-M-REMS-5-MODRDR-V1.0`, soles 4814 a 4843, 305 MB). El archivo de RAD del PDS en UCLA solo llega al sol 804, por eso se usó CDAWeb. Salida: `app/assets/site_gale/environment.json` (147 KB), generado por `tools/06_clima_radiacion.py`.
- Dosis real en las rutas: `config/params.json` ahora tiene `radiation.dose_rate_ugy_per_day` = 151 µGy por día (línea base medida por RAD, detector E) y todas las dosis se muestran en µGy. Es dosis absorbida, no dosis equivalente. El peligro y el éxito de las rutas no cambian, porque el componente de radiación depende del tiempo de salida; los resultados del bloque de la fase 2 siguen valiendo.
- Pantalla Seguridad con datos reales:
  - Selector de sol (los 30 de REMS; por defecto el 4843) que mueve toda la pantalla.
  - Radiación: tasa del sol, línea base, cociente, dosis de la ruta y barras de los 60 sols previos con las líneas de la base y del umbral de precaución.
  - Clima: temperatura del aire y del suelo por hora local con la ventana de la salida sombreada, presión, pico de UV y humedad.
  - Polvo: sin producto en el PDS, marcado como pendiente.
  - Panel de reglas con los umbrales a la vista (`environment` en `config/params.json`).
  - Estado general: 4 de las 5 verificaciones usan datos reales (radiación, clima, terreno y consumibles). Mientras el polvo no tenga datos, el estado general nunca dice GO: dice "datos incompletos", salvo que haya precaución o NO-GO.
- Regla de GO / NO-GO (supuestos del equipo, no límites de la NASA; validar con referencias del traje): radiación en precaución a partir de 1.5 veces la línea base y NO-GO a partir de 3; clima en precaución si la temperatura mínima del aire en la ventana de la salida es de −60 °C o menos y NO-GO a −80 °C o menos; la salida empieza a las 09:00 de tiempo solar medio local y dura lo que dura la ruta.
- Pantalla Ciencia: la fila de radiación muestra la tasa real del sol elegido. El panel de capas ya no lista «Flujo de radiación», porque no existe un mapa de radiación: la medida es una serie en el tiempo, igual para toda la zona.
- Hallazgo de la verificación en la tablet: la app, en modo desarrollo, mostraba la pantalla de Seguridad y el panel de rutas en blanco. `MeterBar` y la barra de consumibles usaban `LayoutBuilder` dentro de `IntrinsicHeight`; una build de release lo ignora, pero el modo desarrollo lanza una aserción. Se reescribieron sin `LayoutBuilder` y se añadió `app/test/app_smoke_test.dart`, que abre las tres pestañas con las aserciones activas (como el modo desarrollo) y falla ante cualquier error que no sea un desborde de texto. Captura de la tablet en `docs/fase4_seguridad_tablet.png`.
- Verificación: `tools/comprobar_ambiente.py` recalcula con numpy, desde los archivos originales, tres soles al azar (4818, 4824 y 4826): temperaturas del aire, presión, horas con dato, dosis media de RAD y número de mediciones coinciden con el JSON de la app (diferencias de redondeo de 0.05 o menos). Pruebas: 9 de Python y 17 de Dart pasan; `flutter analyze` sin avisos. Referencias de rutas regeneradas con las dosis en µGy.
- Limitaciones: la app evalúa un sol pasado, no el día de hoy (REMS llega hasta marzo de 2026); el polvo no tiene datos; el viento se descartó porque casi siempre falta; el clima solo decide por temperatura del aire; el sol se calcula con la duración media del sol marciano (error de minutos).

### Fase 5. Extras (solo si sobra tiempo)

En este orden:

1. Fichas de ciencia con fotos reales de Curiosity por objetivo, con cámara y sol citados. Cubre O6.
2. Pantalla de casco como concepto visual, con la posición simulada sobre la ruta.

**Avance de la fase 5 (2026-11-14, sin cerrar).**

- Capa térmica real: THEMIS-IR de día, de las teselas de Mars Trek (100 m por píxel, brillo relativo), con `tools/07_termica.py` → `app/assets/site_gale/layers/thermal.png`. Ya está en el panel de capas, apagada por defecto. Detalle en `RECURSOS.md`.
- Contexto geológico: `tools/08_geologia.py` identifica la unidad del mapa geológico global del USGS en el recuadro («Hesperian transition undivided unit»); la pantalla Ciencia la muestra como una fila de texto. Detalle en `RECURSOS.md`.
- Fotos reales de Curiosity para cada objetivo: fuente verificada (API de imágenes crudas de mars.nasa.gov) y descargadas con `tools/09_fotos_rover.py`; **todavía no están conectadas a la pantalla Ciencia**. Hay que decidir entre Mastcam y Navcam (las primeras eran en blanco y negro, con viñeteo y mostraban el suelo cercano, no el horizonte). Registro completo en `RETOMAR.md`, sección 11.
- Simulación de la EVA en el mapa (hecha el 2026-11-14): marcador y rastro del astronauta, pestaña Misión con telemetría del traje y alertas. Detalle en `RETOMAR.md`, sección 11.
- Falta: conectar las fotos, capa de minerales (CRISM, sigue como ejemplo), pantalla de casco, citar las fuentes oficiales en la interfaz y actualizar el PDF del equipo y el APK de `dist/` (el v0.2 no trae las capas nuevas).

### Ampliación: Meridiani, transporte por objetivo y misiones guardadas (pedida el 2026-11-14)

Anula «Gale único sitio». Fases: **F0** verificar datos de Meridiani (**hecha**; hallazgos en `RETOMAR.md` y `RECURSOS.md`); **F1** varios sitios (**hecha**, sin datos nuevos: registro `app/assets/sites.json`, selector de sitio); **F2** misiones guardadas en el dispositivo (**hecha**: `shared_preferences`, diálogo «Misiones», autoguardado); **F3** transporte por objetivo (a pie, vehículo o híbrido; Python y Dart con referencias golden) (**hecha**: modo «Por objetivo», reglas en `RETOMAR.md`); **F4** (**hecha**) datos locales de Meridiani, dos ventanas: Endeavour (HiRISE y DEM de 1 m) y zona habitable (CTX y DEM de 200 m, rutas indicativas); **F5** (**hecha** para Meridiani) capas científicas y de tránsito (minerales, zonas de exploración, DCI e inercia térmica); **F5b** (**hecha**) marco de contexto fuera de línea y más rasgos (dunas, cráteres, nombres, geología) en los cuatro sitios; **B hecho** para Gale (24 km) y Endeavour (22 km, DEM mixto), rejilla de 16 m; mapas base de 40 m de toda la región, todo offline; C (mapas en línea) **descartado** por la regla «todo offline»; D (paquetes descargables) descartado igual: todo va empaquetado. **F6** (**hecha**) seguridad por sitio (aviso sin mediciones y nota de dosis), fuentes en la interfaz, PDF del equipo v0.5, documentación y APK v0.5. Pendientes del usuario: fecha de entrega y tamaño del equipo, criterio de pendiente (grados o porcentaje) y supuestos de consumibles y equipo.

### Fase 6. Entrega

1. Sustituir o marcar todo dato de ejemplo que quede.
2. Compilar la versión web y probarla desde cero.
3. Video de demostración y texto de la entrega.
4. Declaración de uso de IA a partir de `AI_USAGE.md`.
5. Lista de fuentes de datos con su cita.

## 5. Orden de recorte si falta tiempo

1. Pantalla de casco.
2. Capas térmica y de minerales. Quedan óptico, relieve y radiación, que son tres tipos de datos reales.
3. Objetivos creados por el usuario: pasan a ser fijos y las rutas se dejan calculadas de antemano con Python.

## 6. Reglas de trabajo

- Uso de IA: cada vez que una herramienta de IA deje un resultado en el proyecto, añadir una fila en `AI_USAGE.md`.
- No presentar como dato de la NASA ningún valor, imagen o texto generado por IA. Los datos de ejemplo se marcan como tales en la interfaz.
- Toda fuente de datos usada se anota en `RECURSOS.md` con URL y fecha.
- Descargas e instalaciones: pedir permiso antes, con nombre, origen y tamaño.
- Cambios de alcance: avisar al usuario si algo se sale del objetivo del hackathon.
- No versionar `data/raw/` ni archivos pesados.

## 7. Lo que sigue sin verificar o sin resolver

- Suelo firme en el hábitat: haría falta inercia térmica calibrada; la capa térmica de la app es brillo relativo.
- Supuestos del traje (velocidad, duración de la salida, oxígeno) y umbrales de GO / NO-GO: los propuso la IA; no hay referencia de la NASA.
- Opacidad del polvo: el PDS no tiene un producto de REMS; falta otra fuente.
- Minerales (CRISM): productos y cobertura sobre Gale por verificar.
- Términos de uso de los JSON de `mars.nasa.gov`, de las teselas de Mars Trek y de las imágenes crudas de Curiosity: sin consultar. Citar a NASA/JPL-Caltech mientras tanto.
- Los valores de las pantallas de `stitch/` son de ejemplo, generados por Google Stitch. No usarlos como datos.
- Ya verificado y cerrado: coordenadas de la zona y cobertura de los mosaicos del USGS (fase 0); productos de RAD y REMS (fase 4); Mars Trek como fuente de la capa térmica y del mapa geológico; el mapa de la app es propio, sin `flutter_map`.

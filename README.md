# ARES PATH

**Planificador de caminatas de astronauta (EVA) en Marte, con datos reales de la NASA y el USGS.**
*Mars EVA planner built on real NASA and USGS data. Works fully offline.*

Proyecto del equipo **Atlantis33** para el **NASA Space Apps Challenge 2026**, desafío **«Interplanetary Survival Guide: Martian Map»**.

| | |
|---|---|
| **Versión actual** | 0.9.4 (build 13) |
| **Plataformas** | Tableta Android (probada en Samsung Galaxy Tab S9+) y versión web |
| **Web** | https://arespath.hellofactura.com/ |
| **Stack** | Flutter (app), Python (preparación de datos). Sin servidor, sin cuenta, sin red |
| **Idiomas** | Español e inglés, con el botón EN / ES |
| **Licencia** | MIT (ver `LICENSE`) |

## ¿Qué es?

ARES PATH ayuda a planear una caminata de astronauta en Marte. Para un sitio concreto reúne mapas y datos de la NASA y el USGS en un solo mapa por capas, calcula rutas desde el hábitat hasta los objetivos científicos que el usuario marca, y responde tres preguntas:

1. **¿Por dónde camino?** Tres rutas candidatas por salida: la más segura, la más rápida y la de más ciencia.
2. **¿Cuánto me cuesta?** Distancia, tiempo, oxígeno, dosis de radiación y punto de no retorno de cada ruta, con un puntaje de **peligro** y uno de **éxito** y su desglose a la vista.
3. **¿Salgo o no salgo?** Un panel GO / NO-GO con radiación y clima medidos por Curiosity (RAD y REMS), terreno y consumibles.

Además simula la caminata paso a paso (pestañas Misión y Casco), muestra fichas científicas de cada objetivo y guarda las misiones en la tableta.

La diferencia con [NASA Mars Trek](https://trek.nasa.gov/mars/): Mars Trek muestra capas a escala regional; ARES PATH convierte las capas en una **decisión** a escala de caminata (pocos kilómetros).

## ¿Por qué se hizo?

El desafío pide una guía de supervivencia interplanetaria hecha con mapas de Marte. Una caminata (EVA) es una de las actividades más arriesgadas y caras de una misión: el astronauta lleva oxígeno para pocas horas, la radiación y el frío cambian cada día, y una pendiente o una zona de arena mal elegida puede obligar a volver. Con datos públicos de la NASA ya existe casi todo lo necesario para decidirlo, pero está repartido en servicios distintos y a escalas que no sirven para caminar.

ARES PATH junta esos datos, los hace comparables y deja claro **de dónde sale cada número**:

- **MEDIDO**: dato real de la NASA, el USGS o ASU.
- **MODELADO**: calculado por el equipo a partir de esos datos.
- **Supuesto**: valor del equipo sin referencia oficial (por ejemplo, la autonomía del traje). Se muestra como tal.

## Sitios incluidos

| Sitio | Qué es |
|---|---|
| Gale · Crestas boxwork | Zona de caminata original, Monte Sharp, con datos medidos de Curiosity |
| Gale · Alcance de la EVA (24 km) | Ventana larga alrededor del hábitat |
| Meridiani · Borde de Endeavour | Ventana de 4 km con el recorrido de Opportunity |
| Meridiani · Endeavour, alcance de la EVA (22 km) | Ventana larga en Endeavour |
| Meridiani · Zona habitable | Zona de exploración propuesta por la NASA (indicativo) |
| Meridiani · Contexto regional (100 km) | Vista regional (indicativa) |

En Meridiani no hay radiación ni clima medidos (RAD y REMS son de Curiosity, en Gale): esas verificaciones quedan pendientes y la app lo avisa.

## Cómo está hecho

- **`app/`**: app Flutter (Dart). Mapa por capas, rutas con A*, puntajes, seguridad, ciencia, misión y casco. Las rutas se calculan en un isolate de fondo.
- **`tools/`**: scripts de Python que descargan y preparan los datos (recortes, pendiente, costos, clima, radiación, minerales, fotos). `tools/routing.py` es la referencia del cálculo de rutas; el código de Dart debe dar el mismo resultado y un test lo comprueba (`app/test/routing_golden_test.dart`).
- **`config/`**: parámetros del modelo (`params.json`) y objetivos de demostración.
- **`docs/`**: manual de usuario (PDF), guía del equipo y capturas.
- **`video/`**: videos de presentación.
- **Documentos del proyecto**: `PROPUESTA.md` (qué se construye y qué queda fuera), `PLAN.md` (plan por fases), `RECURSOS.md` (fuentes de datos con URL y fecha), `AI_USAGE.md` (uso de IA), `RETOMAR.md` (estado, comandos y registro de cambios).

### Reglas del proyecto

- **Todo funciona sin red.** Mapas, imágenes y datos van empaquetados en la app. No se cargan teselas ni datos en vivo.
- **Todo texto visible va en `app/lib/l10n/*.arb`**, en español e inglés.
- **Toda fuente de datos está en `RECURSOS.md`** con URL y fecha.

## Qué hace cada pestaña

| Pestaña | Para qué sirve |
|---|---|
| **Plan** | Capas de datos, mapa, objetivos científicos y comparación de las tres rutas, con perfil de elevación |
| **Seguridad** | Radiación y clima del «sol de referencia» elegido, terreno y consumibles, y el estado GO / NO-GO |
| **Ciencia** | Fichas de cada objetivo: ortofoto, unidad geológica, capas de datos y foto del rover |
| **Misión** | Simulación de la caminata con la telemetría del traje (estimada, sin sensores) |
| **Casco** | Concepto visual de la pantalla de visera: rumbo, siguiente objetivo y datos de regreso. En Meridiani, vista en perspectiva del relieve y fotos de Opportunity |

## Cómo se construyó

El proyecto se desarrolló con apoyo de **Claude Code** (IA de Anthropic) dentro de las reglas del hackathon: escribir, depurar y documentar código, resumir documentación técnica y prototipar interfaces. Cada resultado de IA está registrado en [`AI_USAGE.md`](AI_USAGE.md). Ningún dato científico de la app lo generó la IA: viene de fuentes de la NASA y el USGS citadas en [`RECURSOS.md`](RECURSOS.md).

### Cronología

| Fecha | Hito |
|---|---|
| 2026-11-14 | Inicio del proyecto: propuesta, plan por fases, verificación y preparación de datos de Gale, cálculo de rutas (Python y Dart), app Flutter, seguridad con RAD y REMS reales |
| 2026-11-14 | Sitio de Meridiani, misiones guardadas, transporte por objetivo, capas térmica, de tránsito y de minerales, fotos del rover, v0.1 a v0.9 en la tableta |
| 2026-11-15 | Reporte de QA (17 bugs) corregido; capas de biofirmas de Meridiani; Casco en Meridiani; rutas segura y rápida con objetivo propio; manual de usuario y videos; **v0.9.4** |

## Cómo correrlo

Requisitos: Flutter 3.47 (Dart 3.13) para la app; Python 3 para los datos.

```bash
cd app
flutter pub get
flutter gen-l10n          # tras editar app/lib/l10n/*.arb
flutter analyze
flutter test              # unas 100 pruebas; las de humo tardan ~2 min
flutter run -d <id-del-dispositivo>
```

Para la versión web: `flutter build web --release` y servir `app/build/web/`.
Para la APK: `flutter build apk --release` (salida en `app/build/app/outputs/flutter-apk/`).

Los datos que usa la app ya están empaquetados en `app/assets/`. Para regenerarlos (descargan de servidores de la NASA y el USGS) ver la sección 6 («Datos que no están en el repositorio y cómo regenerarlos») de [`RETOMAR.md`](RETOMAR.md).

## Límites

ARES PATH es una **herramienta de planeación**, no un sistema de vuelo:

- No es un pronóstico: el clima y la radiación son de un día pasado (el «sol de referencia»), no de hoy.
- No modela rocas menores de 1 m ni arena suelta; las pendientes salen de un modelo de elevación.
- No lleva signos vitales ni sensores del traje. La simulación y el casco son conceptos visuales.
- Los umbrales de GO / NO-GO, la autonomía de oxígeno, las velocidades y los pesos de peligro y de éxito son **supuestos del equipo**, no estándares de la NASA.

## Presentación

Lo entregado para el desafío es: la app (APK y web), el manual de usuario (`docs/ARES_PATH_manual_usuario.pdf`), los videos de presentación (`video/`), las fuentes (`RECURSOS.md`) y la declaración de uso de IA (`AI_USAGE.md`).

> **Pendiente de completar:** fecha, lugar o evento de la presentación y nombres del equipo.

## Créditos y fuentes

Datos y servicios: NASA/JPL (Mars Trek, PDS, MSL REMS y RAD), NASA SPDF CDAWeb, USGS Astrogeology (HiRISE, MOLA y HRSC, mapa geológico global), ASU Mars Space Flight Facility (THEMIS, TES) y la NASA Image and Video Library (fotos de Opportunity, crédito NASA/JPL-Caltech). El detalle, con URL, fecha y límites de cada uno, está en [`RECURSOS.md`](RECURSOS.md).

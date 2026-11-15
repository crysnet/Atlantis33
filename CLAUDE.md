# Reglas del proyecto

Proyecto para el NASA Space Apps Challenge 2026, desafío "Interplanetary Survival Guide: Martian Map".

## Documentos del proyecto

- `RETOMAR.md`: **leer primero.** Estado actual, qué sigue, entorno, cómo regenerar los datos, comandos, mapa del proyecto, decisiones de fondo y registro de cambios.
- `PLAN.md`: plan de desarrollo por fases. Leerlo antes de programar y seguir su orden.
- `PROPUESTA.md`: qué se construye, por qué y qué queda fuera de alcance.
- `RECURSOS.md`: recursos oficiales del desafío y fuentes de datos.
- `AI_USAGE.md`: registro de uso de IA para la entrega.
- `stitch/`: prototipo visual de cinco pantallas (valores de ejemplo).

Si una idea o tarea se sale del objetivo del hackathon, avisar al usuario antes de hacerla.

## Decisiones del usuario que no están en el código

- **Stack:** Flutter para la app (tableta Android; la versión web es para verla en una PC); Python para preparar los datos. Node.js + MySQL solo si algún día hubiera backend: hoy está fuera de alcance, no hay servidor y la app funciona sin red.
- **Idioma:** el usuario trabaja en español y prefiere respuestas cortas y directas. La interfaz de la app es en español e inglés, configurable: todo texto visible va en `app/lib/l10n/*.arb`, nunca fijo en el código.
- **Sitios:** Gale y Meridiani Planum (tres ventanas: Endeavour, zona habitable y contexto regional; desde el 2026-11-14, el usuario amplió lo anterior de «Gale único sitio»). Cada sitio nuevo se prepara con `tools/10` a `12` y se registra en `app/assets/sites.json`. Reforzar con recursos oficiales de la NASA y el USGS; otros sitios son trabajo futuro.
- **Todo fuera de línea (regla del usuario, 2026-11-14):** todo mapa, imagen y dato debe quedar empaquetado dentro de la app y funcionar sin red. No cargar teselas ni datos en vivo desde Trek, el USGS ni otro servidor (ni siquiera como extra opcional): se descargan al preparar los datos con `tools/` y se empaquetan. Si algo no cabe, se reduce la resolución o el área, no se pasa a línea.
- **Descargas e instalaciones:** informar nombre, origen y tamaño antes. Ya está autorizado descargar de servidores de la NASA y el USGS y `pip install --user` de lo necesario, siempre con aviso previo.
- **Fuentes:** toda fuente de datos va a `RECURSOS.md` con URL y fecha.

## Regla de compilación y pruebas

Compilar toma mucho tiempo. No compilar tras cada cambio.

- Para encontrar errores, basta con el análisis: `flutter analyze` (y `flutter test` cuando el cambio toque el cálculo de rutas o los widgets).
- `flutter test` incluye una prueba de humo (`app/test/app_smoke_test.dart`) que abre las cuatro pestañas con las aserciones activas, como el modo desarrollo. Una build de release oculta errores de maquetación (por ejemplo `LayoutBuilder` dentro de `IntrinsicHeight`) que el modo desarrollo sí lanza: correr esa prueba tras cambiar widgets.
- **No instalar en la tablet en modo desarrollo por iniciativa propia** (tarda mucho). Si hace falta ver el cambio en pantalla, preguntar al usuario y esperar su confirmación. Instalar solo cuando lo confirme: `flutter run -d <id-de-la-tablet>` (modo debug) o, si pide compilar, el APK de release. No generar builds de release para probar sin que lo pida.
- Nada de `flutter build apk` ni `flutter build web` para comprobar cambios. Compilar un APK o una versión web de release solo cuando el usuario lo pida o para una entrega.
- **Al compilar para una entrega, compilar siempre el APK y la versión web, y publicar la web** (regla del usuario, 2026-11-14): `flutter build web --release` y copiar el contenido de `app/build/web/` a `/www/wwwroot/arespath.hellofactura.com/`. Esa carpeta es de `www:www` con permisos 755, así que el usuario tiene que darle permiso de escritura (ver `RETOMAR.md`, sección 7). No usar `sudo` sin que el usuario lo dé o lo pida. Dejar el APK en `dist/` con su SHA-256 y anotar ambas compilaciones en `RETOMAR.md`.
- El modo debug es más lento que release. No sacar conclusiones de rendimiento de ahí; las mediciones de rendimiento se hacen en release y solo si el usuario las pide.
- La tablet de prueba está conectada por adb en red (`flutter devices` muestra su id; el puerto puede cambiar).

## Regla general: uso de IA

El hackathon permite usar IA solo para:

- Escribir, depurar y documentar código.
- Resumir artículos y documentación técnica.
- Prototipar interfaces, imágenes o audio.

Obligatorio: declarar en la entrega cómo se usó la IA.

Cómo cumplirlo durante el desarrollo:

- Cada vez que una herramienta de IA deje un resultado en el proyecto, añadir una fila en `AI_USAGE.md` (fecha, herramienta, uso, resultado).
- No presentar como dato real de la NASA ningún valor, imagen o texto generado por IA. Marcar los datos de ejemplo como tales.
- Los datos científicos de la aplicación deben venir de fuentes de la NASA citadas en `RECURSOS.md`.

## Regla de documentación

El usuario alterna entre cuentas. Todo cambio en el proyecto se documenta en el mismo momento: añadir una línea en la sección "Registro de cambios" de `RETOMAR.md` (fecha, qué se hizo, qué falta) y, si cambia el estado de una fase, actualizar `PLAN.md`. Si el cambio usa IA, añadir también la fila en `AI_USAGE.md`.

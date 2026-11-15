# Recursos oficiales del desafío

Desafío: Interplanetary Survival Guide: Martian Map (NASA Space Apps Challenge 2026)

Fuente: https://www.spaceappschallenge.org/2026/challenges/interplanetary-survival-guide-martian-map/?tab=resources

Extraído el 2026-11-14. La página avisa que se pueden añadir más recursos antes del hackathon.

## NASA Data & Resources

| Recurso | Enlace | Descripción oficial |
|---|---|---|
| JPL Mars Trek | https://trek.nasa.gov/mars/ | Portal web de la NASA para explorar Marte. Muestra datos recopilados por la NASA en varios sitios de aterrizaje. |
| USGS-NASA Planetary Geologic Mapping Program | https://astrogeology-usgs.hub.arcgis.com/pages/interactive-maps-mars | Mapa geológico estandarizado de alta calidad de Marte. |
| Ruta propuesta de Curiosity en el Monte Sharp | https://science.nasa.gov/resource/curiositys-proposed-path-up-mount-sharp/ | Ejemplo de mapa de ruta. Animación de la ruta propuesta de Curiosity por la parte baja del Monte Sharp, con regiones de interés científico anotadas y un video de sobrevuelo. |
| NASA Worldview | https://worldview.earthdata.nasa.gov/ | Explorador visual de imágenes satelitales de la Tierra (parte de NASA Earthdata). Sirve como referencia de interfaz por capas, no como fuente de datos de Marte. |
| Mars Perseverance Raw Images Gallery | https://mars.nasa.gov/mars2020/multimedia/raw-images/ | Más de un millón de imágenes crudas tomadas por el rover Perseverance en la superficie de Marte. |

## Nota de uso

La NASA no respalda a entidades ajenas al gobierno de EE. UU. Para sitios que no son del gobierno de EE. UU., hay que cumplir los parámetros de uso de datos de cada sitio.

## Datos de la zona de caminata (Fase 0)

Verificado el 2026-11-14 con los archivos y páginas citados abajo. Las cifras salen de los scripts `tools/00_*.py` aplicados a datos del USGS y de la NASA. Lo que no se pudo comprobar está en "Límites conocidos".

### Dónde están las crestas boxwork

Curiosity estudió las crestas boxwork en 2025. El artículo de NASA/JPL abierto (https://www.jpl.nasa.gov/news/nasas-curiosity-mars-rover-starts-unpacking-boxwork-formations/) las sitúa en las faldas bajas del Monte Sharp, con imágenes del 15 al 18 de mayo y una perforación ("Altadena") el 8 de junio, pero no da coordenadas. No se encontró un mapa oficial de las crestas.

Como aproximación se usa la tabla oficial de posiciones del rover. Sus waypoints de los soles 4500 a 4899, el periodo de la campaña boxwork según las fechas de las imágenes y los blogs de la misión, caen en un área de 620 m (este-oeste) por 1259 m (norte-sur):

- Centroide: lat −4.8048°, lon 137.3823° (planetocéntrico, este positivo), elevación media −3625 m.
- Esa posición coincide con una red poligonal de crestas en la ortofoto (`data/work/quicklook_boxwork.png`, 500 × 500 m a 0.5 m por píxel). Es una comprobación visual, no una fuente oficial.

### Archivos elegidos

Todos los mosaicos usan la proyección equirectangular de Marte (esfera de radio 3 396 190 m, meridiano central 0, latitud planetocéntrica). En esa proyección `lon = este / R` y `lat = norte / R`. La tabla de waypoints de Curiosity trae esas mismas coordenadas (`easting`, `northing`).

| Capa | Archivo | Origen | Tamaño completo | Resolución | Uso |
|---|---|---|---|---|---|
| Relieve | `MSL_Gale_DEM_Mosaic_1m_v3.tif` | https://planetarymaps.usgs.gov/mosaic/Mars/MSL/MSL_Gale_DEM_Mosaic_1m_v3.tif | 3.87 GB (3 868 256 546 bytes) | 1 m por píxel, flotante de 32 bits, 32 980 × 57 440 px, LZW por franjas, sin dato = −32 767 | Se lee solo la ventana de trabajo. Copia local: `data/raw/dem_box_1m.tif` (25 MB) |
| Óptico en color | `MSL_Gale_HiRISE-LRGB_78quads_sharp_cog.tif` | https://asc-pds-services.s3.us-west-2.amazonaws.com/mosaic/Mars/MSL/MSL_Gale_HiRISE-LRGB_78quads_sharp_cog.tif | 1.03 GB (1 030 625 379 bytes) | 0.25 m por píxel, 3 bandas de 8 bits, 36 000 × 76 000 px, teselas de 512 con pirámide | Se lee solo la ventana. Copia local: `data/raw/lrgb_box_025m.tif` (500 MB) |
| Posiciones de Curiosity | `MSL_waypoints.json` | https://mars.nasa.gov/mmgis-maps/MSL/Layers/json/MSL_waypoints.json | 665 124 bytes | 1389 puntos, del sol 3 al sol 5073 | Copia completa en `data/raw/` |
| Recorrido de Curiosity | `MSL_traverse.json` | https://mars.nasa.gov/mmgis-maps/MSL/Layers/json/MSL_traverse.json | 1 357 951 bytes | Línea del recorrido | Copia completa en `data/raw/`. Aún sin usar |

Fichas del USGS (Astropedia):

- DEM: https://astrogeology.usgs.gov/search/map/mars_msl_gale_merged_dem_1m. Extensión: lat −5.0987° a −4.1296°, lon 137.1242° a 137.6806°. Construido a partir de modelos de HRSC, CTX y HiRISE ligados a MOLA. La ficha enumera los pares estéreo HiRISE usados.
- Ortomosaico en escala de grises de 25 cm: https://astrogeology.usgs.gov/search/map/mars_msl_gale_merged_orthophoto_mosaic_25cm. Enlaza el mosaico en color de HiRISE (LRGB, aprox. 1 GB) que se usa aquí.
- Licencia en ambas fichas: "Use Constraints: None. Please credit authors".
- Cita recomendada: Calef III, F. J., y Parker, T. (2016). MSL Gale Merged Orthophoto Mosaic y MSL Gale Merged DEM. PDS Annex, U.S. Geological Survey.
- Términos de uso de los JSON de `mars.nasa.gov`: sin consultar. Citar como NASA/JPL-Caltech hasta confirmarlos.

Descartado: el ortomosaico en escala de grises `MSL_Gale_Orthophoto_Mosaic_25cm_v3.tif` (https://asc-pds-services.s3.us-west-2.amazonaws.com/mosaic/MSL_Gale_Orthophoto_Mosaic_25cm_v3.tif). El servidor informa 50.4 GB (50 404 480 837 bytes), sin compresión ni teselas, y la ficha dice unos 23 GB. El mosaico en color tiene la pirámide y las teselas que hacen barata la lectura por ventanas.

### Recuadro de trabajo

Cuadrado de 4 × 4 km (se descargó con `tools/00_descargar_ventana.py`):

- Este 8 141 400 a 8 145 400 m, norte −286 750 a −282 750 m.
- Esquinas: suroeste lat −4.8376°, lon 137.3503°; noreste lat −4.7702°, lon 137.4178°.
- Contiene los waypoints de la campaña boxwork, el recorrido de Curiosity antes y después, y los candidatos de hábitat.

Resultados de `tools/00_verificar_cobertura.py`:

| Comprobación | Resultado |
|---|---|
| DEM sin dato en el recuadro | 0.00 % |
| Ortofoto en color sin dato | 0.02 % |
| Elevación | −4079 a −3244 m (835 m de desnivel) |
| Pendiente a 4 m por celda: menos de 10° | 43.2 % |
| 10° a 20° | 32.9 % |
| 20° a 25° | 8.3 % |
| Más de 25° | 15.7 % |
| Pendiente máxima | 70.9° |

Todos los waypoints boxwork caen en una misma región conectada de terreno transitable (pendiente menor de 25° a 4 m por celda, vecindad de ocho celdas). El 81.4 % de las celdas a 1–2 km de las crestas pertenece a esa región. Que existan rutas distintas entre sí dentro de ella se comprueba en la fase 2.

### Coordenada del hábitat (candidato 4, confirmado el 2026-11-14)

Criterio del plan: pendiente menor de 5°, suelo firme, a 1–2 km de las crestas. El script `tools/00_analisis_sitio.py` busca discos con pendiente menor de 5° (a 4 m por celda), conectados por terreno transitable con la zona boxwork. Solo el 12.9 % de las celdas cumple pendiente menor de 5° y el disco llano más grande de la ventana tiene 88 m de radio, así que el criterio de radio se bajó a 20–30 m. Candidatos:

| N.º | Este (m) | Norte (m) | Lat | Lon | Elevación | Radio llano | Distancia a crestas | Desnivel vs crestas | Distancia a pendiente mayor de 25° |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 8 144 957 | −286 320 | −4.8304° | 137.4104° | −3332 m | 38 m | 1938 m | +293 m | 85 m |
| 2 | 8 144 889 | −285 936 | −4.8239° | 137.4092° | −3359 m | 32 m | 1718 m | +266 m | 65 m |
| 3 | 8 144 173 | −283 472 | −4.7823° | 137.3971° | −3738 m | 32 m | 801 m | −113 m | 63 m |
| 4 | 8 142 565 | −283 620 | −4.7848° | 137.3700° | −3840 m | 31 m | 1174 m | −215 m | 72 m |
| 5 | 8 143 941 | −283 116 | −4.7763° | 137.3932° | −3780 m | 29 m | 1032 m | −155 m | 66 m |

Elegido: candidato 4. Cumple pendiente menor de 5° y los 1–2 km, y queda 215 m por debajo de las crestas, de modo que la ida baja y el regreso sube. Eso pone el consumo de oxígeno de regreso en el cálculo de forma realista. El candidato 1 es el único que cumple el criterio estricto de radio 30 m y 80 m de margen a la pendiente prohibida, pero está 293 m por encima y a 1.9 km. En la fase 1, sobre la rejilla de 2 m (más ruidosa que la de 4 m), el radio llano del candidato cayó a 18 m y `tools/03_costos.py` lo movió 21 m a la celda E 8 142 553, N −283 637 (lat −4.7851°, lon 137.3698°, elevación −3839 m, radio llano 21 m).

"Suelo firme" no se comprobó. Haría falta inercia térmica (THEMIS); sin ese dato se trata como supuesto.

### Límites conocidos

- Registro entre DEM y ortofoto: comprobado en la fase 1 con el relieve sombreado a la iluminación de la ortofoto (azimut 150°, altura 35°). Desfase mediano de +2 m este y 0 m norte, una celda de la rejilla; 55 de 64 teselas de 500 m quedan dentro de 4 m. Los picos de correlación son bajos (0.02 a 0.10), así que la cifra es indicativa. La comprobación a ojo en `docs/` es la que cierra el criterio.
- Procedencia del DEM por píxel: no se verificó cuánto del recuadro viene de HiRISE y cuánto de CTX o HRSC. La desviación del relieve fino va de 4 a 57 cm por celda de 250 m, lo que indica contenido a 1 m en todo el recuadro, pero no lo prueba.
- La ortofoto en color tiene dos franjas verticales en escala de grises (una al oeste y un recorte al sur). Tienen imagen, pero sin color.
- Las posiciones de la ortofoto y el DEM son de 2016 (versión 3). No reflejan cambios posteriores del terreno, como dunas.
- La fecha de salida de Curiosity de las crestas (marzo de 2026) viene de un resumen de prensa que no se abrió. No se usa en ningún cálculo.
- Capa térmica (THEMIS-IR): resuelta con Mars Trek, ver la sección "Capa térmica (THEMIS-IR, Mars Trek)". Capa de minerales (CRISM): sin resolver todavía. Radiación (RAD) y clima (REMS): resueltos en la Fase 4, ver la sección "Datos de radiación y clima (Fase 4)".

## Datos de radiación y clima (Fase 4)

Verificado el 2026-11-14. Descargas originales en `data/raw/rad/` y `data/raw/rems/` (no se versionan). El script `tools/06_clima_radiacion.py` las baja y las convierte; `tools/comprobar_ambiente.py` las compara con el JSON de la app.

| Dato | Fuente y producto | Qué se tomó | Tamaño | Formato |
|---|---|---|---|---|
| Radiación (RAD) | NASA SPDF CDAWeb, conjunto `MSL_RAD_OBS-L2` (DOI 10.48322/20qb-4e17; investigador principal D. Hassler, SwRI), servicio web CDAS: `https://cdaweb.gsfc.nasa.gov/WS/cdasr/1/dataviews/sp_phys/datasets/MSL_RAD_OBS-L2/data/` | Variable `DOSIMETRY_TOTAL_f` (calidad filtrada) del 1 de noviembre de 2025 al 11 de noviembre de 2026, pedida por meses: 31 018 mediciones, 366 sols con datos (sols 4706 a 5071) | 13 CSV, 1.9 MB en total | CSV con una medición cada unos 17 minutos, en µGy por día |
| Clima (REMS) | PDS Nodo de Atmósferas (NMSU), `MSL-M-REMS-5-MODRDR-V1.0`, volumen `mslrem_1001`, archivos `RMD` (productor: Centro de Astrobiología, INTA-CSIC): `https://atmos.nmsu.edu/PDS/data/mslrem_1001/DATA/SOL_04710_04843/` | Un archivo por sol, soles 4814 a 4843 (19 de febrero al 22 de marzo de 2026) | 30 archivos `.TAB` y 30 `.LBL`, 305 MB | Texto de 40 columnas separadas por comas, una fila por segundo; valor ausente −999; columnas definidas en `LABEL/MODRDR6.FMT` |

Columnas usadas de REMS: temperatura ambiente del aire, temperatura de brillo del suelo, presión, UV A+B+C y humedad relativa (la tabla trae además viento, que casi siempre falta). De RAD: tasa de dosis absorbida del detector E (plástico equivalente a tejido) y del detector B (silicio, con la fuente MMRTG del rover restada).

Qué sale de ahí: `app/assets/site_gale/environment.json` (147 KB). Por sol de REMS, estadísticas y un perfil por hora de tiempo solar medio local; por sol de RAD, media y máximo de la dosis. La línea base de radiación es la mediana de las medias diarias del detector E en los 60 sols previos al periodo de REMS (sols 4754 a 4813): 150.9 µGy por día.

Notas de la fuente:
- El archivo de RAD del PDS en el nodo PPI de UCLA (`MSLRAD_1002`) llega solo al sol 804, así que no sirve para datos actuales. CDAWeb, de la NASA, sí llega hasta noviembre de 2026.
- REMS en el PDS llega hasta el sol 4843 (21 y 22 de marzo de 2026; publicación de julio de 2026). La app evalúa un sol de esa ventana, no el día de hoy.
- Opacidad del polvo: el PDS no tiene un producto de REMS para ella. Queda pendiente de otra fuente.
- La dosis de RAD es dosis absorbida (µGy), no dosis equivalente (mSv). Pasar a mSv exige un factor de calidad que no se aplicó.
- El sol se calcula desde la hora UTC con la duración media del sol marciano (88 775.244 s), calibrada con el inicio del sol 4843 en REMS; el error es de minutos.
- Licencia: los productos del PDS y de CDAWeb son datos públicos de la NASA; citar a NASA PDS y a NASA SPDF, y al equipo de cada instrumento (RAD: SwRI; REMS: CAB INTA-CSIC). No se consultaron términos de uso adicionales.

## Capa térmica (THEMIS-IR, Mars Trek)

Verificado y descargado el 2026-11-14. Mars Trek es el recurso 1 de la lista oficial del desafío.

| Dato | Valor |
|---|---|
| Producto | `THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018` (THEMIS-IR de día, mosaico global controlado, Mars Odyssey) |
| Origen | `https://trek.nasa.gov/tiles/Mars/EQ/THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018/1.0.0/default/default028mm/9/269/902.png` (WMTS, conjunto de teselas `default028mm`, nivel 9) |
| Capacidades | `https://trek.nasa.gov/tiles/Mars/EQ/THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018/1.0.0/WMTSCapabilities.xml` |
| Archivos | 4 teselas PNG de 256 px (unos 180 KB en total) en `data/raw/themis/`; solo la 269/902 cubre el recuadro de 4 × 4 km |
| Resolución | 100 m por píxel nativo; la tesela del nivel 9 da 81 m por píxel. El recuadro son unos 50 × 50 píxeles |
| Qué es el valor | Brillo relativo de 8 bits (la tesela ya viene estirada), no una temperatura calibrada ni inercia térmica |
| Proceso | `tools/07_termica.py`: remuestrea al plano local a 8 m por píxel (interpolación bilineal) y colorea; salida `app/assets/site_gale/layers/thermal.png` (181 KB) |
| Licencia | Datos públicos de la NASA; citar NASA/JPL Mars Trek y el equipo THEMIS (Universidad Estatal de Arizona). No se consultaron términos de uso adicionales |

Descartado: `TES_Thermal_Inertia` (3 km por píxel, unas pocas celdas en el recuadro). El catálogo de Trek (`https://trek.nasa.gov/mars/TrekServices/ws/index/eq/searchItems?rows=2100`) lista además mosaicos CRISM de minerales; su cobertura sobre Gale no está verificada.

## Contexto geológico (mapa global del USGS, Mars Trek)

Verificado y descargado el 2026-11-14. Cubre el recurso oficial 2 (programa de mapeo geológico del USGS y la NASA) en la medida en que existe para Gale.

| Dato | Valor |
|---|---|
| Producto | `SIM3292_Global_Geology`: mapa geológico global de Marte del USGS (Scientific Investigations Map 3292), escala 1:20 000 000 |
| Origen | `https://trek.nasa.gov/mars/trekarcgis/rest/services/SIM3292_Global_Geology/MapServer/WMTS/tile/1.0.0/SIM3292_Global_Geology/default/default028mm/9/269/902.png`; leyenda en `.../MapServer/legend?f=json` |
| Archivos | 1 tesela PNG útil del nivel 9 (1133 bytes en total con las otras tres que se bajaron). El servicio devuelve teselas vacías del nivel 10 en adelante |
| Resultado | Todo el recuadro de 4 × 4 km cae en una sola unidad: «Hesperian transition undivided unit» (100 %), por comparación del color de la tesela con la leyenda |
| Uso en la app | Solo texto en la pantalla Ciencia (fila «Unidad geológica»). No se dibuja como capa, porque sería un color plano |
| Proceso | `tools/08_geologia.py` |
| Límite | Es un mapa global. En 4 × 4 km no tiene detalle y no distingue las formaciones locales que estudia Curiosity (por ejemplo, la unidad con crestas boxwork). Es contexto, no dato de ruta |
| Licencia | Producto del USGS en Mars Trek; citar USGS y NASA/JPL Mars Trek. Términos de uso adicionales sin consultar |

No se encontró un mapa geológico del programa de mapeo del USGS específico de Gale (búsqueda del 2026-11-14).

## Fuentes oficiales del desafío y qué capa sale de cada una

| Recurso oficial | Qué usamos |
|---|---|
| JPL Mars Trek | Capa térmica THEMIS-IR; mapa geológico global (texto en Ciencia); sirve también la misma ortofoto HiRISE y el mismo DEM de Gale (`curiosity_hirise_mosaic`, `Gale_DEM_SMG_1m`, misma extensión que los mosaicos del USGS) |
| USGS-NASA Planetary Geologic Mapping Program | Mapa geológico global SIM 3292 (vía Trek); sin mapa específico de Gale |
| Ruta propuesta de Curiosity en el Monte Sharp | Referencia para comparar nuestras rutas con el recorrido real (waypoints de `mars.nasa.gov`) |
| NASA Worldview | Solo referencia de interfaz por capas |
| Imágenes crudas de Perseverance | No usadas: son de Jezero, no de Gale |

Datos de la NASA y el USGS que no están en la lista oficial: mosaicos HiRISE y DEM del USGS Astrogeology (los archivos que se procesan), radiación RAD (NASA SPDF) y clima REMS (PDS).

## Fotos en primera persona de Curiosity (Fase 5)

Verificado y descargado el 2026-11-14. Cubre el objetivo O6 del desafío (imágenes en primera persona).

| Dato | Valor |
|---|---|
| Fuente | API de imágenes crudas de Curiosity en `mars.nasa.gov`: `https://mars.nasa.gov/api/v1/raw_image_items/?order=sample_type_sort+asc&per_page=100&page=0&condition_1=msl:mission&condition_2=<sol>:sol:gte&condition_3=<sol>:sol:lte&condition_4=NAV_LEFT_B,NAV_RIGHT_B:instrument:in` |
| Imágenes | 4 JPEG de Navcam de 1024 × 1024 px, en blanco y negro, de 450 a 527 KB (2.0 MB en total), una por objetivo de demostración: sol 4500 (`NLB_796987459EDR_F1142454NCAM00485M_`), 4548 (`NRB_801253219EDR_F1161260NCAM00299M_`), 4609 (`NLB_806660624EDR_F1172730NCAM00266M_`) y 4889 (`NLB_831507564EDR_F1220138NCAM00250M_`) |
| Crédito | NASA/JPL-Caltech |
| Proceso | `tools/09_fotos_rover.py --camara NAV --elegir 4548=NRB_801253219EDR_F1161260NCAM00299M_`; copia las fotos a `app/assets/site_gale/rover/` y escribe `app/assets/site_gale/rover_photos.json` |
| Descartado | Mastcam izquierda (`data/raw/rover_fotos/`, 892 KB): en blanco y negro, con viñeteo elíptico y mostrando solo el suelo cercano al rover. Navcam da gran angular con horizonte |
| Límites | Las fotos son de ese sol, tomadas cerca de la parada, no una vista del objetivo en sí; los objetivos de demostración son paradas reales de Curiosity pero su tipo y prioridad son supuestos del equipo. Algunas fotos muestran partes del rover. Términos de uso de las imágenes sin consultar; se citan como NASA/JPL-Caltech |

## Referencias de vehículos de superficie (modo con rover)

Verificadas el 2026-11-14 en registros públicos de la NASA. Respaldan los supuestos de `config/params.json`, bloque `rover`, pero ninguna es una especificación de un rover en Marte.

| Dato | Valor | Fuente |
|---|---|---|
| Pendiente del vehículo lunar de Apolo | Diseñado para 20 a 23° en condiciones favorables, 25° como máximo | [NTRS 20250011301](https://ntrs.nasa.gov/citations/20250011301) |
| Velocidad del vehículo lunar de Apolo | 9 a 13 km/h teóricos; velocidad media lograda 2.0 m/s (Apolo 15) y 1.7 m/s (Apolo 16), es decir 7.2 y 6.1 km/h; máximos de 2.6 y 2.5 m/s; hasta 14 km/h según el informe de Apolo 16 | [NTRS 20250011301](https://ntrs.nasa.gov/citations/20250011301) |
| Space Exploration Vehicle (rover presurizado, concepto) | Unos 10 km/h, dos tripulantes (cuatro en emergencia). Una tripulación a pie podría regresar unos 10 km | Ficha técnica de la NASA, [nasa.gov](https://www.nasa.gov/wp-content/uploads/2015/08/464826main_sev_factsheet_508.pdf) |
| Vehículo lunar de Artemis | Pendiente de 20° como capacidad requerida (resumen secundario, sin verificar en el documento de requisitos) | [Jatan Space](https://jatan.space/what-we-know-about-artemis-ltv/) |

Valores del modelo: velocidad 6 km/h (la lograda en Apolo 16, redondeada), límite de pendiente 20°. Sin referencia, supuestos del equipo: rugosidad máxima de 30 cm, oxígeno a 0.5 del ritmo nominal sobre el rover (sentado) y 5 minutos para subir o bajar.


## Datos para Meridiani: DCI y inercia térmica de TES (ASU), descargados el 2026-11-14

Solo bajados a `data/raw/asu/` (no versionado), sin usarse todavía en la app. Fuentes del Mars Space Flight Facility de ASU; los datos son de MGS/TES (NASA).

| Dato | Archivo | Tamaño | Formato y resolución | Fuente |
|---|---|---|---|---|
| Índice de cobertura de polvo (DCI) | `dci_16ppd.raw` (SHA-256 `7a4248d688cfddc8415881edd413b6edd71f4456439cdbf5e24a610b47b75e3c`) | 66.4 MB | float32 little-endian, 5760 × 2880, 16 píxeles por grado (3.5 km por píxel), columna 0 = −180° E. Rango 0.85 a 0.991 | `http://www.mars.asu.edu/~ruff/DCI/dci_lo_ice_dust_16ppd_shifted.raw`; cita: Ruff y Christensen, JGR 107, 2002, doi 10.1029/2001JE001580 |
| Inercia térmica numérica (recorte 330 a 360° E, −15 a 10°) | `ti_meridiani.vicar` (SHA-256 `0ad9beba59db7f8fec4ed92872098b6fac12f0a5563d5800b23c758352316938`) | 193 KB | VICAR, entero de 32 bits little-endian (`FORMAT='FULL'`), 240 × 200 píxeles remuestreados de un mapa de 8 píxeles por grado (7.5 km por píxel). Rango 147 a 602 | Servicio WMS `http://ms-mars.mars.asu.edu/ti16`, capa `TES_Thermal_Inertia_numeric`, enlazado desde `https://www.mars.asu.edu/data/tes_ti/`; cita: Christensen et al., 2001 |

Comprobaciones: con el origen de columna en −180° E, Syrtis Major sale con DCI alto (0.977) y Tharsis, Arabia y Olímpico con DCI bajo (0.93 a 0.94), como se espera; con origen en 0° E sale al revés. En Meridiani (lat −1.95, lon 354.5° E): DCI 0.974 e inercia térmica 219; en Gale: DCI 0.954. Términos de uso de ASU sin consultar. Las teselas de Mars Trek de estas capas son coloreadas y de nivel 0 a 2: no sirven para umbrales.

## Vectores de Mars Trek para Meridiani, descargados el 2026-11-14

Servicios ArcGIS de Mars Trek (NASA/JPL), consultados con un recuadro de lon −8° a −2° y lat −5° a 1° y guardados como GeoJSON en `data/raw/trek_vectores/` (unos 280 KB en total, no versionado, sin usar todavía en la app). La ruta salió de `getLayerServices?uuid=` del catálogo de Trek. Términos de uso de Trek sin consultar. Longitudes en −180 a 180.

| Capa | Archivo | Elementos | Servicio |
|---|---|---|---|
| Distribución de minerales acuosos (puntos; clases `sulfate` y `phyllosilicate`; no hay `carbonate` en el recuadro) | `acuosos_meridiani.geojson` | 64 (32 posiciones únicas: 20 sulfatos, 12 filosilicatos) | `https://trek.nasa.gov/mars/trekarcgis/rest/services/Aquieous_Mineral_Distribution_Options_clon0/MapServer/0` |
| Minerales hidratados (OMEGA y CRISM; Carter et al. 2013 según la descripción de Trek) | `hidratados_meridiani.geojson` | 24 (22 CRISM, 2 OMEGA) | `.../Hydrous_Mineral_Detections_OMEGA_CRISM_clon0/MapServer/0` |
| Zonas de exploración (NASA EMC, taller de 2015): puntos | `ez_puntos_meridiani.geojson` | 3: SW Sinus Meridiani (lat −2.25, lon −6.43), Southern Meridiani Planum (−3.17, −4.52), Western Meridiani Planum (−2.94, −5.54) | `.../EZ/MapServer/0` |
| EZMars: zonas habitables, sitios de aterrizaje, regiones de interés y radios de 100 km | `ezmars_capa1.geojson` (2 Hab_Zone), `ezmars_capa2.geojson` (2 Landing_Zone), `ezmars_capa3.geojson` (26 polígonos ROI), `ezmars_capa4.geojson` (4 círculos EZ_Buffer) | ver archivos | `.../EZMars/MapServer/{1,2,3,4}` |

Zonas habitables de Meridiani: «Meridiani Planum» (lat −3.085, lon −5.50) y «Sinus Meridiani» (−2.382, −6.594). Sitios de aterrizaje: (−3.08, −5.54) y (−2.30, −6.40). No hay ninguna zona llamada «East Meridiani»; los radios EZ_Buffer son «Firsoff Crater», «Sinus Meridiani» y dos «Meridiani Planum» (centros lat 0.5 lon −4.5 y lat −3.08 lon −5.54).

Redes de valles (Hynek, `Hynek_Valley_Networks`): solo servicio de teselas (WMTS); no hay ninguna tesela de nivel 5 a 7 en el recuadro, es decir, sin redes de valles de Hynek en Meridiani. CRISM por mosaico (`frt_07_*`): sin servicio; los puntos de minerales acuosos e hidratados lo sustituyen. Las teselas de MOLA color hillshade global (463 m) siguen sin respuesta.

Valores de las capas en la zona habitable «Meridiani Planum»: DCI 0.974 e inercia térmica 226 (amarilla con los umbrales del usuario); en «Sinus Meridiani»: DCI 0.968 e inercia 187 (amarilla). Dentro de 100 km de la primera zona habitable: 6 sulfatos, 6 filosilicatos y 8 detecciones hidratadas.

## DEM global MOLA y HRSC de 200 m (USGS), verificado el 2026-11-14

| Dato | Archivo | Tamaño | Formato | Fuente |
|---|---|---|---|---|
| Relieve de Marte, mezcla de MOLA y HRSC | `Mars_HRSC_MOLA_BlendDEM_Global_200mp_v2.tif` | 11.38 GB (11 384 463 908 bytes); no se descarga entero | GeoTIFF sin compresión, entero de 16 bits (metros), 106 694 × 53 347 px, coordenadas en grados (CRS ESRI:104971, esfera de Marte, radio 3 396 190 m), 0.003374° por píxel = 200 m, sin dato = −32 768, franjas de una fila; el servidor admite rangos HTTP | `https://planetarymaps.usgs.gov/mosaic/Mars/HRSC_MOLA_Blend/Mars_HRSC_MOLA_BlendDEM_Global_200mp_v2.tif` |

Prueba: se leyó solo una ventana de 100 × 100 píxeles (20 × 20 km, 6 s) alrededor de la zona habitable de Meridiani Planum (lat −3.085, lon −5.50) y se calculó la pendiente con el tamaño de píxel en metros. Elevación de −1696 a −1331 m; pendiente mediana 1.55°, percentil 90 de 3.41°, máxima 16.9°; 1.3 % de la ventana supera 8.5° (15 %) y nada supera 20°. La pendiente a 200 m alisa las rugosidades pequeñas: sirve para una ruta indicativa, no para evitar rocas ni pendientes locales. Ficha de USGS Astrogeology y términos de uso sin consultar.

## Fuentes para las ventanas locales de Meridiani (F4), verificadas el 2026-11-14

Solo verificación; la descarga de ortofotos y del recorte de pendiente está pendiente de autorización.

| Ventana | Dato | Fuente | Detalle |
|---|---|---|---|
| Endeavour (rutas de calidad alta) | Relieve de 1 m del cráter Endeavour | Mars Trek, `DEM_1m_Endeavour_Crater_isis3_2017-04-14`: `https://trek.nasa.gov/mars/TrekWS/rest/cat/data/stream?label=DEM_1m_Endeavour_Crater_isis3_2017-04-14` | 703 735 672 bytes. El servidor **no admite rangos HTTP**: una petición con `Range` devuelve el archivo entero. GeoTIFF sin compresión, float32, 8091 × 21739 px a 1 m, coordenadas en metros (esfera de Marte, radio 3 396 190 m; lon = x / R, lat = y / R), sin dato = −32 767, elevación de −1694 a −1381 m, 64 % de píxeles válidos. Metadato de autoría: «TBD» (sin cita; hay que anotarla como «MRO HiRISE, DEM Endeavour Crater, vía Mars Trek») |
| Endeavour | Ortofoto HiRISE | Mars Trek, teselas WMTS `opportunity_hirise_mosaic`: `https://trek.nasa.gov/tiles/Mars/EQ/opportunity_hirise_mosaic/1.0.0/default/default028mm/{z}/{fila}/{col}.png` | PNG de 256 px, ~46 000 bytes cada una, hasta el nivel 17 (0.32 m por píxel); nivel 16 = 0.64 m por píxel. Cobertura lon −5.596° a −4.995°, lat −2.751° a −1.899° |
| Zona habitable | Relieve de 200 m | USGS, `Mars_HRSC_MOLA_BlendDEM_Global_200mp_v2.tif` (ver la sección del DEM global) | Lectura por rangos; unos 21 MB por una ventana de 20 × 20 km, porque cada franja es de una fila |
| Zona habitable | Ortofoto CTX | Mars Trek, teselas WMTS `S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd` | PNG de 256 px (grises con alfa), ~58 000 bytes cada una, hasta el nivel 12 (10.2 m por píxel). USGS la tiene a 6 m: `https://asc-pds-services.s3.us-west-2.amazonaws.com/mosaic/Mars/CTX_EZs/S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd.tif` (2.75 GB, sin comprobar si admite recortes por rangos) |

Ventana elegida para Endeavour (ventana de 4 × 4 km del DEM, filas 10000 a 14000 y columnas 2500 a 6500 desde la esquina noroeste del archivo, en píxeles de 1 m): lon −5.4045° a −5.3370°, lat −2.3599° a −2.2924°; 100 % de píxeles válidos, relieve de 306 m, pendiente mediana 0.8° y percentil 95 de 17° (a 10 m por píxel). El listado del bucket de USGS (`https://asc-pds-services.s3.us-west-2.amazonaws.com/?list-type=2&prefix=mosaic/Mars/&delimiter=/`) no trae el DEM ni la ortofoto de Endeavour; sí trae los mosaicos CTX de las zonas de exploración (`CTX_EZs/`).

**Descargado el 2026-11-14 (F4), a petición del usuario.** En `data/raw/meridiani_endeavour/`: `dem_box_1m.tif` (recorte de 4 × 4 km, 53 MB; el DEM original de 704 MB se bajó entero y se borró) y `hirise_z17/` (2704 teselas, 117.1 MB). En `data/raw/meridiani_habitat/`: `dem_box_200m.tif` (100 × 100 px) y `ctx_z12/` (110 teselas, 6.3 MB). Procesado con `tools/10_meridiani_datos.py` y `tools/11_sitio_meridiani.py`; resultado en `app/assets/site_meridiani_endeavour/` y `site_meridiani_habitat/`. Citar como: NASA/JPL-Caltech/University of Arizona (HiRISE y CTX, MRO), vía NASA Mars Trek; USGS Astrogeology (DEM MOLA y HRSC). Términos de uso de Trek sin consultar.

**Descargado el 2026-11-14 (F5), con aviso previo.** En `data/raw/meridiani_regional/`: `dem_box_400m.tif` (DEM del USGS de 200 m leído a 400 m por la pirámide, 250 × 250 px), `ctx_z11/` (506 teselas CTX de Mars Trek, 26.4 MB, 20.35 m por píxel) y `themis_noche_z9/` (64 teselas THEMIS-IR noche, `THEMIS_NightIR_ControlledMosaics_100m_v2_oct2018`, 3.3 MB, 81.4 m por píxel). Capas de F5 (`tools/12_capas_meridiani.py`): tránsito a partir de DCI (Ruff y Christensen 2002, ASU, 3.5 km) e inercia térmica (Christensen et al. 2001, ASU, 7.5 km) con umbrales del usuario sin fuente; térmica de noche (THEMIS-IR vía Trek, brillo relativo, no es inercia térmica calibrada); minerales y zonas de exploración de Mars Trek (ver la sección de vectores). No se halló el recorrido de Opportunity: las rutas `mars.nasa.gov/mmgis-maps/MER*/Layers/json/*` responden 403.

**Descargado el 2026-11-14 (F5b), con aviso previo.** `data/raw/contexto/`: teselas CTX de Mars Trek para los marcos de contexto: `gale_ctx_z11/` (producto `Gale_CTX_BlockAdj_dd`, 110 teselas, 5.9 MB, 20.35 m por píxel), `endeavour_ctx_z11/` (`S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd`, 110 teselas, 5.4 MB) y `regional_ctx_z9/` (mismo producto, nivel 9, 156 teselas, 8.0 MB, 81.4 m por píxel). `data/raw/rasgos/{gale,meridiani}/` (23 MB): minerales acuosos e hidratados, zonas de exploración (NASA EMC 2015), campos de dunas y nombres de la UAI (Mars Trek, servicios ArcGIS `https://trek.nasa.gov/mars/trekarcgis/rest/services/` y catálogo `searchItems`), cráteres de la base de Robbins de 1 km o más (`https://astrogeology.usgs.gov/pygeoapi/collections/mars/robbinsv1`) y unidades del mapa geológico global SIM 3292 (`.../mars/sim3292_global_geologic_map/units`, USGS Astrogeology). Cuentas dentro de las regiones: Gale 14 acuosos, 6 hidratados, 2 dunas, 43 cráteres, 6 unidades, 5 nombres; Meridiani 32 acuosos, 9 hidratados, 278 cráteres, 2 unidades, 5 nombres. Términos de uso de Trek y del servicio del USGS sin consultar.

**Descargado el 2026-11-14 (B, alcance de Gale), con aviso previo.** `data/raw/gale_alcance/`: `dem_box_16m.tif` (DEM del USGS `MSL_Gale_DEM_Mosaic_1m_v3.tif` leído a 16 m por su pirámide `.ovr`, 1500 × 1500 px, 9 MB; `https://planetarymaps.usgs.gov/mosaic/Mars/MSL/MSL_Gale_DEM_Mosaic_1m_v3.tif`) y `hirise_z14/` (1280 teselas del mosaico HiRISE `curiosity_hirise_mosaic` de Mars Trek, nivel 14, 55.8 MB, 2.54 m por píxel; 320 teselas del borde sin dato). El mosaico HiRISE tiene huecos: se rellenan con CTX. Procesado con `tools/15_sitio_alcance_gale.py`.

**Descargado el 2026-11-14 («ambos»), con aviso previo.** `data/raw/base/`: mosaicos CTX completos de Mars Trek a nivel 10 (40.7 m por píxel), `gale_ctx_z10/` (`Gale_CTX_BlockAdj_dd`, 552 teselas, 26.3 MB) y `meridiani_ctx_z10/` (`S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd`, 800 teselas, 36.8 MB). `data/raw/endeavour_alcance/`: `DEM_1m_Endeavour_completo.tif` (703 735 672 bytes, Trek), `dem_fino_16m.tif`, `dem_grueso_200m.tif` (USGS MOLA y HRSC, recorte de 22 km) y `hirise_z14/` (1369 teselas HiRISE de `opportunity_hirise_mosaic`, nivel 14, 64.3 MB). Procesado con `tools/16_mapa_base.py` y `tools/17_sitio_alcance_endeavour.py`. Términos de uso de Trek sin consultar.

## Capa de tránsito de Gale y recorrido de Opportunity, descargados el 2026-11-14

Con aviso previo al usuario. Solo a `data/raw/` (no versionado). Procesados con `tools/21_tes_gale.py` y `tools/22_opportunity.py`.

| Dato | Archivo | Tamaño | Formato y resolución | Fuente |
|---|---|---|---|---|
| Inercia térmica de TES, recorte de Gale (127 a 147° E, −12.5 a 12.5°) | `data/raw/asu/ti_gale.vicar` (SHA-256 `6f0649d47584f3dcd11e460ee8357fa0822a7195a0749fd27533dc800d1f5bfd`) | 128 640 bytes | VICAR, entero de 32 bits little-endian, 160 × 200 píxeles de 0.125° (7.5 km); etiqueta de 640 bytes. Rango 104 a 602 | Servicio WMS `http://ms-mars.mars.asu.edu/ti16`, capa `TES_Thermal_Inertia_numeric`, `image/vicar`, `EPSG:4326`; cita: Christensen et al., 2001 |
| Recorrido corregido de Opportunity | `data/raw/opportunity/MERB_traverse_5130.csv` (SHA-256 `bd0a50b39c62f021ce609170f72c00229ef9dd15459bf48fa5bb5f5c45ba553b`) | 1 463 086 bytes, 21 103 filas | CSV: `SITE, DRIVE, START_SOL, END_SOL, RAW_X, RAW_Y, RAW_Z, CORRECTED_X, CORRECTED_Y` (metros al este y al norte del sitio de aterrizaje, sol 1 a 5081) | PDS Geosciences Node (Washington University), `https://an.rsl.wustl.edu/mera/AN/meri/MER/traverse/MERB_traverse_5130.csv`; la página `https://an.rsl.wustl.edu/mera/AN/pages/mer/mer_traverse.htm` lo atribuye a Tim Parker (JPL) |
| Catálogo de Mars Trek | `data/raw/opportunity/trek_catalogo.json` | 1 504 672 bytes | JSON del buscador de Trek | `https://trek.nasa.gov/mars/TrekServices/ws/index/eq/searchItems?rows=2100`. Resultado: sin recorrido de Opportunity en Trek (solo el de Perseverance) |

Notas: (1) El DCI de Gale sale del mismo `dci_16ppd.raw` global. En la ventana de 4 km de Gale (DCI 0.967 a 0.971, inercia 344 a 369) la capa es de un solo color (verde); en el alcance de 24 km (DCI 0.944 a 0.971, inercia 294 a 486) hay 71.5 % verde, 5.4 % amarillo y 23 % sin clase. Umbrales: supuestos del equipo, los mismos que en Meridiani. (2) La CSV no dice el datum ni el origen. Se tomó como sitio de aterrizaje Eagle Crater (lat −1.9462, lon 354.4734° E, valor publicado por la NASA) con un plano local; el final del recorrido (sol 5081) cae en lat −2.329, lon −5.350, dentro del recuadro del DEM de Endeavour, y es coherente con Perseverance Valley. La posición es **aproximada** (error sin medir). (3) Términos de uso de ASU y del PDS sin consultar. (4) Probado sin salida: `mars.nasa.gov/mmgis-maps/MER-B/...` responde 403.


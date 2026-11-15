"""Genera docs/ARES_PATH_manual_usuario.pdf: manual completo de uso de ARES PATH (v0.9.4), con capturas de la tablet.

Reutiliza las fuentes, estilos y tablas de tools/generar_guia_equipo.py. Las capturas están en docs/manual/ (tomadas de la
tablet por adb con la app en español: `adb exec-out screencap -p`).
Uso: python3 generar_manual.py
"""
import importlib.util
import os

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (BaseDocTemplate, Frame, KeepTogether, PageBreak, PageTemplate, Paragraph, Spacer, Table,
                                TableStyle)

_spec = importlib.util.spec_from_file_location("guia", os.path.join(os.path.dirname(os.path.abspath(__file__)), "generar_guia_equipo.py"))
g = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(g)

P, H1, H2, BODY, SMALL, CELL, W = g.P, g.H1, g.H2, g.BODY, g.SMALL, g.CELL, g.W
bullets, tabla, recuadro, imagen = g.bullets, g.tabla, g.recuadro, g.imagen
VERSION = "0.9.4"
FECHA = "14 de noviembre de 2026"
SALIDA = os.path.join(g.DOCS, "ARES_PATH_manual_usuario.pdf")
MONO = ParagraphStyle("mono2", parent=BODY, fontName="Mono", fontSize=8.2, leading=11.5, leftIndent=10, backColor=g.SOFT, borderPadding=5, spaceBefore=3, spaceAfter=8)
NUM = ParagraphStyle("num", parent=BODY, leftIndent=14, bulletIndent=0, spaceAfter=3)


def pasos(items):
    return [Paragraph(t, NUM, bulletText=f"{i}.") for i, t in enumerate(items, 1)]


def imagen_manual(nombre, ancho, max_px=1500, calidad=80):
    """Captura de docs/manual/ reducida a JPEG para que el PDF pese poco."""
    im = g.PILImage.open(os.path.join(g.DOCS, "manual", nombre)).convert("RGB")
    im = im.resize((max_px, round(im.height * max_px / im.width)))
    tmp = os.path.join(g.tempfile.gettempdir(), "ares_manual_" + os.path.splitext(nombre)[0] + ".jpg")
    im.save(tmp, quality=calidad)
    img = g.Image(tmp, width=ancho, height=ancho * im.height / im.width)
    img.hAlign = "CENTER"
    return img


def fig(nombre, ancho, pie):
    return KeepTogether([imagen_manual(nombre, ancho), Paragraph(pie, ParagraphStyle("pie", parent=SMALL, alignment=1, spaceBefore=3, spaceAfter=10))])


def formula(t):
    return Paragraph(t, MONO)


def portada():
    t = Table([[[
        Paragraph("ARES PATH", ParagraphStyle("t", fontName="Grotesk", fontSize=32, leading=36, textColor=colors.white)),
        Paragraph("Manual de uso", ParagraphStyle("st", fontName="Grotesk", fontSize=15, leading=19, textColor=g.ORANGE, spaceBefore=2)),
        Spacer(1, 8),
        Paragraph(f"Versión {VERSION} · {FECHA}<br/>Planificador de caminatas de astronauta (EVA) en Marte<br/>NASA Space Apps Challenge 2026 · «Interplanetary Survival Guide: Martian Map»",
                  ParagraphStyle("meta", fontName="Inter", fontSize=8.8, leading=13, textColor=colors.HexColor("#CFC6C0"))),
    ]]], colWidths=[W])
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), g.DARK), ("LEFTPADDING", (0, 0), (-1, -1), 18), ("TOPPADDING", (0, 0), (-1, -1), 20),
                           ("BOTTOMPADDING", (0, 0), (-1, -1), 18), ("LINEBELOW", (0, 0), (-1, -1), 3, g.ORANGE)]))
    return t


def pie(canvas, doc):
    canvas.saveState()
    canvas.setFont("Inter", 7.5)
    canvas.setFillColor(g.MUTE)
    canvas.drawString(0.75 * inch, 0.45 * inch, f"ARES PATH · Manual de uso · versión {VERSION} · {FECHA}")
    canvas.drawRightString(letter[0] - 0.75 * inch, 0.45 * inch, f"Página {doc.page}")
    canvas.setStrokeColor(g.LINE)
    canvas.setLineWidth(0.4)
    canvas.line(0.75 * inch, 0.62 * inch, letter[0] - 0.75 * inch, 0.62 * inch)
    canvas.restoreState()


def contenido():
    s = []
    A = s.append
    E = s.extend

    A(portada())
    A(Spacer(1, 14))
    A(P("Este manual explica cómo usar ARES PATH, cómo calcula cada número que muestra y de dónde sale cada dato. Está pensado para quien prueba la "
        "app en la tablet, para quien la presenta y para quien necesita defender sus resultados. Las capturas son de la tablet "
        "(Samsung Galaxy Tab S9+) con la app en español."))
    A(P("<b>Contenido</b>", H2))
    E(bullets([
        "1. Qué es ARES PATH y qué no es",
        "2. Instalación y primer arranque",
        "3. Recorrido de la pantalla",
        "4. Pestaña Plan: capas, mapa, objetivos, rutas",
        "5. Pestaña Seguridad",
        "6. Pestaña Ciencia",
        "7. Pestaña Misión (simulación de la caminata)",
        "8. Pestaña Casco (visera)",
        "9. Sitios y misiones guardadas",
        "10. Cómo se calcula cada cosa",
        "11. De dónde salen los datos",
        "12. Límites, supuestos y advertencias",
        "13. Problemas frecuentes · 14. Glosario · Anexo: valores de los supuestos",
    ]))
    A(PageBreak())

    # ---------------- 1 ----------------
    A(P("1. Qué es ARES PATH y qué no es", H1))
    A(P("ARES PATH ayuda a planear una caminata de astronauta (EVA, actividad extravehicular) en Marte. Para un sitio concreto, la app muestra un mapa "
        "con capas de datos reales de la NASA y el USGS, calcula tres rutas candidatas desde el hábitat hasta los objetivos científicos que "
        "el usuario coloca, y dice qué tan peligrosa y qué tan exitosa es cada una. También revisa si las condiciones de radiación y de clima "
        "permiten salir (GO / NO-GO), simula la caminata paso a paso y muestra una pantalla de visera de casco."))
    A(P("Cuatro ideas resumen la app:", BODY))
    E(bullets([
        "<b>Todo funciona sin red.</b> Mapas, imágenes y datos van dentro de la app. No hay servidor ni cuenta.",
        "<b>Cada valor es de uno de tres tipos</b>, marcado en pantalla: <b>MEDIDO</b> (dato real de la NASA, el USGS o ASU), <b>MODELADO</b> (calculado por el equipo con esos datos) "
        "o <b>supuesto</b> del equipo (no es un estándar de la NASA). La etiqueta «EJEMPLO» solo aparece donde falta un dato real, por ejemplo en la foto de un objetivo que no trae foto del rover.",
        "<b>Es una herramienta de planeación, no un sistema de vuelo.</b> No sustituye procedimientos reales ni da signos vitales; la simulación y la visera son conceptos visuales.",
        "<b>Idioma:</b> español e inglés, con el botón EN / ES de la barra superior.",
    ]))
    A(recuadro("Lo que ARES PATH no hace", [
        "No es un pronóstico: el clima y la radiación son de un día pasado (el «sol de referencia»), no de hoy.",
        "No modela rocas sueltas menores de 1 m ni arena suelta (no hay dato de ello); las pendientes salen de un modelo de elevación, no de la superficie real.",
        "No lleva signos vitales ni sensores del traje: nadie los mide. Lo que la simulación muestra es una estimación a partir de los totales de la ruta.",
    ], g.AMBER_DK))

    # ---------------- 2 ----------------
    A(P("2. Instalación y primer arranque", H1))
    A(P("Tableta Android", H2))
    A(P("La app está pensada para tableta en horizontal y a pantalla completa. El instalador es <font name='Mono'>ARES_PATH_v0.9.4.apk</font> (unos 217 MB). "
        "Hay dos formas de instalarlo:"))
    E(pasos([
        "<b>Con un cable o por red (adb):</b> conecta la tablet con la depuración USB o inalámbrica activada y ejecuta en la PC <font name='Mono'>adb install -r dist/ARES_PATH_v0.9.4.apk</font>.",
        "<b>Desde la propia tablet:</b> copia el APK a la tablet, ábrelo y permite la instalación de apps de origen desconocido cuando Android lo pida. Se instala sobre una versión anterior sin perder las misiones guardadas.",
    ]))
    A(P("Comprueba el archivo con su huella SHA-256 (está en <font name='Mono'>RETOMAR.md</font>) si lo recibes por un medio no confiable."))
    A(P("Versión web", H2))
    A(P("La misma app corre en un navegador de escritorio en <font name='Mono'>https://arespath.hellofactura.com</font>. Sirve para verla en una PC; la experiencia "
        "pensada es la de la tableta. La primera carga baja unos 236 MB de mapas, y después funciona con lo guardado en el navegador."))
    A(P("Primer arranque", H2))
    A(P("Al abrir la app aparece el sitio por defecto, <b>Gale · Crestas boxwork</b>, con una misión llamada «Mission 1» y cuatro objetivos de demostración. "
        "Las rutas se calculan solas (la barra superior muestra «CALCULANDO RUTAS…» un instante). Los objetivos de demostración son paradas reales de "
        "Curiosity; su tipo, prioridad y tiempo de trabajo son supuestos del equipo."))

    # ---------------- 3 ----------------
    A(P("3. Recorrido de la pantalla", H1))
    A(fig("01_plan.png", 6.9 * inch, "Pestaña Plan (Gale): capas a la izquierda, mapa con perfil de elevación al centro y comparación de rutas a la derecha, con el bloque «Frente a la ruta rápida»."))
    A(P("Barra superior", H2))
    E(bullets([
        "<b>Logotipo y nombre.</b> ARES PATH.",
        "<b>Selector de sitio</b> (la flecha junto al nombre del sitio). Abre la lista de sitios; el activo lleva un círculo naranja. Ver sección 9.",
        "<b>Misión</b> (icono de carpeta con el nombre de la misión abierta). Abre el administrador de misiones guardadas.",
        "<b>Pestañas:</b> PLAN, SEGURIDAD, CIENCIA, MISIÓN y CASCO.",
        "<b>EN / ES</b> cambia el idioma al instante. Todo texto visible cambia, incluidos los números (coma decimal en español, punto en inglés). El idioma y las capas encendidas de cada sitio se recuerdan al cerrar y volver a abrir la app.",
        "<b>Estado de la ruta seleccionada:</b> FACTIBLE (verde), NO FACTIBLE o INALCANZABLE (rojo), SIN OBJETIVO (ámbar).",
    ]))
    A(P("Barra inferior", H2))
    A(P("A la izquierda, la atribución de las imágenes (HiRISE, NASA/JPL/UArizona, y USGS Astrogeology). A la derecha, <b>FUENTES</b>: abre una ventana con las "
        "fuentes de datos agrupadas en tres tipos (reales, calculados por el equipo y supuestos)."))

    # ---------------- 4 ----------------
    A(PageBreak())
    A(P("4. Pestaña Plan", H1))
    A(P("Es la pantalla principal. Aquí se eligen las capas, se colocan los objetivos y se comparan las tres rutas."))
    A(P("4.1 Capas de datos (panel izquierdo)", H2))
    A(P("Cada capa tiene una casilla, una etiqueta de tipo (MEDIDO o MODELADO), la fuente y la resolución, y un deslizador de opacidad cuando está encendida. "
        "El contador «N ACTIVAS» muestra cuántas están encendidas y el icono circular las restablece a las de arranque (superficie óptica, pendiente y recorrido del rover)."))
    A(tabla([
        ["Capa", "Qué muestra", "Dato"],
        ["Superficie óptica", "Imagen HiRISE a color (0.25 m por píxel en Gale)", "MEDIDO · HiRISE/MRO"],
        ["Relieve (sombreado)", "Relieve sombreado del modelo de elevación", "MEDIDO · DEM 1 m"],
        ["Pendiente", "Pendiente por colores: &lt;10° verde, 10–20° amarillo, 20–25° naranja, &gt;25° rojo", "MODELADO · 4 m"],
        ["Zonas prohibidas", "Celdas donde no se puede caminar (pendiente sobre 25° o sin dato)", "MODELADO"],
        ["Pendiente mayor de 15 %", "Marca las celdas con más de 15 % (8.5°); es el límite que se evita para una base", "MODELADO"],
        ["Recorrido de Curiosity / Opportunity", "Línea real del rover en el sitio (Curiosity en Gale, Opportunity en Meridiani)", "MEDIDO · NASA/PDS"],
        ["Térmica (THEMIS-IR día / noche)", "Brillo relativo en infrarrojo (no es temperatura calibrada). La de noche es un indicador de la inercia térmica", "MEDIDO · Odyssey"],
        ["Zonas de tránsito", "Verde / amarillo / rojo según el índice de polvo (DCI) y la inercia térmica de TES", "MODELADO · TES 3.5 km"],
        ["Minerales acuosos e hidratados", "Todos los puntos de sulfatos, filosilicatos y minerales hidratados vistos desde órbita (apagada al arrancar)", "MEDIDO · CRISM, OMEGA"],
        ["Minerales acuosos · biofirmas", "Solo filosilicatos y carbonatos (rombos magenta y verdes): suelo con más probabilidad de conservar biofirmas. Solo Meridiani", "MEDIDO · Mars Trek"],
        ["Minerales hidratados (CRISM, OMEGA)", "Detecciones hidratadas en todo el mosaico CTX de Meridiani (rombos cian). Solo Meridiani", "MEDIDO · CRISM, OMEGA"],
        ["Redes de valles (Hynek 2010)", "Líneas azules de valles formados por agua antigua, recortadas al mapa base. Solo Meridiani", "MEDIDO · Hynek y otros 2010"],
        ["Zonas de exploración", "Zonas habitables y de exploración propuestas por la NASA en 2015", "MEDIDO · NASA"],
        ["Nombres oficiales", "Nombres de rasgos aprobados por la UAI", "MEDIDO · Trek"],
        ["Cráteres de 1 km o más", "Círculos de la base de datos de Robbins", "MEDIDO"],
        ["Geología y dunas", "Unidades geológicas del mapa global del USGS y campos de dunas", "MEDIDO · escala global"],
    ], [1.75 * inch, 3.75 * inch, 1.5 * inch]))
    A(Spacer(1, 6))
    A(P("Algunas capas dependen del sitio; el panel solo muestra las que ese sitio tiene. Debajo de la lista hay una leyenda que cambia con las capas encendidas "
        "(pendiente, tránsito, minerales, zonas, geología). Una nota explica que fuera del recuadro punteado hay una imagen de contexto más gruesa."))
    A(P("En los cuatro sitios de Meridiani, las tres capas de <b>Búsqueda de biofirmas</b> (acuosos, hidratados y redes de valles) arrancan encendidas y su leyenda lo aclara: son detecciones desde órbita, no muestras. "
        "La capa «Minerales acuosos e hidratados» sigue aparte, apagada, y es la única que dibuja los sulfatos. Si una capa de biofirmas está encendida, esa capa no repite sus puntos."))

    A(P("4.2 El mapa", H2))
    E(bullets([
        "<b>Mover:</b> arrastra con un dedo. <b>Acercar o alejar:</b> pellizca con dos dedos, o usa los botones + y − de la esquina. El botón de la tercera posición ajusta todo el recuadro a la vista.",
        "<b>Recuadro punteado «ÁREA DE RUTAS»:</b> solo dentro de él se calculan rutas. Fuera hay imagen de contexto y, al alejarte mucho, el mapa base de la región.",
        "<b>Barra de abajo a la izquierda:</b> coordenadas (latitud y longitud), elevación y pendiente del último punto tocado o apuntado. Con el dedo se actualiza al tocar y al mantener pulsado.",
        "<b>Escala</b> en la esquina inferior derecha.",
        "<b>Rutas:</b> la seleccionada se dibuja gruesa; las demás, más tenues. Cada color corresponde a un perfil (ver 4.5). Un rombo marca cada objetivo con su código y prioridad (por ejemplo «T1 · P5»), y un cuadro verde marca el hábitat.",
    ]))

    A(P("4.3 Tarjeta de información del punto", H2))
    A(fig("02_punto.png", 5.9 * inch, "Al tocar un punto vacío del mapa aparece la mira y la tarjeta «INFO DEL PUNTO»."))
    A(P("Toca cualquier punto del mapa que no sea un objetivo. Aparece una mira cian y, arriba a la derecha, la tarjeta con todo lo que se sabe de ese punto. "
        "Todo sale de los datos empaquetados en la app; no hay consulta en línea."))
    A(tabla([
        ["Campo", "Cómo se obtiene"],
        ["Coordenadas y posición local", "Del plano local del sitio (metros desde la esquina noroeste) convertido a latitud y longitud con la esfera de Marte de 3 396 190 m de radio"],
        ["Elevación, pendiente, rugosidad", "De la rejilla de costos del sitio (ver sección 10.1). La rugosidad solo aparece si el sitio la conoce"],
        ["Terreno", "«Transitable a pie» o «Prohibido o sin dato», según la zona prohibida"],
        ["Distancia al hábitat", "Línea recta"],
        ["Distancia a la ruta elegida", "Al punto más cercano del camino de la ruta seleccionada (o «Sin ruta calculada»)"],
        ["Unidad geológica / campo de dunas", "El polígono del mapa geológico del USGS que contiene el punto"],
        ["Objetivo más cercano", "Código, nombre y distancia. Si ese objetivo trae foto real del rover y está a menos de 250 m, se muestra la foto con su cámara y sol"],
        ["Rasgo con nombre más cercano", "Nombre de la UAI a menos de 2 km"],
        ["Mineral detectado más cercano", "Sulfato, filosilicato o mineral hidratado a menos de 1 km"],
        ["Recorrido del rover", "Si Curiosity u Opportunity pasó a menos de 150 m: el sol y la distancia"],
    ], [2.1 * inch, 4.9 * inch]))
    A(Spacer(1, 6))
    A(P("Dos botones al pie de la tarjeta:"))
    E(bullets([
        "<b>Medir desde aquí</b> fija ese punto como origen (un punto ámbar). Toca otro punto: la tarjeta añade «Desde el punto de medida» con la distancia en línea recta y la diferencia de elevación, y el mapa dibuja la línea entre los dos. «Quitar medida» la borra.",
        "<b>Crear objetivo aquí</b> coloca un objetivo nuevo en ese punto y abre su diálogo de edición.",
    ]))
    A(P("Fuera del recuadro de rutas la tarjeta solo da coordenadas y avisa que ahí no hay datos de terreno. Se cierra con la X o al tocar un objetivo."))

    A(P("4.4 Objetivos científicos", H2))
    A(fig("03_objetivo.png", 5.6 * inch, "Diálogo «Editar objetivo»: nombre, tipo, prioridad, transporte y tiempo de trabajo."))
    A(P("Un objetivo es un lugar al que se quiere ir a trabajar. Cada cambio recalcula las rutas y se guarda solo en la misión abierta."))
    E(pasos([
        "<b>Crear:</b> en el panel derecho pulsa <b>AÑADIR OBJETIVO</b> (el mapa muestra «TOCA EL MAPA PARA COLOCARLO») y toca el mapa; o usa «Crear objetivo aquí» en la tarjeta de punto. Se abre el diálogo «Añadir objetivo»: el objetivo solo existe al pulsar <b>Guardar</b>; <b>Cancelar</b> no deja nada y no recalcula las rutas.",
        "<b>Editar:</b> toca el rombo del objetivo. Cambia nombre, tipo (Muestra, Imagen, Medición, Equipo), prioridad de 1 a 5, transporte y tiempo de trabajo en minutos. <b>Guardar</b> aplica; <b>Borrar</b> lo elimina.",
        "<b>Mover:</b> mantén el dedo sobre el rombo y arrástralo. Al soltar se recalculan las rutas.",
        "<b>Seleccionar:</b> al tocar un objetivo se resalta; también se selecciona desde la lista del panel derecho o desde la pestaña Ciencia.",
    ]))
    A(P("El nombre no puede quedar vacío y el tiempo de trabajo acepta solo dígitos, de 0 a 600 minutos; si algo no vale, el error sale en el campo y el diálogo no se cierra. Un objetivo en terreno prohibido se marca «En terreno prohibido» y ninguna ruta lo visita. El <b>transporte</b> (A pie, Vehículo, Híbrido) solo cuenta en el modo de salida «Por objetivo»."))

    A(P("4.5 Modos de salida y comparación de rutas (panel derecho)", H2))
    A(P("Arriba se elige el <b>modo de salida</b>; debajo aparecen las tres tarjetas de rutas (en pareja, dos). Cambiar de modo recalcula todo."))
    A(tabla([
        ["Modo", "Qué supone"],
        ["A pie", "El astronauta camina todo el recorrido. Es el modo base."],
        ["Con rover", "Un rover presurizado lleva a la tripulación por el primer tramo que puede recorrer y la recoge a la vuelta. El resto, a pie. Hay tiempo de subir y bajar."],
        ["Apoyo", "Un rover espera en el hábitat. La caminata es igual que a pie; el rover solo cambia el regreso en una emergencia."],
        ["Pareja", "Dos astronautas salen juntos, se reparten los objetivos y deben mantenerse a menos de 500 m uno del otro."],
        ["Por objetivo", "Cada objetivo trae su transporte (a pie, vehículo o híbrido) y el vehículo es uno solo."],
    ], [1.2 * inch, 5.8 * inch]))
    A(Spacer(1, 6))
    A(P("Las tres rutas, siempre del hábitat a los objetivos y de vuelta al hábitat:"))
    E(bullets([
        "<b>Más segura</b> (blanca): evita pendientes y terreno rugoso aunque dé un rodeo. Límite de pendiente 22°. Va al objetivo de menor peligro entre los que valen al menos el 60 % de la prioridad máxima.",
        "<b>Más rápida</b> (naranja): prioriza el tiempo. Límite 25°. Va al objetivo que más prioridad da por hora, entre esos mismos. Puede ser otro objetivo que el de la segura.",
        "<b>Más ciencia</b> (cian): añade objetivos por prioridad mientras la salida siga factible y con margen cómodo.",
    ]))
    A(P("Cada tarjeta trae: <b>Distancia</b>, <b>Duración</b>, <b>Pendiente máx.</b>, <b>Ascenso</b>, <b>O₂ al volver</b>, <b>Dosis</b>, la barra de <b>PELIGRO</b> (0 a 100, menos es mejor), la barra de <b>ÉXITO</b> (0 a 100, más es mejor), "
        "los objetivos visitados y el <b>punto de no retorno</b>. <b>DESGLOSE</b> abre las componentes de peligro y de éxito y la lista de objetivos no incluidos con su motivo "
        "(terreno prohibido, inalcanzable, falta tiempo, falta oxígeno, margen muy justo, no va en esta ruta). Tocar una tarjeta la selecciona: el mapa, el perfil y las demás pestañas pasan a esa ruta."))
    A(P("Las tarjetas de la segura y de ciencia traen además el bloque <b>FRENTE A LA RUTA RÁPIDA</b>: cuánto cambian el peligro, la pendiente máxima, el oxígeno al volver (en puntos porcentuales) y los minutos, en verde si mejora y en ámbar si empeora. "
        "Si es el mismo objetivo y casi el mismo camino, la tarjeta lo dice: en terreno plano, como Meridiani, los perfiles pueden dar casi lo mismo."))
    A(P("Etiquetas de estado: <b>FACTIBLE</b> (cabe en el tiempo y el oxígeno), <b>NO FACTIBLE</b> (no cabe), <b>INALCANZABLE</b> (no hay camino) y <b>SIN OBJETIVO</b>. "
        "Al pie del panel, <b>SUPUESTOS</b> lista los valores del equipo que se usaron y una nota recuerda que no son estándares de la NASA."))
    A(P("4.6 Perfil de elevación y pendiente", H2))
    A(P("Bajo el mapa, el perfil muestra la elevación a lo largo de la ruta seleccionada. El trazo cambia de color con la pendiente (verde, amarillo, naranja). "
        "El hábitat aparece al inicio y la línea vertical marca el <b>PNR</b>, el punto de no retorno."))

    # ---------------- 5 ----------------
    A(P("5. Pestaña Seguridad", H1))
    A(fig("06_seguridad.png", 6.9 * inch, "Pestaña Seguridad: estado general GO / NO-GO, radiación, clima, terreno y consumibles."))
    A(P("Responde una pregunta: ¿se puede salir en ese día? Evalúa cinco verificaciones y las junta en un <b>ESTADO GENERAL</b>: GO, PRECAUCIÓN, NO-GO, DATOS INCOMPLETOS o PENDIENTE."))
    A(tabla([
        ["Verificación", "Qué revisa", "Origen del dato"],
        ["RAD", "Dosis de radiación del sol de referencia frente a la línea base de los 60 sols previos", "Medido · RAD de Curiosity (NASA SPDF)"],
        ["CLIMA", "Temperatura mínima del aire dentro de la ventana de la salida", "Medido · REMS de Curiosity (NASA PDS)"],
        ["POLVO", "Opacidad del polvo", "Sin dato: el PDS no publica un producto de REMS. Queda «pendiente»"],
        ["TERRENO", "Peligro de la ruta seleccionada", "Modelado"],
        ["CONSUMIBLES", "Oxígeno y tiempo de la ruta frente a los límites", "Modelado"],
    ], [1.2 * inch, 3.4 * inch, 2.4 * inch]))
    A(Spacer(1, 6))
    E(bullets([
        "<b>Sol de referencia.</b> El deslizador elige el sol marciano que se evalúa. Es un <b>período pasado</b>: REMS llega hasta el sol 4843 (marzo de 2026). No es un pronóstico ni las condiciones de hoy.",
        "<b>Radiación · MSL RAD.</b> Tasa de dosis del detector E (en µGy por día), línea base, cociente entre ambas, dosis de la ruta elegida y un historial de 60 sols. La dosis es absorbida en plástico equivalente a tejido; no es dosis equivalente (mSv).",
        "<b>Clima · MSL REMS.</b> Curvas de temperatura del aire y del suelo por hora local (LMST), presión, pico de UV y humedad máxima. Un sombreado marca la ventana de la salida y se anota la temperatura mínima del aire en ella.",
        "<b>Peligro del terreno.</b> Distancia de la ruta por clase de pendiente y rugosidad media.",
        "<b>Consumibles y regreso a pie.</b> Oxígeno al volver, reserva mínima, tiempo de salida usado, comparación de las tres rutas y una tabla del regreso directo a pie desde cada parada.",
        "<b>Reglas GO / NO-GO.</b> Muestra los umbrales usados. Son supuestos del equipo, no límites de la NASA (ver 10.9).",
    ]))
    A(P("El sol de referencia no solo cambia esta pestaña: la temperatura del aire de Misión y Casco, y la dosis de las rutas en Plan y Misión, salen del mismo sol."))
    A(P("En sitios sin RAD ni REMS (Meridiani), esas dos verificaciones quedan pendientes y la dosis de las rutas usa la línea base de Gale como supuesto; la app lo avisa."))

    # ---------------- 6 ----------------
    A(P("6. Pestaña Ciencia", H1))
    A(fig("07_ciencia.png", 6.9 * inch, "Pestaña Ciencia: lista de objetivos, imagen orbital y foto del rover, datos del punto y operación en el sitio."))
    A(P("Presenta cada objetivo como un expediente. A la izquierda, la lista «OBJETIVOS // SALIDA» (se elige uno) y el botón + para crear otro. En el centro:"))
    E(bullets([
        "<b>Orbital · HiRISE:</b> recorte de la imagen orbital con una mira sobre el objetivo.",
        "<b>Suelo · foto del rover:</b> foto real de Curiosity (Navcam) del sol en que el rover estuvo cerca de esa parada, con su cámara, sol y crédito NASA/JPL-Caltech. Si el objetivo no trae foto (por ejemplo, uno creado por el usuario), lo dice.",
        "<b>Datos en este punto:</b> imagen óptica, topografía y pendiente (elevación, pendiente local, rugosidad, distancia al hábitat y diferencia de elevación), térmica, radiación y unidad geológica.",
    ]))
    A(P("A la derecha, <b>Operación en el sitio</b>: tiempo de trabajo, tipo, en cuáles de las tres rutas está incluido, coordenadas y el botón <b>Editar objetivo</b>. "
        "Los objetivos de demostración son paradas reales de Curiosity; su tipo y prioridad son supuestos."))

    # ---------------- 7 ----------------
    A(P("7. Pestaña Misión (simulación de la caminata)", H1))
    A(fig("08_mision.png", 6.9 * inch, "Pestaña Misión: el astronauta simulado recorre la ruta seleccionada y la telemetría se calcula en cada posición."))
    A(P("El astronauta recorre la ruta seleccionada y el panel derecho muestra la telemetría de la posición. Abajo: <b>reproducir / pausar</b>, <b>volver al inicio</b> y la velocidad de la simulación (1x, 2x, 4x, 8x), con una barra de avance."))
    A(tabla([
        ["Grupo", "Lecturas"],
        ["Estado", "NOMINAL, PRECAUCIÓN o ALERTA, con el motivo: pasado el punto de no retorno, oxígeno por debajo de lo que pide volver a pie, o reserva menor de 10 % al regresar"],
        ["Posición", "Latitud y longitud, elevación, pendiente local, rumbo con punto cardinal y siguiente objetivo con su distancia"],
        ["Traje", "Oxígeno (o «agotado» si no alcanza), oxígeno para volver a pie, reserva al regresar, dosis hasta aquí y temperatura del aire (REMS del sol de referencia)"],
        ["Regreso", "Distancia al hábitat en línea recta, tiempo de regreso a pie, punto de no retorno y si ya se pasó"],
        ["Avance", "Hora local (LMST = hora de inicio + tiempo transcurrido, igual que la hora de fin de Seguridad), tiempo transcurrido y metros recorridos del total"],
    ], [1.0 * inch, 6.0 * inch]))
    A(Spacer(1, 6))
    A(recuadro("Es una simulación", [
        "La posición y la hora avanzan de forma proporcional a la ruta. El tiempo, el oxígeno y la dosis se interpolan de los totales de la ruta; no hay sensores. "
        "Los datos reales que entran son elevación, pendiente y la temperatura de REMS por hora local. Ver 10.10.",
    ], g.AMBER_DK))

    # ---------------- 8 ----------------
    A(P("8. Pestaña Casco (visera)", H1))
    A(fig("09_casco.png", 6.9 * inch, "Pestaña Casco: concepto de pantalla de visera con rumbo, siguiente objetivo y datos de regreso."))
    A(P("Es un <b>concepto visual</b> de la pantalla de visera (HUD). Comparte la simulación de la pestaña Misión: al reproducir, avanzan la brújula, el objetivo siguiente, las lecturas «AQUÍ» "
        "(rumbo, pendiente adelante a 90 m, temperatura, hora local, tiempo y oxígeno estimados) y el cuadro «REGRESO». Aparece un aviso de PRECAUCIÓN cuando hay una pendiente fuerte adelante. "
        "En Gale, el fondo es una foto real de Curiosity (Navcam); no es la vista de esta ruta."))
    A(P("<b>En Meridiani no hay fotos del rover</b>, así que el fondo es una <b>vista en perspectiva del terreno dibujada con el modelo de elevación</b> del sitio, desde la posición y el rumbo simulados, con el brillo de la ortofoto empaquetada como textura. Cambia mientras se reproduce la ruta. No es una foto, y la nota de la esquina lo dice. "
        "Meridiani es casi plano, así que se ve como una llanura con textura y horizonte."))
    A(fig("12_casco_meridiani.png", 6.9 * inch, "Casco en Meridiani · Endeavour: vista del terreno dibujada con el relieve, y la tarjeta con una foto real de Opportunity."))
    A(P("En los dos sitios de Endeavour, una tarjeta abajo a la derecha muestra <b>fotos reales de Opportunity</b> en Perseverance Valley (cuatro imágenes de prensa del JPL, Navcam y Pancam, con su título, cámara, sol y crédito NASA/JPL-Caltech). "
        "Toca la tarjeta para pasar a la siguiente. Son fotos de la zona, no del punto exacto, y por eso la tarjeta lo advierte."))

    # ---------------- 9 ----------------
    A(PageBreak())
    A(P("9. Sitios y misiones guardadas", H1))
    A(P("9.1 Sitios", H2))
    A(fig("04_sitios.png", 6.4 * inch, "Selector de sitios. «Largo alcance» e «Indicativo» marcan sitios con menos detalle."))
    A(tabla([
        ["Sitio", "Rejilla y calidad", "Para qué sirve"],
        ["Gale · Crestas boxwork (4 km)", "Rejilla de 4 m para las rutas, relieve de 1 m, imagen de 0.25 m. Alta calidad", "Sitio principal: crestas boxwork del Monte Sharp. Con RAD y REMS reales"],
        ["Gale · Alcance de la EVA (24 km)", "Rejilla de 16 m. «Largo alcance»", "Rutas hasta unos 12 km del hábitat; no ve obstáculos pequeños y no conoce la rugosidad"],
        ["Meridiani · Borde de Endeavour (4 km)", "Relieve de 1 m. Alta calidad", "Borde del cráter Endeavour, donde estuvo Opportunity. Con su recorrido"],
        ["Meridiani · Endeavour, alcance de la EVA (22 km)", "Rejilla de 16 m. «Largo alcance»", "Alcance de la EVA alrededor de Endeavour"],
        ["Meridiani · Zona habitable (20 km)", "Rejilla de 100 m sobre un relieve de 200 m. «Indicativo»", "Zona habitable propuesta por la NASA. Pendientes alisadas"],
        ["Meridiani · Contexto regional (100 km)", "Rejilla de 400 m. «Indicativo»", "Panorama regional; las rutas son una aproximación"],
    ], [2.2 * inch, 2.2 * inch, 2.6 * inch]))
    A(Spacer(1, 6))
    A(P("Al cambiar de sitio se abre la última misión de ese sitio, o una nueva con objetivos de demostración. Los sitios «Largo alcance» e «Indicativo» muestran un aviso ámbar en el panel de rutas: "
        "sirven como aproximación, no para evitar rocas ni pendientes pequeñas."))
    A(P("9.2 Misiones", H2))
    A(fig("05_misiones.png", 6.9 * inch, "Administrador de misiones: lista a la izquierda y detalle a la derecha."))
    A(P("Una <b>misión</b> guarda un sitio, sus objetivos, el modo de salida, notas, consumibles y equipo. Todo se guarda en la tablet (almacenamiento privado de la app), sin servidor. "
        "Se guarda solo al cambiar algo y al pasar la app a segundo plano."))
    E(bullets([
        "<b>Nueva misión</b> crea una en el sitio abierto. El icono de duplicar copia la actual; el de papelera la borra (pide confirmación y no se puede borrar la última).",
        "Tocar una misión de la lista la abre; si es de otro sitio, cambia de sitio.",
        "Campos: nombre, notas, consumibles y equipo con herramientas (nombre, cantidad, unidad y masa por unidad). La masa declarada se suma sola.",
        "<b>Copiar JSON</b> copia la misión completa al portapapeles, para guardarla o compartirla.",
    ]))
    A(P("Los consumibles y el equipo los escribe el usuario: no son datos de la NASA y <b>todavía no cambian</b> el cálculo de rutas."))

    # ---------------- 10 ----------------
    A(PageBreak())
    A(P("10. Cómo se calcula cada cosa", H1))
    A(P("Esta sección explica el método completo. Todos los valores numéricos están en la tabla del anexo; los que son supuestos se marcan así. "
        "El cálculo vive en Dart (<font name='Mono'>app/lib/routing/</font>) y tiene una versión de referencia en Python (<font name='Mono'>tools/routing.py</font>); "
        "las pruebas comprueban que dan el mismo resultado."))
    A(P("10.1 De la imagen al terreno: la rejilla de costos", H2))
    E(pasos([
        "<b>Relieve.</b> Se parte del modelo digital de elevación (DEM) de 1 m por píxel del USGS. Se remuestrea a una cuadrícula alineada con el recuadro y se promedia en bloques de 2 × 2, lo que da 2 m por celda. A 1 m domina el ruido del modelo estéreo.",
        "<b>Pendiente.</b> Diferencias centrales sobre la cuadrícula de 2 m (línea base de 4 m), en grados.",
        "<b>Rugosidad.</b> Raíz del cuadrado medio del relieve local a 1 m menos su media móvil de 7 × 7 m, en centímetros. No ve rocas sueltas menores de 1 m.",
        "<b>Zonas prohibidas.</b> Celda prohibida si la pendiente supera 25° o no hay dato.",
        "<b>Rejilla de rutas.</b> Para calcular rutas, la app promedia la rejilla en bloques hasta 4 m por celda (16 m en los sitios de largo alcance, 100 m en la zona habitable y 400 m en el contexto regional). Cada celda guarda pendiente, pendiente real, rugosidad, elevación y bandera de prohibida.",
        "<b>Coordenadas.</b> Plano local en metros: x al este, y al sur, desde la esquina noroeste del recuadro. No hay proyecciones dentro de la app; la latitud y la longitud salen con una esfera de 3 396 190 m.",
    ]))
    A(P("10.2 Búsqueda de la ruta: A*", H2))
    A(P("Cada tramo entre dos puntos (hábitat, objetivo, hábitat) se busca con el algoritmo A* sobre las 8 celdas vecinas. El costo de pasar de una celda u a la v, a distancia d, es:"))
    A(formula("costo = d × (1 + w_pend × (pendiente_v / 25°)² + w_rug × min(rugosidad_v / 40 cm, 1) + w_tiempo × (t − 1))"))
    A(P("donde <b>t = v_máx / v(θ) ≥ 1</b> es el cociente entre la velocidad máxima y la velocidad en la pendiente θ del paso. Como el multiplicador es siempre ≥ 1, la distancia octil es una heurística admisible y A* da el camino de menor costo. "
        "No se cortan esquinas junto a celdas prohibidas, y se rechazan las celdas con pendiente o rugosidad sobre el límite del perfil."))
    A(tabla([
        ["Perfil", "w_pend", "w_rug", "w_tiempo", "Límite de pendiente", "Idea"],
        ["Más segura", "12", "4", "0.5", "22°", "Evita lo empinado y lo rugoso aunque rodee"],
        ["Más rápida", "0.5", "0.2", "1.0", "25°", "Minimiza el tiempo"],
        ["Más ciencia", "4", "1.5", "0.5", "25°", "Equilibrio; visita más objetivos"],
    ], [1.1 * inch, 0.7 * inch, 0.7 * inch, 0.8 * inch, 1.4 * inch, 2.3 * inch]))
    A(Spacer(1, 6))
    A(P("10.3 Qué objetivos visita cada ruta", H2))
    E(bullets([
        "<b>Segura y rápida:</b> consideran los objetivos libres con al menos el 60 % de la prioridad máxima y regresan. La segura toma el de menor puntaje de peligro y la rápida el que más prioridad da por hora (prioridad / horas). A igualdad, gana el de mayor prioridad y luego el de menor identificador. Es un supuesto del equipo (<font name='Mono'>safe_fast_targets: by_profile</font>); con <font name='Mono'>primary</font> las dos van al de mayor prioridad.",
        "<b>Ciencia:</b> recorre los objetivos por prioridad descendente y añade cada uno si la salida sigue siendo factible. Desde el segundo objetivo exige además <b>margen cómodo</b> (ver 10.6), para no agotar tiempo y oxígeno. Un objetivo que no entra queda en «No incluidos» con su motivo.",
        "<b>Orden de visita:</b> con hasta 6 objetivos se prueban todas las permutaciones y se elige el orden de menor costo; con más, se toma siempre el más barato desde donde se está (heurística del vecino más cercano).",
    ]))
    A(P("10.4 Tiempo de marcha", H2))
    A(P("La velocidad depende de la pendiente del paso con la función de Tobler, escalada: "))
    A(formula("factor(tan θ) = exp(−3.5 × (|tan θ + 0.05| − 0.05)),   mínimo 0.1;   velocidad = 2 km/h × factor"))
    A(P("Es máxima en una bajada leve (tan θ = −0.05) y cae al subir o al bajar fuerte. El tiempo de cada paso es distancia / velocidad; las paradas de trabajo se suman (tiempo de trabajo del objetivo). "
        "La duración de la ruta es la marcha más las paradas; debe ser ≤ 6 h."))
    A(P("10.5 Oxígeno y dosis", H2))
    A(formula("O₂ del paso = tiempo × (1 + 3 × máx(0, tan θ)) / 8 h        (marcha: más consumo al subir)\nO₂ de una parada = horas × 0.8 / 8 h"))
    A(P("El oxígeno usado es la suma de ambos, como fracción de una capacidad de 8 h. <b>O₂ al volver</b> = 1 − usado; debe ser ≥ la reserva de 20 %. "
        "La <b>dosis</b> de la ruta es una sola cifra en Plan, Seguridad y Misión: la tasa de radiación del sol de referencia elegido en Seguridad (µGy por día, medida por RAD) × duración / 24 h. Sin dato de RAD (Meridiani), se usa la línea base de Gale (151 µGy por día) como supuesto. Si el oxígeno no alcanza, la app escribe «agotado» en vez de un porcentaje negativo."))
    A(P("10.6 Factible, margen cómodo y punto de no retorno", H2))
    E(bullets([
        "<b>Factible:</b> duración ≤ 6 h <b>y</b> oxígeno restante ≥ 20 % (y, en modo por objetivo, el vehículo no queda sin recoger).",
        "<b>Margen cómodo:</b> factible, con margen de tiempo ≥ 25 % y margen de oxígeno ≥ 30 % (sobre la reserva).",
        "<b>Punto de no retorno (PNR):</b> el primer punto de la ruta desde el que lo que falta por hacer cuesta menos tiempo que deshacer lo andado. Para el regreso se usa la velocidad en sentido contrario (subir y bajar cambian).",
    ]))
    A(P("10.7 Puntaje de peligro (0 a 100, menos es mejor)", H2))
    A(P("Suma ponderada de seis componentes, cada una entre 0 y 1:"))
    A(tabla([
        ["Componente", "Peso", "Cómo se calcula"],
        ["Exposición a pendiente", "30", "(0.25 × metros en 10–20° + 1.0 × metros en 20–25°) / 1000 m"],
        ["Terreno rugoso", "15", "Rugosidad media de la ruta / 40 cm"],
        ["Más allá del regreso a pie", "20", "(radio máximo desde el hábitat − 1.5 km) / 1.5 km; 1.5 km es lo que se camina en 45 min"],
        ["Margen de consumibles", "20", "El peor de: 1 − margen de oxígeno / 0.5, y 1 − margen de tiempo / 0.25"],
        ["Dosis de radiación", "5", "Dosis de la ruta / dosis de una salida de 6 h"],
        ["Condiciones del día", "10", "Vale 0 por ahora: no entra al cálculo hasta que haya un dato de polvo"],
    ], [1.9 * inch, 0.6 * inch, 4.5 * inch]))
    A(Spacer(1, 6))
    A(P("10.8 Puntaje de éxito (0 a 100, más es mejor)", H2))
    A(formula("éxito = 100 × valor científico × factor de tiempo × factor de consumibles × (1 − peligro / 200)"))
    E(bullets([
        "<b>Valor científico</b> = prioridad de los objetivos visitados / prioridad total de todos los objetivos.",
        "<b>Factor de tiempo</b> = margen de tiempo / 0.25, entre 0 y 1. <b>Factor de consumibles</b> = margen de oxígeno / 0.3, entre 0 y 1.",
        "<b>Penalización por peligro</b> = 1 − peligro / 200: un peligro de 100 resta la mitad.",
    ]))
    A(P("10.9 Verificaciones GO / NO-GO", H2))
    A(tabla([
        ["Verificación", "PRECAUCIÓN", "NO-GO"],
        ["Radiación (tasa del sol / línea base de 60 sols)", "≥ 1.5 veces", "≥ 3 veces"],
        ["Temperatura mínima del aire en la ventana de la salida", "≤ −60 °C", "≤ −80 °C"],
    ], [3.8 * inch, 1.6 * inch, 1.6 * inch]))
    A(Spacer(1, 6))
    A(P("La <b>línea base</b> es la mediana de las dosis diarias del detector E en los 60 sols previos. La <b>ventana de la salida</b> empieza a las 09:00 de hora solar media local (LMST) y dura lo que la ruta. "
        "La ventana equivale a la duración de la ruta convertida a horas solares marcianas. <b>Terreno</b> da PRECAUCIÓN si la pendiente máxima de la ruta llega a 20° (NO-GO si no hay ruta); <b>Consumibles</b> da GO con margen cómodo, PRECAUCIÓN si la ruta es factible pero justa y NO-GO si no es factible. "
        "El estado general es el peor de las verificaciones con datos; mientras el polvo no tenga dato, nunca llega a GO completo y se marca «datos incompletos». "
        "Los umbrales son supuestos del equipo."))
    A(P("10.10 Simulación de la caminata", H2))
    E(bullets([
        "La posición es un avance <b>t</b> de 0 a 1 sobre la ruta seleccionada. El tiempo transcurrido, el oxígeno gastado y la dosis son los acumulados de las métricas de la ruta en esa celda (con interpolación entre celdas).",
        "<b>Oxígeno para volver</b>: fracción que haría falta para ir en línea recta al hábitat a pie, con el ritmo medio de la ruta. Si supera el oxígeno que queda, hay alerta.",
        "<b>Rumbo y pendiente adelante</b> salen de las celdas siguientes del camino (a 90 m); la <b>temperatura</b> es la de REMS del sol de referencia a la hora local de la posición simulada.",
        "<b>Estado:</b> ALERTA si ya se pasó el punto de no retorno o falta oxígeno para volver; PRECAUCIÓN si la reserva al regresar es menor de 10 %; NOMINAL en otro caso.",
    ]))
    A(P("10.11 Modos con vehículo y en pareja", H2))
    E(bullets([
        "<b>Con rover:</b> el rover (6 km/h, pendiente máxima 20°, rugosidad máxima 30 cm) se deja en un punto de la ruta, el más lejano del primer tramo que puede recorrer. La ida usa el rover hasta ahí; el resto y las paradas son a pie. A la vuelta se recoge en ese punto y se llega al hábitat por el último tramo transitable. En el rover el oxígeno se gasta al 50 % de lo normal y no hay recargo por subida. Subir o bajar cuesta 5 min.",
        "<b>Apoyo:</b> el rover espera en el hábitat y sale 10 min después de un aviso; en una emergencia se encuentra con el astronauta en el camino. No cambia el tiempo ni el oxígeno de la salida: cambia el tiempo de regreso en emergencia, el punto de no retorno y el radio que cuenta en el peligro.",
        "<b>Pareja:</b> dos astronautas salen juntos y se reparten los objetivos. Cada minuto se comprueba que estén a menos de 500 m. La duración es la del que más tarda, el peligro es el mayor de los dos, el éxito cuenta los objetivos que visite cualquiera y cada uno tiene su oxígeno.",
        "<b>Por objetivo:</b> cada objetivo trae su transporte. «Vehículo» busca el camino solo por celdas que el rover puede recorrer; «Híbrido» usa el vehículo hasta donde el terreno lo permita y sigue a pie. Hay un solo vehículo: se queda donde se aparca y solo se vuelve a usar si la ruta pasa por ese punto; si queda sin recoger, la ruta no es factible. La app explica cada decisión con una nota.",
    ]))
    A(P("10.12 Rendimiento", H2))
    A(P("El cálculo corre en un hilo de fondo (un «isolate»): la pantalla no se congela. Si cambias algo mientras se calcula, solo cuenta el pedido más nuevo. "
        "En la tablet, las tres rutas de Gale tardan alrededor de 1 s; en la versión web el cálculo corre en el hilo principal y puede notarse. "
        "El tiempo de cálculo se muestra arriba del panel de rutas."))

    # ---------------- 11 ----------------
    A(PageBreak())
    A(P("11. De dónde salen los datos", H1))
    A(P("Todo dato científico de la app viene de una fuente de la NASA, el USGS o ASU (datos de la NASA) citada en <font name='Mono'>RECURSOS.md</font> con su dirección y la fecha en que se descargó. "
        "Los datos se bajaron una vez, el 14 de noviembre de 2026, y se empaquetaron dentro de la app con los scripts de <font name='Mono'>tools/</font>: la app nunca consulta un servidor."))
    A(tabla([
        ["Qué", "Fuente", "Cómo se usa"],
        ["Relieve de Gale, 1 m", "USGS Astrogeology: <font name='Mono'>MSL_Gale_DEM_Mosaic_1m_v3.tif</font>", "Elevación, pendiente, rugosidad, zonas prohibidas y relieve sombreado (ventana de 4 × 4 km)"],
        ["Imagen de Gale, 0.25 m", "USGS / HiRISE (MRO): mosaico LRGB de 78 cuadrantes", "Capa óptica (pirámide de teselas)"],
        ["Gale de largo alcance", "DEM de 1 m leído a 16 m por su pirámide; teselas HiRISE de Mars Trek (nivel 14)", "Rejilla de 16 m para rutas de unos 12 km"],
        ["Meridiani: Endeavour", "Mars Trek: DEM de 1 m del cráter Endeavour y mosaico HiRISE de Opportunity (hasta 0.32 m)", "Sitio de 4 km y de alcance"],
        ["Meridiani: zona habitable y regional", "USGS: DEM de 200 m (mezcla MOLA y HRSC); CTX de Mars Trek (10 a 20 m)", "Sitios indicativos de 20 km y de 100 km"],
        ["Mapa base de la región", "Mars Trek: mosaicos CTX a nivel 10 (40 m por píxel)", "Imagen al alejar el mapa"],
        ["Recorrido de Curiosity", "NASA/JPL, MMGIS: <font name='Mono'>MSL_waypoints.json</font> (1389 puntos, sol 3 a 5073)", "Capa de recorrido y objetivos de demostración"],
        ["Recorrido de Opportunity", "PDS Geosciences Node: <font name='Mono'>MERB_traverse_5130.csv</font> (sol 1 a 5081)", "Capa de recorrido. Posición aproximada (origen supuesto en Eagle Crater)"],
        ["Fotos del rover", "NASA/JPL-Caltech: imágenes crudas de Navcam de Curiosity", "Una foto por objetivo de demostración"],
        ["Radiación", "NASA SPDF CDAWeb: MSL_RAD_OBS-L2 (RAD, DOI 10.48322/20qb-4e17)", "Tasa de dosis, línea base y verificación RAD"],
        ["Clima", "PDS Atmósferas: MSL-M-REMS-5-MODRDR-V1.0 (REMS)", "Temperatura, presión, UV y humedad; verificación de clima"],
        ["Térmica de día / noche", "Mars Trek: THEMIS-IR de Mars Odyssey (100 m)", "Brillo relativo (no calibrado)"],
        ["Zonas de tránsito", "ASU: índice de cobertura de polvo (DCI) y inercia térmica de TES (Mars Global Surveyor)", "Clases por los umbrales del equipo"],
        ["Minerales, zonas de exploración, nombres, cráteres", "Mars Trek (CRISM, OMEGA, NASA EMC 2015, UAI) y base de Robbins", "Capas de rasgos"],
        ["Biofirmas en Meridiani: minerales acuosos e hidratados y redes de valles", "Mars Trek (servicios ArcGIS; Hynek, Hoke y Hutchison 2010), recuadro del mosaico CTX de Meridiani", "Detecciones desde órbita, no muestras"],
        ["Fotos de Opportunity (Casco en Endeavour)", "NASA Image and Video Library (JPL): PIA21724, PIA21725, PIA22074 y PIA22071, crédito NASA/JPL-Caltech", "Imágenes de prensa; muestran la zona, no el punto"],
        ["Geología", "USGS SIM 3292 (mapa global, 1:20 000 000) vía Mars Trek", "Unidad geológica; solo contexto"],
        ["Rover de referencia", "NASA NTRS 20250011301 (vehículo lunar de Apolo)", "Redondeo de los límites del rover (pendiente, velocidad)"],
    ], [1.6 * inch, 3.0 * inch, 2.4 * inch]))
    A(Spacer(1, 8))
    A(P("Los tres tipos de dato", H2))
    E(bullets([
        "<b>Medido (real):</b> viene de una misión o producto de la NASA, el USGS o ASU. Ejemplos: imágenes, elevación, posiciones de los rovers, RAD y REMS.",
        "<b>Modelado:</b> lo calcula el equipo a partir de datos medidos. Ejemplos: pendiente, rugosidad, zonas prohibidas, rutas, puntajes y clases de tránsito.",
        "<b>Supuesto del equipo:</b> un valor sin referencia oficial. Ejemplos: velocidad del traje, duración de la salida, capacidad de oxígeno, límites GO / NO-GO, umbrales de tránsito, prioridades y tiempos de los objetivos de demostración, posiciones del hábitat. "
        "Los límites del rover se redondean del vehículo lunar de Apolo.",
    ]))
    A(P("Cómo se prepararon los datos", H2))
    A(P("Los scripts de Python de <font name='Mono'>tools/</font> descargan, recortan y convierten los datos en archivos binarios y de imagen que la app carga al arrancar. "
        "Los principales: <font name='Mono'>00</font> a <font name='Mono'>04</font> (ventana de Gale, pendiente, costos y exportación), <font name='Mono'>06</font> (RAD y REMS), "
        "<font name='Mono'>07</font> y <font name='Mono'>08</font> (térmica y geología), <font name='Mono'>09</font> (fotos), <font name='Mono'>10</font> a <font name='Mono'>17</font> (Meridiani, contexto, rasgos y largo alcance), "
        "<font name='Mono'>21</font> y <font name='Mono'>22</font> (tránsito de Gale y recorrido de Opportunity). El orden y los comandos están en <font name='Mono'>RETOMAR.md</font>, sección 6."))
    A(fig("10_endeavour.png", 6.4 * inch, "Meridiani · Borde de Endeavour: otro sitio, con el recorrido de Opportunity, la leyenda «Búsqueda de biofirmas» y el aviso de que la segura y la rápida dan casi lo mismo en terreno plano."))

    # ---------------- 12 ----------------
    A(P("12. Límites, supuestos y advertencias", H1))
    E(bullets([
        "<b>Los supuestos del traje no son de la NASA.</b> Velocidad, duración de la salida, oxígeno y umbrales de GO / NO-GO son del equipo. Si tienes valores citables, se cambian en <font name='Mono'>config/params.json</font> y se regenera.",
        "<b>La resolución limita las rutas.</b> A 4 m no se ven rocas ni pendientes pequeñas; a 16 m, menos; a 100–400 m las rutas solo son indicativas.",
        "<b>Sin rocas sueltas ni arena.</b> La rugosidad no ve rocas menores de 1 m y no hay un dato de arena suelta.",
        "<b>El clima y la radiación son pasados.</b> Se evalúa un sol de referencia, no un pronóstico.",
        "<b>Sin dato de polvo.</b> El PDS no tiene un producto de opacidad de REMS; esa verificación queda pendiente.",
        "<b>Tránsito en ventanas chicas.</b> TES tiene 3.5 a 7.5 km por píxel: en 4 km la capa es de un solo color.",
        "<b>Recorrido de Opportunity aproximado.</b> La tabla del PDS no declara su datum; se usó Eagle Crater como origen. El final del recorrido cae donde debe, en Perseverance Valley.",
        "<b>Dosis sin referencia fuera de Gale.</b> En Meridiani no hay RAD; se usa la línea base de Gale como supuesto.",
        "<b>La simulación y la visera son conceptos.</b> No hay signos vitales ni sensores.",
        "<b>Los consumibles y el equipo de las misiones</b> son notas del usuario; todavía no entran al cálculo de rutas.",
    ]))

    # ---------------- 13 ----------------
    A(P("13. Problemas frecuentes", H1))
    A(tabla([
        ["Qué pasa", "Qué hacer"],
        ["La barra dice CALCULANDO RUTAS… mucho tiempo", "En la web puede tardar unos segundos. En la tablet no debería pasar de 2 s; si pasa, toca otra ruta o cambia de modo y avisa"],
        ["Un objetivo no aparece en ninguna ruta", "Abre el desglose de la ruta: «No incluidos» da el motivo (terreno prohibido, inalcanzable, falta tiempo u oxígeno, margen justo). Mueve el objetivo fuera de la zona roja o baja su tiempo de trabajo"],
        ["Todas las rutas dicen NO FACTIBLE", "El objetivo está muy lejos para 6 h o 8 h de oxígeno con reserva de 20 %. Acércalo o prueba el modo con rover"],
        ["El Casco no muestra foto en Meridiani", "Es esperado: ahí no hay fotos del rover. El fondo es el relieve dibujado; en Endeavour, la tarjeta de abajo a la derecha trae fotos de Opportunity"],
        ["La segura y la rápida son casi iguales", "En terreno plano, o con un solo objetivo alcanzable, los dos perfiles dan casi lo mismo; la tarjeta lo dice. Con más objetivos y relieve se separan"],
        ["No hay radiación ni clima", "Estás en un sitio de Meridiani: RAD y REMS son de Curiosity, en Gale. Es esperado"],
        ["El mapa se ve gris fuera del recuadro", "Es la imagen de contexto (CTX). Las rutas solo se calculan dentro del recuadro punteado"],
        ["Cambié de sitio y perdí mis objetivos", "No se pierden: cada sitio abre su última misión. Ábrela desde el botón de misiones"],
        ["La app no abre una misión de otro sitio", "Ese sitio no se pudo cargar; la app se queda en el actual y lo avisa"],
        ["La tableta se ve en vertical", "La app se bloquea en horizontal; gira la tablet"],
    ], [2.6 * inch, 4.4 * inch]))

    # ---------------- 14 ----------------
    A(P("14. Glosario", H1))
    A(tabla([
        ["Término", "Significado"],
        ["EVA", "Actividad extravehicular: caminata del astronauta fuera del hábitat"],
        ["Hábitat", "Punto de salida y de regreso de todas las rutas"],
        ["DEM", "Modelo digital de elevación: la altura de cada punto del terreno"],
        ["HiRISE / CTX", "Cámaras del Mars Reconnaissance Orbiter: 0.25 m y 6 m por píxel"],
        ["THEMIS-IR", "Cámara infrarroja de Mars Odyssey; da brillo relativo, no temperatura calibrada"],
        ["TES, DCI", "Espectrómetro de Mars Global Surveyor; el DCI es el índice de cobertura de polvo"],
        ["Inercia térmica", "Qué tan rápido se calienta o enfría el suelo; sirve para distinguir arena suelta de roca"],
        ["RAD, REMS", "Detector de radiación y estación meteorológica de Curiosity"],
        ["Sol", "Un día marciano (24 h 39 min). El sol de referencia es el que se evalúa"],
        ["LMST", "Hora solar media local en Marte"],
        ["GO / NO-GO", "Decisión de salir o no salir según las verificaciones"],
        ["PNR", "Punto de no retorno: desde ahí terminar la ruta cuesta menos que deshacerla"],
        ["µGy", "Microgray: unidad de dosis absorbida (no es dosis equivalente)"],
        ["Boxwork", "Crestas minerales entrecruzadas del Monte Sharp, el sitio de la caminata en Gale"],
        ["MMGIS, PDS, SPDF", "Servicios de la NASA: mapas web, archivo de datos planetarios y datos de heliofísica"],
    ], [1.6 * inch, 5.4 * inch]))

    # ---------------- Anexo ----------------
    A(P("Anexo: valores de los supuestos", H1))
    A(P("Se guardan en <font name='Mono'>config/params.json</font> y se empaquetan con cada sitio. Son supuestos del equipo salvo que se indique otra cosa."))
    A(tabla([
        ["Grupo", "Valor"],
        ["Movilidad", "Velocidad en llano 2 km/h; Tobler k = 3.5; factor mínimo 0.1; salida máxima 6 h"],
        ["Consumibles", "Oxígeno 8 h; reserva mínima 20 %; consumo al subir × (1 + 3 tan θ); consumo en parada 0.8"],
        ["Pendiente", "Nominal &lt; 10°; precaución 10–20°; precaución alta 20–25°; prohibida &gt; 25°; máx. del hábitat 5°"],
        ["Rejilla de rutas", "4 m en los sitios de 4 km; 16 m en largo alcance; referencia de pendiente 25°, de rugosidad 40 cm"],
        ["Rover", "6 km/h; pendiente máx. 20°; rugosidad máx. 30 cm; oxígeno al 50 %; subir o bajar 5 min; salida de apoyo 10 min"],
        ["Pareja", "Separación máxima 500 m; comprobada cada 1 min"],
        ["Radiación", "151 µGy por día (medida, RAD, referencia de Gale); precaución 1.5 × la línea base, NO-GO 3 ×"],
        ["Clima", "Precaución ≤ −60 °C; NO-GO ≤ −80 °C; inicio de la salida 09:00 LMST"],
        ["Peligro (pesos)", "Pendiente 30; terreno 15; regreso a pie 20; consumibles 20; radiación 5; día 10 (vale 0)"],
        ["Éxito", "Margen de tiempo bueno 25 %; margen de oxígeno bueno 30 %"],
    ], [1.6 * inch, 5.4 * inch]))
    return agrupar(s)


def agrupar(items):
    """Un título seguido de una figura va junto: evita títulos huérfanos al pie de una página."""
    out, i = [], 0
    while i < len(items):
        it = items[i]
        nxt = items[i + 1] if i + 1 < len(items) else None
        if isinstance(it, Paragraph) and it.style.name in ("h1", "h2") and isinstance(nxt, KeepTogether):
            out.append(KeepTogether([it, nxt]))
            i += 2
        else:
            out.append(it)
            i += 1
    return out


def main():
    doc = BaseDocTemplate(SALIDA, pagesize=letter, leftMargin=0.75 * inch, rightMargin=0.75 * inch, topMargin=0.7 * inch, bottomMargin=0.85 * inch,
                          title="ARES PATH — Manual de uso", author="Equipo ARES PATH", subject="NASA Space Apps Challenge 2026 · Martian Map")
    doc.addPageTemplates([PageTemplate(id="p", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="f")], onPage=pie)])
    doc.build(contenido())
    print("escrito", SALIDA, f"{os.path.getsize(SALIDA) / 1e6:.2f} MB")


if __name__ == "__main__":
    main()

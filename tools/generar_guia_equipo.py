"""Genera docs/ARES_PATH_guia_equipo.pdf: explicación de la app, instalación, guía de pruebas y siguientes pasos.

Uso (desde la raíz del proyecto):
    python3 tools/generar_guia_equipo.py

Lee las capturas de docs/ y la huella del APK en dist/. Si cambia el APK o los resultados, actualizar los textos y volver a correrlo.
"""
import hashlib
import os
import tempfile

from PIL import Image as PILImage
from reportlab.graphics.shapes import Drawing, Line, Polygon, Rect, String
from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, Flowable, Frame, HRFlowable, Image, KeepTogether, PageBreak,
                                PageTemplate, Paragraph, Spacer, Table, TableStyle, XPreformatted)

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(RAIZ, "docs")
APK = os.path.join(RAIZ, "dist", "ARES_PATH_v0.7.apk")
SALIDA = os.path.join(DOCS, "ARES_PATH_guia_equipo.pdf")

# ---- Fuentes (instaladas en el sistema; ReportLab las incrusta en el PDF) ----
FT = "/usr/share/fonts/truetype"
pdfmetrics.registerFont(TTFont("Inter", f"{FT}/inter-zorin-os/Inter-Regular.ttf"))
pdfmetrics.registerFont(TTFont("Inter-Bold", f"{FT}/inter-zorin-os/Inter-SemiBold.ttf"))
pdfmetrics.registerFont(TTFont("Inter-Italic", f"{FT}/inter-zorin-os/Inter-Italic.ttf"))
pdfmetrics.registerFont(TTFont("Inter-BoldItalic", f"{FT}/inter-zorin-os/Inter-SemiBoldItalic.ttf"))
pdfmetrics.registerFontFamily("Inter", normal="Inter", bold="Inter-Bold", italic="Inter-Italic", boldItalic="Inter-BoldItalic")
pdfmetrics.registerFont(TTFont("Grotesk", f"{FT}/space-grotesk-zorin-os/SpaceGrotesk-Bold.ttf"))
pdfmetrics.registerFont(TTFont("Mono", f"{FT}/jetbrains-mono-zorin-os/JetBrainsMono-Regular.ttf"))
pdfmetrics.registerFont(TTFont("Mono-Bold", f"{FT}/jetbrains-mono-zorin-os/JetBrainsMono-Bold.ttf"))
pdfmetrics.registerFontFamily("Mono", normal="Mono", bold="Mono-Bold", italic="Mono", boldItalic="Mono-Bold")

ORANGE = colors.HexColor("#E2622B")
ORANGE_DK = colors.HexColor("#B8470F")
DARK = colors.HexColor("#0E0C0B")
INK = colors.HexColor("#26211E")
MUTE = colors.HexColor("#6F625B")
LINE = colors.HexColor("#D9D2CC")
SOFT = colors.HexColor("#F6F2EF")
CYAN_DK = colors.HexColor("#007C8C")
GREEN_DK = colors.HexColor("#1B7F46")
AMBER_DK = colors.HexColor("#9A5F00")

BODY = ParagraphStyle("body", fontName="Inter", fontSize=9.4, leading=13.6, textColor=INK, spaceAfter=5)
SMALL = ParagraphStyle("small", parent=BODY, fontSize=8, leading=11, textColor=MUTE, spaceAfter=3)
CELL = ParagraphStyle("cell", parent=BODY, fontSize=8.3, leading=11, spaceAfter=0)
CELLB = ParagraphStyle("cellb", parent=CELL, fontName="Inter-Bold")
CELLH = ParagraphStyle("cellh", parent=CELL, fontName="Inter-Bold", textColor=colors.white)
H1 = ParagraphStyle("h1", fontName="Grotesk", fontSize=17, leading=21, textColor=INK, spaceBefore=10, spaceAfter=6, keepWithNext=1)
H2 = ParagraphStyle("h2", fontName="Grotesk", fontSize=11.5, leading=15, textColor=ORANGE_DK, spaceBefore=10, spaceAfter=4, keepWithNext=1)
BUL = ParagraphStyle("bul", parent=BODY, leftIndent=12, bulletIndent=2, spaceAfter=2.5)
MONO = ParagraphStyle("mono", fontName="Mono", fontSize=7.8, leading=10.6, textColor=INK)
W = letter[0] - 1.5 * inch  # ancho útil


def P(t, s=BODY):
    return Paragraph(t, s)


def bullets(items, style=BUL):
    return [Paragraph(t, style, bulletText="•") for t in items]


def tabla(rows, widths, header=True, zebra=True, extra=None):
    data = []
    for i, r in enumerate(rows):
        row = []
        for c in r:
            if isinstance(c, str):
                row.append(Paragraph(c, CELLH if (header and i == 0) else CELL))
            else:
                row.append(c)
        data.append(row)
    t = Table(data, colWidths=widths, repeatRows=1 if header else 0)
    st = [
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LINEBELOW", (0, 0), (-1, -1), 0.4, LINE),
        ("BOX", (0, 0), (-1, -1), 0.6, LINE),
    ]
    if header:
        st += [("BACKGROUND", (0, 0), (-1, 0), DARK)]
    if zebra:
        for i in range(1 if header else 0, len(rows)):
            if (i % 2) == 0:
                st.append(("BACKGROUND", (0, i), (-1, i), SOFT))
    t.setStyle(TableStyle(st + (extra or [])))
    return t


class Casilla(Flowable):
    """Casilla vacía para marcar una prueba."""

    def __init__(self, size=9):
        super().__init__()
        self.size = size
        self.width = size
        self.height = size

    def draw(self):
        self.canv.setStrokeColor(MUTE)
        self.canv.setLineWidth(0.9)
        self.canv.rect(0, 0, self.size, self.size)


def pruebas(rows):
    data = [["", "Qué hacer", "Qué debería pasar", "Resultado / nota"]]
    for hacer, esperado in rows:
        data.append([Casilla(), hacer, esperado, ""])
    return tabla(data, [0.3 * inch, 2.95 * inch, 2.6 * inch, 1.15 * inch])


def recuadro(titulo, lineas, color=ORANGE):
    contenido = [Paragraph(f"<b>{titulo}</b>", ParagraphStyle("rt", parent=BODY, textColor=color, spaceAfter=3))]
    contenido += [Paragraph(t, CELL) for t in lineas]
    t = Table([[contenido]], colWidths=[W])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SOFT),
        ("LINEBEFORE", (0, 0), (0, -1), 3, color),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 8),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
    ]))
    return t


def imagen(nombre, ancho, calidad=82, max_px=1700):
    """Reduce la imagen a JPEG para que el PDF pese poco."""
    src = os.path.join(DOCS, nombre)
    im = PILImage.open(src).convert("RGB")
    if im.width > max_px:
        im = im.resize((max_px, round(im.height * max_px / im.width)))
    tmp = os.path.join(tempfile.gettempdir(), "ares_guia_" + os.path.splitext(nombre)[0] + ".jpg")
    im.save(tmp, quality=calidad)
    img = Image(tmp, width=ancho, height=ancho * im.height / im.width)
    img.hAlign = "CENTER"
    return img


def diagrama():
    d = Drawing(W, 1.05 * inch)
    cajas = [
        ("NASA / USGS", "HiRISE, relieve,", "Curiosity (MSL)"),
        ("Python (tools/)", "recorte, pendiente,", "rejilla de costos"),
        ("Archivos de la app", "teselas, PNG,", ".bin y JSON"),
        ("App Flutter (Dart)", "A*, métricas,", "puntajes"),
        ("Tablet Android", "mapa, rutas,", "objetivos"),
    ]
    n = len(cajas)
    gap = 0.22 * inch
    bw = (W - gap * (n - 1)) / n
    bh = 0.82 * inch
    y = 0.12 * inch
    for i, (a, b, c) in enumerate(cajas):
        x = i * (bw + gap)
        d.add(Rect(x, y, bw, bh, fillColor=DARK if i in (0, 4) else colors.white, strokeColor=ORANGE if i in (1, 2, 3) else DARK, strokeWidth=1.2))
        txt = colors.white if i in (0, 4) else INK
        d.add(String(x + bw / 2, y + bh - 17, a, textAnchor="middle", fontName="Grotesk", fontSize=8.6, fillColor=ORANGE if i in (0, 4) else ORANGE_DK))
        d.add(String(x + bw / 2, y + bh - 32, b, textAnchor="middle", fontName="Inter", fontSize=7.6, fillColor=txt))
        d.add(String(x + bw / 2, y + bh - 43, c, textAnchor="middle", fontName="Inter", fontSize=7.6, fillColor=txt))
        if i < n - 1:
            x0, x1 = x + bw + 2, x + bw + gap - 2
            d.add(Line(x0, y + bh / 2, x1 - 4, y + bh / 2, strokeColor=ORANGE, strokeWidth=1.4))
            d.add(Polygon([x1, y + bh / 2, x1 - 5, y + bh / 2 + 3, x1 - 5, y + bh / 2 - 3], fillColor=ORANGE, strokeColor=ORANGE))
    d.add(String(0, 0, "Se corre antes, en la PC del equipo", fontName="Inter-Italic", fontSize=7, fillColor=MUTE))
    d.add(String(W, 0, "Corre dentro de la tablet, sin red", textAnchor="end", fontName="Inter-Italic", fontSize=7, fillColor=MUTE))
    return d


def pie(canvas, doc):
    canvas.saveState()
    canvas.setFont("Inter", 7.5)
    canvas.setFillColor(MUTE)
    canvas.drawString(0.75 * inch, 0.45 * inch, "ARES PATH · Guía para el equipo · versión 0.7 · 14 de noviembre de 2026")
    canvas.drawRightString(letter[0] - 0.75 * inch, 0.45 * inch, f"Página {doc.page}")
    canvas.setStrokeColor(LINE)
    canvas.setLineWidth(0.4)
    canvas.line(0.75 * inch, 0.62 * inch, letter[0] - 0.75 * inch, 0.62 * inch)
    canvas.restoreState()


def portada():
    t = Table(
        [[[
            Paragraph("ARES PATH", ParagraphStyle("t", fontName="Grotesk", fontSize=30, leading=34, textColor=colors.white)),
            Paragraph("Guía de la aplicación y de pruebas para el equipo",
                      ParagraphStyle("st", fontName="Grotesk", fontSize=13, leading=17, textColor=ORANGE, spaceBefore=2)),
            Spacer(1, 8),
            Paragraph("Versión 0.7 · 14 de noviembre de 2026<br/>NASA Space Apps Challenge 2026 · «Interplanetary Survival Guide: Martian Map»",
                      ParagraphStyle("meta", fontName="Inter", fontSize=8.6, leading=12.5, textColor=colors.HexColor("#CFC6C0"))),
        ]]],
        colWidths=[W],
    )
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), DARK),
        ("LEFTPADDING", (0, 0), (-1, -1), 18),
        ("TOPPADDING", (0, 0), (-1, -1), 18),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 16),
        ("LINEBELOW", (0, 0), (-1, -1), 3, ORANGE),
    ]))
    return t


def construir():
    huella = hashlib.sha256(open(APK, "rb").read()).hexdigest()
    tam_apk = os.path.getsize(APK) / 1e6
    s = []

    # ------------------------------------------------------------ 1. Resumen
    s.append(portada())
    s.append(Spacer(1, 12))
    s.append(P("<b>ARES PATH</b> es una aplicación de tableta Android, hecha en Flutter, para planear una caminata de astronauta (EVA) en la zona de "
               "crestas boxwork del Monte Sharp, en el cráter Gale, Marte. Reúne datos reales de la NASA y del USGS en un mapa por capas y convierte "
               "el mapa en una decisión: <b>por dónde camino, cuánto tardo y si me alcanza el oxígeno</b>. Funciona sin red y sin servidor."))
    s.append(imagen("fase3_tablet.png", 5.3 * inch, max_px=1500))
    s.append(P("Captura de la versión 0.1 de la app corriendo en una Samsung Galaxy Tab S9+ (Android 15). Faltan capturas de las pantallas nuevas (ver sección 7).", SMALL))
    s.append(P("Qué puede hacer hoy", H2))
    s.extend(bullets([
        "<b>Mapa por capas</b> del recuadro de 4 × 4 km: ortofoto real de 25 cm, relieve, pendiente, zonas prohibidas y el recorrido real de Curiosity.",
        "<b>Tres rutas</b> desde un hábitat: la más segura, la más rápida y la de más ciencia, con distancia, tiempo, oxígeno al volver, dosis y punto de no retorno.",
        "<b>Dos puntajes por ruta</b> (peligro y éxito, de 0 a 100), siempre con su desglose y sus supuestos a la vista.",
        "<b>Objetivos científicos</b> que el usuario crea tocando el mapa, edita, arrastra y borra. Cada cambio recalcula las rutas.",
        "<b>Capas reales nuevas:</b> térmica (THEMIS-IR, de Mars Trek) y, en la pantalla Ciencia, la unidad geológica del USGS y una <b>foto real de Curiosity</b> por objetivo.",
        "<b>Seguridad con datos reales:</b> radiación (RAD) y clima (REMS) por sol, y reglas GO / NO-GO visibles.",
        "<b>Cuatro modos de salida:</b> a pie, con rover, con rover de apoyo y en pareja, cada uno con su tiempo, oxígeno y puntajes.",
        "<b>Pestaña Casco:</b> concepto de pantalla de visera con la posición simulada sobre la ruta.",
        "<b>Español e inglés</b>, configurable desde la barra superior.",
    ]))
    s.append(Spacer(1, 4))
    s.append(recuadro("Qué se le pide al equipo", [
        "Instalar la app (sección 2), recorrer la guía de pruebas (sección 6) y reportar lo que falle con la plantilla de la página final de pruebas. "
        "Lo más valioso: <b>probar con los dedos</b> (pellizco, arrastre, toques) y <b>opinar sobre si las rutas y los supuestos tienen sentido</b>.",
    ]))
    s.append(PageBreak())

    # ------------------------------------------------------------ 2. Instalación
    s.append(P("1. Qué contiene este documento", H1))
    s.append(tabla([
        ["Sección", "Para qué sirve"],
        ["2. Cómo instalar la app", "Pasos para instalarla en una tablet Android."],
        ["3. Cómo funciona", "Del dato de la NASA a la ruta en pantalla; cómo se calculan rutas y puntajes."],
        ["4. Datos, fuentes y formatos", "Qué se descargó, de dónde, cuánto pesa y en qué formato quedó."],
        ["5. Real, supuesto o ejemplo", "Qué datos son de la NASA y cuáles son supuestos del equipo. Límites conocidos."],
        ["6. Guía de pruebas", "Lista de verificación por pantalla y plantilla para reportar fallos."],
        ["7. Cambios desde la v0.1 y validación de los 6 puntos", "Qué se implementó, cómo comprobarlo en la tablet y, lo que no, por qué y cómo se hará."],
        ["8. Estado y qué sigue", "Fases cerradas, pendientes y recomendación de siguiente paso."],
        ["Anexos", "Parámetros del modelo, estructura del proyecto, comandos y glosario."],
    ], [1.9 * inch, W - 1.9 * inch]))

    s.append(P("2. Cómo instalar la app en la tablet", H1))
    s.append(P(f"El instalador es el archivo <b>ARES_PATH_v0.7.apk</b> ({tam_apk:.1f} MB), que está en la carpeta <font name='Mono'>dist/</font> del proyecto (versión 0.7.0, compilada en modo release). "
               "La app está pensada para tableta Android en horizontal; se instaló en una Samsung Galaxy Tab S9+ con Android 15."))
    s.append(P("Pasos", H2))
    s.extend(bullets([
        "Pasar el APK a la tablet (cable USB, Drive, correo o el medio que use el equipo).",
        "Abrirlo desde el gestor de archivos. Android pedirá permiso para instalar apps desde esa fuente: aceptar solo para esta instalación.",
        "Puede aparecer un aviso de Google Play Protect porque la app no está en Play Store y está firmada con la llave de depuración del proyecto. Es lo esperado; elegir instalar de todas formas.",
        "Abrir <b>ARES PATH</b>. Debe girar sola a horizontal y mostrar el mapa en pocos segundos.",
        "Para desinstalarla: mantener pulsado el icono y elegir desinstalar, como cualquier app.",
    ]))
    s.append(P("Verificar el archivo (opcional)", H2))
    s.append(P("Para comprobar que el APK no se corrompió al copiarlo, su huella SHA-256 debe ser:"))
    s.append(Table([[XPreformatted(huella, MONO)]], colWidths=[W], style=TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SOFT), ("BOX", (0, 0), (-1, -1), 0.5, LINE),
        ("LEFTPADDING", (0, 0), (-1, -1), 8), ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 6)])))
    s.append(P("Instalar por cable o Wi-Fi con adb (para quien tenga las herramientas de Android)", H2))
    s.append(Table([[XPreformatted("adb devices\nadb install -r ARES_PATH_v0.7.apk", MONO)]], colWidths=[W], style=TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SOFT), ("BOX", (0, 0), (-1, -1), 0.5, LINE),
        ("LEFTPADDING", (0, 0), (-1, -1), 8), ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 6)])))
    s.append(P("<b>También corre en Chrome</b> (versión web, útil para ver la app en una PC), pero el producto es Android. "
               "Para compilar desde el código se necesita Flutter 3.47 y el SDK de Android (ver el anexo B).", ParagraphStyle("x", parent=BODY, spaceBefore=6)))
    s.append(PageBreak())

    # ------------------------------------------------------------ 3. Cómo funciona
    s.append(P("3. Cómo funciona", H1))
    s.append(diagrama())
    s.append(Spacer(1, 6))
    s.append(P("La app no pide nada a internet. Todo el trabajo pesado con los mapas de la NASA se hace antes, en la PC, y deja archivos ligeros que van "
               "dentro del APK. La tablet solo carga esos archivos y calcula las rutas."))
    s.append(P("3.1 Preparación de datos (Python, en <font name='Mono'>tools/</font>)", H2))
    s.append(tabla([
        ["Script", "Qué hace"],
        ["00_descargar_ventana.py", "Lee por rangos HTTP solo el recuadro de 4 × 4 km de los mosaicos del USGS, sin bajar los archivos completos."],
        ["01_recortar.py", "Alinea el modelo de elevación a la esquina del recuadro (corrige un desfase de medio metro)."],
        ["02_pendiente.py", "Calcula pendiente, rugosidad y relieve sombreado a 2 m por celda."],
        ["03_costos.py", "Arma la rejilla de costos y marca como prohibidas las celdas de más de 25° de pendiente."],
        ["04_exportar.py", "Genera teselas de la ortofoto, capas PNG, la rejilla binaria y los JSON que carga la app."],
        ["05_rutas.py y comparar_curiosity.py", "Referencia en Python del cálculo de rutas y comparación con el recorrido real de Curiosity."],
    ], [2.1 * inch, W - 2.1 * inch]))
    s.append(P("3.2 La app (Dart / Flutter, en <font name='Mono'>app/lib/</font>)", H2))
    s.extend(bullets([
        "<b>Mapa propio</b> en un plano local en metros (x al este, y al sur desde la esquina noroeste del recuadro). Elige el nivel de teselas según el zoom.",
        "<b>Rutas con A*</b> sobre la rejilla de costos (celdas de 4 m en la app), con 8 vecinos y sin cortar esquinas junto a celdas prohibidas.",
        "<b>Costo de un paso</b> = distancia × (1 + peso de pendiente × (pendiente/25°)² + peso de rugosidad × rugosidad + peso de tiempo × lentitud del paso). "
        "Subir cuesta más que bajar, porque el tiempo de cada paso usa la pendiente en el sentido en que se camina.",
        "<b>Tres perfiles</b>, el mismo algoritmo con pesos distintos: segura (límite de 22°, peso alto a pendiente y terreno suelto), rápida (límite de 25°, minimiza tiempo) "
        "y ciencia (límite de 25°, pesos intermedios).",
        "<b>Qué objetivos visita cada ruta:</b> segura y rápida van al objetivo de mayor prioridad y vuelven. Ciencia suma objetivos por prioridad mientras la salida siga "
        "teniendo margen cómodo (al menos 25 % del tiempo y oxígeno por encima de la reserva más 30 puntos).",
        "<b>Se calcula en el dispositivo:</b> 0.76 s en la tablet de prueba para las tres rutas (1.5 s en Chrome).",
    ]))
    s.append(P("3.3 Métricas y puntajes", H2))
    s.append(P("Cada ruta muestra distancia, tiempo (marcha y paradas), pendiente máxima, metros por clase de pendiente, ascenso, oxígeno al volver, dosis de radiación "
               "y <b>punto de no retorno</b> (el primer punto desde el que terminar la ruta cuesta menos que deshacer lo andado)."))
    s.append(P("<b>Puntaje de peligro (0 a 100, más alto es peor):</b> suma ponderada de seis componentes normalizados de 0 a 1: exposición a pendiente (30), "
               "terreno rugoso o suelto (15), distancia más allá del regreso a pie (20), margen de consumibles (20), dosis de radiación (5) y condiciones del día (10; "
               "hoy vale 0 porque faltan datos). Los pesos son supuestos del equipo."))
    s.append(P("<b>Puntaje de éxito (0 a 100):</b> 100 × valor científico × factor de tiempo × factor de consumibles × (1 − peligro/200). "
               "El valor científico es la suma de prioridades de los objetivos visitados entre la suma de todas. Los factores valen 1 con margen holgado y bajan hasta 0 cuando el margen se agota. "
               "<i>El puntaje ordena rutas; no sustituye el criterio de la tripulación.</i>"))
    s.append(P("Ejemplo con los 4 objetivos de demostración (celdas de 4 m)", H2))
    s.append(tabla([
        ["Ruta", "Visita", "Distancia", "Tiempo", "Pend. máx.", "O<sub>2</sub> al volver", "Peligro", "Éxito"],
        ["Más segura", "T1", "4.2 km", "3 h 23 m", "22°", "52 %", "20.2", "32.1"],
        ["Más rápida", "T1", "3.5 km", "3 h 00 m", "24°", "57 %", "25.9", "31.1"],
        ["Más ciencia", "T1 y T3", "3.8 km", "3 h 36 m", "24°", "50 %", "23.4", "44.2"],
    ], [1.0 * inch, 0.75 * inch, 0.8 * inch, 0.8 * inch, 0.8 * inch, 0.95 * inch, 0.8 * inch, W - 5.9 * inch]))
    s.append(P("Los números cambian si cambia cualquier parámetro u objetivo. Ciencia no visita T2 ni T4 porque con ellos el margen deja de ser cómodo.", SMALL))
    s.append(imagen("fase2_rutas_4m.jpg", 3.5 * inch, max_px=1300))
    s.append(P("Rutas calculadas sobre la ortofoto: blanca = segura, naranja = rápida, cian = ciencia. Los círculos amarillos son los objetivos.", SMALL))

    # ------------------------------------------------------------ 4. Datos
    s.append(P("4. Datos descargados, fuentes y formatos", H1))
    s.append(P("No se bajaron los archivos completos: se leyó solo la ventana del recuadro mediante peticiones HTTP por rangos. "
               "Los mosaicos usan la proyección equirectangular de Marte (esfera de radio 3 396 190 m, latitud planetocéntrica, este positivo)."))
    s.append(P("4.1 Datos de la NASA y el USGS", H2))
    s.append(tabla([
        ["Dato", "Fuente", "Completo", "En disco", "Formato"],
        ["Relieve, 1 m por píxel", "USGS Astrogeology: <font name='Mono'>MSL_Gale_DEM_Mosaic_1m_v3.tif</font> (HRSC + CTX + HiRISE, ligado a MOLA)", "3.87 GB", "25 MB", "GeoTIFF flotante de 32 bits"],
        ["Ortofoto en color, 0.25 m por píxel", "USGS: <font name='Mono'>MSL_Gale_HiRISE-LRGB_78quads_sharp_cog.tif</font> (imágenes HiRISE del MRO)", "1.03 GB", "500 MB", "GeoTIFF de 3 bandas, con pirámide"],
        ["Posiciones de Curiosity", "NASA/JPL: <font name='Mono'>MSL_waypoints.json</font> (mars.nasa.gov, capa MMGIS)", "665 KB", "665 KB", "GeoJSON, 1389 puntos hasta el sol 5073"],
        ["Recorrido de Curiosity", "NASA/JPL: <font name='Mono'>MSL_traverse.json</font>", "1.4 MB", "1.4 MB", "GeoJSON (aún sin usar)"],
    ], [1.25 * inch, 2.75 * inch, 0.65 * inch, 0.65 * inch, W - 5.3 * inch]))
    s.append(P("URL base de los mosaicos: <font name='Mono'>planetarymaps.usgs.gov</font> y <font name='Mono'>asc-pds-services.s3.us-west-2.amazonaws.com</font>. "
               "Fichas: <font name='Mono'>astrogeology.usgs.gov/search/map/mars_msl_gale_merged_dem_1m</font> y "
               "<font name='Mono'>…/mars_msl_gale_merged_orthophoto_mosaic_25cm</font>. Licencia en ambas: «Use Constraints: None. Please credit authors». "
               "Cita: Calef III, F. J. y Parker, T. (2016). <i>MSL Gale Merged Orthophoto Mosaic</i> y <i>MSL Gale Merged DEM</i>. PDS Annex, U.S. Geological Survey. "
               "Los términos de uso de los JSON de mars.nasa.gov no se han consultado: citar como NASA/JPL-Caltech hasta confirmarlos.", SMALL))
    s.append(P("Datos añadidos después de la versión 0.1", H2))
    s.append(tabla([
        ["Dato", "Fuente", "Tamaño", "Cómo se usa"],
        ["Radiación (RAD)", "NASA SPDF, CDAWeb, conjunto <font name='Mono'>MSL_RAD_OBS-L2</font> (investigador principal D. Hassler, SwRI)", "1.9 MB", "Dosis por sol y línea base de 151 µGy por día en las rutas y la pantalla Seguridad"],
        ["Clima (REMS)", "PDS, nodo de Atmósferas (NMSU), <font name='Mono'>MSL-M-REMS-5-MODRDR-V1.0</font> (CAB, INTA-CSIC); soles 4814 a 4843", "305 MB", "Temperatura, presión y ultravioleta por hora; regla de GO / NO-GO"],
        ["Térmica (THEMIS-IR de día)", "Mars Trek (recurso oficial del desafío), teselas WMTS de <font name='Mono'>THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018</font>", "180 KB", "Capa «Térmica». Es brillo relativo a unos 100 m por píxel, no temperatura calibrada"],
        ["Unidad geológica", "Mars Trek, mapa geológico global del USGS (<font name='Mono'>SIM3292_Global_Geology</font>, 1:20 000 000)", "1 KB", "Una fila de texto en Ciencia: todo el recuadro cae en una sola unidad, «Hesperian transition undivided unit»"],
        ["Fotos de Curiosity", "API de imágenes crudas de <font name='Mono'>mars.nasa.gov</font>, Navcam, soles 4500, 4548, 4609 y 4889 (crédito NASA/JPL-Caltech)", "2.0 MB", "Una foto por objetivo de demostración en la pantalla Ciencia"],
    ], [1.2 * inch, 2.7 * inch, 0.6 * inch, W - 4.5 * inch]))
    s.append(P("4.2 Lo que no se descargó (todavía)", H2))
    s.extend(bullets([
        "Ortomosaico en escala de grises de 25 cm: 50.4 GB, sin teselas ni compresión. Se usó el mosaico en color, que sí se lee por ventanas.",
        "Minerales (CRISM): sin resolver; su cobertura sobre Gale en Mars Trek no está verificada. La capa se muestra como ejemplo.",
        "Polvo (opacidad): el PDS no tiene un producto de REMS para él. Se muestra como pendiente.",
        "Térmica de inercia (TES, 3 km por píxel): descartada por ser demasiado gruesa para 4 × 4 km.",
    ]))
    s.append(P("4.3 Qué lleva la app dentro (<font name='Mono'>app/assets/</font>, unos 54 MB)", H2))
    s.append(tabla([
        ["Archivo", "Contenido", "Formato"],
        ["ortho/{z}/{x}/{y}.jpg", "341 teselas de la ortofoto, niveles 0 a 4 (de 8 m a 0.5 m por píxel)", "JPEG de 512 px, 29 MB"],
        ["layers/slope.png, hillshade.png", "Pendiente coloreada y relieve sombreado, 2 m por píxel", "PNG de 2000 × 2000"],
        ["grid/slope.bin", "Pendiente en pasos de 0.5°", "1 byte por celda (2000 × 2000)"],
        ["grid/rough.bin", "Rugosidad en pasos de 0.5 cm", "1 byte por celda"],
        ["grid/forbidden.bin", "1 = celda prohibida (más de 25° o sin dato)", "1 byte por celda"],
        ["grid/elev.bin", "Elevación en pasos de 2 cm sobre un desfase", "2 bytes por celda, little-endian"],
        ["site.json", "Recuadro, fórmulas a latitud y longitud, capas, hábitat, esquema de teselas", "JSON"],
        ["params.json", "Parámetros del modelo (copia de <font name='Mono'>config/params.json</font>)", "JSON"],
        ["objectives.json", "Los 4 objetivos de demostración", "JSON"],
        ["curiosity_waypoints.json", "317 posiciones reales de Curiosity dentro del recuadro", "JSON"],
        ["fonts/", "Space Grotesk, JetBrains Mono, Inter (copiadas del sistema)", "TTF"],
    ], [1.75 * inch, 3.35 * inch, W - 5.1 * inch]))
    s.append(P("4.4 Zona de trabajo", H2))
    s.append(P("Recuadro de 4 × 4 km centrado en la zona donde Curiosity estudió las crestas boxwork (soles 4500 a 4899): esquina suroeste 4.8376° S, 137.3503° E; "
               "esquina noreste 4.7702° S, 137.4178° E; elevación de −4079 a −3244 m. <b>No existe un mapa oficial de las crestas</b>: se usaron las posiciones del rover como aproximación."))

    # ------------------------------------------------------------ 5. Real / supuesto / ejemplo
    s.append(P("5. Qué es real, qué es supuesto y qué es de ejemplo", H1))
    s.append(P("Regla del hackathon: ningún valor, imagen o texto generado por IA se presenta como dato de la NASA. La app marca cada capa como <b>MEDIDO</b>, "
               "<b>MODELADO</b> o <b>EJEMPLO</b>."))
    s.append(tabla([
        ["Dato", "Estado", "Origen y cómo se ve en la app"],
        ["Ortofoto, relieve y posiciones de Curiosity", "<font color='#007C8C'><b>Real</b></font>", "Archivos de la NASA y el USGS. Etiqueta MEDIDO."],
        ["Radiación (RAD), clima (REMS), térmica (THEMIS-IR), unidad geológica y fotos de Curiosity", "<font color='#007C8C'><b>Real</b></font>", "Datos de la NASA y el USGS (sección 4). Etiqueta MEDIDO. La térmica es de baja resolución y la geología es de escala global."],
        ["Pendiente, rugosidad, zonas prohibidas, rutas y puntajes", "<font color='#B8470F'><b>Calculado</b></font>", "Derivado de datos reales con nuestro código. Etiqueta MODELADO."],
        ["Parámetros del rover (6 km/h, 20°, 30 cm, oxígeno al 50 %, 5 min), salida del rover de apoyo (10 min) y separación máxima de la pareja (500 m)", "<font color='#9A5F00'><b>Supuesto</b></font>", "Velocidad y pendiente se apoyan en el vehículo lunar de Apolo (NASA); el resto es nuestro. Se muestran en «Supuestos» al elegir el modo."],
        ["Velocidad, curva de pendiente, EVA de 6 h, oxígeno de 8 h, reserva de 20 %, pesos y límites", "<font color='#9A5F00'><b>Supuesto</b></font>", "Los propuso la IA como valores de trabajo; no son estándares de la NASA. Se muestran en «Supuestos» (panel derecho) y están en <font name='Mono'>config/params.json</font>."],
        ["Tipo, prioridad y tiempo de los 4 objetivos de demostración", "<font color='#9A5F00'><b>Supuesto</b></font>", "Las posiciones sí son paradas reales de Curiosity; el resto lo definimos nosotros."],
        ["Hábitat", "<font color='#9A5F00'><b>Elegido</b></font>", "Punto plano a 1.2 km de las crestas, elegido por pendiente. «Suelo firme» no está comprobado (haría falta inercia térmica)."],
        ["Dosis de radiación (0.65 mSv/día) y «condiciones del día»", "<font color='#6F625B'><b>Ejemplo</b></font>", "Valores provisionales hasta la fase 4. Marcados como ejemplo."],
        ["Térmica, minerales, radiación, clima, polvo, fotos del rover", "<font color='#6F625B'><b>Pendiente</b></font>", "Sin datos. La app lo dice en pantalla en vez de inventar valores."],
    ], [2.3 * inch, 0.95 * inch, W - 3.25 * inch]))
    s.append(P("Límites que conviene conocer", H2))
    s.extend(bullets([
        "El modelo de elevación es de 2016 y no resuelve crestas de 1 a 2 m: en la zona boxwork deja manchas de pendiente alta por ruido.",
        "El desfase entre ortofoto y modelo es de unos 2 m (una celda de la rejilla).",
        "Comparada con el recorrido real de Curiosity, la ruta segura evita las mismas pendientes de más de 20° (el rover pisó 1.7 % del tiempo pendientes de 20° a 25°; el recuadro tiene 8.7 %). "
        "Pero nuestras rutas son más cortas (329 m contra 451 m por tramo), porque el rover tenía otras restricciones (arena, desgaste de ruedas, paradas científicas). "
        "Es una comprobación de coherencia, <b>no una validación para un traje</b>.",
        "La navegación real del traje no se construye: en Marte no hay GPS. La app es una herramienta de planeación.",
    ]))
    s.append(PageBreak())

    # ------------------------------------------------------------ 6. Guía de pruebas
    s.append(P("6. Guía de pruebas", H1))
    s.append(P("Marcar cada casilla al probarla y anotar el resultado. Si algo no coincide con «qué debería pasar», reportarlo con la plantilla del final de esta sección. "
               "Todas las pruebas son con los dedos, en la tablet, en horizontal."))
    s.append(recuadro("Lo que más necesitamos que confirmen", [
        "1) El <b>pellizco</b> y el <b>arrastre con el dedo</b> (hasta ahora solo se probó con ratón en Chrome). "
        "2) Que <b>mover y crear objetivos</b> con el dedo funciona y recalcula las rutas. "
        "3) Que las <b>rutas y los supuestos tienen sentido</b> para quien conozca el tema.",
    ], color=CYAN_DK))
    s.append(P("A. Instalación y arranque", H2))
    s.append(pruebas([
        ("Instalar el APK y abrir la app.", "Abre sin cerrarse. No pide permisos de cámara, ubicación ni almacenamiento."),
        ("Mirar la pantalla con la tablet en vertical y luego en horizontal.", "La app queda en horizontal y a pantalla completa."),
        ("Esperar el arranque.", "En pocos segundos aparece el mapa. El panel derecho muestra «COMPUTING ROUTES…» y luego las tres tarjetas de rutas."),
        ("Cerrar la app y volver a abrirla.", "Arranca de nuevo igual, con los 4 objetivos de demostración (la app no guarda cambios al cerrarse)."),
    ]))
    s.append(P("B. Barra superior e idioma", H2))
    s.append(pruebas([
        ("Tocar PLAN, SAFETY y SCIENCE.", "Cambia de pantalla; la pestaña activa se subraya en naranja."),
        ("Tocar ES y luego EN.", "Todos los textos cambian de idioma. Anotar cualquier texto que quede en el idioma equivocado o cortado."),
        ("Mirar la etiqueta verde de la derecha.", "Dice FEASIBLE / FACTIBLE cuando la ruta seleccionada cabe en tiempo y oxígeno."),
    ]))
    s.append(P("C. Mapa (pantalla Plan)", H2))
    s.append(pruebas([
        ("Arrastrar el mapa con un dedo.", "El mapa se mueve siguiendo el dedo, sin saltos."),
        ("Pellizcar con dos dedos para acercar y alejar.", "El zoom sigue a los dedos. Al acercar, la imagen gana detalle (teselas más finas) sin quedar en blanco más de un instante."),
        ("Tocar los botones +, − y el de «ajustar a la vista».", "Acercan, alejan y recentran el mapa completo."),
        ("Mirar la barra de escala de abajo a la derecha al hacer zoom.", "Cambia de valor (por ejemplo 1 km, 500 m, 100 m) y su largo coincide con el mapa."),
        ("Mirar la lectura de coordenadas de abajo a la izquierda.", "Muestra una ayuda de uso. Con dedo no sigue la posición (solo con ratón): es una limitación conocida."),
    ]))
    s.append(P("D. Capas (panel izquierdo)", H2))
    s.append(pruebas([
        ("Activar y desactivar «Relieve (sombreado)», «Pendiente», «Zonas prohibidas» y «Recorrido de Curiosity».", "Cada capa aparece o desaparece sobre la ortofoto. El contador «N ACTIVAS» se actualiza."),
        ("Mover el deslizador de opacidad de cada capa.", "La capa se vuelve más o menos transparente al instante."),
        ("Tocar el icono de reiniciar capas.", "Vuelven los valores iniciales: óptica, pendiente al 40 % y recorrido de Curiosity."),
        ("Activar «Térmica (THEMIS-IR día)».", "Aparece una capa de colores sobre la ortofoto (azul oscuro frío a amarillo cálido) que sigue las crestas y los valles. Etiqueta MEDIDO."),
        ("Mirar la capa Mineralogía.", "Aparece atenuada, con etiqueta EJEMPLO y «Sin datos todavía». No se puede activar (CRISM sin resolver)."),
        ("Comparar los colores de la leyenda con la capa de pendiente.", "Verde < 10°, amarillo 10–20°, naranja 20–25°, rojo > 25° (prohibida)."),
    ]))
    s.append(P("E. Rutas (panel derecho)", H2))
    s.append(pruebas([
        ("Tocar cada tarjeta: Más segura, Más rápida, Más ciencia.", "La ruta elegida se resalta en el mapa y el perfil de elevación de abajo cambia."),
        ("Comparar las tres tarjetas.", "La segura es más larga y con menor pendiente máxima; la rápida es más corta; ciencia visita más de un objetivo."),
        ("Abrir «Desglose» en una tarjeta.", "Muestra cada componente del peligro con su peso (suma 100) y los factores del éxito."),
        ("Activar «Zonas prohibidas» y seguir las rutas.", "Ninguna ruta cruza zonas rojas."),
        ("Mirar el punto de no retorno (marca ámbar «PNR»).", "Aparece sobre la ruta seleccionada y en el perfil de elevación."),
    ]))
    s.append(P("F. Objetivos (la prueba más importante)", H2))
    s.append(pruebas([
        ("Tocar un objetivo en el mapa (rombo cian).", "Se abre el diálogo de edición con nombre, tipo, prioridad (1 a 5) y tiempo de trabajo."),
        ("Cambiar la prioridad o el tiempo y guardar.", "Aparece «COMPUTING ROUTES…» y las rutas y puntajes se recalculan."),
        ("Mantener el dedo sobre un objetivo y arrastrarlo a otro sitio.", "El objetivo sigue al dedo. Al soltar, se recalculan las rutas."),
        ("Pulsar «ADD OBJECTIVE» y tocar un punto del mapa.", "Se crea un objetivo nuevo (U1, U2…) y se abre su diálogo. El modo de añadir se apaga solo."),
        ("Colocar un objetivo sobre una zona roja (prohibida).", "El objetivo se ve en rojo, la lista dice «En terreno prohibido» y las rutas no lo incluyen."),
        ("Crear 6 o más objetivos y mover uno.", "La app sigue respondiendo. Anotar cuánto tarda el recálculo (aparece en milisegundos arriba a la derecha del panel)."),
        ("Borrar un objetivo desde su diálogo.", "Desaparece del mapa y de la lista; las rutas se recalculan."),
    ]))
    s.append(P("G. Pantalla Safety", H2))
    s.append(pruebas([
        ("Abrir SAFETY.", "Muestra el estado general y una verificación por tema. Radiación, clima, terreno y consumibles usan datos reales o del modelo; el polvo dice que está pendiente, y por eso el estado general nunca dice GO: dice «datos incompletos»."),
        ("Mover el selector de sol (30 soles de REMS) y leer la nota debajo.", "Cambian la dosis, la temperatura del día y la presión. Una línea fija avisa que es la evaluación de un período pasado (REMS hasta el sol 4843, marzo de 2026), no un pronóstico."),
        ("Mirar el panel de reglas GO / NO-GO.", "Muestra los umbrales (radiación 1.5× y 3× la línea base; aire −60 °C y −80 °C; inicio a las 09:00) como SUPUESTO, y la línea: «la salida es de dos astronautas; consumibles y dosis para uno; no se modela un rover»."),
        ("Cambiar entre las tres rutas con los botones de arriba.", "El reparto de metros por pendiente, la tabla de regreso por parada y los consumibles cambian."),
        ("Revisar el panel de consumibles.", "Barra de oxígeno con la reserva marcada en ámbar, barra de tiempo de salida y tabla comparativa de las tres rutas."),
    ]))
    s.append(P("H. Pantalla Science", H2))
    s.append(pruebas([
        ("Abrir SCIENCE y tocar cada objetivo de la lista.", "El detalle cambia: coordenadas, elevación, pendiente y un recorte de la ortofoto centrado en el objetivo."),
        ("Mirar «Datos en este punto».", "Elevación, pendiente, rugosidad, distancia y desnivel respecto al hábitat; térmica (brillo relativo de THEMIS-IR), radiación del sol elegido y unidad geológica (una sola en el recuadro), todos MEDIDO. Minerales sigue como EJEMPLO."),
        ("Mirar el panel «Ground · Rover photo» de t1, t2, t3 y t4.", "Cada uno muestra una foto real de Navcam de Curiosity con el pie «CURIOSITY · cámara · SOL · fecha» y el crédito NASA/JPL-Caltech. La foto es de ese sol, cerca de la parada, no del objetivo en sí."),
        ("Crear un objetivo nuevo en el mapa y abrirlo en Ciencia.", "El panel de foto dice «Sin foto del rover para este objetivo»."),
        ("Mirar «Included in routes» a la derecha.", "Marca con una palomita en qué rutas entra ese objetivo."),
        ("Tocar «Edit objective».", "Abre el mismo diálogo de edición."),
    ]))
    s.append(P("I. Robustez y rendimiento", H2))
    s.append(pruebas([
        ("Mandar la app a segundo plano, abrir otra y volver.", "Regresa al mismo estado, sin reiniciarse."),
        ("Usar la app 10 minutos seguidos.", "No se calienta de forma anormal ni se cierra sola. Anotar el modelo de la tablet y el nivel de batería."),
        ("Anotar el tiempo de recálculo que aparece arriba a la derecha del panel de rutas.", "Debería ser del orden de 0.5 a 2 s. Reportar si pasa de 3 s."),
    ]))
    s.append(P("J. Revisión de contenido (para quien conozca el tema)", H2))
    s.append(pruebas([
        ("Mirar las tres rutas sobre la ortofoto.", "Evitan escarpes y barrancos y siguen terreno razonable. Anotar tramos que parezcan absurdos."),
        ("Leer el panel «Supuestos».", "Opinar si la velocidad, la duración de la salida y el oxígeno son razonables para un traje. Proponer valores mejores si los hay."),
        ("Revisar los objetivos de demostración.", "Opinar si el tipo, la prioridad y el tiempo de cada uno son razonables."),
    ]))

    s.append(P("K. Modos de salida (panel de rutas, arriba)", H2))
    s.append(pruebas([
        ("Tocar «Con rover».", "Las tres rutas se recalculan (aparece «calculando»). Cada tarjeta añade «Rover: metros · horas». Con el límite de 20° el rover cubre poco: de 240 a 760 m por ruta. En la ruta rápida el tiempo sube un poco (10 min de subir y bajar)."),
        ("Con «Con rover» activo, mirar el bloque «Supuestos».", "Aparecen velocidad 6 km/h, pendiente 20°, rugosidad 30 cm, oxígeno 50 % y 5 min, y la nota de que velocidad y pendiente salen del vehículo lunar de Apolo."),
        ("Tocar «Apoyo».", "Las rutas son las mismas que a pie (mismo tiempo y oxígeno). Cada tarjeta muestra «Regreso en emergencia» junto a «A pie»: por ejemplo 1.11 h contra 1.18 h en la ruta segura. El punto de no retorno de la segura pasa de 2110 m a 2176 m."),
        ("Tocar «Pareja».", "Aparece la tarjeta «Salida en pareja» y dos rutas: «Astronauta 1» (cian) y «Astronauta 2» (naranja). Con los 4 objetivos de demostración visitan t1, t2 y t3, con separación máxima de 455 m contra el límite de 500 m. t4 queda fuera."),
        ("En «Pareja», mover un objetivo lejos (más de 500 m del hábitat y de los otros).", "El reparto cambia o el objetivo queda fuera. Si ninguna pareja cumple la separación, la tarjeta lo dice."),
        ("Volver a «A pie».", "Regresan las tres rutas originales (segura 3.38 h, rápida 3.00 h, ciencia 3.60 h con los objetivos de demostración)."),
    ]))
    s.append(P("L. Pestaña Casco (concepto)", H2))
    s.append(pruebas([
        ("Abrir CASCO.", "Muestra una foto real de Curiosity atenuada de fondo, rotulada como «no es la vista de esta ruta», con la etiqueta CONCEPTO."),
        ("Pulsar reproducir y mover el deslizador de avance.", "La brújula cambia de rumbo, la distancia al siguiente objetivo y al hábitat cambian, y la temperatura del aire usa la hora local simulada."),
        ("Avanzar hasta pasar el punto de no retorno.", "«Pasado el punto» cambia de NO a SÍ en ámbar."),
        ("Buscar un tramo con pendiente por delante.", "Aparece el aviso «PRECAUCIÓN: PENDIENTE DE n° A m m» en ámbar o rojo."),
        ("Cambiar la ruta o el modo en PLAN y volver a CASCO.", "El HUD usa la ruta seleccionada."),
    ]))
    s.append(P("No es un fallo (limitaciones conocidas)", H2))
    s.extend(bullets([
        "Minerales (CRISM) y polvo siguen como pendientes o ejemplo; la unidad geológica es de escala global y la capa térmica tiene pocos píxeles en el recuadro.",
        "La pantalla Casco es un concepto: la posición es simulada, y no hay signos vitales ni sensores del traje.",
        "Los modos con rover, con rover de apoyo y en pareja usan supuestos del equipo, no especificaciones de la NASA. Con el límite de 20° el rover ayuda poco en este terreno.",
        "El modo en pareja puede tardar varios segundos en calcularse (no se midió en la tablet).",
        "La lectura de coordenadas solo sigue al ratón; con el dedo no se actualiza.",
        "Tras cada cambio, la interfaz se bloquea entre 0.5 y 2 s mientras se recalculan las rutas.",
        "La app no guarda los objetivos al cerrarse.",
        "Las rutas de ida y de vuelta se dibujan casi sobre la misma línea.",
        "El texto usa la tipografía Inter en lugar de IBM Plex Sans (la del diseño original), que aún no está instalada.",
        "No existen la ruta con línea de tiempo ni los botones «aprobar ruta» y «recalcular» del prototipo.",
        "Los valores del modelo (velocidad, oxígeno, pesos) son supuestos, no datos de la NASA.",
    ]))

    campos = [
        "Quién reporta y fecha", "Tablet (modelo) y versión de Android", "Idioma de la app (ES / EN)",
        "Pantalla y prueba (por ejemplo F-3)", "Pasos para repetirlo", "Qué debería pasar",
        "Qué pasó en realidad", "Captura de pantalla (sí / no)", "¿Siempre ocurre o solo a veces?",
    ]
    s.append(KeepTogether([
        P("Plantilla para reportar un fallo", H2),
        tabla([[a, ""] for a in campos], [2.6 * inch, W - 2.6 * inch], header=False, zebra=False,
              extra=[("BACKGROUND", (0, 0), (0, -1), SOFT), ("TOPPADDING", (0, 0), (-1, -1), 8), ("BOTTOMPADDING", (0, 0), (-1, -1), 8)]),
    ]))

    # ------------------------------------------------------------ 7. Cambios y validación de los 6 puntos
    s.append(PageBreak())
    s.append(P("7. Cambios desde la versión 0.1 y validación de los 6 puntos", H1))
    s.append(P("El desafío propone seis consideraciones («puede, pero no está obligado»). Las revisamos una por una. Esta sección dice qué se implementó, "
               "<b>cómo comprobarlo en la tablet</b> y, donde no se implementó, por qué y cómo se hará."))
    s.append(P("7.1 Qué cambió", H2))
    s.append(tabla([
        ["Cambio", "Dónde se ve", "Detalle"],
        ["Datos reales de seguridad (RAD y REMS)", "SEGURIDAD", "Dosis real de 151 µGy por día, clima por sol, selector de 30 soles, reglas GO / NO-GO visibles."],
        ["Capa térmica real (THEMIS-IR, Mars Trek)", "PLAN, capas", "Etiqueta MEDIDO; brillo relativo a unos 100 m por píxel."],
        ["Unidad geológica (mapa del USGS, Mars Trek)", "CIENCIA, «Datos en este punto»", "Una sola unidad en el recuadro; escala global."],
        ["Fotos reales de Curiosity (Navcam)", "CIENCIA", "Una por objetivo de demostración, con cámara, sol, fecha y crédito."],
        ["Aviso de período pasado", "SEGURIDAD", "La evaluación es de un sol pasado, no un pronóstico."],
        ["Pestaña Casco (concepto de HUD)", "CASCO", "Posición simulada sobre la ruta."],
        ["Modos de salida: a pie, con rover, apoyo y pareja", "PLAN, panel de rutas", "Cada modo con su tiempo, oxígeno, puntajes y supuestos."],
        ["Supuesto de salida en pareja sin rover", "SEGURIDAD, reglas", "Línea fija en el panel de reglas GO / NO-GO."],
        ["Fuentes oficiales citadas", "RECURSOS.md, PROPUESTA.md", "Qué capa sale de cada recurso oficial del desafío."],
        ["Pruebas", "Proyecto", "24 de Python y 85 de Dart; la prueba de humo recorre las cuatro pestañas y los cuatro modos, y otra recorre Meridiani."],
    ], [2.35 * inch, 1.55 * inch, W - 3.9 * inch]))
    s.append(P("7.2 Los 6 puntos, uno por uno", H2))
    ok = "<font color='#1B7F46'><b>Hecho</b></font>"
    parc = "<font color='#9A5F00'><b>Parcial</b></font>"
    s.append(tabla([
        ["Nº", "Qué propone el desafío", "Estado y qué se hizo", "Cómo validarlo en la tablet", "Lo que no se hizo: por qué y cómo se hará"],
        ["1", "Formato: tableta, pantalla de nave o HUD de casco.",
         parc + ". Es una app de tableta Android. La pantalla de casco existe como <b>concepto</b> con posición simulada.",
         "Abrir CASCO y seguir la prueba L (reproducir, deslizador, aviso de pendiente, punto de no retorno).",
         "El HUD real con signos vitales y sensores del traje no se hizo: no hay datos ni hardware, y el prototipo de Stitch traía valores de ejemplo que no se usaron. Se haría con el traje y sensores reales; hoy queda como trabajo futuro."],
        ["2", "Instantánea, producto interactivo o sistema que genere mapas de otros lugares.",
         parc + ". Es un producto interactivo (capas, objetivos, rutas, modos). Siete sitios: dos de Gale y cinco de Meridiani (versión 0.6).",
         "Pruebas A a E: capas, rutas, crear y mover objetivos, cambiar de modo.",
         "Un generador automático de mapas de otros sitios no se hizo: cada sitio se prepara con scripts propios (Meridiani se añadió en la versión 0.5 con <font name='Mono'>tools/10</font> a <font name='Mono'>12</font>). Se haría empaquetando cada sitio con el mismo formato (teselas, rejilla, objetivos, series); Jezero encaja con el recurso oficial de imágenes de Perseverance. Está en «Trabajo futuro» de PROPUESTA.md."],
        ["3", "Inspirarse en cómo la NASA ha hecho mapas para otros destinos.",
         ok + ". PROPUESTA.md tiene una sección con 4 referencias de la NASA sobre planificación de caminatas en la Luna (Artemis) y Worldview.",
         "Leer la sección «Inspiración en misiones a otros destinos» de PROPUESTA.md y abrir los enlaces (NTRS 20230006633, 20220012753, 20250011301, 20250011660).",
         "No se comparó con Moon Trek (no se encontró su documentación). Las referencias son contexto de diseño, no validación de nuestros umbrales. Se verificará cuando haya acceso a la documentación de Moon Trek."],
        ["4", "Período de tiempo: pasado, futuro o ninguno.",
         ok + " para un período pasado: clima REMS de los soles 4814 a 4843 (feb. a mar. de 2026) y radiación RAD, con aviso fijo en SEGURIDAD. El terreno no depende del tiempo.",
         "Abrir SEGURIDAD, mover el selector de sol y leer la nota: «Evaluación de un período pasado… no es un pronóstico».",
         "El pronóstico no se hizo: las fuentes que usamos no traen datos predichos. Se haría con modelos de clima de Marte; queda como trabajo futuro. El polvo no tiene dato en el PDS."],
        ["5", "Imágenes en primera persona de las misiones.",
         ok + ". Una foto real de Navcam por objetivo de demostración, con cámara, sol, fecha y crédito NASA/JPL-Caltech.",
         "CIENCIA: tocar t1 a t4 (foto con pie) y crear un objetivo nuevo (dice «Sin foto del rover para este objetivo»).",
         "Las fotos son de ese sol y cerca de la parada, en blanco y negro, y algunas muestran partes del rover; Mastcam se descartó (miraba el suelo cercano). Un objetivo nuevo no tiene foto. Se mejoraría eligiendo fotos con un criterio por posición y fecha."],
        ["6", "Rovers y sistemas robóticos; astronautas en parejas.",
         parc + ". Tres modos con supuestos visibles: <b>con rover</b> (rover aparcado en un punto de la ruta), <b>rover de apoyo</b> en el hábitat (regreso en emergencia) y <b>pareja</b> con separación máxima de 500 m.",
         "Prueba K: tocar «Con rover», «Apoyo» y «Pareja» y comparar con «A pie».",
         "Las rutas siguen optimizadas para caminar (no para el rover); no se combinan los modos; no hay un rover presurizado ni puntos de encuentro. Los parámetros son supuestos del equipo; solo velocidad y pendiente se apoyan en el vehículo lunar de Apolo. Se haría optimizando la ruta para el rover y con una referencia citable para Marte."],
    ], [0.3 * inch, 1.1 * inch, 1.75 * inch, 1.55 * inch, W - 4.7 * inch]))
    s.append(P("7.3 Resultado de los cuatro modos (4 m por celda, objetivos de demostración)", H2))
    s.append(tabla([
        ["Modo", "Segura", "Rápida", "Ciencia"],
        ["A pie", "3.38 h · O<sub>2</sub> 52 % · éxito 32.1", "3.00 h · O<sub>2</sub> 57 % · éxito 31.1", "3.60 h · O<sub>2</sub> 50 % · éxito 44.2 (t1, t3)"],
        ["Con rover (20°)", "3.22 h · 764 m en rover", "3.08 h · 241 m en rover", "3.55 h · 475 m en rover"],
        ["Rover de apoyo (emergencia)", "1.11 h contra 1.18 h a pie · PNR 2176 m", "1.00 h, sin mejora", "1.07 h contra 1.10 h · PNR 2285 m"],
        ["Pareja", "—", "—", "t1, t2, t3 · 3.60 h · separación 455 m · éxito 62.3"],
    ], [1.6 * inch, 1.65 * inch, 1.65 * inch, W - 4.9 * inch]))
    s.append(P("El rover ayuda poco con el límite de 20° porque el hábitat solo se conecta con el terreno por un paso de unos 20°. El resultado depende mucho de ese límite: "
               "a 22° el rover haría toda la ruta segura (1.54 h). Es el supuesto más importante del modo.", SMALL))
    s.append(P("7.4 Cómo se validó por dentro", H2))
    s.extend(bullets([
        "<b>24 pruebas de Python y 85 de Dart</b> pasan; <font name='Mono'>flutter analyze</font> sin avisos. La prueba de humo abre las cuatro pestañas y los cuatro modos con las aserciones del modo desarrollo activas.",
        "<b>Dart da el mismo resultado que Python</b>: camino celda por celda y métricas a 1e-6, en los modos a pie, rover, apoyo y pareja (referencias en <font name='Mono'>app/test/golden/</font>).",
        "<b>Datos reales:</b> tres soles al azar (4818, 4824, 4826) coinciden con los archivos originales de RAD y REMS (<font name='Mono'>tools/comprobar_ambiente.py</font>).",
        "<b>Falta:</b> verificar a mano en la tablet los modos (sobre todo el tiempo de cálculo del modo pareja), la pestaña Casco, la capa térmica y las fotos. No hay capturas de estas pantallas en este documento porque la captura por adb se colgaba.",
    ]))
    # ------------------------------------------------------------ 7.4 Versión 0.5
    s.append(P("7.5 Versión 0.7: sitios, misiones, transporte, capas y mapas completos", H2))
    s.append(P("La versión 0.7 amplía lo anterior. <b>Anula la decisión de «Gale único sitio»</b>: ahora hay siete sitios (Gale de 4 y de 24 km; Meridiani: Endeavour de 4 y de 22 km, zona habitable, contexto regional). Cada sitio se abre desde el nombre, arriba a la izquierda. <b>Todo funciona sin red</b>: los mapas y datos van dentro de la app."))
    s.append(tabla([
        ["Qué", "Detalle", "Límites"],
        ["Sitios de Meridiani", "<b>Endeavour</b> (4 × 4 km, relieve de 1 m, ortofoto HiRISE), <b>zona habitable</b> (20 × 20 km, relieve de 200 m, indicativa) y <b>contexto regional</b> (100 × 100 km, indicativo).", "El relieve de 200 m alisa las pendientes y no da rugosidad. Los objetivos son de ejemplo. Sin radiación ni clima propios."],
        ["Misiones guardadas", "Botón con el nombre de la misión, junto al sitio: crear, duplicar, abrir y borrar; notas, consumibles y equipo; se guarda solo en la tablet; copiar como JSON.", "Los consumibles y el equipo los escribe el usuario y todavía no cambian el cálculo."],
        ["Transporte por objetivo", "A pie, vehículo o híbrido (vehículo hasta donde el terreno lo permita y el resto a pie). Modo «Por objetivo» en el panel de rutas.", "Un solo vehículo; en Gale nunca llega a un objetivo (el paso de 20° cerca del hábitat). Supuestos del equipo."],
        ["Capas de Meridiani", "Pendiente mayor de 15 %, zonas de tránsito (DCI e inercia térmica de TES), térmica de noche, minerales acuosos e hidratados y zonas de exploración.", "TES tiene 3.5 y 7.5 km por píxel; con los umbrales del equipo todo Meridiani sale amarillo."],
        ["Mapas completos y marco de contexto", "Mapa base de 40 m de toda la región (CTX de Gale y de Meridiani), imagen de contexto más fina cerca y un recuadro punteado «ÁREA DE RUTAS».", "Fuera del recuadro no hay relieve: las rutas solo se calculan dentro. El mosaico CTX tiene zonas sin dato (negro)."],
        ["Rasgos en el mapa", "Dunas, cráteres de 1 km o más, nombres oficiales, unidades geológicas, minerales y zonas de exploración, con leyenda.", "Pocos nombres por zona; la geología es de escala global."],
        ["Sitios de largo alcance", "Gale (24 km) y Endeavour (22 km), con rejilla de 16 m, para rutas que llegan a todo el alcance de la EVA (unos 12 km).", "La rejilla de 16 m no ve obstáculos pequeños. En Endeavour solo el 23 % de la ventana tiene relieve de 1 m; el resto es de 200 m."],
        ["Seguridad por sitio", "En sitios sin radiación ni clima, aviso fijo y verificaciones pendientes; la dosis usa la línea base de Gale (supuesto).", "RAD y REMS son de Curiosity, en Gale."],
        ["Fuentes en la interfaz", "Botón FUENTES, abajo a la derecha: datos reales, calculados por el equipo y supuestos.", "Los archivos y fechas están en RECURSOS.md."],
    ], [1.45 * inch, 3.3 * inch, W - 4.75 * inch]))
    s.append(P("Pruebas nuevas (M a R)", H3 if 'H3' in globals() else H2))
    s.append(pruebas([
        ("<b>M. Sitios.</b> Tocar el nombre del sitio y elegir «Meridiani · Borde de Endeavour», luego «Zona habitable» y «Contexto regional».", "Cada sitio carga en pocos segundos con su ortofoto y sus rutas. La zona habitable y el contexto regional muestran el aviso ámbar de rutas indicativas."),
        ("<b>N. Misiones.</b> Tocar el nombre de la misión, crear una nueva, escribir un consumible, cerrar la app del todo y volver a abrirla.", "La app abre la misión que estaba abierta y conserva sus objetivos, notas y consumibles."),
        ("<b>O. Transporte.</b> Elegir el modo «Por objetivo», tocar un objetivo y cambiar su transporte a Híbrido o Vehículo.", "Las rutas se recalculan; la tarjeta muestra los metros en vehículo o un aviso (por ejemplo «el vehículo no llega»)."),
        ("<b>P. Capas.</b> En el contexto regional encender zonas de tránsito, minerales y zonas de exploración.", "Aparecen las capas con su leyenda; el mapa sigue fluido al acercar y alejar."),
        ("<b>R. Mapas completos y largo alcance.</b> Elegir «Gale · Alcance de la EVA (24 km)», alejar el mapa con los dedos hasta ver el recuadro punteado y encender nombres, cráteres y geología.", "El mapa se ve sin bordes negros cerca del sitio; el recuadro marca el área de rutas; las rutas llegan más lejos que en el sitio de 4 km."),
        ("<b>Q. Seguridad y fuentes.</b> En Meridiani abrir SEGURIDAD y luego tocar FUENTES.", "SEGURIDAD dice que no hay mediciones de radiación ni de clima; FUENTES separa datos reales, calculados y supuestos."),
    ]))
    s.append(PageBreak())

    # ------------------------------------------------------------ 8. Estado y qué sigue
    s.append(P("8. Estado y qué sigue", H1))
    s.append(tabla([
        ["Fase", "Qué entrega", "Estado"],
        ["0. Verificar datos", "Zona, cobertura del modelo de elevación y la ortofoto, hábitat", "<font color='#1B7F46'><b>Cerrada</b></font>"],
        ["1. Preparar datos", "Teselas, pendiente, rejilla de costos, capas y JSON", "<font color='#1B7F46'><b>Cerrada</b></font>"],
        ["2. Rutas y puntajes", "A* con tres perfiles, métricas y puntajes, en Python y Dart", "<font color='#1B7F46'><b>Cerrada</b></font>"],
        ["3. App Flutter", "Mapa, capas, rutas, objetivos, pantallas Plan, Seguridad y Ciencia, ES/EN, Android", "<font color='#1B7F46'><b>Cerrada</b></font> (falta prueba táctil del equipo)"],
        ["4. Seguridad", "Radiación (RAD) y clima (REMS) reales, panel GO / NO-GO con umbrales visibles", "<font color='#1B7F46'><b>Cerrada</b></font>"],
        ["5. Extras", "Fotos reales de Curiosity por objetivo; pantalla de casco como concepto", "<font color='#9A5F00'><b>Hecha</b></font> (sin revisar en la tablet)"],
        ["Extra: modos de salida", "A pie, con rover, rover de apoyo y pareja", "<font color='#9A5F00'><b>Hecho</b></font> (supuestos del equipo)"],
        ["Extra: Meridiani, misiones y transporte", "Siete sitios (Gale y Meridiani), mapas completos sin red, misiones guardadas, transporte por objetivo, capas científicas y de tránsito, fuentes en la interfaz", "<font color='#9A5F00'><b>Hecho</b></font> (v0.7; revisado en parte en la tablet)"],
        ["6. Entrega", "Video, texto, declaración de uso de IA, lista de fuentes", "En curso: APK y guía listos; faltan video y texto"],
    ], [1.35 * inch, W - 3.4 * inch, 2.05 * inch]))
    s.append(P("Qué sigue, en orden", H2))
    s.extend(bullets([
        "<b>Que el equipo pruebe la versión 0.7 en la tablet</b> con las pruebas de la sección 6 (en especial K y L) y las de la sección 7.5 (M a R), y reporte los fallos.",
        "<b>Capas científicas en Gale</b> (minerales, tránsito): faltan datos de TES recortados para Gale; no hay mineral de Hynek en Meridiani.",
        "<b>Recorrido de Opportunity:</b> no se halló la URL de MMGIS para MER.",
        "<b>Pulidos:</b> lectura de coordenadas al mantener pulsado (táctil), guardar objetivos al cerrar, que el recálculo no bloquee la pantalla, APK por arquitectura, tipografía IBM Plex Sans.",
        "<b>Fase 6 (entrega):</b> video de demostración, texto, declaración de uso de IA y lista de fuentes.",
    ]))
    s.append(P("Decisiones que necesitamos del equipo", H2))
    s.extend(bullets([
        "<b>Fecha de entrega y tamaño del equipo.</b> Define hasta qué fase se llega.",
        "<b>Permiso para descargar la tipografía IBM Plex Sans</b> (licencia libre) y ser fieles al diseño.",
        "<b>Supuestos del traje y del rover:</b> velocidad, duración de la salida, oxígeno, límite de pendiente del rover y separación de la pareja. ¿Alguien tiene valores de referencia de la NASA que podamos citar?",
        "<b>Quién prueba en qué tablets</b> y cuándo entregan sus reportes.",
    ]))
    s.append(recuadro("Uso de IA (obligatorio declararlo en la entrega)", [
        "El hackathon permite IA para escribir, depurar y documentar código, resumir documentación y prototipar interfaces. Cada resultado de IA que entra al proyecto se registra en "
        "<font name='Mono'>AI_USAGE.md</font>. Este documento también se redactó con ayuda de IA.",
    ]))

    # ------------------------------------------------------------ Anexos
    s.append(P("Anexo A. Parámetros del modelo (supuestos del equipo)", H1))
    s.append(P("Viven en <font name='Mono'>config/params.json</font>, la única fuente de parámetros para Python y Dart. Ninguno es un estándar de la NASA."))
    s.append(tabla([
        ["Parámetro", "Valor", "Parámetro", "Valor"],
        ["Velocidad en llano", "2.0 km/h", "Pendiente nominal", "menos de 10°"],
        ["Curva de pendiente", "Tobler (k = 3.5)", "Pendiente de precaución", "10° a 20°"],
        ["Duración máxima de la salida", "6 h", "Precaución alta (transitable)", "20° a 25°"],
        ["Capacidad de oxígeno", "8 h a ritmo nominal", "Prohibida", "más de 25°"],
        ["Reserva mínima de oxígeno", "20 %", "Límite del perfil seguro", "22°"],
        ["Gasto extra al subir", "factor 3 sobre la tangente", "Límite de rápida y ciencia", "25°"],
        ["Gasto en paradas de trabajo", "0.8 del nominal", "Regreso a pie (línea recta)", "0.75 h a 2 km/h = 1.5 km"],
        ["Dosis de radiación (ejemplo)", "0.65 mSv/día", "Margen cómodo (ciencia)", "tiempo ≥ 25 %; O<sub>2</sub> ≥ reserva + 30 puntos"],
    ], [1.75 * inch, 1.4 * inch, 1.9 * inch, W - 5.05 * inch]))
    s.append(Spacer(1, 4))
    s.append(KeepTogether([
        tabla([
            ["Perfil", "Peso pendiente", "Peso rugosidad", "Peso tiempo", "Límite de pendiente"],
            ["Segura", "12", "4", "0.5", "22°"],
            ["Rápida", "0.5", "0.2", "1.0", "25°"],
            ["Ciencia", "4", "1.5", "0.5", "25°"],
        ], [1.2 * inch, 1.4 * inch, 1.4 * inch, 1.3 * inch, W - 5.3 * inch]),
        P("Pesos del peligro: pendiente 30, terreno 15, regreso a pie 20, consumibles 20, radiación 5, condiciones del día 10 (hoy 0).", SMALL),
    ]))

    s.append(P("Anexo B. Estructura del proyecto y comandos", H1))
    s.append(tabla([
        ["Carpeta o archivo", "Contenido"],
        ["PLAN.md, PROPUESTA.md, RECURSOS.md, AI_USAGE.md", "Plan por fases con resultados, qué se construye y por qué, fuentes con URL y registro de uso de IA"],
        ["config/", "<font name='Mono'>params.json</font> (parámetros) y <font name='Mono'>objectives.json</font> (objetivos de demostración)"],
        ["tools/", "Scripts de Python: preparación de datos, rutas de referencia, pruebas y comparación con Curiosity"],
        ["app/", "Proyecto Flutter: <font name='Mono'>lib/</font> (código), <font name='Mono'>assets/</font> (datos), <font name='Mono'>test/</font> (pruebas)"],
        ["docs/", "Capturas de comprobación de cada fase y este documento"],
        ["dist/", "El APK instalable"],
        ["data/", "Descargas originales y archivos intermedios (no se versionan)"],
        ["stitch/", "Prototipo visual de cinco pantallas, con valores de ejemplo"],
    ], [2.6 * inch, W - 2.6 * inch]))
    s.append(Spacer(1, 4))
    cmds = ("# Ejecutar en Chrome\n"
            "cd app\n"
            "~/fvm/versions/3.47.7/bin/flutter run -d chrome\n\n"
            "# Instalar en la tablet conectada (modo release)\n"
            "cd app\n"
            "~/fvm/versions/3.47.7/bin/flutter run -d &lt;id-tablet&gt; --release\n\n"
            "# Pruebas de Dart (16) y de Python (9)\n"
            "cd app && ~/fvm/versions/3.47.7/bin/flutter test\n"
            "cd tools && python3 -m unittest test_routing\n\n"
            "# Rehacer los datos y exportarlos a la app (desde tools/)\n"
            "python3 01_recortar.py\n"
            "python3 02_pendiente.py\n"
            "python3 03_costos.py\n"
            "python3 04_exportar.py")
    s.append(Table([[XPreformatted(cmds, MONO)]], colWidths=[W], style=TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), SOFT), ("BOX", (0, 0), (-1, -1), 0.5, LINE),
        ("LEFTPADDING", (0, 0), (-1, -1), 8), ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 6)])))

    s.append(P("Anexo C. Glosario", H1))
    s.append(tabla([
        ["Término", "Significado"],
        ["EVA", "Actividad extravehicular: la caminata del astronauta."],
        ["Boxwork", "Red de crestas bajas, de 1 a 2 m de alto, que Curiosity estudió en 2025 en las faldas del Monte Sharp."],
        ["HiRISE", "Cámara del orbitador MRO de la NASA; da la ortofoto de 25 cm por píxel."],
        ["DEM / DTM", "Modelo digital de elevación: de él se calculan la pendiente y la rugosidad."],
        ["MSL / Curiosity", "Misión y rover de la NASA que explora el cráter Gale desde 2012."],
        ["RAD / REMS", "Instrumentos de Curiosity: RAD mide radiación en superficie; REMS mide clima (temperatura, presión, ultravioleta)."],
        ["THEMIS / CRISM", "Instrumentos orbitales: THEMIS da inercia térmica (roca firme o arena suelta); CRISM da minerales."],
        ["PDS", "Planetary Data System: el archivo oficial de datos planetarios de la NASA."],
        ["A*", "Algoritmo de búsqueda de caminos. Es determinista y explicable: cada giro tiene una causa que se puede mostrar. No usa IA."],
        ["Punto de no retorno (PNR)", "Primer punto de la ruta desde el que terminar cuesta menos que deshacer lo andado."],
        ["Sol", "Día marciano (unas 24 h 40 min). Los datos de Curiosity se indexan por sol."],
        ["Teselas", "Pedazos cuadrados de imagen en varios niveles de detalle, para mostrar el mapa rápido a cualquier zoom."],
    ], [1.8 * inch, W - 1.8 * inch]))
    return s


def main():
    doc = BaseDocTemplate(SALIDA, pagesize=letter, leftMargin=0.75 * inch, rightMargin=0.75 * inch, topMargin=0.7 * inch, bottomMargin=0.85 * inch,
                          title="ARES PATH — Guía de la aplicación y de pruebas para el equipo", author="Equipo ARES PATH",
                          subject="NASA Space Apps Challenge 2026 · Martian Map")
    doc.addPageTemplates([PageTemplate(id="p", frames=[Frame(doc.leftMargin, doc.bottomMargin, doc.width, doc.height, id="f")], onPage=pie)])
    doc.build(construir())
    print("escrito", SALIDA, f"{os.path.getsize(SALIDA) / 1e6:.2f} MB")


if __name__ == "__main__":
    main()

"""Contexto geológico: mapa geológico global de Marte (USGS SIM 3292), de las teselas WMTS de Mars Trek.

El mapa es de escala global (1:20 000 000). En el recuadro de 4 x 4 km sale una sola unidad, así que NO se dibuja
como capa (sería un color plano): solo se averigua qué unidad es, comparando el color de la tesela con la leyenda
del servicio, y se guarda en data/work/geologia_stats.json. La app lo muestra como texto en la pantalla Ciencia.
Leyenda: https://trek.nasa.gov/mars/trekarcgis/rest/services/SIM3292_Global_Geology/MapServer/legend?f=json

Uso: python3 08_geologia.py [--descargar]
"""
import base64
import io
import json
import math
import os
import sys
import urllib.request

import numpy as np
from PIL import Image

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRODUCTO = "SIM3292_Global_Geology"
LEYENDA = "https://trek.nasa.gov/mars/trekarcgis/rest/services/%s/MapServer/legend?f=json" % PRODUCTO
URL = ("https://trek.nasa.gov/mars/trekarcgis/rest/services/%s/MapServer/WMTS/tile/1.0.0/%s/default/default028mm/%d/%d/%d.png")
Z = 9  # el servicio solo trae datos hasta el nivel 9; del 10 en adelante devuelve teselas vacías
GRADOS = 360.0 / 2 ** (Z + 1)
CRUDO = os.path.join(RAIZ, "data", "raw", "geologia")

STATS = os.path.join(RAIZ, "data", "work", "geologia_stats.json")
SALIDA_PX = 500  # 8 m por píxel en 4000 m


def main():
    site = json.load(open(os.path.join(RAIZ, "app", "assets", "site_gale", "site.json")))
    g = site["georeference"]
    R, e0, n0, lado = g["radius_m"], g["origin_easting_m"], g["origin_northing_m"], site["frame"]["size_m"]
    lon_w, lon_e = math.degrees(e0 / R), math.degrees((e0 + lado) / R)
    lat_n, lat_s = math.degrees(n0 / R), math.degrees((n0 - lado) / R)
    c0, c1 = math.floor((lon_w + 180) / GRADOS), math.floor((lon_e + 180) / GRADOS)
    r0, r1 = math.floor((90 - lat_n) / GRADOS), math.floor((90 - lat_s) / GRADOS)
    os.makedirs(CRUDO, exist_ok=True)
    mosaico = np.zeros(((r1 - r0 + 1) * 256, (c1 - c0 + 1) * 256, 4), np.uint8)
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            ruta = os.path.join(CRUDO, "z%d_%d_%d.png" % (Z, r, c))
            if not os.path.exists(ruta) or "--descargar" in sys.argv:
                urllib.request.urlretrieve(URL % (PRODUCTO, PRODUCTO, Z, r, c), ruta)
            y, x = (r - r0) * 256, (c - c0) * 256
            mosaico[y:y + 256, x:x + 256] = np.asarray(Image.open(ruta).convert("RGBA"))
    xs = (np.arange(SALIDA_PX) + 0.5) * lado / SALIDA_PX
    lon = np.degrees((e0 + xs) / R)
    lat = np.degrees((n0 - xs) / R)
    col = np.floor(((lon + 180) / GRADOS - c0) * 256).astype(int)
    fila = np.floor(((90 - lat) / GRADOS - r0) * 256).astype(int)
    salida = mosaico[fila[:, None], col[None, :]]
    leyenda = json.load(urllib.request.urlopen(LEYENDA, timeout=60))["layers"][0]["legend"]
    por_color = {}
    for e in leyenda:
        im = Image.open(io.BytesIO(base64.b64decode(e["imageData"]))).convert("RGBA")
        por_color[im.getpixel((im.width // 2, im.height // 2))] = e["label"]
    colores, cuenta = np.unique(salida.reshape(-1, 4), axis=0, return_counts=True)
    unidades = [{"unidad": por_color.get(tuple(int(v) for v in c)), "rgba": [int(v) for v in c], "pct": round(100.0 * n / salida.shape[0] / salida.shape[1], 1)} for c, n in zip(colores, cuenta)]
    os.makedirs(os.path.dirname(STATS), exist_ok=True)
    json.dump({"producto": PRODUCTO, "teselas": [Z, r0, r1, c0, c1], "px_nativo_m": GRADOS * math.pi / 180 * R / 256, "colores": unidades}, open(STATS, "w"), indent=1)
    print("teselas", Z, r0, r1, c0, c1, "| m/px nativo %.1f" % (GRADOS * math.pi / 180 * R / 256))
    print("colores distintos:", len(unidades), sorted(unidades, key=lambda u: -u["pct"])[:6])
    print("unidades:", [(u["unidad"], u["pct"]) for u in unidades])


main()

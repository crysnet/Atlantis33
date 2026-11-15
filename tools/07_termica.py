"""Capa térmica de la app: THEMIS-IR día (Mars Odyssey), de las teselas WMTS de Mars Trek.

Descarga unas pocas teselas del nivel 9 (unos 81 m por píxel; el mosaico es de 100 m),
las une, las remuestrea al plano local de 4 x 4 km (8 m por píxel) y las colorea.
Salida: app/assets/site_gale/layers/thermal.png y data/work/themis_stats.json.

El valor del píxel es un brillo relativo (la tesela viene ya estirada a 8 bits),
no una temperatura calibrada. La app lo marca así.

Uso: python3 07_termica.py [--descargar]
"""
import json
import math
import os
import sys
import urllib.request

import numpy as np
from PIL import Image
from scipy.ndimage import map_coordinates

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PRODUCTO = "THEMIS_DayIR_ControlledMosaics_100m_v2_oct2018"
URL = "https://trek.nasa.gov/tiles/Mars/EQ/%s/1.0.0/default/default028mm/%d/%d/%d.png"
Z = 9
GRADOS = 360.0 / 2 ** (Z + 1)  # el nivel 9 tiene 1024 x 512 teselas de 256 px
CRUDO = os.path.join(RAIZ, "data", "raw", "themis")
SALIDA = os.path.join(RAIZ, "app", "assets", "site_gale", "layers", "thermal.png")
STATS = os.path.join(RAIZ, "data", "work", "themis_stats.json")
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
    mosaico = np.zeros(((r1 - r0 + 1) * 256, (c1 - c0 + 1) * 256), np.float32)
    alfa = np.zeros_like(mosaico)
    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            ruta = os.path.join(CRUDO, "z%d_%d_%d.png" % (Z, r, c))
            if not os.path.exists(ruta) or "--descargar" in sys.argv:
                urllib.request.urlretrieve(URL % (PRODUCTO, Z, r, c), ruta)
            im = np.asarray(Image.open(ruta).convert("LA"), np.float32)
            y, x = (r - r0) * 256, (c - c0) * 256
            mosaico[y:y + 256, x:x + 256] = im[..., 0]
            alfa[y:y + 256, x:x + 256] = im[..., 1]
    # píxel (fila, col) de cada celda de salida; el centro del píxel está a +0.5
    xs = (np.arange(SALIDA_PX) + 0.5) * lado / SALIDA_PX
    lon = np.degrees((e0 + xs) / R)
    lat = np.degrees((n0 - xs) / R)
    col = ((lon + 180) / GRADOS - c0) * 256 - 0.5
    fila = ((90 - lat) / GRADOS - r0) * 256 - 0.5
    cc, ff = np.meshgrid(col, fila)
    v = map_coordinates(mosaico, [ff, cc], order=1, mode="nearest")
    a = map_coordinates(alfa, [ff, cc], order=1, mode="nearest")
    lo, hi = np.percentile(v, [1, 99])
    t = np.clip((v - lo) / (hi - lo), 0, 1)
    # paleta frío (azul oscuro) a cálido (amarillo claro)
    paradas = np.array([0.0, 0.35, 0.7, 1.0])
    colores = np.array([[20, 24, 90], [150, 40, 130], [235, 100, 50], [255, 235, 150]], np.float32)
    rgb = np.stack([np.interp(t, paradas, colores[:, i]) for i in range(3)], -1)
    rgba = np.dstack([rgb, np.where(a > 0, 255, 0)]).astype(np.uint8)
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    Image.fromarray(rgba, "RGBA").save(SALIDA, optimize=True)
    os.makedirs(os.path.dirname(STATS), exist_ok=True)
    json.dump({"producto": PRODUCTO, "teselas": [Z, r0, r1, c0, c1], "px_nativo_m": GRADOS * math.pi / 180 * R / 256,
               "salida_px": SALIDA_PX, "p1": float(lo), "p99": float(hi), "min": float(v.min()), "max": float(v.max()),
               "alfa_min": float(a.min())}, open(STATS, "w"), indent=1)
    print("tesela", r0, r1, c0, c1, "| m/px nativo %.1f" % (GRADOS * math.pi / 180 * R / 256), "| rango", v.min(), v.max(), "| p1-p99", lo, hi, "| alfa min", a.min())
    print("escrito", SALIDA, os.path.getsize(SALIDA), "bytes")


main()

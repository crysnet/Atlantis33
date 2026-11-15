"""Capa de tránsito (TES) para los dos sitios de Gale.

Entrada: data/raw/asu/dci_16ppd.raw (DCI global, 3.5 km por píxel) y data/raw/asu/ti_gale.vicar (inercia térmica de TES,
recorte 127 a 147° E, -12.5 a 12.5° N, 0.125° por píxel, bajado del servicio WMS de ASU; ver RECURSOS.md).
Salida: layers/transit.png en site_gale y site_gale_reach, y su entrada en `layers` de cada site.json.
Usa los mismos umbrales y colores que Meridiani (tools/12_capas_meridiani.py). La ventana de 4 km cabe en un píxel de TES: un solo color.
Uso: python3 21_tes_gale.py
"""
import importlib.util
import json
import math
import os

import numpy as np
from PIL import Image

import common

_spec = importlib.util.spec_from_file_location("capas12", os.path.join(os.path.dirname(os.path.abspath(__file__)), "12_capas_meridiani.py"))
capas = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(capas)

R = common.R_MARTE
ASSETS = os.path.join(common.RAIZ, "app", "assets")
SITIOS = ["site_gale", "site_gale_reach"]
LON0, LAT1, PASO = 127.0, 12.5, 0.125  # esquina noroeste y tamaño de píxel del recorte de inercia térmica


def cargar_ti():
    b = np.fromfile(os.path.join(common.RAW, "asu", "ti_gale.vicar"), dtype="u1")
    return np.frombuffer(b[640:].tobytes(), dtype="<i4").reshape(200, 160)


def capa(site, salida, dci, ti):
    g = site["georeference"]
    lado = site["frame"]["size_m"]
    n = 250
    img = np.zeros((n, n, 4), np.uint8)
    cuenta = {k: 0 for k in capas.COLORES}
    vals = []
    for i in range(n):
        for j in range(n):
            x, y = (j + 0.5) / n * lado, (i + 0.5) / n * lado
            lon = math.degrees((g["origin_easting_m"] + x) / R) % 360.0
            lat = math.degrees((g["origin_northing_m"] - y) / R)
            d = float(dci[int((90.0 - lat) * 16), int(((lon + 180.0) % 360.0) * 16)])
            t = float(ti[int((LAT1 - lat) / PASO), int((lon - LON0) / PASO)])
            c = capas.clasificar(d, t)
            img[i, j] = capas.COLORES[c]
            cuenta[c] += 1
            vals.append((d, t))
    os.makedirs(os.path.join(salida, "layers"), exist_ok=True)
    Image.fromarray(img, "RGBA").save(os.path.join(salida, "layers", "transit.png"), optimize=True)
    v = np.array(vals)
    res = {k: round(c / (n * n), 4) for k, c in cuenta.items()}
    print(f"  transit.png: DCI {v[:, 0].min():.3f} a {v[:, 0].max():.3f}, inercia {v[:, 1].min():.0f} a {v[:, 1].max():.0f}; clases {res}")
    return {"dci_min": float(v[:, 0].min()), "dci_max": float(v[:, 0].max()), "ti_min": float(v[:, 1].min()), "ti_max": float(v[:, 1].max()), "fractions": res}


def main():
    dci, ti = capas.cargar_dci(), cargar_ti()
    for nombre in SITIOS:
        print("==", nombre)
        salida = os.path.join(ASSETS, nombre)
        ruta = os.path.join(salida, "site.json")
        site = json.load(open(ruta, encoding="utf-8"))
        stats = capa(site, salida, dci, ti)
        entrada = {"id": "transit", "kind": "modeled", "file": "layers/transit.png", "source": "TES Dust Cover Index (ASU, 3.5 km/px) and TES thermal inertia (ASU, 7.5 km/px) combined with the team's thresholds", "resolution_m": 3500.0, "stats": stats}
        site["layers"] = [q for q in site["layers"] if q["id"] != "transit"] + [entrada]
        with open(ruta, "w", encoding="utf-8") as f:
            json.dump(site, f, indent=2)


if __name__ == "__main__":
    main()

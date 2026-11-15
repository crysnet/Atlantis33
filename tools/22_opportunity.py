"""Recorrido de Opportunity (MER-B) en las ventanas de Meridiani, y registro de la capa de tránsito de Gale.

Entrada: data/raw/opportunity/MERB_traverse_5130.csv (PDS Geosciences Node; posiciones corregidas CORRECTED_X / CORRECTED_Y en metros
al este y al norte del sitio de aterrizaje, Eagle Crater; ver RECURSOS.md).
Se proyecta a cada sitio con una esfera local alrededor del punto de aterrizaje (lat -1.9462, lon 354.4734 E, valor publicado por la NASA)
y se escribe `curiosity_waypoints.json` (el nombre es heredado: el archivo lleva el recorrido del rover del sitio; en Meridiani es Opportunity).
Se descartan puntos a menos de 20 m del anterior. La posición es aproximada: la CSV no dice el datum y el punto de aterrizaje lleva su propio error.
También añade `opportunity` a las capas de los sitios de Meridiani y `transit` a las de Gale en `app/assets/sites.json`.
Uso: python3 22_opportunity.py
"""
import csv
import json
import math
import os

import common

R = common.R_MARTE
ASSETS = os.path.join(common.RAIZ, "app", "assets")
SITIOS = ["site_meridiani_endeavour", "site_meridiani_habitat", "site_meridiani_regional", "site_meridiani_endeavour_reach"]
LAT0, LON0 = -1.9462, -5.5266  # Eagle Crater (354.4734 E)
CSV = os.path.join(common.RAW, "opportunity", "MERB_traverse_5130.csv")


def leer():
    pts = []
    with open(CSV, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            pts.append((int(r["END_SOL"]), float(r["CORRECTED_X"]), float(r["CORRECTED_Y"])))
    return pts


def a_lonlat(x, y):
    lat = LAT0 + math.degrees(y / R)
    lon = LON0 + math.degrees(x / (R * math.cos(math.radians(LAT0))))
    return lon, lat


def main():
    pts = leer()
    print(f"{len(pts)} filas; fin del recorrido: {a_lonlat(pts[-1][1], pts[-1][2])}")
    con_puntos = set()
    for nombre in SITIOS:
        ruta = os.path.join(ASSETS, nombre, "site.json")
        site = json.load(open(ruta, encoding="utf-8"))
        g = site["georeference"]
        lado = site["frame"]["size_m"]
        salida, ult = [], None
        for sol, x, y in pts:
            lon, lat = a_lonlat(x, y)
            lx = math.radians(lon) * R - g["origin_easting_m"]
            ly = g["origin_northing_m"] - math.radians(lat) * R
            if not (-lado <= lx <= 2 * lado and -lado <= ly <= 2 * lado):
                continue
            if ult is not None and math.hypot(lx - ult[0], ly - ult[1]) < 20:
                continue
            ult = (lx, ly)
            salida.append({"sol": sol, "x_m": round(lx, 1), "y_m": round(ly, 1), "elev_m": 0.0, "boxwork_campaign": False})
        doc = {
            "source": "Opportunity (MER-B) corrected traverse, PDS Geosciences Node (MERB_traverse_5130.csv, T. Parker); position approximate",
            "kind": "measured",
            "rover": "Opportunity",
            "points": salida,
        }
        with open(os.path.join(ASSETS, nombre, "curiosity_waypoints.json"), "w", encoding="utf-8") as f:
            json.dump(doc, f, separators=(",", ":"))
        print(f"{nombre}: {len(salida)} puntos")
        if salida:
            con_puntos.add(nombre)

    ruta = os.path.join(ASSETS, "sites.json")
    reg = json.load(open(ruta, encoding="utf-8"))
    for s in reg["sites"]:
        ids = s["layers"]
        if s["asset_dir"] in con_puntos and "opportunity" not in ids:
            ids.insert(ids.index("forbidden") + 1, "opportunity")
        if s["asset_dir"] in ("site_gale", "site_gale_reach") and "transit" not in ids:
            ids.insert(ids.index("thermal") + 1 if "thermal" in ids else ids.index("curiosity") + 1, "transit")
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(reg, f, indent=2, ensure_ascii=False)
        f.write("\n")


if __name__ == "__main__":
    main()

"""F5: capas científicas y de tránsito de los tres sitios de Meridiani.

Entrada: data/raw/asu/ (DCI y inercia térmica de TES), data/raw/trek_vectores/ (minerales y zonas de exploración, Mars Trek),
         data/raw/meridiani_regional/themis_noche_z9/ (THEMIS-IR noche, Mars Trek), app/assets/site_meridiani_*/site.json
Salida en cada app/assets/site_meridiani_*/:
  layers/transit.png        zonas de tránsito por DCI e inercia térmica de TES (verde, amarillo, rojo), con la resolución real de TES
  layers/thermal_night.png  THEMIS-IR de noche (81 m por píxel en las teselas de nivel 9): brillo relativo, proxy de inercia térmica
  (vectors.json y los marcos de contexto los genera 14_contexto_y_rasgos.py)
  y añade las capas a `layers` de site.json.

Reglas de tránsito (propuesta del usuario, sin fuente citada: son supuestos; los huecos quedan «sin clasificar»):
  verde    DCI > 0.96 e inercia térmica > 300
  amarillo DCI > 0.95 e inercia térmica de 180 a 300
  rojo     DCI < 0.94 e inercia térmica < 150  (evitar)
El DCI de TES tiene 3.5 km por píxel y la inercia térmica, 7.5 km: en una ventana de 4 km la capa es de un solo color.

Uso (desde tools/): python3 12_capas_meridiani.py
"""
import importlib.util
import json
import math
import os

import numpy as np
from PIL import Image

import common

_spec = importlib.util.spec_from_file_location("datos10", os.path.join(os.path.dirname(os.path.abspath(__file__)), "10_meridiani_datos.py"))
datos = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(datos)

R = common.R_MARTE
ASSETS = os.path.join(common.RAIZ, "app", "assets")
SITIOS = ["site_meridiani_endeavour", "site_meridiani_habitat", "site_meridiani_regional"]
ASU = os.path.join(common.RAW, "asu")
VEC = os.path.join(common.RAW, "trek_vectores")

COLORES = {"green": (60, 170, 92, 175), "yellow": (230, 170, 40, 175), "red": (210, 50, 50, 175), "none": (150, 150, 150, 70)}


def cargar_dci():
    return np.fromfile(os.path.join(ASU, "dci_16ppd.raw"), dtype="<f4").reshape(2880, 5760)


def cargar_ti():
    b = np.fromfile(os.path.join(ASU, "ti_meridiani.vicar"), dtype="u1")
    return np.frombuffer(b[960:].tobytes(), dtype="<i4").reshape(200, 240)  # lon 330 a 360 E, lat 10 a -15, 0.125° por píxel


def clasificar(dci, ti):
    if dci > 0.96 and ti > 300:
        return "green"
    if dci > 0.95 and 180 <= ti <= 300:
        return "yellow"
    if dci < 0.94 and ti < 150:
        return "red"
    return "none"


def capa_transito(site, salida, dci, ti):
    g = site["georeference"]
    lado = site["frame"]["size_m"]
    n = 250
    img = np.zeros((n, n, 4), np.uint8)
    cuenta = {k: 0 for k in COLORES}
    vals = []
    for i in range(n):
        for j in range(n):
            x, y = (j + 0.5) / n * lado, (i + 0.5) / n * lado
            lon = math.degrees((g["origin_easting_m"] + x) / R)
            lat = math.degrees((g["origin_northing_m"] - y) / R)
            d = float(dci[int((90.0 - lat) * 16), int((lon + 180.0) * 16)])
            t = float(ti[int((10.0 - lat) / 0.125), int(((lon % 360.0) - 330.0) / 0.125)])
            c = clasificar(d, t)
            img[i, j] = COLORES[c]
            cuenta[c] += 1
            vals.append((d, t))
    Image.fromarray(img, "RGBA").save(os.path.join(salida, "layers", "transit.png"), optimize=True)
    v = np.array(vals)
    res = {k: round(c / (n * n), 4) for k, c in cuenta.items()}
    print(f"  transit.png: DCI {v[:, 0].min():.3f} a {v[:, 0].max():.3f}, inercia {v[:, 1].min():.0f} a {v[:, 1].max():.0f}; clases {res}")
    return {"dci_min": float(v[:, 0].min()), "dci_max": float(v[:, 0].max()), "ti_min": float(v[:, 1].min()), "ti_max": float(v[:, 1].max()), "fractions": res}


def mosaico_themis():
    """Une las teselas THEMIS de noche. Devuelve (gris, lon0, lat1, deg) de la esquina noroeste del mosaico."""
    z = 9
    carpeta = os.path.join(datos.RAW_R, "themis_noche_z9")
    lista, deg = datos.teselas_de(datos.REGIONAL, z)
    r0, r1 = min(r for r, _ in lista), max(r for r, _ in lista)
    c0, c1 = min(c for _, c in lista), max(c for _, c in lista)
    gris = np.zeros(((r1 - r0 + 1) * 256, (c1 - c0 + 1) * 256), np.uint8)
    for r, c in lista:
        ruta = os.path.join(carpeta, str(z), str(r), f"{c}.png")
        if os.path.exists(ruta):
            gris[(r - r0) * 256:(r - r0 + 1) * 256, (c - c0) * 256:(c - c0 + 1) * 256] = np.asarray(Image.open(ruta).convert("L"))
    return gris, c0, r0, deg


def capa_termica(site, salida, mos, lim):
    gris, c0, r0, deg = mos
    g = site["georeference"]
    lado = site["frame"]["size_m"]
    lon0 = math.degrees(g["origin_easting_m"] / R)
    lat1 = math.degrees(g["origin_northing_m"] / R)
    lon1 = math.degrees((g["origin_easting_m"] + lado) / R)
    lat0 = math.degrees((g["origin_northing_m"] - lado) / R)
    box = (((lon0 + 180.0) / deg - c0) * 256.0, ((90.0 - lat1) / deg - r0) * 256.0, ((lon1 + 180.0) / deg - c0) * 256.0, ((90.0 - lat0) / deg - r0) * 256.0)
    n = 1250 if lado > 50000 else 500
    # estiramiento de contraste común a los tres sitios (percentiles 2 y 98 de la ventana regional)
    est = np.clip((gris.astype("float32") - lim[0]) / (lim[1] - lim[0]), 0.0, 1.0)
    im = Image.fromarray((est * 255).astype("uint8"), "L").resize((n, n), Image.BICUBIC, box=box)
    im.save(os.path.join(salida, "layers", "thermal_night.png"), optimize=True)
    a = np.asarray(im)
    print(f"  thermal_night.png: {n} x {n} px, brillo medio {a.mean():.0f}")


def anillo(coords, maximo=72):
    pts = coords[0] if isinstance(coords[0][0], (list, tuple)) else coords
    paso = max(1, len(pts) // maximo)
    return pts[::paso]


def vectores(site, salida):
    g = site["georeference"]
    x0, y0, lado = g["origin_easting_m"], g["origin_northing_m"], site["frame"]["size_m"]

    def loc(lon, lat):
        return R * math.radians(lon) - x0, y0 - R * math.radians(lat)

    def dentro(x, y, margen=0.15):
        return -margen * lado <= x <= (1 + margen) * lado and -margen * lado <= y <= (1 + margen) * lado

    feats = []
    vistos = set()
    for f in json.load(open(os.path.join(VEC, "acuosos_meridiani.geojson")))["features"]:
        lon, lat = f["geometry"]["coordinates"]
        x, y = loc(lon, lat)
        clave = (round(lon, 3), round(lat, 3), f["properties"]["Class"])
        if clave in vistos or not dentro(x, y):
            continue
        vistos.add(clave)
        feats.append({"kind": "mineral", "cls": f["properties"]["Class"], "source": "aqueous", "x_m": round(x, 1), "y_m": round(y, 1)})
    for f in json.load(open(os.path.join(VEC, "hidratados_meridiani.geojson")))["features"]:
        lon, lat = f["geometry"]["coordinates"]
        x, y = loc(lon, lat)
        if dentro(x, y):
            feats.append({"kind": "mineral", "cls": "hydrous", "source": f["properties"]["Instrument"], "x_m": round(x, 1), "y_m": round(y, 1)})
    for archivo, tipo in (("ez_puntos_meridiani.geojson", "ez"), ("ezmars_capa1.geojson", "habitation"), ("ezmars_capa2.geojson", "landing")):
        for f in json.load(open(os.path.join(VEC, archivo)))["features"]:
            lon, lat = f["geometry"]["coordinates"]
            x, y = loc(lon, lat)
            if dentro(x, y):
                feats.append({"kind": "zone", "type": tipo, "name": f["properties"]["name"], "x_m": round(x, 1), "y_m": round(y, 1)})
    for archivo, tipo in (("ezmars_capa3.geojson", "roi"), ("ezmars_capa4.geojson", "ez_radius")):
        for f in json.load(open(os.path.join(VEC, archivo)))["features"]:
            ring = [[round(a, 1), round(b, 1)] for a, b in (loc(lo, la) for lo, la in anillo(f["geometry"]["coordinates"]))]
            xs, ys = [p[0] for p in ring], [p[1] for p in ring]
            # entra si el recuadro de la figura toca la ventana
            if max(xs) >= 0 and min(xs) <= lado and max(ys) >= 0 and min(ys) <= lado:
                feats.append({"kind": "zone", "type": tipo, "name": f["properties"].get("name", ""), "ring": ring})
    doc = {
        "source": "NASA Mars Trek (JPL): Aqueous Mineral Distribution, Hydrous Mineral Detections (OMEGA, CRISM) and Exploration Zones (NASA EMC, 2015 workshop)",
        "kind": "measured",
        "retrieved": "2026-11-14",
        "features": feats,
    }
    with open(os.path.join(salida, "vectors.json"), "w", encoding="utf-8") as f:
        json.dump(doc, f, separators=(",", ":"))
    cuenta = {}
    for q in feats:
        k = q.get("cls") or q.get("type")
        cuenta[k] = cuenta.get(k, 0) + 1
    print(f"  vectors.json: {len(feats)} elementos {cuenta}")


def main():
    dci, ti = cargar_dci(), cargar_ti()
    mos = mosaico_themis()
    reg = json.load(open(os.path.join(ASSETS, "site_meridiani_regional", "site.json")))
    gr = reg["georeference"]
    # límites de contraste: percentiles 2 y 98 de la parte del mosaico que cubre la ventana regional con datos
    v = mos[0][mos[0] > 0]
    lim = (float(np.percentile(v, 2)), float(np.percentile(v, 98)))
    print(f"THEMIS noche: percentiles 2 y 98 = {lim[0]:.0f}, {lim[1]:.0f}")
    for nombre in SITIOS:
        print("==", nombre)
        salida = os.path.join(ASSETS, nombre)
        ruta = os.path.join(salida, "site.json")
        site = json.load(open(ruta))
        stats = capa_transito(site, salida, dci, ti)
        capa_termica(site, salida, mos, lim)
        ids = {q["id"] for q in site["layers"]}
        nuevas = [
            {"id": "transit", "kind": "modeled", "file": "layers/transit.png", "source": "TES Dust Cover Index (ASU, 3.5 km/px) and TES thermal inertia (ASU, 7.5 km/px) combined with the team's thresholds", "resolution_m": 3500.0, "stats": stats},
            {"id": "thermal_night", "kind": "measured", "file": "layers/thermal_night.png", "source": "THEMIS-IR night mosaic (Mars Odyssey) via NASA Mars Trek; relative brightness, a proxy for thermal inertia", "resolution_m": 100.0},
        ]
        site["layers"] += [q for q in nuevas if q["id"] not in ids]
        with open(ruta, "w", encoding="utf-8") as f:
            json.dump(site, f, indent=2)


if __name__ == "__main__":
    main()

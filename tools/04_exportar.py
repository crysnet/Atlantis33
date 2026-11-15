"""Fase 1, paso 4: exporta a app/assets/site_gale/ lo que consume la app.

Entrada: data/raw/lrgb_box_025m.tif, data/work/ (dem_2m, slope_2m, hillshade_2m), data/work/costos/, config/params.json
Salida en app/assets/site_gale/:
  ortho/{z}/{x}/{y}.jpg   pirámide de teselas de la ortofoto (512 px, z = 0..4)
  layers/slope.png        pendiente coloreada con transparencia, 2000 x 2000 px, 2 m por píxel
  layers/hillshade.png    relieve sombreado en gris, 2000 x 2000 px
  grid/*.bin              rejilla de costos (ver data/work/costos/costos.json)
  curiosity_waypoints.json posiciones reales de Curiosity dentro del recuadro (NASA/JPL), en coordenadas locales
  params.json             copia de config/params.json
  site.json               recuadro, transformaciones, capas, hábitat y esquema de teselas

Sistema de coordenadas de la app: plano local en metros. x crece al este, y crece al sur (como las filas de
imagen), con el origen en la esquina noroeste del recuadro. Un píxel de la rejilla de 2 m ocupa
[col * 2, (col + 1) * 2) en x. No hay proyecciones dentro de la app.

Esquema de teselas: el mundo es un cuadrado de 4096 m (el recuadro de 4000 m más 96 m de relleno negro al este
y al sur). En el nivel z mide 512 * 2^z píxeles de lado, así que z = 0 son 8 m por píxel y z = 4 son 0.5 m.
La tesela (x, y) del nivel z tiene x de oeste a este e y de norte a sur.
"""
import json
import os
import shutil
import sys

import numpy as np
import rasterio
from PIL import Image

import common

MUNDO_M = 4096.0


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def reducir_a_la_mitad(a):
    a = a.astype(np.uint16)
    return ((a[0::2, 0::2] + a[1::2, 0::2] + a[0::2, 1::2] + a[1::2, 1::2] + 2) // 4).astype(np.uint8)


def exportar_teselas(p, salida):
    t = p["tiles"]
    px, zmax = t["tile_px"], t["max_zoom"]
    ruta = os.path.join(salida, "ortho")
    if os.path.isdir(ruta):
        shutil.rmtree(ruta)
    with rasterio.open(common.ORTHO_RAW) as o:
        img = np.ascontiguousarray(np.moveaxis(o.read([1, 2, 3]), 0, -1))  # 16000 x 16000 x 3, 0.25 m
    nivel = reducir_a_la_mitad(img)  # 0.5 m
    del img
    mundo_px = px * 2 ** zmax
    if nivel.shape[0] > mundo_px:
        raise SystemExit("El mosaico no cabe en el nivel máximo")
    lienzo = np.zeros((mundo_px, mundo_px, 3), np.uint8)
    lienzo[: nivel.shape[0], : nivel.shape[1]] = nivel
    del nivel
    total = 0
    cubierto_px = {}
    for z in range(zmax, -1, -1):
        n = lienzo.shape[0] // px
        for ty in range(n):
            for tx in range(n):
                tesela = lienzo[ty * px:(ty + 1) * px, tx * px:(tx + 1) * px]
                d = os.path.join(ruta, str(z), str(tx))
                os.makedirs(d, exist_ok=True)
                Image.fromarray(tesela).save(os.path.join(d, f"{ty}.jpg"), quality=t["jpeg_quality"], optimize=True)
                total += 1
        cubierto_px[z] = n * px
        if z > 0:
            lienzo = np.stack([reducir_a_la_mitad(lienzo[..., c]) for c in range(3)], axis=-1)
    mb = sum(os.path.getsize(os.path.join(r, f)) for r, _, fs in os.walk(ruta) for f in fs) / 1e6
    print(f"teselas: {total} archivos, {mb:.1f} MB")
    return total


def exportar_capas(p, salida):
    os.makedirs(os.path.join(salida, "layers"), exist_ok=True)
    s = p["slope"]
    with rasterio.open(common.SLOPE_2M) as d:
        pend = d.read(1)
    with rasterio.open(common.HILLSHADE_2M) as d:
        hs = d.read(1)
    col = {k: hex_rgb(v) for k, v in s["colors"].items()}
    rgba = np.zeros(pend.shape + (4,), np.uint8)
    v = np.nan_to_num(pend, nan=999.0)
    clases = [
        (v < s["nominal_max_deg"], col["nominal"]),
        ((v >= s["nominal_max_deg"]) & (v < s["caution_max_deg"]), col["caution"]),
        ((v >= s["caution_max_deg"]) & (v <= s["forbidden_above_deg"]), col["high_caution"]),
        (v > s["forbidden_above_deg"], col["forbidden"]),
    ]
    for mascara, c in clases:
        rgba[mascara] = (*c, 255)
    rgba[~np.isfinite(pend)] = (0, 0, 0, 0)
    Image.fromarray(rgba, "RGBA").save(os.path.join(salida, "layers", "slope.png"), optimize=True)
    Image.fromarray(hs, "L").save(os.path.join(salida, "layers", "hillshade.png"), optimize=True)
    print("capas: slope.png y hillshade.png")


def exportar_rejilla(salida):
    d = os.path.join(salida, "grid")
    os.makedirs(d, exist_ok=True)
    for f in ("slope.bin", "rough.bin", "forbidden.bin", "elev.bin"):
        shutil.copy(os.path.join(common.COSTOS_DIR, f), os.path.join(d, f))
    mb = sum(os.path.getsize(os.path.join(d, f)) for f in os.listdir(d)) / 1e6
    print(f"rejilla: 4 archivos, {mb:.1f} MB sin comprimir")


def exportar_waypoints(p, salida, e0, n1, lado):
    wp = json.load(open(common.WAYPOINTS))["features"]
    sol_min, sol_max = p["site"]["boxwork_sol_range"]
    puntos = []
    for f in wp:
        q = f["properties"]
        x, y = q["easting"] - e0, n1 - q["northing"]
        if 0 <= x < lado and 0 <= y < lado:
            puntos.append({
                "sol": q["sol"], "x_m": round(x, 2), "y_m": round(y, 2), "elev_m": q["elev_geoid"],
                "lon": q["lon"], "lat": q["lat"], "boxwork_campaign": sol_min <= q["sol"] <= sol_max,
            })
    doc = {
        "source": "NASA/JPL-Caltech, Curiosity rover waypoints (MSL_waypoints.json)",
        "source_url": "https://mars.nasa.gov/mmgis-maps/MSL/Layers/json/MSL_waypoints.json",
        "retrieved": "2026-11-14",
        "kind": "measured",
        "points": puntos,
    }
    with open(os.path.join(salida, "curiosity_waypoints.json"), "w", encoding="utf-8") as f:
        json.dump(doc, f, separators=(",", ":"))
    print(f"waypoints de Curiosity dentro del recuadro: {len(puntos)}")


def escribir_site(p, salida, e0, n1, lado):
    meta = json.load(open(os.path.join(common.COSTOS_DIR, "costos.json")))
    hab = meta["habitat"]
    wp = json.load(open(os.path.join(salida, "curiosity_waypoints.json")))["points"]
    cam = [q for q in wp if q["boxwork_campaign"]]
    cx = float(np.mean([q["x_m"] for q in cam]))
    cy = float(np.mean([q["y_m"] for q in cam]))
    t = p["tiles"]
    lon_c, lat_c = common.a_lonlat(e0 + lado / 2, n1 - lado / 2)
    site = {
        "id": p["site"]["id"],
        "name": p["site"]["name"],
        "frame": {
            "description": "Local plane in metres. x grows east, y grows south, origin at the north-west corner of the box.",
            "size_m": lado,
        },
        "georeference": {
            "projection": "Mars equirectangular, sphere radius 3396190 m, central meridian 0, planetocentric latitude",
            "radius_m": common.R_MARTE,
            "origin_easting_m": e0,
            "origin_northing_m": n1,
            "easting_m": "origin_easting_m + x_m",
            "northing_m": "origin_northing_m - y_m",
            "lon_deg": "degrees(easting_m / radius_m)",
            "lat_deg": "degrees(northing_m / radius_m)",
            "center_lon_deg": lon_c,
            "center_lat_deg": lat_c,
        },
        "grid": {
            "cell_m": meta["cell_m"], "width": meta["width"], "height": meta["height"],
            "order": meta["order"], "components": meta["components"],
        },
        "tiles": {
            "template": "ortho/{z}/{x}/{y}.jpg",
            "tile_px": t["tile_px"], "min_zoom": 0, "max_zoom": t["max_zoom"],
            "world_size_m": MUNDO_M,
            "m_per_px": [MUNDO_M / (t["tile_px"] * 2 ** z) for z in range(t["max_zoom"] + 1)],
            "covered_size_m": lado,
        },
        "habitat": {
            "x_m": hab["easting"] - e0, "y_m": n1 - hab["northing"], "col": hab["col"], "row": hab["row"],
            "lon": hab["lon"], "lat": hab["lat"], "elevation_m": hab["elevation_m"],
            "flat_radius_m": hab["flat_radius_m"],
            "kind": "assumption",
            "note": "Notional start point chosen from slope data. Firm ground not verified (needs thermal inertia).",
        },
        "boxwork_campaign": {
            "sol_range": p["site"]["boxwork_sol_range"],
            "centroid_x_m": cx, "centroid_y_m": cy,
            "note": "Centroid of Curiosity waypoints during the boxwork campaign. It stands in for the ridges until they are mapped.",
        },
        "layers": [
            {"id": "optical", "kind": "measured", "file": "tiles", "source": "HiRISE (MRO), USGS mosaic", "resolution_m": 0.25},
            {"id": "hillshade", "kind": "measured", "file": "layers/hillshade.png", "source": "USGS merged DEM from HiRISE/CTX/HRSC stereo", "resolution_m": 2.0},
            {"id": "slope", "kind": "modeled", "file": "layers/slope.png", "source": "Computed from the USGS DEM", "resolution_m": 2.0},
            {"id": "forbidden", "kind": "modeled", "file": "grid/forbidden.bin", "source": "Slope above limit", "resolution_m": 2.0},
            {"id": "thermal", "kind": "measured", "file": "layers/thermal.png", "source": "THEMIS-IR day mosaic (Mars Odyssey) via NASA Mars Trek; relative brightness", "resolution_m": 100.0},
            {"id": "minerals", "kind": "example", "file": None, "source": "Pending: CRISM (MRO)", "resolution_m": None},
            {"id": "radiation", "kind": "example", "file": None, "source": "Pending phase 4: RAD (Curiosity)", "resolution_m": None},
        ],
    }
    with open(os.path.join(salida, "site.json"), "w", encoding="utf-8") as f:
        json.dump(site, f, indent=2)
    shutil.copy(common.PARAMS_PATH, os.path.join(salida, "params.json"))
    shutil.copy(os.path.join(common.RAIZ, "config", "objectives.json"), os.path.join(salida, "objectives.json"))
    print("site.json, params.json y objectives.json escritos")


def copiar_config():
    """Copia solo la configuración (parámetros y objetivos), sin regenerar teselas ni capas."""
    os.makedirs(common.SALIDA, exist_ok=True)
    shutil.copy(common.PARAMS_PATH, os.path.join(common.SALIDA, "params.json"))
    shutil.copy(os.path.join(common.RAIZ, "config", "objectives.json"), os.path.join(common.SALIDA, "objectives.json"))
    print("params.json y objectives.json copiados a app/assets/site_gale/")


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "config":
        copiar_config()
        return
    p = common.params()
    e0, n1, lado = common.caja(p)
    os.makedirs(common.SALIDA, exist_ok=True)
    exportar_capas(p, common.SALIDA)
    exportar_rejilla(common.SALIDA)
    exportar_waypoints(p, common.SALIDA, e0, n1, lado)
    escribir_site(p, common.SALIDA, e0, n1, lado)
    exportar_teselas(p, common.SALIDA)
    tot = sum(os.path.getsize(os.path.join(r, f)) for r, _, fs in os.walk(common.SALIDA) for f in fs) / 1e6
    print(f"app/assets/site_gale/: {tot:.1f} MB en total")


if __name__ == "__main__":
    main()

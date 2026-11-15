"""F7 (B): sitio de Gale con el alcance de la EVA: ventana de 24 km (una EVA llega a unos 12 km del hábitat).

Entrada (la deja `10_meridiani_datos.py alcance-gale` en data/raw/gale_alcance/):
  dem_box_16m.tif   DEM del USGS de 1 m leído a 16 m por su pirámide (24 km, 99.5 % válido)
  hirise_z14/       teselas HiRISE del mosaico de Curiosity de Mars Trek, nivel 14 (2.5 m por píxel)
Salida: app/assets/site_gale_reach/ con el mismo esquema que los demás sitios, más el recorrido real de Curiosity,
        el ambiente y las fotos copiados de site_gale/ (es el mismo cráter).

Decisiones:
- Rejilla de 16 m (base y ruteo): 1500 x 1500 celdas. La pendiente sale de un DEM real, pero a 16 m no ve obstáculos
  menores y no hay rugosidad (queda sin dato). Es para rutas de largo alcance; el detalle está en el sitio de 4 km.
- El hábitat es el mismo del sitio de 4 km (se mueve como máximo 3 km a la celda transitable más cercana).
- Objetivos: los cuatro de demostración de Gale (config/objectives.json, desplazados al nuevo origen) y uno lejano de ejemplo.
- Unidad de elevación de 0.1 m: el relieve de la ventana (3250 m, con el Monte Sharp) no cabe con 0.02 m.

Uso (desde tools/): python3 15_sitio_alcance_gale.py   (después, 14_contexto_y_rasgos.py)
"""
import importlib.util
import json
import os
import shutil

import numpy as np

import common


def _cargar(nombre, archivo):
    spec = importlib.util.spec_from_file_location(nombre, os.path.join(os.path.dirname(os.path.abspath(__file__)), archivo))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


datos = _cargar("datos10", "10_meridiani_datos.py")
s11 = _cargar("sitio11", "11_sitio_meridiani.py")

ASSETS = os.path.join(common.RAIZ, "app", "assets")
GALE = os.path.join(ASSETS, "site_gale")
V = datos.GALE_REACH
GALE_SITE = json.load(open(os.path.join(GALE, "site.json"), encoding="utf-8"))
GEO = GALE_SITE["georeference"]
HAB = GALE_SITE["habitat"]

S = {
    "id": "gale_reach",
    "asset": "site_gale_reach",
    "name": "Gale crater: EVA reach (24 km)",
    "ventana": V,
    "dem": os.path.join(datos.RAW_GR, "dem_box_16m.tif"),
    "dem_res_m": 16.0,
    "celda_m": 16.0,
    "ruteo_m": 16.0,
    "tesela": ("curiosity_hirise_mosaic", 14, os.path.join(datos.RAW_GR, "hirise_z14")),
    "mundo_m": 24576.0,
    "zmax": 4,
    "optico": "HiRISE (MRO) mosaic of the Curiosity roving site, via NASA Mars Trek (WMTS level 14, 2.5 m/px)",
    "optico_m": 2.54,
    "relieve": "USGS Gale merged DEM (HiRISE, CTX, HRSC) at 1 m, read at 16 m: local slopes are smoothed, roughness unknown",
    "habitat": (GEO["origin_easting_m"] + HAB["x_m"], GEO["origin_northing_m"] - HAB["y_m"]),
    "obj_m": (6000.0, 11000.0),
    "elev_unit_m": 0.1,
}


def waypoints(salida, p):
    wp = json.load(open(common.WAYPOINTS))["features"]
    sol_min, sol_max = p["site"].get("boxwork_sol_range", GALE_SITE.get("boxwork_campaign", {}).get("sol_range", [4500, 4899]))
    puntos = []
    for f in wp:
        q = f["properties"]
        x, y = q["easting"] - V["x0"], V["y0"] - q["northing"]
        if 0 <= x < V["size_m"] and 0 <= y < V["size_m"]:
            puntos.append({"sol": q["sol"], "x_m": round(x, 2), "y_m": round(y, 2), "elev_m": q["elev_geoid"], "lon": q["lon"], "lat": q["lat"],
                           "boxwork_campaign": sol_min <= q["sol"] <= sol_max})
    doc = {"source": "NASA/JPL-Caltech, Curiosity rover waypoints (MSL_waypoints.json)", "source_url": "https://mars.nasa.gov/mmgis-maps/MSL/Layers/json/MSL_waypoints.json",
           "retrieved": "2026-11-14", "kind": "measured", "points": puntos}
    with open(os.path.join(salida, "curiosity_waypoints.json"), "w", encoding="utf-8") as f:
        json.dump(doc, f, separators=(",", ":"))
    print(f"  waypoints de Curiosity en la ventana: {len(puntos)}")


def main():
    salida = os.path.join(ASSETS, S["asset"])
    os.makedirs(salida, exist_ok=True)
    p = s11.params_del_sitio(S, common.params())
    p["site"]["boxwork_sol_range"] = GALE_SITE.get("boxwork_campaign", {}).get("sol_range", [4500, 4899])
    g = s11.preparar_rejilla(S, p)
    print(f"  rejilla {g['ancho']} x {g['alto']} de {g['celda']:g} m; elevación {np.nanmin(g['z']):.0f} a {np.nanmax(g['z']):.0f} m")
    prohibida, comp = s11.escribir_rejilla(g, p, salida)
    v = g["pend"][np.isfinite(g["pend"])]
    print(f"  pendiente: mediana {np.median(v):.1f}°, p95 {np.percentile(v, 95):.1f}°, máxima {v.max():.1f}°; prohibidas {100 * prohibida.mean():.1f} %")
    h = s11.elegir_habitat(S, g, p, prohibida)
    print(f"  hábitat: celda ({h['col']}, {h['row']}), lon {h['lon']:.4f} lat {h['lat']:.4f}, elevación {h['elev']:.0f} m, radio llano {h['radio']:.0f} m")
    # objetivos: los de demostración de Gale (desplazados al origen de esta ventana) y uno lejano de ejemplo
    dx, dy = GEO["origin_easting_m"] - V["x0"], V["y0"] - GEO["origin_northing_m"]
    objs = []
    for o in json.load(open(os.path.join(common.RAIZ, "config", "objectives.json"), encoding="utf-8"))["objectives"]:
        q = dict(o, x_m=round(o["x_m"] + dx, 1), y_m=round(o["y_m"] + dy, 1))
        objs.append(q)
    lejanos = s11.objetivos_ejemplo(S, g, h, prohibida)
    far = next((o for o in lejanos if o["id"] == "e4"), lejanos[0] if lejanos else None)
    if far:
        far = dict(far, id="f1", name="Far plain site (example)")
        objs.append(far)
    for o in objs:
        ok = not prohibida[int(o["y_m"] // g["celda"]), int(o["x_m"] // g["celda"])]
        print(f"  objetivo {o['id']}: ({o['x_m']:.0f}, {o['y_m']:.0f}) m, transporte {o.get('transport')}, {'transitable' if ok else 'EN CELDA PROHIBIDA'}")
    with open(os.path.join(salida, "objectives.json"), "w", encoding="utf-8") as f:
        json.dump({"_nota": "Los cuatro objetivos de demostración de Gale (paradas reales de Curiosity; tipo, prioridad, tiempo y transporte son supuestos) desplazados a esta ventana, y un objetivo lejano de ejemplo elegido por reglas sobre el relieve.",
                   "kind": "suggested", "objectives": objs}, f, indent=2, ensure_ascii=False)
    s11.exportar_capas(p, g, salida)
    s11.escribir_site(S, p, g, h, comp, salida)
    gris = s11.mosaico_ortofoto(S)
    # El mosaico HiRISE tiene huecos (franjas sin imagen): se rellenan con la imagen CTX de la misma ventana para que no queden negros
    ctx = s11.mosaico_ortofoto(dict(S, tesela=("Gale_CTX_BlockAdj_dd", 11, os.path.join(datos.RAW_C, "gale_ctx_z11"))))
    huecos = gris == 0
    print(f"  huecos del mosaico HiRISE rellenados con CTX: {100 * huecos.mean():.1f} % de los píxeles")
    gris = np.where(huecos, ctx, gris).astype("uint8")
    s11.exportar_teselas(S, p, salida, gris)
    # el mismo cráter: recorrido real, ambiente y fotos de Curiosity
    waypoints(salida, p)
    shutil.copy(os.path.join(GALE, "environment.json"), os.path.join(salida, "environment.json"))
    shutil.copy(os.path.join(GALE, "rover_photos.json"), os.path.join(salida, "rover_photos.json"))
    dest = os.path.join(salida, "rover")
    if os.path.isdir(dest):
        shutil.rmtree(dest)
    shutil.copytree(os.path.join(GALE, "rover"), dest)
    ruta = os.path.join(salida, "site.json")
    site = json.load(open(ruta, encoding="utf-8"))
    site["quality"] = "reach"
    site["layers"].append({"id": "curiosity", "kind": "measured", "file": "curiosity_waypoints.json", "source": "NASA/JPL-Caltech, Curiosity rover waypoints", "resolution_m": None})
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(site, f, indent=2)
    tot = sum(os.path.getsize(os.path.join(r, f)) for r, _, fs in os.walk(salida) for f in fs) / 1e6
    print(f"  app/assets/{S['asset']}/: {tot:.1f} MB en total")


if __name__ == "__main__":
    main()

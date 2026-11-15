"""F7 (B): sitio de Endeavour con el alcance de la EVA: ventana de 22 km, con el DEM de 1 m donde existe y el de 200 m fuera.

Entrada (la deja `10_meridiani_datos.py alcance-endeavour` en data/raw/endeavour_alcance/):
  dem_fino_16m.tif    DEM de 1 m de Endeavour (Mars Trek) leído a 16 m; cubre una franja de ~8 x 22 km (el resto, sin dato)
  dem_grueso_200m.tif DEM global MOLA y HRSC de 200 m del USGS en la misma ventana
  hirise_z14/         teselas HiRISE del mosaico de Opportunity de Mars Trek, nivel 14 (2.5 m por píxel)
Salida: app/assets/site_meridiani_endeavour_reach/.

DEM mixto: donde el de 1 m tiene dato se usa ese; fuera, el de 200 m interpolado (bilineal) a 16 m y con un desfase único
(la mediana de la diferencia en la zona donde los dos tienen dato) para que no haya un escalón en el borde. Es una mezcla de
fuentes con resoluciones muy distintas: fuera de la franja las pendientes salen alisadas.

Uso (desde tools/): python3 17_sitio_alcance_endeavour.py   (después, 14 y 16)
"""
import importlib.util
import json
import os

import numpy as np
import rasterio
from scipy import ndimage

import common


def _cargar(nombre, archivo):
    spec = importlib.util.spec_from_file_location(nombre, os.path.join(os.path.dirname(os.path.abspath(__file__)), archivo))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


datos = _cargar("datos10", "10_meridiani_datos.py")
s11 = _cargar("sitio11", "11_sitio_meridiani.py")
ASSETS = os.path.join(common.RAIZ, "app", "assets")
V = datos.ENDEAVOUR_REACH
BASE_SITE = json.load(open(os.path.join(ASSETS, "site_meridiani_endeavour", "site.json"), encoding="utf-8"))
GEO, HAB = BASE_SITE["georeference"], BASE_SITE["habitat"]
S = {
    "id": "meridiani_endeavour_reach",
    "asset": "site_meridiani_endeavour_reach",
    "name": "Meridiani Planum: Endeavour, EVA reach (22 km)",
    "ventana": V,
    "dem": os.path.join(datos.RAW_ER, "dem_box_16m.tif"),
    "dem_res_m": 16.0,
    "celda_m": 16.0,
    "ruteo_m": 16.0,
    "tesela": ("opportunity_hirise_mosaic", 14, os.path.join(datos.RAW_ER, "hirise_z14")),
    "mundo_m": 24576.0,
    "zmax": 4,
    "optico": "HiRISE (MRO) mosaic of the Opportunity region, via NASA Mars Trek (WMTS level 14, 2.5 m/px), gaps filled with CTX",
    "optico_m": 2.54,
    "relieve": "HiRISE DEM of Endeavour crater at 1 m (read at 16 m) where it exists, USGS MOLA and HRSC 200 m DEM elsewhere: slopes outside the strip are smoothed",
    "habitat": (GEO["origin_easting_m"] + HAB["x_m"], GEO["origin_northing_m"] - HAB["y_m"]),
    "obj_m": (6000.0, 10000.0),
    "elev_unit_m": 0.1,
}


def leer(ruta):
    with rasterio.open(ruta) as d:
        a = d.read(1).astype("float64")
        nod = d.nodata
        a[(a == nod) | ~np.isfinite(a)] = np.nan
        return a, d.transform


def mezclar():
    fino, tf = leer(os.path.join(datos.RAW_ER, "dem_fino_16m.tif"))
    grueso, tg = leer(os.path.join(datos.RAW_ER, "dem_grueso_200m.tif"))
    h, w = fino.shape
    # el DEM grueso, interpolado a los centros de las celdas del fino (el origen de los dos puede diferir hasta 200 m)
    xs = tf.c + (np.arange(w) + 0.5) * tf.a
    ys = tf.f + (np.arange(h) + 0.5) * tf.e
    cc = (xs[None, :] - tg.c) / tg.a - 0.5
    rr = (ys[:, None] - tg.f) / tg.e - 0.5
    gz = np.where(np.isfinite(grueso), grueso, np.nanmean(grueso))
    g_up = ndimage.map_coordinates(gz, [np.broadcast_to(rr, (h, w)), np.broadcast_to(cc, (h, w))], order=1, mode="nearest")
    valido = np.isfinite(fino)
    delta = float(np.median(fino[valido] - g_up[valido])) if valido.any() else 0.0
    print(f"  DEM fino válido en {100 * valido.mean():.1f} % de la ventana; desfase mediano fino - grueso: {delta:+.1f} m")
    z = np.where(valido, fino, g_up + delta)
    os.makedirs(datos.RAW_ER, exist_ok=True)
    tr = rasterio.transform.from_origin(tf.c, tf.f, 16.0, 16.0)
    with rasterio.open(S["dem"], "w", driver="GTiff", height=h, width=w, count=1, dtype="float32", nodata=-32767.0, transform=tr, compress="lzw",
                       crs=f"+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +R={common.R_MARTE} +units=m +no_defs") as out:
        out.write(z.astype("float32"), 1)
    return valido


def main():
    salida = os.path.join(ASSETS, S["asset"])
    os.makedirs(salida, exist_ok=True)
    valido = mezclar()
    p = s11.params_del_sitio(S, common.params())
    g = s11.preparar_rejilla(S, p)
    print(f"  rejilla {g['ancho']} x {g['alto']} de {g['celda']:g} m; elevación {np.nanmin(g['z']):.0f} a {np.nanmax(g['z']):.0f} m")
    prohibida, comp = s11.escribir_rejilla(g, p, salida)
    v = g["pend"][np.isfinite(g["pend"])]
    print(f"  pendiente: mediana {np.median(v):.1f}°, p95 {np.percentile(v, 95):.1f}°, máxima {v.max():.1f}°; prohibidas {100 * prohibida.mean():.1f} %")
    h = s11.elegir_habitat(S, g, p, prohibida)
    print(f"  hábitat: celda ({h['col']}, {h['row']}), lon {h['lon']:.4f} lat {h['lat']:.4f}, elevación {h['elev']:.0f} m, radio llano {h['radio']:.0f} m")
    dx, dy = GEO["origin_easting_m"] - V["x0"], V["y0"] - GEO["origin_northing_m"]
    base = json.load(open(os.path.join(ASSETS, "site_meridiani_endeavour", "objectives.json"), encoding="utf-8"))["objectives"]
    objs = [dict(o, x_m=round(o["x_m"] + dx, 1), y_m=round(o["y_m"] + dy, 1)) for o in base]
    lejanos = s11.objetivos_ejemplo(S, g, h, prohibida)
    far = next((o for o in lejanos if o["id"] == "e4"), lejanos[0] if lejanos else None)
    if far:
        objs.append(dict(far, id="f1", name="Far plain site (example)"))
    for o in objs:
        ok = not prohibida[int(o["y_m"] // g["celda"]), int(o["x_m"] // g["celda"])]
        print(f"  objetivo {o['id']}: ({o['x_m']:.0f}, {o['y_m']:.0f}) m, transporte {o.get('transport')}, {'transitable' if ok else 'EN CELDA PROHIBIDA'}")
    with open(os.path.join(salida, "objectives.json"), "w", encoding="utf-8") as f:
        json.dump({"_nota": "Los cuatro objetivos de ejemplo del sitio de Endeavour de 4 km desplazados a esta ventana y uno lejano de ejemplo. Elegidos por reglas sobre el relieve; no son objetivos científicos.",
                   "kind": "suggested", "objectives": objs}, f, indent=2, ensure_ascii=False)
    s11.exportar_capas(p, g, salida)
    s11.escribir_site(S, p, g, h, comp, salida)
    gris = s11.mosaico_ortofoto(S)
    ctx = s11.mosaico_ortofoto(dict(S, tesela=("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 11, os.path.join(datos.RAW_C, "endeavour_ctx_z11"))))
    huecos = gris == 0
    print(f"  huecos del mosaico HiRISE rellenados con CTX: {100 * huecos.mean():.1f} % de los píxeles")
    s11.exportar_teselas(S, p, salida, np.where(huecos, ctx, gris).astype("uint8"))
    ruta = os.path.join(salida, "site.json")
    site = json.load(open(ruta, encoding="utf-8"))
    site["quality"] = "reach"
    site["dem_fine_fraction"] = float(valido.mean())
    with open(ruta, "w", encoding="utf-8") as f:
        json.dump(site, f, indent=2)
    tot = sum(os.path.getsize(os.path.join(r, f)) for r, _, fs in os.walk(salida) for f in fs) / 1e6
    print(f"  app/assets/{S['asset']}/: {tot:.1f} MB en total")


if __name__ == "__main__":
    main()

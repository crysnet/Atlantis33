"""F4: genera los assets de las dos ventanas locales de Meridiani para la app.

Entrada (la deja `10_meridiani_datos.py` en data/raw/):
  meridiani_endeavour/dem_box_1m.tif y hirise_z17/   (ventana de 4 x 4 km, DEM de 1 m y ortofoto HiRISE de 0.32 m)
  meridiani_habitat/dem_box_200m.tif y ctx_z12/      (ventana de 20 x 20 km, DEM de 200 m y ortofoto CTX de 10 m)
  meridiani_regional/dem_box_400m.tif y ctx_z11/     (ventana de 100 x 100 km, DEM de 400 m y ortofoto CTX de 20 m)
Salida: app/assets/site_meridiani_endeavour/, site_meridiani_habitat/ y site_meridiani_regional/, con el mismo esquema que site_gale/
  (site.json, params.json, objectives.json, grid/*.bin, layers/*.png, ortho/{z}/{x}/{y}.jpg y los JSON de datos).

Uso (desde tools/):
    python3 11_sitio_meridiani.py endeavour|habitat|regional|ambos   (ambos = los tres)

Decisiones (todas se anotan en site.json y en RETOMAR.md):
- Mismo plano local que Gale: metros, x al este, y al sur, origen en la esquina noroeste de la ventana. Las teselas de Trek
  están en un plano de grados iguales (equirectangular), igual que los metros del plano local: la correspondencia es lineal.
- Endeavour: rejilla de 2 m (bloques de 2 x 2 del DEM de 1 m), pendiente con diferencias centrales y rugosidad a 1 m, igual que Gale.
- Zona habitable: el DEM de 200 m se interpola a 100 m (bilineal) y la pendiente sale con una línea base de 200 m. Alisa
  todas las pendientes locales y no ve rugosidad: la rugosidad queda sin dato. Las rutas de esta ventana son indicativas.
- Hábitat: en la zona habitable es el centro de la ventana (la zona habitable de EZMars de Mars Trek, lat -3.085, lon -5.50);
  en Endeavour lo elegimos nosotros: la celda con mayor radio llano de la región transitable principal.
- Objetivos de ejemplo: elegidos por reglas sobre el relieve (no son objetivos científicos). Marcados como ejemplo.
- Sin datos propios de radiación y clima (RAD y REMS son de Curiosity, en Gale): environment.json va sin mediciones.
"""
import importlib.util
import json
import math
import os
import shutil
import sys

import numpy as np
import rasterio
from PIL import Image
from scipy import ndimage

import common

_spec = importlib.util.spec_from_file_location("datos10", os.path.join(os.path.dirname(os.path.abspath(__file__)), "10_meridiani_datos.py"))
datos = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(datos)

R = common.R_MARTE
ASSETS = os.path.join(common.RAIZ, "app", "assets")

SITIOS = {
    "endeavour": {
        "id": "meridiani_endeavour",
        "asset": "site_meridiani_endeavour",
        "name": "Meridiani Planum: Endeavour crater rim",
        "ventana": datos.ENDEAVOUR,
        "dem": os.path.join(datos.RAW_E, "dem_box_1m.tif"),
        "dem_res_m": 1.0,
        "celda_m": 2.0,
        "ruteo_m": 4.0,
        "tesela": ("opportunity_hirise_mosaic", 17, os.path.join(datos.RAW_E, "hirise_z17")),
        "mundo_m": 4096.0,
        "zmax": 4,
        "optico": "HiRISE (MRO) mosaic of the Opportunity region, via NASA Mars Trek (WMTS level 17, 0.32 m/px)",
        "optico_m": 0.32,
        "relieve": "HiRISE DEM of Endeavour crater at 1 m/px, via NASA Mars Trek (no author in the metadata)",
        "habitat": None,
    },
    "habitat": {
        "id": "meridiani_habitat",
        "asset": "site_meridiani_habitat",
        "name": "Meridiani Planum: habitation zone",
        "ventana": datos.HABITAT,
        "dem": os.path.join(datos.RAW_H, "dem_box_200m.tif"),
        "dem_res_m": 200.0,
        "celda_m": 100.0,
        "ruteo_m": 100.0,
        "tesela": ("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 12, os.path.join(datos.RAW_H, "ctx_z12")),
        "mundo_m": 20480.0,
        "zmax": 2,
        "optico": "CTX (MRO) mosaic of Meridiani Planum - Sinus Meridiani, via NASA Mars Trek (WMTS level 12, 10 m/px)",
        "optico_m": 10.2,
        "relieve": "USGS MOLA and HRSC blended DEM, 200 m/px, interpolated to 100 m: local slopes are smoothed",
        "habitat": (math.radians(-5.50) * R, math.radians(-3.085) * R),
        "obj_m": (1500.0, 3500.0),  # al alcance de una EVA de 6 h a pie (ida y vuelta de menos de 8 km)
    },
    "regional": {
        "id": "meridiani_regional",
        "asset": "site_meridiani_regional",
        "name": "Meridiani Planum: regional context (100 km)",
        "ventana": datos.REGIONAL,
        "dem": os.path.join(datos.RAW_R, "dem_box_400m.tif"),
        "dem_res_m": 400.0,
        "celda_m": 400.0,
        "ruteo_m": 400.0,
        "tesela": ("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 11, os.path.join(datos.RAW_R, "ctx_z11")),
        "mundo_m": 102400.0,
        "zmax": 3,
        "optico": "CTX (MRO) mosaic of Meridiani Planum - Sinus Meridiani, via NASA Mars Trek (WMTS level 11, 20 m/px)",
        "optico_m": 20.35,
        "relieve": "USGS MOLA and HRSC blended DEM, 200 m/px, read at 400 m/px: local slopes are strongly smoothed",
        "habitat": (math.radians(-5.50) * R, math.radians(-3.085) * R),
        "obj_m": (1500.0, 3500.0),
        "elev_unit_m": 0.05,  # el rango de elevación (2215 m) no cabe en uint16 con 0.02 m
    },
}


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def reducir_a_la_mitad(a):
    a = a.astype(np.uint16)
    return ((a[0::2, 0::2] + a[1::2, 0::2] + a[0::2, 1::2] + a[1::2, 1::2] + 2) // 4).astype(np.uint8)


# ---------------------------------------------------------------- relieve y rejilla

def preparar_rejilla(s, p):
    """DEM de la ventana -> elevación, pendiente, rugosidad y sombreado en la rejilla de trabajo. Devuelve un diccionario."""
    v = s["ventana"]
    with rasterio.open(s["dem"]) as d:
        z0 = d.read(1).astype("float64")
        nod = d.nodata
        e0, n1 = d.transform.c, d.transform.f
        res = d.res[0]
    z0[(z0 == nod) | ~np.isfinite(z0)] = np.nan
    celda = s["celda_m"]
    k = int(round(celda / res))
    if res < 10.0 and k >= 1 and abs(k * res - celda) < 1e-6 and celda >= res:
        z = common.bloque_medio(z0, k) if k > 1 else z0
        zf, malo = common.rellenar_nan(z)
        # rugosidad a la resolución del DEM, después promedio al tamaño de celda (como Gale)
        z0f, malo0 = common.rellenar_nan(z0)
        win = p["roughness"]["window_px"]
        resid = z0f - ndimage.uniform_filter(z0f, win)
        rms = 100.0 * np.sqrt(ndimage.uniform_filter(resid ** 2, win))
        rms[malo0] = np.nan
        rug = common.bloque_medio(rms, k) if k > 1 else rms
        rug_nodata = False
    else:
        # DEM más grueso que la celda: se interpola (bilineal) y no hay rugosidad
        f = res / celda
        zf0, malo0 = common.rellenar_nan(z0)
        zf = ndimage.zoom(zf0, f, order=1, mode="nearest")
        malo = ndimage.zoom(malo0.astype("float32"), f, order=0) > 0.5
        z = np.where(malo, np.nan, zf)
        rug = np.full(zf.shape, np.nan)
        rug_nodata = True
    pend = common.pendiente_grados(zf, celda)
    pend[malo] = np.nan
    hs = (common.sombreado(zf, celda) * 255.0).astype("uint8")
    return {"z": z, "zf": zf, "pend": pend, "rug": rug, "hs": hs, "celda": celda, "e0": v["x0"], "n1": v["y0"],
            "alto": z.shape[0], "ancho": z.shape[1], "rug_nodata": rug_nodata, "dem_origen": (e0, n1)}


def escribir_rejilla(g, p, salida):
    s = p["slope"]
    pend, z, rug = g["pend"], g["z"], g["rug"]
    sin_dato = ~np.isfinite(pend) | ~np.isfinite(z)
    prohibida = sin_dato | (pend > s["forbidden_above_deg"])
    slope_q = np.where(sin_dato, 255, np.clip(np.round(pend / 0.5), 0, 254)).astype("uint8")
    unidad_rug = p["roughness"]["byte_unit_cm"]
    rough_q = np.where(~np.isfinite(rug), 255, np.clip(np.round(rug / unidad_rug), 0, 254)).astype("uint8")
    unidad_z = p["elevation"]["byte_unit_m"]
    z0 = float(np.floor(np.nanmin(z)))
    if np.nanmax(z) - z0 >= (p["elevation"]["nodata_value"] - 1) * unidad_z:
        raise SystemExit("El rango de elevación no cabe en uint16")
    elev_q = np.where(~np.isfinite(z), p["elevation"]["nodata_value"], np.round((z - z0) / unidad_z)).astype("<u2")
    d = os.path.join(salida, "grid")
    os.makedirs(d, exist_ok=True)
    for nombre, arr in (("slope", slope_q), ("rough", rough_q), ("forbidden", prohibida.astype("uint8")), ("elev", elev_q)):
        arr.tofile(os.path.join(d, nombre + ".bin"))
    comp = {
        "slope": {"file": "slope.bin", "dtype": "uint8", "unit_deg": 0.5, "nodata": 255},
        "rough": {"file": "rough.bin", "dtype": "uint8", "unit_cm": unidad_rug, "nodata": 255, "saturates_at": 254},
        "forbidden": {"file": "forbidden.bin", "dtype": "uint8", "values": {"0": "walkable", "1": "forbidden"}},
        "elev": {"file": "elev.bin", "dtype": "uint16-le", "unit_m": unidad_z, "offset_m": z0, "nodata": p["elevation"]["nodata_value"]},
    }
    return prohibida, comp


def elegir_habitat(s, g, p, prohibida):
    """Celda del hábitat. Con posición fijada (zona habitable de EZMars) se usa esa; si no, la de mayor radio llano."""
    celda, pend = g["celda"], g["pend"]
    alto, ancho = pend.shape
    etiquetas, n = ndimage.label(~prohibida, structure=np.ones((3, 3)))
    tam = np.bincount(etiquetas.ravel())[1:]
    mayor = int(np.argmax(tam)) + 1
    llano = (pend < p["slope"]["habitat_max_deg"]) & ~prohibida
    radio = ndimage.distance_transform_edt(llano) * celda
    if s["habitat"] is not None:
        he, hn = s["habitat"]
        col0, fila0 = int((he - g["e0"]) // celda), int((g["n1"] - hn) // celda)
        rr, cc = np.ogrid[:alto, :ancho]
        cerca = ((rr - fila0) ** 2 + (cc - col0) ** 2 <= (3000.0 / celda) ** 2) & (etiquetas == mayor)
        puntaje = np.where(cerca, -((rr - fila0) ** 2 + (cc - col0) ** 2), -1e18)  # la más cercana al punto pedido
        nota = "Habitation zone of NASA's first Exploration Zone workshop (EZMars layer of Mars Trek), moved to the nearest walkable cell."
    else:
        rr, cc = np.ogrid[:alto, :ancho]
        centro = ((rr - alto / 2) ** 2 + (cc - ancho / 2) ** 2) <= (0.35 * ancho) ** 2
        puntaje = np.where((etiquetas == mayor) & centro, radio, -1)
        nota = "Notional start point chosen by the team: the cell with the largest flat radius in the main walkable region. Firm ground not verified."
    fila, col = np.unravel_index(np.argmax(puntaje), puntaje.shape)
    he, hn = g["e0"] + (col + 0.5) * celda, g["n1"] - (fila + 0.5) * celda
    lon, lat = common.a_lonlat(he, hn)
    return {"col": int(col), "row": int(fila), "e": he, "n": hn, "lon": lon, "lat": lat, "elev": float(g["z"][fila, col]),
            "radio": float(radio[fila, col]), "nota": nota, "etiquetas": etiquetas, "mayor": mayor}


def objetivos_ejemplo(s, g, h, prohibida):
    """Cuatro objetivos de ejemplo elegidos por reglas sobre el relieve (no son objetivos científicos)."""
    celda, pend, z = g["celda"], g["pend"], g["zf"]
    alto, ancho = pend.shape
    ok = (h["etiquetas"] == h["mayor"]) & ~prohibida
    rr, cc = np.mgrid[:alto, :ancho]
    dist = np.hypot((rr - h["row"]) * celda, (cc - h["col"]) * celda)
    out = []

    def poner(id_, nombre, tipo, pri, min_, mask, score, transporte):
        m = ok & mask
        if not m.any():
            return
        sc = np.where(m, score, -np.inf)
        f, c = np.unravel_index(np.argmax(sc), sc.shape)
        out.append({"id": id_, "name": nombre, "type": tipo, "priority": pri, "work_min": min_,
                    "x_m": round((c + 0.5) * celda, 1), "y_m": round((f + 0.5) * celda, 1), "transport": transporte,
                    "source": "Example point chosen by the team from the terrain (not a science target)"})

    alcance = s["ruteo_m"] * 0  # sin uso; se deja por claridad
    del alcance
    lejos, cerca = s.get("obj_m", (0.12 * g["ancho"] * celda, 0.40 * g["ancho"] * celda))  # distancias al hábitat
    poner("e1", "Highest reachable point (example)", "image", 4, 30, (dist >= lejos) & (dist <= cerca), z, "hybrid")
    poner("e2", "Flat bench (example)", "measurement", 3, 25, (dist >= lejos) & (dist <= cerca) & (pend < 4), -np.abs(dist - 0.7 * cerca), "vehicle")
    poner("e3", "Steep slope base (example)", "sample", 5, 40, (dist >= lejos) & (dist <= cerca) & (pend >= 8) & (pend < 18), pend - 0.001 * dist, "foot")
    poner("e4", "Plain site (example)", "equipment", 2, 20, (dist >= lejos) & (dist <= 0.6 * cerca) & (pend < 2), dist, "vehicle")
    return out


# ---------------------------------------------------------------- ortofoto

def mosaico_ortofoto(s):
    """Une las teselas de Trek, recorta la ventana y la lleva al tamaño del nivel máximo de la pirámide. Devuelve uint8 (alto, ancho)."""
    producto, z, carpeta = s["tesela"]
    v = s["ventana"]
    lista, deg = datos.teselas_de(v, z)
    r0, r1 = min(r for r, _ in lista), max(r for r, _ in lista)
    c0, c1 = min(c for _, c in lista), max(c for _, c in lista)
    h, w = (r1 - r0 + 1) * 256, (c1 - c0 + 1) * 256
    gris = np.zeros((h, w), np.uint8)
    alfa = np.zeros((h, w), np.uint8)
    faltan = 0
    for r, c in lista:
        ruta = os.path.join(carpeta, str(z), str(r), f"{c}.png")
        if not os.path.exists(ruta):
            faltan += 1
            continue
        im = Image.open(ruta).convert("LA")
        a = np.asarray(im)
        gris[(r - r0) * 256:(r - r0 + 1) * 256, (c - c0) * 256:(c - c0 + 1) * 256] = a[..., 0]
        alfa[(r - r0) * 256:(r - r0 + 1) * 256, (c - c0) * 256:(c - c0 + 1) * 256] = a[..., 1]
    if faltan:
        print(f"  aviso: {faltan} de {len(lista)} teselas sin archivo (quedan negras)")
    gris[alfa == 0] = 0
    lon0, lat1 = datos.lonlat(v["x0"], v["y0"])
    lon1, lat0 = datos.lonlat(v["x0"] + v["size_m"], v["y0"] - v["size_m"])
    # píxel de la ventana en el mosaico de teselas (la tesela (r, c) cubre lon -180 + c * deg y lat 90 - r * deg)
    izq = ((lon0 + 180.0) / deg - c0) * 256.0
    der = ((lon1 + 180.0) / deg - c0) * 256.0
    arr = (90.0 - lat1) / deg - r0
    aba = (90.0 - lat0) / deg - r0
    destino = int(round(s["mundo_m"] / (512 * 2 ** s["zmax"]) * 0 + 512 * 2 ** s["zmax"] * v["size_m"] / s["mundo_m"]))
    im = Image.fromarray(gris, "L").resize((destino, destino), Image.LANCZOS, box=(izq, arr * 256.0, der, aba * 256.0))
    cubierto = np.asarray(im)
    print(f"  ortofoto: {len(lista)} teselas, mosaico {w} x {h} px, ventana a {destino} x {destino} px ({v['size_m'] / destino:.3f} m/px); "
          f"píxeles negros {100 * (cubierto == 0).mean():.1f} %")
    return cubierto


def exportar_teselas(s, p, salida, gris, nombre="ortho"):
    t = p["tiles"]
    px, zmax = t["tile_px"], s["zmax"]
    ruta = os.path.join(salida, nombre)
    if os.path.isdir(ruta):
        shutil.rmtree(ruta)
    mundo_px = px * 2 ** zmax
    lienzo = np.zeros((mundo_px, mundo_px, 3), np.uint8)
    lienzo[: gris.shape[0], : gris.shape[1]] = gris[..., None]
    total = 0
    for z in range(zmax, -1, -1):
        n = lienzo.shape[0] // px
        for ty in range(n):
            for tx in range(n):
                d = os.path.join(ruta, str(z), str(tx))
                os.makedirs(d, exist_ok=True)
                Image.fromarray(lienzo[ty * px:(ty + 1) * px, tx * px:(tx + 1) * px]).save(os.path.join(d, f"{ty}.jpg"), quality=t["jpeg_quality"], optimize=True)
                total += 1
        if z > 0:
            lienzo = np.stack([reducir_a_la_mitad(lienzo[..., c]) for c in range(3)], axis=-1)
    mb = sum(os.path.getsize(os.path.join(r, f)) for r, _, fs in os.walk(ruta) for f in fs) / 1e6
    print(f"  teselas: {total} archivos, {mb:.1f} MB")


def exportar_capas(p, g, salida):
    os.makedirs(os.path.join(salida, "layers"), exist_ok=True)
    s = p["slope"]
    pend = g["pend"]
    if pend.shape[0] < 1000:
        # rejilla gruesa: se interpola la pendiente (bilineal) antes de clasificar, para que los bordes no salgan a bloques
        f = 1000 // pend.shape[0] + 1
        valido = ndimage.zoom(np.isfinite(pend).astype("float32"), f, order=0) > 0.5
        pend = ndimage.zoom(np.where(np.isfinite(pend), pend, 0.0), f, order=1)
        pend[~valido] = np.nan
    col = {k: hex_rgb(v) for k, v in s["colors"].items()}
    rgba = np.zeros(pend.shape + (4,), np.uint8)
    v = np.nan_to_num(pend, nan=999.0)
    for mascara, c in [
        (v < s["nominal_max_deg"], col["nominal"]),
        ((v >= s["nominal_max_deg"]) & (v < s["caution_max_deg"]), col["caution"]),
        ((v >= s["caution_max_deg"]) & (v <= s["forbidden_above_deg"]), col["high_caution"]),
        (v > s["forbidden_above_deg"], col["forbidden"]),
    ]:
        rgba[mascara] = (*c, 255)
    rgba[~np.isfinite(pend)] = (0, 0, 0, 0)
    hs = g["hs"]
    # Las capas se dibujan estiradas sobre el recuadro: las rejillas gruesas se amplían para que no salgan a bloques
    if hs.shape[0] < 1000:
        f = 1000 // hs.shape[0] + 1
        hs = np.asarray(Image.fromarray(hs, "L").resize((hs.shape[1] * f, hs.shape[0] * f), Image.BICUBIC))
    # Pendiente de más de 15 % (8.53°), el filtro de la propuesta de zonas de exploración: máscara roja
    m15 = np.zeros(pend.shape + (4,), np.uint8)
    m15[np.nan_to_num(pend, nan=0.0) > math.degrees(math.atan(0.15))] = (231, 76, 60, 170)
    Image.fromarray(m15, "RGBA").save(os.path.join(salida, "layers", "slope15.png"), optimize=True)
    Image.fromarray(rgba, "RGBA").save(os.path.join(salida, "layers", "slope.png"), optimize=True)
    Image.fromarray(hs, "L").save(os.path.join(salida, "layers", "hillshade.png"), optimize=True)
    print(f"  capas: slope.png y hillshade.png ({rgba.shape[1]} x {rgba.shape[0]} px)")


# ---------------------------------------------------------------- JSON del sitio

def params_del_sitio(s, base):
    p = json.loads(json.dumps(base))
    p["site"] = {"id": s["id"], "name": s["name"], "box": {"easting_min": s["ventana"]["x0"], "northing_max": s["ventana"]["y0"], "size_m": s["ventana"]["size_m"]},
                 "_nota": "Ventana local de Meridiani (F4). Ver tools/11_sitio_meridiani.py."}
    p["grid"]["cell_m"] = s["celda_m"]
    p["routing"]["cell_m"] = s["ruteo_m"]
    if "elev_unit_m" in s:
        p["elevation"]["byte_unit_m"] = s["elev_unit_m"]
    return p


def escribir_site(s, p, g, h, comp, salida):
    v = s["ventana"]
    t = p["tiles"]
    lon_c, lat_c = common.a_lonlat(v["x0"] + v["size_m"] / 2, v["y0"] - v["size_m"] / 2)
    site = {
        "id": s["id"], "name": s["name"],
        "frame": {"description": "Local plane in metres. x grows east, y grows south, origin at the north-west corner of the box.", "size_m": v["size_m"]},
        "georeference": {
            "projection": "Mars equirectangular, sphere radius 3396190 m, central meridian 0, planetocentric latitude",
            "radius_m": R, "origin_easting_m": v["x0"], "origin_northing_m": v["y0"],
            "easting_m": "origin_easting_m + x_m", "northing_m": "origin_northing_m - y_m",
            "lon_deg": "degrees(easting_m / radius_m)", "lat_deg": "degrees(northing_m / radius_m)",
            "center_lon_deg": lon_c, "center_lat_deg": lat_c,
        },
        "grid": {"cell_m": g["celda"], "width": g["ancho"], "height": g["alto"], "order": "row-major, north to south, west to east", "components": comp},
        "tiles": {
            "template": "ortho/{z}/{x}/{y}.jpg", "tile_px": t["tile_px"], "min_zoom": 0, "max_zoom": s["zmax"],
            "world_size_m": s["mundo_m"], "m_per_px": [s["mundo_m"] / (t["tile_px"] * 2 ** z) for z in range(s["zmax"] + 1)],
            "covered_size_m": v["size_m"],
        },
        "habitat": {"x_m": h["e"] - v["x0"], "y_m": v["y0"] - h["n"], "col": h["col"], "row": h["row"], "lon": h["lon"], "lat": h["lat"],
                    "elevation_m": h["elev"], "flat_radius_m": h["radio"], "kind": "assumption", "note": h["nota"]},
        "layers": [
            {"id": "optical", "kind": "measured", "file": "tiles", "source": s["optico"], "resolution_m": s["optico_m"]},
            {"id": "hillshade", "kind": "measured", "file": "layers/hillshade.png", "source": s["relieve"], "resolution_m": g["celda"]},
            {"id": "slope", "kind": "modeled", "file": "layers/slope.png", "source": "Computed from the DEM above", "resolution_m": g["celda"]},
            {"id": "forbidden", "kind": "modeled", "file": "grid/forbidden.bin", "source": "Slope above limit", "resolution_m": g["celda"]},
            {"id": "slope15", "kind": "modeled", "file": "layers/slope15.png", "source": "Slope above 15 % (8.5 deg), computed from the DEM above", "resolution_m": g["celda"]},
        ],
        "quality": "indicative" if s["dem_res_m"] > 10 else "high",
        "regional": s["ventana"]["size_m"] >= 50000,
    }
    with open(os.path.join(salida, "site.json"), "w", encoding="utf-8") as f:
        json.dump(site, f, indent=2)
    with open(os.path.join(salida, "params.json"), "w", encoding="utf-8") as f:
        json.dump(p, f, indent=2)
    with open(os.path.join(salida, "curiosity_waypoints.json"), "w", encoding="utf-8") as f:
        json.dump({"source": "none: Curiosity is in Gale; the Opportunity traverse is not loaded yet", "kind": "none", "points": []}, f)
    with open(os.path.join(salida, "rover_photos.json"), "w", encoding="utf-8") as f:
        json.dump({}, f)
    env = {
        "generated": "2026-11-14", "reference_sol": 0,
        "sol_calibration": {"note": "No calibration: no measurements at this site"},
        "radiation": {"source": "No radiation measurements at this site: RAD is on Curiosity, in Gale crater", "kind": "none", "baseline_e_median_ugy_day": None, "per_sol": []},
        "weather": {"source": "No weather measurements at this site: REMS is on Curiosity, in Gale crater", "kind": "none", "sols": []},
        "dust": {"kind": "none", "note": "No dust data"},
    }
    with open(os.path.join(salida, "environment.json"), "w", encoding="utf-8") as f:
        json.dump(env, f)


def generar(clave):
    s = SITIOS[clave]
    print(f"== {s['id']}")
    salida = os.path.join(ASSETS, s["asset"])
    os.makedirs(salida, exist_ok=True)
    p = params_del_sitio(s, common.params())
    g = preparar_rejilla(s, p)
    print(f"  rejilla {g['ancho']} x {g['alto']} de {g['celda']:g} m; elevación {np.nanmin(g['z']):.0f} a {np.nanmax(g['z']):.0f} m")
    prohibida, comp = escribir_rejilla(g, p, salida)
    v = g["pend"][np.isfinite(g["pend"])]
    print(f"  pendiente: mediana {np.median(v):.1f}°, percentil 95 {np.percentile(v, 95):.1f}°, máxima {v.max():.1f}°; prohibidas {100 * prohibida.mean():.1f} %")
    h = elegir_habitat(s, g, p, prohibida)
    print(f"  hábitat: celda ({h['col']}, {h['row']}), lon {h['lon']:.4f} lat {h['lat']:.4f}, elevación {h['elev']:.0f} m, radio llano {h['radio']:.0f} m")
    objs = objetivos_ejemplo(s, g, h, prohibida)
    for o in objs:
        print(f"  objetivo {o['id']}: {o['name']} en ({o['x_m']:.0f}, {o['y_m']:.0f}) m, transporte {o['transport']}")
    with open(os.path.join(salida, "objectives.json"), "w", encoding="utf-8") as f:
        json.dump({"_nota": "Objetivos de ejemplo elegidos por reglas sobre el relieve (tools/11_sitio_meridiani.py). No son objetivos científicos. Coordenadas locales: x al este, y al sur, desde la esquina noroeste de la ventana.",
                   "kind": "suggested", "objectives": objs}, f, indent=2, ensure_ascii=False)
    exportar_capas(p, g, salida)
    escribir_site(s, p, g, h, comp, salida)
    exportar_teselas(s, p, salida, mosaico_ortofoto(s))
    tot = sum(os.path.getsize(os.path.join(r, f)) for r, _, fs in os.walk(salida) for f in fs) / 1e6
    print(f"  app/assets/{s['asset']}/: {tot:.1f} MB en total")


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "ambos"
    for k in (["endeavour", "habitat", "regional"] if arg == "ambos" else [arg]):
        generar(k)


if __name__ == "__main__":
    main()

"""Amplía el sitio `meridiani_regional` a toda la traza disponible del mosaico CTX de Sinus Meridiani (327,68 km)."""
import json
import math
import os
import struct
import urllib.parse
import urllib.request

import numpy as np
import rasterio
from PIL import Image
from rasterio.enums import Resampling
from rasterio.windows import from_bounds
from scipy import ndimage

from common import R_MARTE, pendiente_grados, rellenar_nan

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_M = os.path.join(RAIZ, "data", "raw", "meridiani")
RAW_ASU = os.path.join(RAIZ, "data", "raw", "asu")
RAW_RASGOS = os.path.join(RAIZ, "data", "raw", "rasgos")
BASE_DIR = os.path.join(RAIZ, "app", "assets", "base_meridiani")
SITE_DIR = os.path.join(RAIZ, "app", "assets", "site_meridiani_regional")
PARAMS_BASE = os.path.join(RAIZ, "config", "params.json")

UA = "ARES-PATH/0.1 (NASA Space Apps 2026)"

# Ventana completa del mosaico CTX de Sinus Meridiani (`base_meridiani`)
LON0 = -8.208
LAT1 = 0.013
X0 = math.radians(LON0) * R_MARTE
Y0 = math.radians(LAT1) * R_MARTE
SIZE_M = 327680.0
LON1 = math.degrees((X0 + SIZE_M) / R_MARTE)
LAT0 = math.degrees((Y0 - SIZE_M) / R_MARTE)

# Origen antiguo del recuadro de 100 km para trasladar coordenadas existentes
OLD_X0 = -376010.83622296227
OLD_Y0 = -132862.44167794976
DX_OLD_TO_NEW = OLD_X0 - X0  # +110515.881 m
DY_OLD_TO_NEW = Y0 - OLD_Y0  # +133633.013 m

GRID_N = 512
CELL_M = SIZE_M / GRID_N  # 640.0 m
LAYER_PX = 1024  # 320.0 m/px

URL_DEM = (
    "https://planetarymaps.usgs.gov/mosaic/Mars/HRSC_MOLA_Blend/"
    "Mars_HRSC_MOLA_BlendDEM_Global_200mp_v2.tif"
)
URL_DCI = "http://www.mars.asu.edu/~ruff/DCI/dci_lo_ice_dust_16ppd_shifted.raw"
URL_TI_WMS = "http://ms-mars.mars.asu.edu/ti16"
URL_TREK = "https://trek.nasa.gov/tiles/Mars/EQ"
CAPA_TERMICA = "THEMIS_NightIR_ControlledMosaics_100m_v2_oct2018"
URL_NOMENCLATURA = "https://trek.nasa.gov/mars/TrekServices/ws/index/eq/searchItems"
URL_ROBBINS = "https://astrogeology.usgs.gov/pygeoapi/collections/mars/robbinsv1/items"


def _descargar(url, destino, timeout=180):
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    if os.path.exists(destino) and os.path.getsize(destino) > 0:
        return
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r, open(destino, "wb") as f:
        while True:
            bloque = r.read(65536)
            if not bloque:
                break
            f.write(bloque)


def mascara_traza_ctx(lado_px=LAYER_PX):
    """Extrae la máscara booleana (lado_px x lado_px) de la traza válida del mosaico CTX a partir de `base_meridiani/1`."""
    z = 1
    n = 1 << z  # 2x2 teselas de 512 px = 1024x1024 px
    mosaico = Image.new("L", (n * 512, n * 512))
    for ty in range(n):
        for tx in range(n):
            p = os.path.join(BASE_DIR, str(z), str(tx), f"{ty}.jpg")
            mosaico.paste(Image.open(p).convert("L"), (tx * 512, ty * 512))
    if mosaico.size != (lado_px, lado_px):
        mosaico = mosaico.resize((lado_px, lado_px), Image.Resampling.BILINEAR)
    arr = np.asarray(mosaico, dtype=np.uint8)

    # El fondo sin datos fuera de la traza CTX es negro (<= 3 por compresión JPEG) y toca el borde exterior
    negro = arr <= 3
    etiquetas, _ = ndimage.label(negro)
    borde_ids = set(np.unique(etiquetas[0, :])) | set(np.unique(etiquetas[-1, :]))
    borde_ids |= set(np.unique(etiquetas[:, 0])) | set(np.unique(etiquetas[:, -1]))
    borde_ids.discard(0)
    fondo_exterior = np.isin(etiquetas, list(borde_ids))
    # Dilatar 2 px el fondo exterior para limpiar el anillo JPEG del borde del mosaico
    fondo_exterior = ndimage.binary_dilation(fondo_exterior, iterations=2)
    valida = ~fondo_exterior
    return valida


def descargar_dem_ventana():
    ruta = os.path.join(RAW_M, "dem_traza_200m.tif")
    if os.path.exists(ruta) and os.path.getsize(ruta) > 0:
        return ruta
    os.makedirs(RAW_M, exist_ok=True)
    margen = 0.08
    with rasterio.open(URL_DEM) as src:
        win = from_bounds(
            LON0 - margen, LAT0 - margen, LON1 + margen, LAT1 + margen, src.transform
        )
        win = win.round_offsets().round_lengths()
        datos = src.read(1, window=win)
        transform = src.window_transform(win)
        perfil = src.profile.copy()
        perfil.update(
            driver="GTiff",
            height=datos.shape[0],
            width=datos.shape[1],
            count=1,
            transform=transform,
            compress="deflate",
        )
        with rasterio.open(ruta, "w", **perfil) as dst:
            dst.write(datos, 1)
    print(f"DEM traza guardado: {ruta} ({datos.shape[1]}x{datos.shape[0]} px)")
    return ruta


def muestrear_dem(ruta_dem, n_celdas):
    with rasterio.open(ruta_dem) as src:
        win = from_bounds(LON0, LAT0, LON1, LAT1, src.transform)
        z = src.read(
            1,
            window=win,
            out_shape=(n_celdas, n_celdas),
            resampling=Resampling.bilinear,
        ).astype(np.float32)
        nodata = src.nodata
    if nodata is not None:
        z[z == nodata] = np.nan
    z, _ = rellenar_nan(z)
    return z


def color_pendiente_rgba(pend, mascara_valida):
    rgba = np.zeros((pend.shape[0], pend.shape[1], 4), dtype=np.uint8)
    m0 = (pend < 10.0) & mascara_valida
    m1 = (pend >= 10.0) & (pend < 20.0) & mascara_valida
    m2 = (pend >= 20.0) & (pend <= 25.0) & mascara_valida
    m3 = (pend > 25.0) & mascara_valida
    rgba[m0] = (46, 204, 113, 180)
    rgba[m1] = (241, 196, 15, 210)
    rgba[m2] = (230, 126, 34, 225)
    rgba[m3] = (231, 76, 60, 235)
    return rgba


def generar_transito_rgba(mascara_valida):
    os.makedirs(RAW_ASU, exist_ok=True)
    ruta_dci = os.path.join(RAW_ASU, "dci_16ppd.raw")
    _descargar(URL_DCI, ruta_dci)

    # 1. Leer DCI (16 ppd, 2880x5760 float32 little-endian, col 0 = -180 E)
    dci_global = np.fromfile(ruta_dci, dtype="<f4").reshape(2880, 5760)

    # 2. Descargar TI de ASU WMS (lon 330..360 E, lat -15..10, 240x200 int32 little-endian)
    ruta_ti = os.path.join(RAW_ASU, "ti_meridiani.vicar")
    if not os.path.exists(ruta_ti) or os.path.getsize(ruta_ti) < 10000:
        if os.path.exists(ruta_ti):
            os.remove(ruta_ti)
        url_ti = (
            f"{URL_TI_WMS}?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap"
            "&LAYERS=TES_Thermal_Inertia_numeric&STYLES=&SRS=EPSG:4326"
            "&BBOX=330,-15,360,10&WIDTH=240&HEIGHT=200&FORMAT=image/vicar"
        )
        _descargar(url_ti, ruta_ti)

    raw_ti = open(ruta_ti, "rb").read()
    lblsize = int(
        raw_ti[:200].decode("ascii", errors="ignore").split("LBLSIZE=")[1].split()[0]
    )
    ti_global = np.frombuffer(raw_ti[lblsize:], dtype="<i4", count=200 * 240).reshape(
        200, 240
    )

    ys = np.linspace(LAT1, LAT0, LAYER_PX, endpoint=False)
    xs = np.linspace(LON0, LON1, LAYER_PX, endpoint=False)
    lon_grid, lat_grid = np.meshgrid(xs, ys)

    row_dci = np.clip(((90.0 - lat_grid) * 16.0).astype(int), 0, 2879)
    col_dci = np.clip(((lon_grid + 180.0) * 16.0).astype(int), 0, 5759)
    dci = dci_global[row_dci, col_dci].astype(np.float32)

    row_ti = np.clip(((10.0 - lat_grid) / 0.125).astype(int), 0, 199)
    col_ti = np.clip((((lon_grid % 360.0) - 330.0) / 0.125).astype(int), 0, 239)
    ti = ti_global[row_ti, col_ti].astype(np.float32)

    verde = (dci > 0.96) & (ti > 300.0)
    amarillo = (~verde) & (dci > 0.95) & (ti >= 180.0) & (ti <= 300.0)
    rojo = (~verde) & (~amarillo) & (dci < 0.94) & (ti < 150.0)
    ninguno = (~verde) & (~amarillo) & (~rojo)

    rgba = np.zeros((LAYER_PX, LAYER_PX, 4), dtype=np.uint8)
    rgba[verde & mascara_valida] = (60, 170, 92, 175)
    rgba[amarillo & mascara_valida] = (230, 170, 40, 175)
    rgba[rojo & mascara_valida] = (210, 50, 50, 175)
    rgba[ninguno & mascara_valida] = (150, 150, 150, 70)
    return rgba


def generar_termica_noche_rgba(mascara_valida):
    z = 8
    n_rows = 1 << z
    n_cols = 2 << z
    deg_por_tesela = 180.0 / n_rows

    c0 = int((LON0 + 180.0) // deg_por_tesela)
    c1 = int((LON1 + 180.0) // deg_por_tesela)
    r0 = int((90.0 - LAT1) // deg_por_tesela)
    r1 = int((90.0 - LAT0) // deg_por_tesela)

    carpeta = os.path.join(RAW_M, f"termica_traza_z{z}")
    os.makedirs(carpeta, exist_ok=True)
    w_mos = (c1 - c0 + 1) * 256
    h_mos = (r1 - r0 + 1) * 256
    mosaico = Image.new("L", (w_mos, h_mos))

    for r in range(r0, r1 + 1):
        for c in range(c0, c1 + 1):
            destino = os.path.join(carpeta, f"{r}_{c}.png")
            url = f"{URL_TREK}/{CAPA_TERMICA}/1.0.0/default/default028mm/{z}/{r}/{c}.png"
            _descargar(url, destino)
            tesela = Image.open(destino).convert("L")
            mosaico.paste(tesela, ((c - c0) * 256, (r - r0) * 256))

    lon_mos0 = -180.0 + c0 * deg_por_tesela
    lat_mos1 = 90.0 - r0 * deg_por_tesela
    deg_por_px = deg_por_tesela / 256.0

    px0 = (LON0 - lon_mos0) / deg_por_px
    px1 = (LON1 - lon_mos0) / deg_por_px
    py0 = (lat_mos1 - LAT1) / deg_por_px
    py1 = (lat_mos1 - LAT0) / deg_por_px

    recorte = mosaico.crop((round(px0), round(py0), round(px1), round(py1)))
    gris = np.asarray(
        recorte.resize((LAYER_PX, LAYER_PX), Image.Resampling.BICUBIC), dtype=np.float32
    )
    validos = gris[(mascara_valida) & (gris > 0)]
    p2, p98 = np.percentile(validos, (2, 98)) if validos.size else (0.0, 255.0)
    est = np.clip((gris - p2) / max(p98 - p2, 1.0), 0.0, 1.0)
    gris_u8 = (est * 255.0).astype(np.uint8)
    rgba = np.zeros((LAYER_PX, LAYER_PX, 4), dtype=np.uint8)
    rgba[..., 0] = gris_u8
    rgba[..., 1] = gris_u8
    rgba[..., 2] = gris_u8
    rgba[..., 3] = np.where(mascara_valida & (gris > 0), 255, 0).astype(np.uint8)
    return rgba


def _a_xy_nuevo(lon, lat):
    e = math.radians(lon) * R_MARTE
    n = math.radians(lat) * R_MARTE
    return round(e - X0, 1), round(Y0 - n, 1)


def _en_traza(x_m, y_m, mascara_valida):
    if x_m < 0 or y_m < 0 or x_m >= SIZE_M or y_m >= SIZE_M:
        return False
    col = min(int(x_m / SIZE_M * LAYER_PX), LAYER_PX - 1)
    row = min(int(y_m / SIZE_M * LAYER_PX), LAYER_PX - 1)
    return bool(mascara_valida[row, col])


def actualizar_vectores(mascara_valida):
    import re

    ruta_vec = os.path.join(SITE_DIR, "vectors.json")
    with open(ruta_vec, encoding="utf-8") as f:
        vec = json.load(f)

    ya_trasladado = vec.get("frame_m") == [0.0, 0.0, SIZE_M]
    dx = 0.0 if ya_trasladado else DX_OLD_TO_NEW
    dy = 0.0 if ya_trasladado else DY_OLD_TO_NEW

    # 1. Conservar y trasladar `zone`, `mineral`, `valley` al nuevo origen (0..327680 m)
    conservados = []
    for feat in vec.get("features", []):
        kind = feat.get("kind")
        if kind in ("zone", "mineral"):
            nf = dict(feat)
            if "x_m" in nf and nf["x_m"] is not None:
                nf["x_m"] = round(nf["x_m"] + dx, 1)
                nf["y_m"] = round(nf["y_m"] + dy, 1)
            if "ring" in nf and nf["ring"]:
                nf["ring"] = [
                    [round(pt[0] + dx, 1), round(pt[1] + dy, 1)]
                    for pt in nf["ring"]
                ]
            conservados.append(nf)
        elif kind == "valley":
            nf = dict(feat)
            nf["paths"] = [
                [
                    [round(pt[0] + dx, 1), round(pt[1] + dy, 1)]
                    for pt in path
                ]
                for path in feat.get("paths", [])
            ]
            conservados.append(nf)

    # 2. Descargar cráteres Robbins (D >= 1 km) y nombres UAI para toda la ventana de Sinus Meridiani
    os.makedirs(RAW_RASGOS, exist_ok=True)
    bbox_str = f"{LON0:.4f},{LAT0:.4f},{LON1:.4f},{LAT1:.4f}"

    ruta_crat = os.path.join(RAW_RASGOS, "meridiani_traza_craters.json")
    url_crat = f"{URL_ROBBINS}?f=json&limit=10000&bbox={bbox_str}"
    _descargar(url_crat, ruta_crat)
    with open(ruta_crat, encoding="utf-8") as f:
        crat_raw = json.load(f)

    crat_list = []
    for item in crat_raw.get("features", []):
        p = item.get("properties") or {}
        d_km = float(p.get("diamkm") or 0.0)
        if d_km < 1.0:
            continue
        lon_e = float(p.get("lon_e") or 0.0)
        lon = lon_e if lon_e <= 180.0 else lon_e - 360.0
        lat = float(p.get("lat") or 0.0)
        x_m, y_m = _a_xy_nuevo(lon, lat)
        if not _en_traza(x_m, y_m, mascara_valida):
            continue
        crat_list.append(
            {
                "kind": "crater",
                "id": str(p.get("craterid") or ""),
                "x_m": x_m,
                "y_m": y_m,
                "d_m": round(d_km * 1000.0, 0),
            }
        )
    crat_list.sort(key=lambda c: -c["d_m"])
    conservados.extend(crat_list)

    ruta_cat = os.path.join(RAW_RASGOS, "catalogo_trek.json")
    _descargar(f"{URL_NOMENCLATURA}?rows=2100", ruta_cat)
    with open(ruta_cat, encoding="utf-8") as f:
        cat_raw = json.load(f)
    docs = (
        cat_raw
        if isinstance(cat_raw, list)
        else (cat_raw.get("response") or {}).get("docs", [])
    )
    for x in docs:
        if x.get("itemType") != "nomenclature":
            continue
        m = re.match(r"POINT\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)", str(x.get("shape", "")))
        if not m:
            continue
        lon, lat = float(m.group(1)), float(m.group(2))
        if not (LON0 <= lon <= LON1 and LAT0 <= lat <= LAT1):
            continue
        x_m, y_m = _a_xy_nuevo(lon, lat)
        if not _en_traza(x_m, y_m, mascara_valida):
            continue
        tipo = str(x.get("productCat2") or x.get("keyword") or "").split(",")[0]
        conservados.append(
            {
                "kind": "name",
                "name": x.get("title", ""),
                "type": tipo,
                "x_m": x_m,
                "y_m": y_m,
            }
        )

    vec["frame_m"] = [0.0, 0.0, SIZE_M]
    vec["science_extent"] = {
        "name": "Mosaico CTX de Sinus Meridiani (traza completa)",
        "x_m": 0.0,
        "y_m": 0.0,
        "size_m": SIZE_M,
        "lon_range": [round(LON0, 3), round(LON1, 3)],
        "lat_range": [round(LAT0, 3), round(LAT1, 3)],
    }
    vec["features"] = conservados
    with open(ruta_vec, "w", encoding="utf-8") as f:
        json.dump(vec, f, indent=2, ensure_ascii=False)
    print(f"Vectores actualizados: {len(conservados)} rasgos en {ruta_vec}")


def main():
    os.makedirs(os.path.join(SITE_DIR, "grid"), exist_ok=True)
    os.makedirs(os.path.join(SITE_DIR, "layers"), exist_ok=True)

    # 1. Máscara de la traza válida del mosaico CTX
    mascara_1024 = mascara_traza_ctx(LAYER_PX)
    mascara_512 = mascara_traza_ctx(GRID_N)
    frac_valida = float(mascara_1024.mean()) * 100.0
    print(f"Máscara traza CTX: {frac_valida:.1f}% del recuadro de 327,68 km tiene datos CTX")

    # 2. DEM y rejilla de ruteo (512x512, celda de 640 m) + capa de Relieve (1024x1024)
    ruta_dem = descargar_dem_ventana()
    z_512 = muestrear_dem(ruta_dem, GRID_N)
    z_suave_512 = ndimage.gaussian_filter(z_512, sigma=1.5)
    pend_512 = pendiente_grados(z_suave_512, CELL_M)
    rug_512 = np.abs(z_512 - ndimage.uniform_filter(z_512, size=5)) * 100.0
    prohib_512 = ((pend_512 > 25.0) | (~mascara_512)).astype(np.uint8)

    z_1024 = muestrear_dem(ruta_dem, LAYER_PX)
    z_suave_1024 = ndimage.gaussian_filter(z_1024, sigma=1.5)
    pend_1024 = pendiente_grados(z_suave_1024, SIZE_M / LAYER_PX)

    # Binarios de la rejilla
    s_u8 = np.clip(np.rint(pend_512 / 0.25), 0, 254).astype(np.uint8)
    s_u8[~mascara_512] = 255
    r_u8 = np.clip(np.rint(rug_512 / 0.5), 0, 254).astype(np.uint8)
    r_u8[~mascara_512] = 255

    z_min = float(np.nanmin(z_512))
    offset = math.floor(z_min - 10.0)
    z_u16 = np.clip(np.rint((z_512 - offset) / 0.1), 0, 65534).astype("<u2")
    z_u16[~mascara_512] = 65535

    s_u8.tofile(os.path.join(SITE_DIR, "grid", "slope.bin"))
    r_u8.tofile(os.path.join(SITE_DIR, "grid", "rough.bin"))
    prohib_512.tofile(os.path.join(SITE_DIR, "grid", "forbidden.bin"))
    z_u16.tofile(os.path.join(SITE_DIR, "grid", "elev.bin"))

    # 3. Capas PNG (1024x1024) recortadas a la traza válida del mosaico CTX
    slope_rgba = color_pendiente_rgba(pend_1024, mascara_1024)
    Image.fromarray(slope_rgba).save(os.path.join(SITE_DIR, "layers", "slope.png"), optimize=True)

    transit_rgba = generar_transito_rgba(mascara_1024)
    Image.fromarray(transit_rgba).save(os.path.join(SITE_DIR, "layers", "transit.png"), optimize=True)

    termica_rgba = generar_termica_noche_rgba(mascara_1024)
    Image.fromarray(termica_rgba).save(os.path.join(SITE_DIR, "layers", "thermal_night.png"), optimize=True)

    # 4. Hábitat (Opportunity landing site) y objetivos trasladados al nuevo origen
    with open(os.path.join(SITE_DIR, "site.json"), encoding="utf-8") as f:
        site_old = json.load(f)
    hab_old = site_old["habitat"]
    if float(hab_old["x_m"]) < 100000.0:
        hab_x = round(float(hab_old["x_m"]) + DX_OLD_TO_NEW, 1)
        hab_y = round(float(hab_old["y_m"]) + DY_OLD_TO_NEW, 1)
    else:
        hab_x = round(float(hab_old["x_m"]), 1)
        hab_y = round(float(hab_old["y_m"]), 1)
    hab_col = min(max(int(hab_x // CELL_M), 0), GRID_N - 1)
    hab_row = min(max(int(hab_y // CELL_M), 0), GRID_N - 1)
    prohib_512[hab_row, hab_col] = 0
    prohib_512.tofile(os.path.join(SITE_DIR, "grid", "forbidden.bin"))

    with open(os.path.join(SITE_DIR, "objectives.json"), encoding="utf-8") as f:
        obj_data = json.load(f)
    for o in obj_data.get("objectives", []):
        # Si aún están en el marco de 100 km (< 100000), trasladar
        if o["x_m"] < 100000.0 and o["y_m"] < 100000.0:
            o["x_m"] = round(float(o["x_m"]) + DX_OLD_TO_NEW, 1)
            o["y_m"] = round(float(o["y_m"]) + DY_OLD_TO_NEW, 1)
        c_o = min(max(int(o["x_m"] // CELL_M), 0), GRID_N - 1)
        r_o = min(max(int(o["y_m"] // CELL_M), 0), GRID_N - 1)
        o["elev_m"] = round(float(z_512[r_o, c_o]), 1)
    with open(os.path.join(SITE_DIR, "objectives.json"), "w", encoding="utf-8") as f:
        json.dump(obj_data, f, indent=2, ensure_ascii=False)

    # 5. `params.json` y `site.json`
    with open(PARAMS_BASE, encoding="utf-8") as f:
        par = json.load(f)
    par["site"]["name"] = "Meridiani Planum — Sinus Meridiani (CTX)"
    par["site"]["box"] = {
        "easting_min": X0,
        "northing_max": Y0,
        "size_m": SIZE_M,
        "base_cell_m": CELL_M,
    }
    par["site"]["habitat_xy_m"] = [hab_x, hab_y]
    par["routing"]["cell_m"] = CELL_M
    with open(os.path.join(SITE_DIR, "params.json"), "w", encoding="utf-8") as f:
        json.dump(par, f, indent=2, ensure_ascii=False)

    site_meta = {
        "name": "Meridiani Planum — Sinus Meridiani (CTX)",
        "quality": "indicative",
        "crs": "+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +a=3396190 +b=3396190 +units=m +no_defs",
        "georeference": {
            "projection": "Equirectangular (sphere R = 3396190 m, lon_0 = 0, lat_0 = 0)",
            "origin": "top_left (northwest corner of the site box)",
            "origin_easting_m": X0,
            "origin_northing_m": Y0,
            "origin_lon_deg": round(LON0, 6),
            "origin_lat_deg": round(LAT1, 6),
            "x_axis": "east (+m from origin)",
            "y_axis": "south (+m from origin)",
            "radius_m": R_MARTE,
            "formula_lon_deg": "(origin_easting_m + x_m) / radius_m * 180 / pi",
            "formula_lat_deg": "(origin_northing_m - y_m) / radius_m * 180 / pi",
        },
        "frame": {"size_m": SIZE_M, "pixel_m": CELL_M},
        "habitat": {
            "x_m": hab_x,
            "y_m": hab_y,
            "row": hab_row,
            "col": hab_col,
            "elev_m": round(float(z_512[hab_row, hab_col]), 1),
            "slope_deg": round(float(pend_512[hab_row, hab_col]), 2),
            "note": hab_old.get("note", "Opportunity landing site (Challenger Memorial Station)"),
        },
        "tiles": {
            "asset_dir": "base_meridiani",
            "tile_px": 512,
            "max_zoom": 4,
            "world_size_m": SIZE_M,
            "m_per_px": [640.0, 320.0, 160.0, 80.0, 40.0],
        },
        "layers": {
            "slope": {"file": "layers/slope.png", "width": LAYER_PX, "height": LAYER_PX},
            "transit": {"file": "layers/transit.png", "width": LAYER_PX, "height": LAYER_PX},
            "thermal_night": {
                "file": "layers/thermal_night.png",
                "width": LAYER_PX,
                "height": LAYER_PX,
            },
        },
        "grid": {
            "width": GRID_N,
            "height": GRID_N,
            "cell_m": CELL_M,
            "order": "row_major_north_to_south_west_to_east",
            "components": {
                "slope": {"file": "grid/slope.bin", "dtype": "u8", "unit_deg": 0.25, "nodata": 255},
                "rough": {"file": "grid/rough.bin", "dtype": "u8", "unit_cm": 0.5, "nodata": 255},
                "forbidden": {"file": "grid/forbidden.bin", "dtype": "u8"},
                "elev": {
                    "file": "grid/elev.bin",
                    "dtype": "u16le",
                    "unit_m": 0.1,
                    "offset_m": offset,
                    "nodata": 65535,
                },
            },
        },
    }
    with open(os.path.join(SITE_DIR, "site.json"), "w", encoding="utf-8") as f:
        json.dump(site_meta, f, indent=2, ensure_ascii=False)

    # 6. Actualizar vectores
    actualizar_vectores(mascara_1024)
    print("Sitio `site_meridiani_regional` ampliado a toda la traza de Sinus Meridiani.")


if __name__ == "__main__":
    main()

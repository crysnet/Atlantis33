"""F4: descarga los datos de las dos ventanas locales de Meridiani (recuadros de 4 x 4 km y de 20 x 20 km).

Ventana "endeavour" (4 x 4 km, borde del cráter Endeavour, calidad alta):
  - recorte del DEM de 1 m de Mars Trek (el archivo entero pesa 704 MB y el servidor no admite rangos HTTP, así que se
    usa una copia local ya bajada con --dem-completo; el recorte queda en data/raw/meridiani_endeavour/dem_box_1m.tif)
  - teselas HiRISE de Mars Trek, nivel 17 (0.32 m por píxel), en data/raw/meridiani_endeavour/hirise_z17/
Ventana "habitat" (20 x 20 km, zona habitable de Meridiani Planum, indicativa):
  - recorte del DEM global MOLA y HRSC de 200 m del USGS, por rangos HTTP (~21 MB)
  - teselas CTX de Mars Trek, nivel 12 (10 m por píxel), en data/raw/meridiani_habitat/ctx_z12/

Uso (desde tools/):
    python3 10_meridiani_datos.py dem-endeavour --dem-completo RUTA/DEM_1m_Endeavour.tif
    python3 10_meridiani_datos.py teselas-endeavour
    python3 10_meridiani_datos.py dem-habitat
    python3 10_meridiani_datos.py teselas-habitat
Ventana "regional" (100 x 100 km centrada en la zona habitable; contexto de capas, rutas solo indicativas):
  - recorte del DEM de 200 m a 400 m por píxel, leído de la pirámide (.ovr) del USGS (~10 s)
  - teselas CTX de Mars Trek, nivel 11 (20 m por píxel), en data/raw/meridiani_regional/ctx_z11/
  - teselas THEMIS-IR noche de Mars Trek, nivel 9 (81 m por píxel), en data/raw/meridiani_regional/themis_noche_z9/

    python3 10_meridiani_datos.py dem-regional | teselas-regional | termica-noche
Mapas base de toda la región a 40 m (CTX completo de Trek, nivel 10): `python3 10_meridiani_datos.py base`.
Alcance de la EVA de Endeavour (22 km; baja el DEM de 704 MB): `python3 10_meridiani_datos.py alcance-endeavour`.
Alcance de la EVA de Gale (24 km, DEM de 16 m por la pirámide del USGS y teselas HiRISE de Trek nivel 14): `python3 10_meridiani_datos.py alcance-gale`.
Marcos de contexto (CTX de Trek alrededor de cada ventana: Gale 40 km, Endeavour 40 km, regional 200 km): `python3 10_meridiani_datos.py contexto`.
Cada paso reutiliza lo que ya está en disco. Fuentes y fechas en RECURSOS.md.
"""
import argparse
import math
import os
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor

import numpy as np
import rasterio
from rasterio.windows import Window

import common

R = common.R_MARTE
UA = {"User-Agent": "research-client"}

# Ventanas en metros del plano equirectangular de los mosaicos (x = R * lon, y = R * lat, con lon y lat en radianes).
# Endeavour: filas 10000 a 14000 y columnas 2500 a 6500 del DEM de 1 m, desde su esquina noroeste.
DEM_ENDEAVOUR_NO = (-322850.02192614024, -125884.13518831744)
ENDEAVOUR = {"x0": DEM_ENDEAVOUR_NO[0] + 2500.0, "y0": DEM_ENDEAVOUR_NO[1] - 10000.0, "size_m": 4000.0}
# Zona habitable de Meridiani Planum (lat -3.085, lon -5.50, EZMars de Mars Trek), recuadro de 20 km centrado en ella.
_HAB_C = (math.radians(-5.50) * R, math.radians(-3.085) * R)
HABITAT = {"x0": _HAB_C[0] - 10000.0, "y0": _HAB_C[1] + 10000.0, "size_m": 20000.0}

REGIONAL = {"x0": _HAB_C[0] - 50000.0, "y0": _HAB_C[1] + 50000.0, "size_m": 100000.0}

# Marcos de contexto (F5b): imagen más gruesa alrededor de cada ventana, para que el mapa no termine en un recuadro negro.
_GC = (8141400.0 + 2000.0, -282750.0 - 2000.0)  # centro de la ventana de Gale (el recuadro de config/params.json)
GALE_CTX = {"x0": _GC[0] - 20000.0, "y0": _GC[1] + 20000.0, "size_m": 40000.0}
_EC = (ENDEAVOUR["x0"] + 2000.0, ENDEAVOUR["y0"] - 2000.0)
ENDEAVOUR_CTX = {"x0": _EC[0] - 20000.0, "y0": _EC[1] + 20000.0, "size_m": 40000.0}
REGIONAL_CTX = {"x0": _HAB_C[0] - 100000.0, "y0": _HAB_C[1] + 100000.0, "size_m": 200000.0}
RAW_C = os.path.join(common.RAW, "contexto")
# Alcance de la EVA (B): ventana de 24 km alrededor de la de Gale (una EVA llega a unos 12 km del hábitat)
GALE_REACH = {"x0": _GC[0] - 12000.0, "y0": _GC[1] + 12000.0, "size_m": 24000.0}
RAW_GR = os.path.join(common.RAW, "gale_alcance")
# Mapas base de toda la región a 40 m (CTX completo de Trek, nivel 10): mundo cuadrado de 327 680 m (8192 px a 40 m)
BASE_M = 327680.0
BASE_GALE = {"x0": math.radians(134.45) * R, "y0": math.radians(-1.93) * R, "size_m": BASE_M}
BASE_MERIDIANI = {"x0": math.radians(-8.208) * R, "y0": math.radians(0.013) * R, "size_m": BASE_M}
RAW_B = os.path.join(common.RAW, "base")
# Alcance de la EVA de Endeavour: 22 km, de norte a sur sobre todo el DEM de 1 m (8 x 22 km) y 7 km al oeste de él
ENDEAVOUR_REACH = {"x0": DEM_ENDEAVOUR_NO[0] - 7000.0, "y0": DEM_ENDEAVOUR_NO[1], "size_m": 22000.0}
RAW_ER = os.path.join(common.RAW, "endeavour_alcance")
URL_DEM_ENDEAVOUR = "https://trek.nasa.gov/mars/TrekWS/rest/cat/data/stream?label=DEM_1m_Endeavour_Crater_isis3_2017-04-14"
URL_DEM_GALE = "https://planetarymaps.usgs.gov/mosaic/Mars/MSL/MSL_Gale_DEM_Mosaic_1m_v3.tif"

RAW_R = os.path.join(common.RAW, "meridiani_regional")
RAW_E = os.path.join(common.RAW, "meridiani_endeavour")
RAW_H = os.path.join(common.RAW, "meridiani_habitat")
URL_DEM_200 = "https://planetarymaps.usgs.gov/mosaic/Mars/HRSC_MOLA_Blend/Mars_HRSC_MOLA_BlendDEM_Global_200mp_v2.tif"
URL_TESELA = "https://trek.nasa.gov/tiles/Mars/EQ/%s/1.0.0/default/default028mm/%d/%d/%d.png"


def lonlat(x, y):
    return math.degrees(x / R), math.degrees(y / R)


def teselas_de(v, z):
    """Filas y columnas de las teselas WMTS (esquema EQ de Trek) que cubren la ventana, con una tesela de margen."""
    lon0, lat1 = lonlat(v["x0"], v["y0"])
    lon1, lat0 = lonlat(v["x0"] + v["size_m"], v["y0"] - v["size_m"])
    deg = 360.0 / 2 ** (z + 1)
    c0, c1 = int((lon0 + 180) // deg) - 1, int((lon1 + 180) // deg) + 1
    r0, r1 = int((90 - lat1) // deg) - 1, int((90 - lat0) // deg) + 1
    return [(r, c) for r in range(r0, r1 + 1) for c in range(c0, c1 + 1)], deg


def bajar_teselas(producto, z, v, carpeta):
    lista, deg = teselas_de(v, z)
    os.makedirs(carpeta, exist_ok=True)

    def una(rc):
        r, c = rc
        ruta = os.path.join(carpeta, str(z), str(r), f"{c}.png")
        if os.path.exists(ruta) and os.path.getsize(ruta) > 0:
            return "ya", 0
        os.makedirs(os.path.dirname(ruta), exist_ok=True)
        for intento in range(3):
            try:
                with urllib.request.urlopen(urllib.request.Request(URL_TESELA % (producto, z, r, c), headers=UA), timeout=60) as resp:
                    datos = resp.read()
                with open(ruta + ".tmp", "wb") as f:
                    f.write(datos)
                os.replace(ruta + ".tmp", ruta)
                return "ok", len(datos)
            except urllib.error.HTTPError as e:
                if e.code == 404:
                    return "sin_dato", 0
            except Exception:
                pass
        return "error", 0

    res = {"ok": 0, "ya": 0, "sin_dato": 0, "error": 0}
    total = 0
    with ThreadPoolExecutor(max_workers=8) as ex:
        for i, (estado, n) in enumerate(ex.map(una, lista), 1):
            res[estado] += 1
            total += n
            if i % 250 == 0:
                print(f"  {i}/{len(lista)} {res}", flush=True)
    print(f"{producto} nivel {z}: {len(lista)} teselas pedidas, {res}, {total / 1e6:.1f} MB nuevos; {deg / 180 * math.pi * R / 256:.3f} m por píxel")
    with open(os.path.join(carpeta, f"z{z}.json"), "w") as f:
        import json

        json.dump({"product": producto, "z": z, "deg": deg, "rows_cols": [list(rc) for rc in lista], "result": res}, f)
    return res


def recortar(origen, destino, v, reducir=1):
    """Recorta la ventana v de un GeoTIFF en metros o en grados y la guarda como GeoTIFF en metros del plano equirectangular."""
    with rasterio.open(origen) as ds:
        en_grados = ds.crs is not None and ds.crs.is_geographic
        if en_grados:
            lon0, lat1 = lonlat(v["x0"], v["y0"])
            lon1, lat0 = lonlat(v["x0"] + v["size_m"], v["y0"] - v["size_m"])
            r0, c0 = ds.index(lon0, lat1)
            r1, c1 = ds.index(lon1, lat0)
            paso = ds.res[0]  # grados por píxel
            r1, c1 = max(r1, r0 + 1), max(c1, c0 + 1)
            win = Window(c0, r0, c1 - c0, r1 - r0)
            a = ds.read(1, window=win, out_shape=(win.height // reducir, win.width // reducir)) if reducir > 1 else ds.read(1, window=win)
            # esquina noroeste real del recorte, en metros
            e0 = math.radians(ds.transform.c + c0 * ds.transform.a) * R
            n0 = math.radians(ds.transform.f + r0 * ds.transform.e) * R
            res_m = math.radians(paso) * R * (win.width / a.shape[1])
        else:
            r0, c0 = ds.index(v["x0"], v["y0"])
            n = int(round(v["size_m"] / ds.res[0]))
            win = Window(c0, r0, n, n)
            # boundless: la ventana puede salirse del archivo (alcance de Endeavour); lo de fuera queda sin dato
            a = ds.read(1, window=win, out_shape=(n // reducir, n // reducir), boundless=True, fill_value=ds.nodata) if reducir > 1 else ds.read(1, window=win, boundless=True, fill_value=ds.nodata)
            e0, n0, res_m = ds.transform.c + c0 * ds.transform.a, ds.transform.f + r0 * ds.transform.e, ds.res[0] * reducir
        nod = ds.nodata
        dtype = ds.dtypes[0]
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    tr = rasterio.transform.from_origin(e0, n0, res_m, res_m)
    prm = {"driver": "GTiff", "height": a.shape[0], "width": a.shape[1], "count": 1, "dtype": dtype, "nodata": nod,
           "transform": tr, "compress": "lzw", "crs": f"+proj=eqc +lat_ts=0 +lat_0=0 +lon_0=0 +x_0=0 +y_0=0 +R={R} +units=m +no_defs"}
    with rasterio.open(destino, "w", **prm) as out:
        out.write(a, 1)
    valido = np.isfinite(a) & (a != nod)
    print(f"{destino}: {a.shape[1]} x {a.shape[0]} px a {res_m:.3f} m, válido {100 * valido.mean():.1f} %, "
          f"elevación {a[valido].min():.0f} a {a[valido].max():.0f} m, {os.path.getsize(destino) / 1e6:.1f} MB")
    return destino


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("paso", choices=["base", "alcance-endeavour", "alcance-gale", "contexto", "dem-endeavour", "teselas-endeavour", "dem-habitat", "teselas-habitat", "dem-regional", "teselas-regional", "termica-noche"])
    ap.add_argument("--dem-completo", help="ruta del DEM de 1 m de Endeavour ya bajado (704 MB), solo para dem-endeavour")
    args = ap.parse_args()
    if args.paso == "base":
        bajar_teselas("Gale_CTX_BlockAdj_dd", 10, BASE_GALE, os.path.join(RAW_B, "gale_ctx_z10"))
        bajar_teselas("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 10, BASE_MERIDIANI, os.path.join(RAW_B, "meridiani_ctx_z10"))
    elif args.paso == "alcance-endeavour":
        os.makedirs(RAW_ER, exist_ok=True)
        completo = os.path.join(RAW_ER, "DEM_1m_Endeavour_completo.tif")
        if not os.path.exists(completo) or os.path.getsize(completo) != 703735672:
            print("bajando el DEM de 1 m de Endeavour (704 MB; el servidor no admite rangos)...", flush=True)
            with urllib.request.urlopen(urllib.request.Request(URL_DEM_ENDEAVOUR, headers=UA), timeout=600) as r, open(completo + ".tmp", "wb") as f:
                while True:
                    bloque = r.read(1 << 20)
                    if not bloque:
                        break
                    f.write(bloque)
            os.replace(completo + ".tmp", completo)
        print(f"DEM completo: {os.path.getsize(completo) / 1e6:.0f} MB")
        recortar(completo, os.path.join(RAW_ER, "dem_fino_16m.tif"), ENDEAVOUR_REACH, reducir=16)
        recortar(URL_DEM_200, os.path.join(RAW_ER, "dem_grueso_200m.tif"), ENDEAVOUR_REACH, reducir=1)
        bajar_teselas("opportunity_hirise_mosaic", 14, ENDEAVOUR_REACH, os.path.join(RAW_ER, "hirise_z14"))
    elif args.paso == "alcance-gale":
        recortar(URL_DEM_GALE, os.path.join(RAW_GR, "dem_box_16m.tif"), GALE_REACH, reducir=16)
        bajar_teselas("curiosity_hirise_mosaic", 14, GALE_REACH, os.path.join(RAW_GR, "hirise_z14"))
    elif args.paso == "contexto":
        bajar_teselas("Gale_CTX_BlockAdj_dd", 11, GALE_CTX, os.path.join(RAW_C, "gale_ctx_z11"))
        bajar_teselas("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 11, ENDEAVOUR_CTX, os.path.join(RAW_C, "endeavour_ctx_z11"))
        bajar_teselas("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 9, REGIONAL_CTX, os.path.join(RAW_C, "regional_ctx_z9"))
    elif args.paso == "dem-endeavour":
        if not args.dem_completo:
            sys.exit("falta --dem-completo (el servidor de Trek no admite rangos: hay que bajar el archivo entero, 704 MB)")
        recortar(args.dem_completo, os.path.join(RAW_E, "dem_box_1m.tif"), ENDEAVOUR)
    elif args.paso == "teselas-endeavour":
        bajar_teselas("opportunity_hirise_mosaic", 17, ENDEAVOUR, os.path.join(RAW_E, "hirise_z17"))
    elif args.paso == "dem-habitat":
        recortar(URL_DEM_200, os.path.join(RAW_H, "dem_box_200m.tif"), HABITAT)
    elif args.paso == "teselas-habitat":
        bajar_teselas("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 12, HABITAT, os.path.join(RAW_H, "ctx_z12"))
    elif args.paso == "dem-regional":
        recortar(URL_DEM_200, os.path.join(RAW_R, "dem_box_400m.tif"), REGIONAL, reducir=2)
    elif args.paso == "teselas-regional":
        bajar_teselas("S_Meridiani_Sinus_Planium_CTX_BlockAdj_dd", 11, REGIONAL, os.path.join(RAW_R, "ctx_z11"))
    else:
        bajar_teselas("THEMIS_NightIR_ControlledMosaics_100m_v2_oct2018", 9, REGIONAL, os.path.join(RAW_R, "themis_noche_z9"))


if __name__ == "__main__":
    main()

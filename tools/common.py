"""Utilidades comunes de los scripts de preparación de datos (fase 1)."""
import json
import math
import os

import numpy as np

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(RAIZ, "data", "raw")
WORK = os.path.join(RAIZ, "data", "work")
SALIDA = os.path.join(RAIZ, "app", "assets", "site_gale")
DOCS = os.path.join(RAIZ, "docs")
PARAMS_PATH = os.path.join(RAIZ, "config", "params.json")

R_MARTE = 3396190.0  # radio de la esfera de referencia de los mosaicos (m)

DEM_RAW = os.path.join(RAW, "dem_box_1m.tif")
ORTHO_RAW = os.path.join(RAW, "lrgb_box_025m.tif")
WAYPOINTS = os.path.join(RAW, "MSL_waypoints.json")
DEM_1M = os.path.join(WORK, "dem_1m.tif")
DEM_2M = os.path.join(WORK, "dem_2m.tif")
SLOPE_2M = os.path.join(WORK, "slope_2m.tif")
ROUGH_2M = os.path.join(WORK, "rough_2m.tif")
HILLSHADE_2M = os.path.join(WORK, "hillshade_2m.tif")
COSTOS_DIR = os.path.join(WORK, "costos")


def params():
    with open(PARAMS_PATH, encoding="utf-8") as f:
        return json.load(f)


def a_lonlat(e, n):
    """Metros de la proyección de los mosaicos a grados planetocéntricos, este positivo."""
    return math.degrees(e / R_MARTE), math.degrees(n / R_MARTE)


def caja(p=None):
    p = p or params()
    b = p["site"]["box"]
    return b["easting_min"], b["northing_max"], b["size_m"]


def bloque_medio(a, k):
    """Media de bloques de k x k, ignorando NaN. Un bloque sin datos queda en NaN."""
    h, w = (a.shape[0] // k) * k, (a.shape[1] // k) * k
    b = a[:h, :w].reshape(h // k, k, w // k, k)
    valido = np.isfinite(b)
    suma = np.where(valido, b, 0.0).sum(axis=(1, 3))
    n = valido.sum(axis=(1, 3))
    with np.errstate(invalid="ignore", divide="ignore"):
        return np.where(n > 0, suma / n, np.nan)


def pendiente_grados(z, paso):
    gy, gx = np.gradient(z, paso)
    return np.degrees(np.arctan(np.hypot(gx, gy)))


def sombreado(z, paso, azimut=315.0, altura=35.0):
    """Relieve sombreado de 0 a 1. Azimut en grados desde el norte, en sentido horario."""
    gy, gx = np.gradient(z, paso)
    pend = np.arctan(np.hypot(gx, gy))
    asp = np.arctan2(-gx, gy)
    az, al = np.radians(360.0 - azimut + 90.0), np.radians(altura)
    hs = np.sin(al) * np.cos(pend) + np.cos(al) * np.sin(pend) * np.cos(az - asp)
    return np.clip(hs, 0.0, 1.0)


def rellenar_nan(z):
    """Sustituye NaN por el valor válido más cercano, para poder filtrar. Devuelve el arreglo y la máscara de NaN."""
    from scipy import ndimage

    malo = ~np.isfinite(z)
    if not malo.any():
        return z, malo
    idx = ndimage.distance_transform_edt(malo, return_distances=False, return_indices=True)
    return z[tuple(idx)], malo


def escribir_tif(ruta, datos, transform, crs, nodata=None, dtype=None):
    import rasterio

    datos = np.asarray(datos)
    if datos.ndim == 2:
        datos = datos[None]
    with rasterio.open(
        ruta,
        "w",
        driver="GTiff",
        height=datos.shape[1],
        width=datos.shape[2],
        count=datos.shape[0],
        dtype=dtype or datos.dtype,
        crs=crs,
        transform=transform,
        nodata=nodata,
        compress="deflate",
        tiled=True,
        blockxsize=256,
        blockysize=256,
        predictor=3 if np.issubdtype(datos.dtype, np.floating) else 2,
    ) as dst:
        dst.write(datos.astype(dtype or datos.dtype))

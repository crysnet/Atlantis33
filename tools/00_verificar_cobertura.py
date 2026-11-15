"""Fase 0: comprueba la cobertura y la calidad de la ventana descargada y genera imágenes de revisión.

Lee data/raw/dem_box_1m.tif y data/raw/lrgb_box_025m.tif. Escribe en data/work/:
  quicklook_hillshade.png, quicklook_slope.png, quicklook_lrgb.png

Uso (desde la raíz del proyecto):
    python3 tools/00_verificar_cobertura.py
"""
import json
import os

import numpy as np
import rasterio
from PIL import Image, ImageDraw
from scipy import ndimage

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(RAIZ, "data", "raw")
WORK = os.path.join(RAIZ, "data", "work")

# Soles en que Curiosity trabajó las crestas boxwork (rango de la tabla de waypoints).
SOL_MIN, SOL_MAX = 4500, 4900

CLASES = [(0, 10, "<10 (nominal)"), (10, 20, "10-20 (precaución)"), (20, 25, "20-25"), (25, 91, ">25 (prohibida)")]
COLORES = {0: (60, 170, 90), 1: (230, 170, 40), 2: (230, 110, 40), 3: (210, 50, 50)}


def pendiente_grados(z, paso):
    gy, gx = np.gradient(z, paso)
    return np.degrees(np.arctan(np.hypot(gx, gy)))


def bloque_medio(z, k):
    h, w = (z.shape[0] // k) * k, (z.shape[1] // k) * k
    return z[:h, :w].reshape(h // k, k, w // k, k).mean(axis=(1, 3))


def sombreado(z, paso, azimut=315, altura=35):
    gy, gx = np.gradient(z, paso)
    pend = np.arctan(np.hypot(gx, gy))
    asp = np.arctan2(-gx, gy)
    az, al = np.radians(360 - azimut + 90), np.radians(altura)
    hs = np.sin(al) * np.cos(pend) + np.cos(al) * np.sin(pend) * np.cos(az - asp)
    return np.clip(hs, 0, 1)


def main():
    with rasterio.open(os.path.join(RAW, "dem_box_1m.tif")) as d:
        z = d.read(1).astype("float64")
        nodata = d.nodata
        tr = d.transform
    malo = (z == nodata) | ~np.isfinite(z)
    print(f"DEM {z.shape[1]}x{z.shape[0]} px, sin dato: {100 * malo.mean():.2f} %")
    z = np.where(malo, np.nan, z)
    print(f"elevación {np.nanmin(z):.1f} .. {np.nanmax(z):.1f} m (desnivel {np.nanmax(z) - np.nanmin(z):.0f} m)")
    zr = np.where(malo, np.nanmean(z), z)

    # Pendiente a dos escalas. A 1 m manda el ruido del modelo; a 4 m es la escala útil para el traje.
    for paso in (1, 4):
        zz = zr if paso == 1 else bloque_medio(zr, paso)
        s = pendiente_grados(zz, paso)
        partes = [f"{lo}-{hi if hi < 91 else '90'}°: {100 * ((s >= lo) & (s < hi)).mean():.1f} %" for lo, hi, _ in CLASES]
        print(f"pendiente a {paso} m  |  " + "  |  ".join(partes) + f"  | máx {s.max():.1f}°")

    # Indicio de procedencia del modelo: HiRISE (1 m real) conserva relieve fino; CTX/HRSC remuestreados lo pierden.
    resid = zr - ndimage.uniform_filter(zr, 11)
    t = 250
    n = z.shape[0] // t
    print(f"desviación del relieve fino (cm) por celda de {t} m, filas de norte a sur:")
    for i in range(n):
        fila = [100 * resid[i * t:(i + 1) * t, j * t:(j + 1) * t].std() for j in range(n)]
        print("  " + " ".join(f"{v:5.0f}" for v in fila))

    # Imágenes de revisión a 4 m por píxel.
    z4 = bloque_medio(zr, 4)
    hs = (sombreado(z4, 4) * 255).astype("uint8")
    Image.fromarray(hs).save(os.path.join(WORK, "quicklook_hillshade.png"))
    s4 = pendiente_grados(z4, 4)
    rgb = np.zeros(s4.shape + (3,), "uint8")
    for k, (lo, hi, _) in enumerate(CLASES):
        rgb[(s4 >= lo) & (s4 < hi)] = COLORES[k]
    rgb = (rgb * (0.45 + 0.55 * (hs[..., None] / 255.0))).astype("uint8")
    Image.fromarray(rgb).save(os.path.join(WORK, "quicklook_slope.png"))

    # Ortofoto a ~2 m por píxel, con los waypoints de Curiosity en la ventana.
    with rasterio.open(os.path.join(RAW, "lrgb_box_025m.tif")) as o:
        factor = 8
        img = o.read(out_shape=(o.count, o.height // factor, o.width // factor))
        otr = o.transform
        print(f"LRGB {o.width}x{o.height} px, {o.count} bandas")
        sin_valor = (img == 0).all(axis=0)
        print(f"LRGB píxeles vacíos (0 en todas las bandas): {100 * sin_valor.mean():.2f} %")
    im = Image.fromarray(np.moveaxis(img[:3], 0, -1)).convert("RGB")
    dib = ImageDraw.Draw(im)
    wp = json.load(open(os.path.join(RAW, "MSL_waypoints.json")))["features"]
    usados = 0
    for f in wp:
        p = f["properties"]
        col, fila = ~otr * (p["easting"], p["northing"])
        x, y = col / factor, fila / factor
        if 0 <= x < im.width and 0 <= y < im.height:
            en_boxwork = SOL_MIN <= p["sol"] < SOL_MAX
            c = (255, 60, 60) if en_boxwork else (60, 200, 255)
            dib.ellipse([x - 4, y - 4, x + 4, y + 4], outline=c, width=2)
            usados += 1
    print(f"waypoints dentro de la ventana: {usados} (rojo = soles {SOL_MIN}-{SOL_MAX}, cian = resto)")
    im.save(os.path.join(WORK, "quicklook_lrgb.png"))


if __name__ == "__main__":
    main()

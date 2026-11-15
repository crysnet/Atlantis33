"""Fase 0: registro DEM-ortofoto, recorte de las crestas a resolución completa y candidatos de hábitat.

Lee data/raw/dem_box_1m.tif, data/raw/lrgb_box_025m.tif y data/raw/MSL_waypoints.json.
Escribe en data/work/: quicklook_boxwork.png, quicklook_habitat.png.

Uso (desde la raíz del proyecto):
    python3 tools/00_analisis_sitio.py
"""
import json
import math
import os
import sys

import numpy as np
import rasterio
from rasterio.enums import Resampling
from PIL import Image, ImageDraw
from scipy import ndimage

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(RAIZ, "data", "raw")
WORK = os.path.join(RAIZ, "data", "work")

R_MARTE = 3396190.0  # radio de la esfera de referencia de los mosaicos (m)
SOL_MIN, SOL_MAX = 4500, 4900
LIM_HABITAT_DEG = 5.0
LIM_PROHIBIDA_DEG = 25.0
# Criterios de hábitat (se pueden pasar por línea de comandos): radio llano mínimo, distancia mínima y máxima
# a las crestas, distancia mínima a pendiente prohibida (todo en metros).
_arg = [float(x) for x in sys.argv[1:5]]
R_MIN, D_MIN, D_MAX, D_PEND = (_arg + [30.0, 1000.0, 2000.0, 80.0][len(_arg):])[:4]


def a_lonlat(e, n):
    return math.degrees(e / R_MARTE), math.degrees(n / R_MARTE)


def pendiente(z, paso):
    gy, gx = np.gradient(z, paso)
    return np.degrees(np.arctan(np.hypot(gx, gy)))


def bloque_medio(z, k):
    h, w = (z.shape[0] // k) * k, (z.shape[1] // k) * k
    return z[:h, :w].reshape(h // k, k, w // k, k).mean(axis=(1, 3))


def borde(a):
    a = ndimage.gaussian_filter(a, 1.0)
    gy, gx = np.gradient(a)
    return np.hypot(gx, gy)


def desplazamiento(a, b):
    """Correlación de fase. Devuelve (dx, dy, pico) para alinear b con a, en píxeles."""
    w = np.outer(np.hanning(a.shape[0]), np.hanning(a.shape[1]))
    fa, fb = np.fft.fft2((a - a.mean()) * w), np.fft.fft2((b - b.mean()) * w)
    cruz = fa * np.conj(fb)
    cruz /= np.abs(cruz) + 1e-9
    c = np.fft.ifft2(cruz).real
    iy, ix = np.unravel_index(np.argmax(c), c.shape)
    dy = iy if iy < a.shape[0] // 2 else iy - a.shape[0]
    dx = ix if ix < a.shape[1] // 2 else ix - a.shape[1]
    return dx, dy, c.max()


def main():
    with rasterio.open(os.path.join(RAW, "dem_box_1m.tif")) as d:
        z = d.read(1).astype("float64")
        dtr = d.transform
        print("DEM origen E,N:", dtr.c, dtr.f, "tamaño", d.width, d.height)
    with rasterio.open(os.path.join(RAW, "lrgb_box_025m.tif")) as o:
        otr = o.transform
        print("LRGB origen E,N:", otr.c, otr.f, "tamaño", o.width, o.height)
        gris1 = np.mean(
            [o.read(b, out_shape=(z.shape[0], z.shape[1]), resampling=Resampling.average).astype("float32") for b in (1, 2, 3)],
            axis=0,
        )
        # Recorte a resolución completa (se calcula más abajo con el centroide de las crestas).
        ortho_path = o.name

    # --- Registro DEM-ortofoto por teselas de 500 m ---
    be, bs = borde(gris1), borde(z)
    t = 500
    print("desplazamiento ortofoto->DEM por tesela de 500 m (dx,dy en m; pico):")
    dxs, dys = [], []
    for i in range(z.shape[0] // t):
        fila = []
        for j in range(z.shape[1] // t):
            a = bs[i * t:(i + 1) * t, j * t:(j + 1) * t]
            b = be[i * t:(i + 1) * t, j * t:(j + 1) * t]
            dx, dy, p = desplazamiento(a, b)
            dxs.append(dx)
            dys.append(dy)
            fila.append(f"({dx:+d},{dy:+d};{p:.2f})")
        print("  " + " ".join(fila))
    print(f"mediana dx {np.median(dxs):+.0f} m, dy {np.median(dys):+.0f} m")

    # --- Waypoints en la ventana ---
    wp = json.load(open(os.path.join(RAW, "MSL_waypoints.json")))["features"]
    box = [(f["properties"]["easting"], f["properties"]["northing"]) for f in wp if SOL_MIN <= f["properties"]["sol"] < SOL_MAX]
    ce, cn = np.mean([p[0] for p in box]), np.mean([p[1] for p in box])
    print(f"centroide de waypoints boxwork: E {ce:.0f} N {cn:.0f} -> lon/lat {a_lonlat(ce, cn)}")

    # --- Recorte de 500 x 500 m a 0.5 m/px alrededor del centroide ---
    with rasterio.open(ortho_path) as o:
        col, fila = ~otr * (ce, cn)
        mitad = 1000
        c0, f0 = int(col) - mitad, int(fila) - mitad
        win = rasterio.windows.Window(c0, f0, 2 * mitad, 2 * mitad)
        img = o.read(window=win, out_shape=(3, 1000, 1000), resampling=Resampling.average)
    im = Image.fromarray(np.moveaxis(img, 0, -1))
    im.save(os.path.join(WORK, "quicklook_boxwork.png"))
    print("recorte boxwork guardado: 500 x 500 m a 0.5 m/px")

    # --- Candidatos de hábitat a 4 m por celda ---
    z4 = bloque_medio(z, 4)
    s4 = pendiente(z4, 4)
    paso = 4.0
    permitido = s4 < LIM_PROHIBIDA_DEG
    etiquetas, _ = ndimage.label(permitido, structure=np.ones((3, 3)))
    # waypoint -> celda
    def a_celda(e, n):
        return int((dtr.f - n) / paso), int((e - dtr.c) / paso)

    celdas_box = [a_celda(e, n) for e, n in box]
    celdas_box = [(r, c) for r, c in celdas_box if 0 <= r < s4.shape[0] and 0 <= c < s4.shape[1]]
    comp_box = {int(etiquetas[r, c]) for r, c in celdas_box if etiquetas[r, c] > 0}
    print("componentes transitables (pendiente < 25 grados) que tocan los waypoints boxwork:", comp_box or "ninguno")

    mask_box = np.zeros(s4.shape, bool)
    for r, c in celdas_box:
        mask_box[r, c] = True
    dist_box = ndimage.distance_transform_edt(~mask_box) * paso
    radio_llano = ndimage.distance_transform_edt(s4 < LIM_HABITAT_DEG) * paso
    dist_pend = ndimage.distance_transform_edt(s4 < LIM_PROHIBIDA_DEG) * paso

    en_anillo = (dist_box >= 1000) & (dist_box <= 2000)
    print(
        "diagnóstico: celdas con pendiente < 5°: {:.1f} %, radio llano máx en la ventana {:.0f} m, "
        "radio llano máx en el anillo de 1-2 km {:.0f} m, celdas del anillo conectadas {:.1f} %".format(
            100 * (s4 < LIM_HABITAT_DEG).mean(),
            radio_llano.max(),
            radio_llano[en_anillo].max() if en_anillo.any() else 0,
            100 * np.isin(etiquetas, list(comp_box))[en_anillo].mean() if en_anillo.any() else 0,
        )
    )
    for r_min in (20, 30, 40, 60):
        print(f"  anillo, radio llano >= {r_min} m: {int((en_anillo & (radio_llano >= r_min)).sum())} celdas; "
              f"con conexión: {int((en_anillo & (radio_llano >= r_min) & np.isin(etiquetas, list(comp_box))).sum())}; "
              f"con >= 80 m de pendiente prohibida: {int((en_anillo & (radio_llano >= r_min) & (dist_pend >= 80)).sum())}")
    ok = (
        (radio_llano >= R_MIN)
        & (dist_box >= D_MIN)
        & (dist_box <= D_MAX)
        & (dist_pend >= D_PEND)
        & np.isin(etiquetas, list(comp_box))
    )
    print(f"celdas candidatas (llano >= {R_MIN:.0f} m de radio, {D_MIN:.0f}-{D_MAX:.0f} m de crestas, >= {D_PEND:.0f} m de pendiente prohibida, conectadas): {int(ok.sum())}")
    elev_box = np.mean([z4[r, c] for r, c in celdas_box])
    print(f"elevación media de los waypoints boxwork: {elev_box:.0f} m")
    cand = []
    puntaje = np.where(ok, radio_llano, 0)
    for _ in range(5):
        r, c = np.unravel_index(np.argmax(puntaje), puntaje.shape)
        if puntaje[r, c] <= 0:
            break
        e = dtr.c + (c + 0.5) * paso
        n = dtr.f - (r + 0.5) * paso
        lon, lat = a_lonlat(e, n)
        cand.append((r, c))
        print(
            f"  candidato: E {e:.0f} N {n:.0f}  lon {lon:.4f} lat {lat:.4f}  elev {z4[r, c]:.0f} m  "
            f"radio llano {radio_llano[r, c]:.0f} m  a crestas {dist_box[r, c]:.0f} m  a pendiente prohibida {dist_pend[r, c]:.0f} m  "
            f"desnivel vs crestas {z4[r, c] - elev_box:+.0f} m"
        )
        rr, cc = np.ogrid[:s4.shape[0], :s4.shape[1]]
        puntaje[(rr - r) ** 2 + (cc - c) ** 2 < (300 / paso) ** 2] = 0

    # imagen de revisión
    rgb = np.zeros(s4.shape + (3,), "uint8")
    rgb[s4 < 10] = (60, 170, 90)
    rgb[(s4 >= 10) & (s4 < 20)] = (230, 170, 40)
    rgb[(s4 >= 20) & (s4 < 25)] = (230, 110, 40)
    rgb[s4 >= 25] = (210, 50, 50)
    rgb[s4 < LIM_HABITAT_DEG] = (30, 110, 60)
    im2 = Image.fromarray(rgb)
    dib = ImageDraw.Draw(im2)
    for r, c in celdas_box:
        dib.point((c, r), fill=(255, 255, 255))
    for k, (r, c) in enumerate(cand, 1):
        dib.ellipse([c - 8, r - 8, c + 8, r + 8], outline=(0, 255, 255), width=2)
        dib.text((c + 10, r - 6), str(k), fill=(255, 255, 255))
    im2.save(os.path.join(WORK, "quicklook_habitat.png"))


if __name__ == "__main__":
    main()

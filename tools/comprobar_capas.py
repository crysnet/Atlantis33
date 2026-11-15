"""Fase 1, criterio de cierre: comprueba que la ortofoto y las capas derivadas del modelo de elevación coinciden.

1. Estima la dirección del sol de la ortofoto: busca el relieve sombreado del modelo que mejor correlaciona
   con ella (se compara solo el detalle fino, sin el brillo del suelo).
2. Con esa iluminación mide el desfase entre ortofoto y modelo por teselas de 500 m (correlación de fase).
3. Guarda imágenes de comprobación en docs/: caja completa y dos detalles con los contornos de pendiente
   dibujados sobre la ortofoto.

Entrada: data/raw/lrgb_box_025m.tif, data/work/dem_1m.tif, data/work/slope_2m.tif, app/assets/site_gale/site.json
Salida:  docs/fase1_caja.jpg, docs/fase1_detalle_boxwork.jpg, docs/fase1_detalle_escarpe.jpg
"""
import json
import os

import numpy as np
import rasterio
from PIL import Image, ImageDraw
from rasterio.enums import Resampling
from rasterio.windows import Window
from scipy import ndimage

import common


def gris_a(o, lado_px):
    return np.mean(
        [o.read(b, out_shape=(lado_px, lado_px), resampling=Resampling.average).astype("float32") for b in (1, 2, 3)],
        axis=0,
    )


def pasa_altos(a, sigma):
    return a - ndimage.gaussian_filter(a, sigma)


def correlacion(a, b):
    a, b = a - a.mean(), b - b.mean()
    return float((a * b).sum() / (np.sqrt((a * a).sum() * (b * b).sum()) + 1e-12))


def desplazamiento(a, b):
    """Correlación de fase. Devuelve (dx, dy, pico): cuánto hay que mover b para alinearlo con a, en píxeles."""
    w = np.outer(np.hanning(a.shape[0]), np.hanning(a.shape[1]))
    fa, fb = np.fft.fft2((a - a.mean()) * w), np.fft.fft2((b - b.mean()) * w)
    cruz = fa * np.conj(fb)
    cruz /= np.abs(cruz) + 1e-9
    c = np.fft.ifft2(cruz).real
    iy, ix = np.unravel_index(np.argmax(c), c.shape)
    dy = iy if iy < a.shape[0] // 2 else iy - a.shape[0]
    dx = ix if ix < a.shape[1] // 2 else ix - a.shape[1]
    return dx, dy, float(c.max())


def borde(mascara, grosor=2):
    b = mascara & ~ndimage.binary_erosion(mascara)
    return ndimage.binary_dilation(b, iterations=grosor - 1) if grosor > 1 else b


def recorte(o, cx_m, cy_m, lado_m, px):
    """Recorta lado_m x lado_m metros centrados en (cx, cy) del plano local, remuestreado a px x px."""
    res = o.transform.a
    c0 = int(round((cx_m - lado_m / 2) / res))
    f0 = int(round((cy_m - lado_m / 2) / res))
    n = int(round(lado_m / res))
    img = o.read([1, 2, 3], window=Window(c0, f0, n, n), out_shape=(3, px, px), resampling=Resampling.average)
    return np.moveaxis(img, 0, -1), c0 * res, f0 * res


def contornos(img, pend2, x0_m, y0_m, lado_m, px, s):
    """Dibuja sobre img los contornos de pendiente. Rojo: prohibida. Ámbar: precaución."""
    out = img.copy()
    n2 = int(round(lado_m / 2.0))
    c0, f0 = int(round(x0_m / 2.0)), int(round(y0_m / 2.0))
    sub = pend2[f0:f0 + n2, c0:c0 + n2]
    sub = np.nan_to_num(sub, nan=0.0)
    f = px / n2
    grande = np.kron(sub, np.ones((int(round(f)), int(round(f)))))[:px, :px]
    for umbral, color in ((s["caution_max_deg"], (255, 200, 40)), (s["forbidden_above_deg"], (255, 40, 40))):
        out[borde(grande > umbral, 2)] = color
    return out


def main():
    os.makedirs(common.DOCS, exist_ok=True)
    p = common.params()
    s = p["slope"]
    with rasterio.open(common.DEM_1M) as d:
        z1 = d.read(1).astype("float64")
    z1f, _ = common.rellenar_nan(z1)
    z2 = z1f.reshape(2000, 2, 2000, 2).mean(axis=(1, 3))
    with rasterio.open(common.ORTHO_RAW) as o:
        gris2 = gris_a(o, 2000)

    # 1. Dirección del sol.
    base = pasa_altos(gris2, 6)
    mejores = []
    for alt in (20, 35, 50):
        for az in range(0, 360, 15):
            hs = common.sombreado(z2, 2.0, az, alt)
            mejores.append((correlacion(base, pasa_altos(hs, 6)), az, alt))
    mejores.sort(key=lambda t: -abs(t[0]))
    print("correlación ortofoto - relieve sombreado (mejores): " + ", ".join(f"{c:+.2f} (az {a}, alt {h})" for c, a, h in mejores[:4]))
    c_best, az_best, alt_best = mejores[0]

    # 2. Desfase por teselas de 500 m, a 2 m por píxel (250 px por tesela).
    hs = pasa_altos(common.sombreado(z2, 2.0, az_best, alt_best), 6) * np.sign(c_best)
    t = 250
    dxs, dys, picos = [], [], []
    print(f"desfase ortofoto -> modelo por tesela de 500 m (dx, dy en metros; pico), sol az {az_best} alt {alt_best}:")
    for i in range(2000 // t):
        fila = []
        for j in range(2000 // t):
            dx, dy, pico = desplazamiento(hs[i * t:(i + 1) * t, j * t:(j + 1) * t], base[i * t:(i + 1) * t, j * t:(j + 1) * t])
            dxs.append(2 * dx)
            dys.append(2 * dy)
            picos.append(pico)
            fila.append(f"({2 * dx:+d},{2 * dy:+d};{pico:.2f})")
        print("  " + " ".join(fila))
    dxs, dys, picos = np.array(dxs), np.array(dys), np.array(picos)
    buenas = picos >= np.percentile(picos, 50)
    print(f"mediana dx {np.median(dxs):+.0f} m, dy {np.median(dys):+.0f} m; en la mitad de teselas con mejor pico: "
          f"dx {np.median(dxs[buenas]):+.0f} m, dy {np.median(dys[buenas]):+.0f} m; "
          f"teselas con desfase de 4 m o menos: {int((np.hypot(dxs, dys) <= 4).sum())} de {len(dxs)}")

    # 3. Imágenes de comprobación.
    with rasterio.open(common.SLOPE_2M) as d:
        pend2 = d.read(1)
    site = json.load(open(os.path.join(common.SALIDA, "site.json")))
    cx, cy = site["boxwork_campaign"]["centroid_x_m"], site["boxwork_campaign"]["centroid_y_m"]

    prohibida = np.nan_to_num(pend2, nan=0.0) > s["forbidden_above_deg"]
    etiquetas, n = ndimage.label(prohibida)
    tam = np.bincount(etiquetas.ravel())
    tam[0] = 0
    mayor = int(np.argmax(tam))
    filas, cols = np.nonzero(etiquetas == mayor)
    ic = int(np.argmin((filas - filas.mean()) ** 2 + (cols - cols.mean()) ** 2))
    ex, ey = cols[ic] * 2.0, filas[ic] * 2.0
    print(f"mayor escarpe prohibido: {tam[mayor]} celdas, punto central en x {ex:.0f} m, y {ey:.0f} m")

    with rasterio.open(common.ORTHO_RAW) as o:
        # Caja completa a 2 m por píxel con la capa de pendiente encima.
        rgb2 = np.moveaxis(o.read([1, 2, 3], out_shape=(3, 2000, 2000), resampling=Resampling.average), 0, -1)
        capa = np.array(Image.open(os.path.join(common.SALIDA, "layers", "slope.png")).convert("RGBA")).astype("float32")
        a = (capa[..., 3:4] / 255.0) * 0.45
        mezcla = (rgb2.astype("float32") * (1 - a) + capa[..., :3] * a).astype("uint8")
        Image.fromarray(mezcla).save(os.path.join(common.DOCS, "fase1_caja.jpg"), quality=88)

        lado, px = 400.0, 800
        for nombre, (x, y) in (("boxwork", (cx, cy)), ("escarpe", (ex, ey))):
            x = float(np.clip(x, lado / 2, 4000 - lado / 2))
            y = float(np.clip(y, lado / 2, 4000 - lado / 2))
            img, x0, y0 = recorte(o, x, y, lado, px)
            con = contornos(img, pend2, x0, y0, lado, px, s)
            lienzo = Image.new("RGB", (px * 2 + 8, px), (0, 0, 0))
            lienzo.paste(Image.fromarray(img), (0, 0))
            lienzo.paste(Image.fromarray(con), (px + 8, 0))
            d = ImageDraw.Draw(lienzo)
            d.text((8, 8), f"ortofoto {lado:.0f} x {lado:.0f} m, centro x {x:.0f} y {y:.0f}", fill=(255, 255, 255))
            d.text((px + 16, 8), "contornos: rojo > 25 grados, ámbar > 20 grados", fill=(255, 255, 255))
            lienzo.save(os.path.join(common.DOCS, f"fase1_detalle_{nombre}.jpg"), quality=90)
    print("imágenes guardadas en docs/")


if __name__ == "__main__":
    main()

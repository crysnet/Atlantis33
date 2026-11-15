"""Fase 1, paso 2: pendiente, rugosidad y relieve sombreado a 2 m por celda.

Entrada: data/work/dem_1m.tif
Salida:  data/work/dem_2m.tif, slope_2m.tif (grados), rough_2m.tif (cm), hillshade_2m.tif (0 a 255)

Decisiones:
- La cuadrícula de trabajo es de 2 m (config/params.json). El modelo de 1 m se promedia en bloques de 2 x 2.
- La pendiente usa diferencias centrales sobre esa cuadrícula (línea base de 4 m). A 1 m el ruido del
  modelo estéreo domina; la fase 0 mostró estadísticas casi iguales a 1 m y a 4 m.
- La rugosidad es el relieve local a 1 m menos su media móvil de 7 x 7 m, en raíz del cuadrado medio.
  No ve rocas sueltas menores de 1 m: el modelo no las resuelve.
"""
import numpy as np
import rasterio
from scipy import ndimage

import common


def main():
    p = common.params()
    celda = p["grid"]["cell_m"]
    k = int(round(celda))  # 1 m -> k celdas por lado
    ventana = p["roughness"]["window_px"]

    with rasterio.open(common.DEM_1M) as d:
        z1 = d.read(1).astype("float64")
        tr1, crs = d.transform, d.crs

    z1f, malo1 = common.rellenar_nan(z1)

    # Rugosidad a 1 m, después promedio a 2 m.
    resid = z1f - ndimage.uniform_filter(z1f, ventana)
    rms_cm = 100.0 * np.sqrt(ndimage.uniform_filter(resid ** 2, ventana))
    rms_cm[malo1] = np.nan
    rugosidad = common.bloque_medio(rms_cm, k)

    # Elevación y pendiente a 2 m.
    z2 = common.bloque_medio(z1, k)
    z2f, malo2 = common.rellenar_nan(z2)
    pend = common.pendiente_grados(z2f, celda)
    pend[malo2] = np.nan
    hs = (common.sombreado(z2f, celda) * 255.0).astype("uint8")

    tr2 = rasterio.Affine(celda, 0.0, tr1.c, 0.0, -celda, tr1.f)
    common.escribir_tif(common.DEM_2M, z2.astype("float32"), tr2, crs, nodata=np.nan)
    common.escribir_tif(common.SLOPE_2M, pend.astype("float32"), tr2, crs, nodata=np.nan)
    common.escribir_tif(common.ROUGH_2M, rugosidad.astype("float32"), tr2, crs, nodata=np.nan)
    common.escribir_tif(common.HILLSHADE_2M, hs, tr2, crs, nodata=None)

    s = p["slope"]
    v = pend[np.isfinite(pend)]
    cortes = [0.0, s["nominal_max_deg"], s["caution_max_deg"], s["forbidden_above_deg"], 91.0]
    nombres = ["nominal", "precaución", "precaución alta", "prohibida"]
    print(f"rejilla {z2.shape[1]} x {z2.shape[0]} celdas de {celda:g} m")
    for i, nombre in enumerate(nombres):
        frac = ((v >= cortes[i]) & (v < cortes[i + 1])).mean() * 100.0
        print(f"  pendiente {nombre} ({cortes[i]:g} a {min(cortes[i + 1], 90):g} grados): {frac:.1f} %")
    print(f"  pendiente máxima {v.max():.1f} grados, media {v.mean():.1f}")
    r = rugosidad[np.isfinite(rugosidad)]
    print(f"  rugosidad: mediana {np.median(r):.1f} cm, percentil 95 {np.percentile(r, 95):.1f} cm, máxima {r.max():.1f} cm")


if __name__ == "__main__":
    main()

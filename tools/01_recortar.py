"""Fase 1, paso 1: alinea el modelo de elevación al recuadro de trabajo y comprueba la ortofoto.

La ortofoto en color ya está recortada al recuadro (tools/00_descargar_ventana.py). El modelo de elevación
quedó con un desfase de medio metro respecto al recuadro, porque la cuadrícula de 1 m del USGS no cae sobre
los metros enteros. Aquí se remuestrea con interpolación bilineal a una cuadrícula de 1 m que arranca
exactamente en la esquina noroeste del recuadro. Conserva la georreferencia.

Entrada: data/raw/dem_box_1m.tif, data/raw/lrgb_box_025m.tif
Salida:  data/work/dem_1m.tif (float32, NaN = sin dato)
"""
import numpy as np
import rasterio
from rasterio.transform import from_origin
from rasterio.warp import Resampling, reproject

import common


def main():
    e0, n1, lado = common.caja()
    n_px = int(round(lado))
    destino_tr = from_origin(e0, n1, 1.0, 1.0)

    with rasterio.open(common.ORTHO_RAW) as o:
        ok_origen = abs(o.transform.c - e0) < 1e-6 and abs(o.transform.f - n1) < 1e-6
        ok_tam = o.width == n_px * 4 and o.height == n_px * 4
        print(f"ortofoto: origen {o.transform.c}, {o.transform.f}; {o.width} x {o.height} px; "
              f"{'alineada con el recuadro' if ok_origen and ok_tam else 'NO coincide con el recuadro'}")
        if not (ok_origen and ok_tam):
            raise SystemExit("La ortofoto no coincide con el recuadro de config/params.json")

    with rasterio.open(common.DEM_RAW) as src:
        print(f"DEM: origen {src.transform.c:.3f}, {src.transform.f:.3f}; desfase respecto al recuadro "
              f"{src.transform.c - e0:+.3f} m este, {src.transform.f - n1:+.3f} m norte")
        z = src.read(1)
        dst = np.full((n_px, n_px), np.nan, dtype="float32")
        reproject(
            source=z,
            destination=dst,
            src_transform=src.transform,
            src_crs=src.crs,
            src_nodata=src.nodata,
            dst_transform=destino_tr,
            dst_crs=src.crs,
            dst_nodata=np.nan,
            resampling=Resampling.bilinear,
        )
        crs = src.crs

    sin_dato = ~np.isfinite(dst)
    print(f"DEM alineado: {n_px} x {n_px} px a 1 m, sin dato {100 * sin_dato.mean():.3f} %, "
          f"elevación {np.nanmin(dst):.1f} a {np.nanmax(dst):.1f} m")
    common.escribir_tif(common.DEM_1M, dst, destino_tr, crs, nodata=np.nan)
    print("escrito", common.DEM_1M)


if __name__ == "__main__":
    main()

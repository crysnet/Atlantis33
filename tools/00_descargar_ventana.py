"""Fase 0: lee por rangos HTTP una ventana de los mosaicos del USGS y la guarda en data/raw/.

No descarga los archivos completos. Coordenadas en metros, proyección equirectangular de Marte
(la misma que usan los mosaicos y la tabla de waypoints de Curiosity: columnas easting/northing).

Uso (desde la raíz del proyecto):
    python3 tools/00_descargar_ventana.py [dem|lrgb|todo]
"""
import os
import sys
import time

os.environ.setdefault("GDAL_DISABLE_READDIR_ON_OPEN", "EMPTY_DIR")
os.environ.setdefault("CPL_VSIL_CURL_ALLOWED_EXTENSIONS", ".tif")
os.environ.setdefault("GDAL_HTTP_MAX_RETRY", "5")
os.environ.setdefault("GDAL_HTTP_RETRY_DELAY", "2")

import rasterio
from rasterio.windows import Window, from_bounds

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(RAIZ, "data", "raw")

# Recuadro de trabajo candidato: 4 x 4 km centrado en la zona donde Curiosity trabajó
# las crestas boxwork (soles 4500-4900: E 8143106..8143726, N -285375..-284116).
E0, E1 = 8141400.0, 8145400.0
N0, N1 = -286750.0, -282750.0

FUENTES = {
    "dem": {
        "url": "https://planetarymaps.usgs.gov/mosaic/Mars/MSL/MSL_Gale_DEM_Mosaic_1m_v3.tif",
        "salida": "dem_box_1m.tif",
    },
    "lrgb": {
        "url": "https://asc-pds-services.s3.us-west-2.amazonaws.com/mosaic/Mars/MSL/MSL_Gale_HiRISE-LRGB_78quads_sharp_cog.tif",
        "salida": "lrgb_box_025m.tif",
    },
}


def copiar_ventana(url, salida, filas_por_bloque=512):
    os.makedirs(RAW, exist_ok=True)
    destino = os.path.join(RAW, salida)
    with rasterio.open("/vsicurl/" + url) as src:
        win = from_bounds(E0, N0, E1, N1, src.transform).round_offsets().round_lengths()
        win = win.intersection(Window(0, 0, src.width, src.height))
        transform = src.window_transform(win)
        perfil = src.profile.copy()
        perfil.update(
            width=int(win.width),
            height=int(win.height),
            transform=transform,
            tiled=True,
            blockxsize=512,
            blockysize=512,
            compress="deflate",
            predictor=3 if src.dtypes[0].startswith("float") else 2,
        )
        if src.count == 3:
            # El origen viene en YCbCr con JPEG; GDAL entrega RGB al leer.
            perfil.update(photometric="rgb")
            perfil.pop("jpeg_quality", None)
        print(f"{salida}: ventana {win.width} x {win.height} px, {src.count} banda(s)", flush=True)
        t0 = time.time()
        with rasterio.open(destino, "w", **perfil) as dst:
            for fila in range(0, int(win.height), filas_por_bloque):
                alto = min(filas_por_bloque, int(win.height) - fila)
                sub = Window(win.col_off, win.row_off + fila, win.width, alto)
                datos = src.read(window=sub)
                dst.write(datos, window=Window(0, fila, win.width, alto))
                if (fila // filas_por_bloque) % 4 == 0:
                    print(f"  {fila + alto}/{int(win.height)} filas, {time.time() - t0:.0f} s", flush=True)
    print(f"{salida}: listo, {os.path.getsize(destino) / 1e6:.1f} MB en disco, {time.time() - t0:.0f} s", flush=True)


if __name__ == "__main__":
    que = sys.argv[1] if len(sys.argv) > 1 else "todo"
    claves = list(FUENTES) if que == "todo" else [que]
    for k in claves:
        copiar_ventana(FUENTES[k]["url"], FUENTES[k]["salida"])

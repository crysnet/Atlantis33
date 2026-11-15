"""Fase 1, paso 3: rejilla de costos a 2 m por celda.

Entrada: data/work/dem_2m.tif, slope_2m.tif, rough_2m.tif
Salida:  data/work/costos/ con un archivo binario por componente (un byte por celda, salvo la elevación
         que usa dos), más costos.json con las unidades y el hábitat ajustado.

Orden de las celdas: filas de norte a sur, columnas de oeste a este (la fila 0 es el borde norte).

Componentes:
  slope.bin      uint8, unidades de 0.5 grados. 255 = sin dato
  rough.bin      uint8, unidades de 0.5 cm, saturado en 255. 255 también si no hay dato
  forbidden.bin  uint8, 1 = celda prohibida (pendiente por encima del límite o sin dato), 0 = transitable
  elev.bin       uint16 little-endian, unidades de 0.02 m sobre `offset_m`. 65535 = sin dato

Falta el componente de arena suelta: necesita inercia térmica (THEMIS), que aún no se ha buscado.
Hasta entonces el peso `w_arena` de la fase 2 vale 0.
"""
import json
import os

import numpy as np
import rasterio
from scipy import ndimage

import common


def leer(ruta):
    with rasterio.open(ruta) as d:
        return d.read(1).astype("float64"), d.transform


def main():
    p = common.params()
    celda = p["grid"]["cell_m"]
    s = p["slope"]
    os.makedirs(common.COSTOS_DIR, exist_ok=True)

    z, tr = leer(common.DEM_2M)
    pend, _ = leer(common.SLOPE_2M)
    rug, _ = leer(common.ROUGH_2M)
    alto, ancho = z.shape

    sin_dato = ~np.isfinite(pend) | ~np.isfinite(z)
    prohibida = sin_dato | (pend > s["forbidden_above_deg"])

    slope_q = np.where(sin_dato, 255, np.clip(np.round(pend / 0.5), 0, 254)).astype("uint8")
    unidad_rug = p["roughness"]["byte_unit_cm"]
    rough_q = np.where(~np.isfinite(rug), 255, np.clip(np.round(rug / unidad_rug), 0, 254)).astype("uint8")
    forb_q = prohibida.astype("uint8")

    unidad_z = p["elevation"]["byte_unit_m"]
    z0 = float(np.floor(np.nanmin(z)))
    elev_q = np.where(~np.isfinite(z), p["elevation"]["nodata_value"], np.round((z - z0) / unidad_z)).astype("<u2")
    if np.nanmax(z) - z0 >= (p["elevation"]["nodata_value"] - 1) * unidad_z:
        raise SystemExit("El rango de elevación no cabe en uint16 con esa unidad")

    for nombre, arr in (("slope", slope_q), ("rough", rough_q), ("forbidden", forb_q), ("elev", elev_q)):
        arr.tofile(os.path.join(common.COSTOS_DIR, nombre + ".bin"))

    # Conectividad del terreno transitable (ocho vecinos).
    etiquetas, n = ndimage.label(~prohibida, structure=np.ones((3, 3)))
    tam = np.bincount(etiquetas.ravel())[1:]
    mayor = int(np.argmax(tam)) + 1
    print(f"celdas {ancho} x {alto}; prohibidas {100 * prohibida.mean():.1f} %; regiones transitables {n}; "
          f"la mayor tiene {100 * tam.max() / (~prohibida).sum():.1f} % de las celdas transitables")

    # Hábitat: comprobar el candidato y ajustarlo como máximo 30 m al centro del disco llano más cercano.
    e0, n1 = tr.c, tr.f
    h = p["site"]["habitat_candidate"]
    col0, fila0 = int((h["easting"] - e0) // celda), int((n1 - h["northing"]) // celda)
    llano = (pend < s["habitat_max_deg"]) & ~prohibida
    radio = ndimage.distance_transform_edt(llano) * celda
    rr, cc = np.ogrid[:alto, :ancho]
    cerca = (rr - fila0) ** 2 + (cc - col0) ** 2 <= (30.0 / celda) ** 2
    cerca &= etiquetas == mayor
    if not cerca.any():
        raise SystemExit("El candidato de hábitat no está en la región transitable principal")
    puntaje = np.where(cerca, radio, -1)
    fila, col = np.unravel_index(np.argmax(puntaje), puntaje.shape)
    he, hn = e0 + (col + 0.5) * celda, n1 - (fila + 0.5) * celda
    mov = float(np.hypot(he - h["easting"], hn - h["northing"]))
    lon, lat = common.a_lonlat(he, hn)
    print(f"hábitat: candidato original radio llano {radio[fila0, col0]:.0f} m; ajustado a celda ({col}, {fila}), "
          f"E {he:.0f} N {hn:.0f}, lon {lon:.4f} lat {lat:.4f}, elevación {z[fila, col]:.0f} m, "
          f"radio llano {radio[fila, col]:.0f} m, movido {mov:.0f} m")

    # Los waypoints boxwork deben quedar en terreno transitable.
    sol_min, sol_max = p["site"]["boxwork_sol_range"]
    wp = json.load(open(common.WAYPOINTS))["features"]
    dentro = fuera = 0
    for f in wp:
        q = f["properties"]
        if sol_min <= q["sol"] <= sol_max:
            c, r = int((q["easting"] - e0) // celda), int((n1 - q["northing"]) // celda)
            if 0 <= c < ancho and 0 <= r < alto:
                if prohibida[r, c]:
                    fuera += 1
                else:
                    dentro += 1
    print(f"waypoints boxwork en terreno transitable: {dentro}; en celdas prohibidas: {fuera}")

    meta = {
        "width": ancho,
        "height": alto,
        "cell_m": celda,
        "origin_easting": e0,
        "origin_northing": n1,
        "order": "row-major, north to south, west to east",
        "components": {
            "slope": {"file": "slope.bin", "dtype": "uint8", "unit_deg": 0.5, "nodata": 255},
            "rough": {"file": "rough.bin", "dtype": "uint8", "unit_cm": unidad_rug, "nodata": 255, "saturates_at": 254},
            "forbidden": {"file": "forbidden.bin", "dtype": "uint8", "values": {"0": "walkable", "1": "forbidden"}},
            "elev": {"file": "elev.bin", "dtype": "uint16-le", "unit_m": unidad_z, "offset_m": z0, "nodata": p["elevation"]["nodata_value"]},
        },
        "habitat": {
            "col": int(col), "row": int(fila), "easting": he, "northing": hn, "lon": lon, "lat": lat,
            "elevation_m": float(z[fila, col]), "flat_radius_m": float(radio[fila, col]), "moved_m": mov,
        },
    }
    with open(os.path.join(common.COSTOS_DIR, "costos.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    print("escrito", common.COSTOS_DIR)


if __name__ == "__main__":
    main()

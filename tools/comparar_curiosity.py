"""Fase 2, criterio de cierre: compara nuestras rutas con el recorrido real de Curiosity.

1. Terreno: qué parte del recorrido real cae en cada clase de pendiente, frente a la parte del recuadro que cae en ella.
2. Tramos: entre pares de waypoints reales (extremos de tramos de unos cientos de metros), calcula nuestras rutas segura y
   rápida y las compara con el tramo real: longitud, metros por clase de pendiente, pendiente máxima, tiempo y desviación lateral.

Entrada: data/raw/MSL_waypoints.json, data/work/costos/, config/params.json
Salida:  data/work/rutas/comparacion_curiosity.json y un resumen por pantalla

Uso (desde tools/):
    python3 comparar_curiosity.py [--cell 4]
"""
import argparse
import copy
import json
import math
import os

import numpy as np
from scipy.spatial import cKDTree

import common
import routing


def densificar(pts, paso=1.0):
    """Interpola una polilínea [(x, y), ...] cada `paso` metros."""
    out = [pts[0]]
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        d = math.hypot(x1 - x0, y1 - y0)
        n = max(1, int(math.ceil(d / paso)))
        for k in range(1, n + 1):
            out.append((x0 + (x1 - x0) * k / n, y0 + (y1 - y0) * k / n))
    return np.array(out)


def a_celdas(rej, xy):
    """Camino de celdas (sin repetir consecutivas) para una polilínea densa en metros."""
    cs = []
    for x, y in xy:
        c = rej.celda_de(x, y)
        if not cs or cs[-1] != c:
            cs.append(c)
    return cs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cell", type=float, default=4.0)
    args = ap.parse_args()
    p = common.params()
    p["routing"]["cell_m"] = args.cell
    mod = routing.Modelo(p)
    rej = routing.Rejilla(mod)
    # Para medir el recorrido real hace falta la pendiente verdadera de cada celda, también de las prohibidas.
    rej_real = copy.copy(rej)
    rej_real.pend_l = rej.pend_real_l
    e0, n1 = rej.origen_e, rej.origen_n
    lado = rej.ancho * rej.celda

    wp = json.load(open(common.WAYPOINTS))["features"]
    pts = []
    for f in wp:
        q = f["properties"]
        x, y = q["easting"] - e0, n1 - q["northing"]
        if 0 <= x < lado and 0 <= y < lado and q["sol"] >= 4400:
            pts.append((q["sol"], x, y))
    pts.sort()
    print(f"waypoints reales dentro del recuadro, soles 4400 en adelante: {len(pts)}")

    # 1. Terreno que pisó Curiosity frente al terreno disponible.
    s = p["slope"]
    cortes = [(0, s["nominal_max_deg"]), (s["nominal_max_deg"], s["caution_max_deg"]), (s["caution_max_deg"], s["forbidden_above_deg"]), (s["forbidden_above_deg"], 91)]
    nombres = ["nominal", "precaución", "precaución alta", "prohibida"]
    real = densificar([(x, y) for _, x, y in pts], 1.0)
    cel_real = a_celdas(rej, real)
    sr = np.array([rej.pend_real_l[c] for c in cel_real])
    todo = rej.pend_real.ravel()
    print("clase de pendiente: parte del recorrido real | parte del recuadro")
    resumen_terreno = {}
    for (lo, hi), n in zip(cortes, nombres):
        a = float(((sr >= lo) & (sr < hi)).mean() * 100)
        b = float(((todo >= lo) & (todo < hi)).mean() * 100)
        resumen_terreno[n] = {"real_pct": a, "box_pct": b}
        print(f"  {n:16s} {a:5.1f} % | {b:5.1f} %")

    # 2. Tramos. Se cortan donde el recorrido real acumula entre 350 y 700 m.
    tramos, ini, acum = [], 0, 0.0
    for i in range(1, len(pts)):
        acum += math.hypot(pts[i][1] - pts[i - 1][1], pts[i][2] - pts[i - 1][2])
        if acum >= 350.0:
            tramos.append((ini, i, acum))
            ini, acum = i, 0.0
    tramos = [t for t in tramos if math.hypot(pts[t[1]][1] - pts[t[0]][1], pts[t[1]][2] - pts[t[0]][2]) >= 200.0]
    print(f"\ntramos reales de unos 350 m o más: {len(tramos)}")
    salida = []
    for (a, b, largo) in tramos:
        xa, ya, xb, yb = pts[a][1], pts[a][2], pts[b][1], pts[b][2]
        ca, cb = rej.celda_de(xa, ya), rej.celda_de(xb, yb)
        trozo = densificar([(x, y) for _, x, y in pts[a:b + 1]], 1.0)
        cel_t = a_celdas(rej, trozo)
        mr = routing.evaluar(rej_real, mod, cel_t, {})
        arbol = cKDTree(trozo)
        fila = {"sol_ini": pts[a][0], "sol_fin": pts[b][0], "recta_m": math.hypot(xb - xa, yb - ya), "real": {k: mr[k] for k in ("distance_m", "total_h", "max_slope_deg", "m_nominal", "m_caution", "m_high_caution", "ascent_m")}}
        print(f"\nsoles {pts[a][0]}-{pts[b][0]}: en línea recta {fila['recta_m']:.0f} m")
        print(f"  real : {mr['distance_m']:.0f} m, {mr['total_h']:.2f} h, máx {mr['max_slope_deg']:.1f}°, precaución {mr['m_caution']:.0f} m, alta {mr['m_high_caution']:.0f} m")
        for nombre in ("safe", "fast"):
            perfil = mod.perfiles[nombre]
            r = routing.astar(rej, mod, perfil, ca, cb)
            if r is None:
                print(f"  {nombre:5s}: sin camino (extremo en celda prohibida o aislada)")
                fila[nombre] = None
                continue
            m = routing.evaluar(rej_real, mod, r[1], {})
            xy = np.array([rej.xy_de(c) for c in r[1]])
            dist, _ = arbol.query(xy)
            print(f"  {nombre:5s}: {m['distance_m']:.0f} m, {m['total_h']:.2f} h, máx {m['max_slope_deg']:.1f}°, precaución {m['m_caution']:.0f} m, "
                  f"alta {m['m_high_caution']:.0f} m; desviación del tramo real: mediana {np.median(dist):.0f} m, p90 {np.percentile(dist, 90):.0f} m, máx {dist.max():.0f} m")
            fila[nombre] = {k: m[k] for k in ("distance_m", "total_h", "max_slope_deg", "m_nominal", "m_caution", "m_high_caution", "ascent_m")}
            fila[nombre].update({"dev_median_m": float(np.median(dist)), "dev_p90_m": float(np.percentile(dist, 90)), "dev_max_m": float(dist.max())})
        salida.append(fila)

    os.makedirs(os.path.join(common.WORK, "rutas"), exist_ok=True)
    with open(os.path.join(common.WORK, "rutas", "comparacion_curiosity.json"), "w", encoding="utf-8") as f:
        json.dump({"cell_m": rej.celda, "terrain": resumen_terreno, "segments": salida}, f, indent=1)


if __name__ == "__main__":
    main()

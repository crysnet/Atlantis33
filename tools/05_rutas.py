"""Fase 2: calcula las tres rutas (segura, rápida, de ciencia) con sus métricas y puntajes.

Entrada: data/work/costos/, config/params.json, config/objectives.json
Salida:  data/work/rutas/rutas_<celda>m.json   resultados completos (celdas del camino, métricas, puntajes, tiempos)
         data/work/rutas/rutas_<celda>m.geojson  las rutas como líneas en longitud y latitud
         docs/fase2_rutas_<celda>m.jpg           imagen de revisión sobre la ortofoto

Uso (desde tools/):
    python3 05_rutas.py [--cell 2|4] [--modo foot|rover|support|pair|objetivo]
"""
import argparse
import json
import os
import time

import numpy as np
import rasterio
from PIL import Image, ImageDraw
from rasterio.enums import Resampling

import common
import routing

COLORES = {"safe": (255, 255, 255), "fast": (226, 98, 43), "science": (39, 197, 216), "pair1": (39, 197, 216), "pair2": (226, 98, 43)}


def cargar_objetivos():
    with open(os.path.join(common.RAIZ, "config", "objectives.json"), encoding="utf-8") as f:
        return json.load(f)["objectives"]


def imprimir(res, mod):
    for nombre in res:
        r = res[nombre]
        print(f"\n== {nombre}: {r['status']}, visita {r['visited']}, omitidos {[(o['id'], o['reason']) for o in r['skipped'] if o['reason'] != 'not_primary']}")
        if not r.get("cells"):
            continue
        m, h, s = r["metrics"], r["hazard"], r["success"]
        print(f"   distancia {m['distance_m']:.0f} m, tiempo {m['total_h']:.2f} h (marcha {m['walk_h']:.2f}, paradas {m['stop_h']:.2f}), "
              f"pendiente máx {m['max_slope_deg']:.1f}°")
        print(f"   metros: nominal {m['m_nominal']:.0f}, precaución {m['m_caution']:.0f}, precaución alta {m['m_high_caution']:.0f}; "
              f"desnivel +{m['ascent_m']:.0f} / -{m['descent_m']:.0f} m")
        print(f"   oxígeno al volver {100 * m['o2_remaining_frac']:.0f} %, dosis {m['dose_ugy']:.1f} uGy, "
              f"punto de no retorno a {m['no_return']['along_m']:.0f} m del inicio ({m['no_return']['from_habitat_m']:.0f} m en línea recta del hábitat)")
        if r.get("transport"):
            tr = r["transport"]
            print(f"   transporte: {tr['objectives']}; vehículo {m['rover_m']:.0f} m en {m['rover_h']:.2f} h; avisos {tr['notes']}")
        comp = ", ".join(f"{k} {100 * v:.0f}" for k, v in h["components"].items())
        print(f"   peligro {h['score']:.1f}  (componentes %: {comp})")
        print(f"   éxito {s['score']:.1f}  (valor científico {s['science_value']:.2f}, factor tiempo {s['time_factor']:.2f}, "
              f"factor consumibles {s['consumables_factor']:.2f}, penalización {s['hazard_penalty']:.3f})")


def geojson(res, rej):
    feats = []
    for nombre, r in res.items():
        if not r.get("cells"):
            continue
        coords = []
        for c, f in r["cells"]:
            x, y = (c + 0.5) * rej.celda, (f + 0.5) * rej.celda
            lon, lat = common.a_lonlat(rej.origen_e + x, rej.origen_n - y)
            coords.append([round(lon, 7), round(lat, 7)])
        props = {"profile": nombre, "status": r["status"], "visited": r["visited"], "hazard": r["hazard"]["score"], "success": r["success"]["score"]}
        feats.append({"type": "Feature", "properties": props, "geometry": {"type": "LineString", "coordinates": coords}})
    return {"type": "FeatureCollection", "features": feats}


def dibujar(res, rej, planificador, ruta_img):
    with rasterio.open(common.ORTHO_RAW) as o:
        rgb = np.moveaxis(o.read([1, 2, 3], out_shape=(3, 2000, 2000), resampling=Resampling.average), 0, -1)
    im = Image.fromarray((rgb * 0.8).astype("uint8"))
    d = ImageDraw.Draw(im)
    k = rej.celda / 2.0
    for nombre, r in res.items():
        if r.get("cells"):
            pts = [((c + 0.5) * k, (f + 0.5) * k) for c, f in r["cells"]]
            d.line(pts, fill=COLORES[nombre], width=4)
    for o in planificador.obj:
        x, y = o["x_m"] / 2.0, o["y_m"] / 2.0
        d.ellipse([x - 12, y - 12, x + 12, y + 12], outline=(255, 220, 0), width=4)
        d.text((x + 16, y - 8), f"{o['id']} (p{o['priority']})", fill=(255, 255, 255))
    hx, hy = rej.xy_de(rej.habitat)
    d.rectangle([hx / 2 - 10, hy / 2 - 10, hx / 2 + 10, hy / 2 + 10], outline=(255, 255, 255), width=4)
    d.text((hx / 2 + 14, hy / 2 - 8), "habitat", fill=(255, 255, 255))
    im.resize((1500, 1500), Image.LANCZOS).save(ruta_img, quality=90)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cell", type=float, default=None, help="tamaño de celda de ruteo en metros (2 o 4)")
    ap.add_argument("--modo", choices=["foot", "rover", "support", "pair", "objetivo"], default="foot", help="a pie (por defecto), con rover, con rover de apoyo, en pareja o con el transporte de cada objetivo")
    args = ap.parse_args()
    p = common.params()
    if args.cell:
        p["routing"]["cell_m"] = args.cell
    mod = routing.Modelo(p)
    t0 = time.perf_counter()
    rej = routing.Rejilla(mod)
    t_carga = time.perf_counter() - t0
    plan = routing.Planificador(rej, mod, cargar_objetivos(), modo=args.modo)
    for o in plan.obj:
        print(f"objetivo {o['id']}: prioridad {o['priority']}, celda {o['idx'] % rej.ancho},{o['idx'] // rej.ancho}"
              f"{', EN ZONA PROHIBIDA' if o['bloqueado'] else ''}")
    t1 = time.perf_counter()
    extra = {}
    if args.modo == "pair":
        pr = plan.pareja()
        res = pr["routes"]
        extra = {"pair": pr["pair"], "pair_status": pr["status"], "max_separation_limit_m": pr["max_separation_limit_m"]}
    else:
        res = plan.las_tres()
    t_calc = time.perf_counter() - t1
    print(f"rejilla {rej.ancho} x {rej.alto} a {rej.celda:g} m; carga {t_carga:.1f} s; cálculo de las tres rutas {t_calc:.1f} s "
          f"con {plan.busquedas} búsquedas A*")
    imprimir(res, mod)
    if extra.get("pair"):
        pa = extra["pair"]
        print(f"\n== pareja: visitan {pa['visited']}, separación máxima {pa['max_separation_m']:.0f} m (límite {extra['max_separation_limit_m']:.0f}), tiempo {pa['total_h']:.2f} h, éxito {pa['success']['score']:.1f}, peligro {pa['hazard']:.1f}")

    sal = os.path.join(common.WORK, "rutas")
    os.makedirs(sal, exist_ok=True)
    os.makedirs(common.DOCS, exist_ok=True)
    nombre = f"{rej.celda:g}m" + ("_" + args.modo if args.modo != "foot" else "")
    doc = {"cell_m": rej.celda, "mode": args.modo, "grid": [rej.ancho, rej.alto], "habitat_cell": [rej.habitat % rej.ancho, rej.habitat // rej.ancho],
           "seconds": t_calc, "astar_searches": plan.busquedas, **extra,
           "objectives": [{k: v for k, v in o.items() if k != "bloqueado"} for o in plan.obj], "routes": res}
    with open(os.path.join(sal, f"rutas_{nombre}.json"), "w", encoding="utf-8") as f:
        json.dump(doc, f)
    with open(os.path.join(sal, f"rutas_{nombre}.geojson"), "w", encoding="utf-8") as f:
        json.dump(geojson(res, rej), f)
    dibujar(res, rej, plan, os.path.join(common.DOCS, f"fase2_rutas_{nombre}.jpg"))
    print("\nescrito en data/work/rutas/ y docs/")


if __name__ == "__main__":
    main()
